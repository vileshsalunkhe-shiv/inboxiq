"""Drive API endpoints."""

from __future__ import annotations

import asyncio
import base64
import logging
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.config import settings
from app.database import get_db
from app.models import Email, User
from app.schemas.drive import (
    DriveFileListResponse,
    DriveFileResponse,
    DriveUploadRequest,
    DriveUploadResponse,
)
from app.services.auth_service import AuthService
from app.services.drive_service import DriveService, HttpError
from app.services.gmail_service import GmailService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/drive", tags=["drive"])


def _decode_base64url(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode((data + padding).encode("utf-8"))


def _parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    if value.endswith("Z"):
        value = value.replace("Z", "+00:00")
    return datetime.fromisoformat(value)


def _collect_attachments(payload: dict) -> list[dict]:
    attachments: list[dict] = []
    parts = [payload]
    while parts:
        part = parts.pop(0)
        filename = part.get("filename")
        body = part.get("body", {}) or {}
        attachment_id = body.get("attachmentId")
        if filename and attachment_id:
            attachments.append(
                {
                    "filename": filename,
                    "mime_type": part.get("mimeType") or "application/octet-stream",
                    "attachment_id": attachment_id,
                }
            )
        for subpart in part.get("parts", []) or []:
            parts.append(subpart)
    return attachments


def _map_google_error(exc: HttpError) -> HTTPException:
    status_code = getattr(exc, "resp", None).status if getattr(exc, "resp", None) else status.HTTP_500_INTERNAL_SERVER_ERROR
    if status_code == 401:
        return HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Google authorization failed")
    if status_code == 404:
        return HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Google resource not found")
    if status_code in (403, 429):
        return HTTPException(status_code=status.HTTP_429_TOO_MANY_REQUESTS, detail="Google API quota exceeded")
    return HTTPException(status_code=status_code, detail="Google API error")


@router.post("/upload", response_model=DriveUploadResponse)
async def upload_to_drive(
    payload: DriveUploadRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DriveUploadResponse:
    """Upload an email attachment to Google Drive."""
    try:
        email_id = int(payload.email_id)
    except (TypeError, ValueError) as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid email_id") from exc

    result = await db.execute(
        select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    )
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    gmail_service = GmailService()

    try:
        message = await gmail_service.get_message(access_token, email.gmail_id, format="full")
    except HttpError as exc:
        raise _map_google_error(exc)

    payload_data = message.get("payload", {}) or {}
    attachments = _collect_attachments(payload_data)
    if not attachments:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No attachments found")

    if payload.attachment_index >= len(attachments):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attachment index out of range")

    attachment_meta = attachments[payload.attachment_index]
    attachment_id = attachment_meta["attachment_id"]
    filename = payload.rename_to or attachment_meta["filename"]
    mime_type = attachment_meta["mime_type"]

    try:
        gmail_client = await gmail_service.build_client(access_token)
        request = gmail_client.users().messages().attachments().get(
            userId=settings.gmail_api_authenticated_user,
            messageId=email.gmail_id,
            id=attachment_id,
        )
        attachment = await asyncio.to_thread(request.execute)
    except HttpError as exc:
        raise _map_google_error(exc)

    data = attachment.get("data")
    if not data:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attachment data missing")

    file_bytes = _decode_base64url(data)

    max_file_size = 10 * 1024 * 1024
    if len(file_bytes) > max_file_size:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File size exceeds 10MB limit",
        )

    allowed_mime_types = {
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/gif",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "text/plain",
        "text/csv",
    }
    if mime_type not in allowed_mime_types:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=(
                "Unsupported file type: "
                f"{mime_type}. Allowed types: PDF, images, Office documents, text files."
            ),
        )

    drive_service = DriveService(db)
    try:
        uploaded = await drive_service.upload_file(
            user_id=str(current_user.id),
            file_content=file_bytes,
            filename=filename,
            mime_type=mime_type,
            folder_id=payload.folder_id,
        )
    except HttpError as exc:
        raise _map_google_error(exc)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    return DriveUploadResponse(
        file_id=uploaded.get("id", ""),
        name=uploaded.get("name", filename),
        mime_type=uploaded.get("mimeType", mime_type),
        web_view_link=uploaded.get("webViewLink", ""),
        created_time=_parse_datetime(uploaded.get("createdTime")),
        size=int(uploaded.get("size")) if uploaded.get("size") else None,
    )


@router.get("/files", response_model=DriveFileListResponse)
async def list_drive_files(
    limit: int = 30,
    order_by: str = "modifiedTime desc",
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DriveFileListResponse:
    """List recent Drive files created by InboxIQ."""
    drive_service = DriveService(db)
    try:
        response = await drive_service.list_files(
            user_id=str(current_user.id),
            limit=limit,
            order_by=order_by,
        )
    except HttpError as exc:
        raise _map_google_error(exc)

    files = []
    for item in response.get("files", []) or []:
        files.append(
            DriveFileResponse(
                id=item.get("id", ""),
                name=item.get("name", ""),
                mime_type=item.get("mimeType"),
                web_view_link=item.get("webViewLink"),
                modified_time=_parse_datetime(item.get("modifiedTime")),
                size=int(item.get("size")) if item.get("size") else None,
                thumbnail_link=item.get("thumbnailLink"),
            )
        )

    return DriveFileListResponse(
        files=files,
        next_page_token=response.get("nextPageToken"),
    )


@router.get("/files/{file_id}", response_model=DriveFileResponse)
async def get_drive_file(
    file_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DriveFileResponse:
    """Get metadata for a specific Drive file."""
    drive_service = DriveService(db)
    try:
        item = await drive_service.get_file_metadata(str(current_user.id), file_id)
    except HttpError as exc:
        raise _map_google_error(exc)

    return DriveFileResponse(
        id=item.get("id", ""),
        name=item.get("name", ""),
        mime_type=item.get("mimeType"),
        web_view_link=item.get("webViewLink"),
        modified_time=_parse_datetime(item.get("modifiedTime")),
        size=int(item.get("size")) if item.get("size") else None,
        thumbnail_link=item.get("thumbnailLink"),
    )


# Download URL endpoint removed (security: no permanent URLs)


@router.get("/debug/token-scopes")
async def debug_token_scopes(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Debug endpoint to check what scopes the current token has."""
    import httpx
    from app.services.auth_service import AuthService
    
    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    
    # Check token scopes with Google
    async with httpx.AsyncClient() as client:
        response = await client.get(
            "https://www.googleapis.com/oauth2/v1/tokeninfo",
            params={"access_token": access_token}
        )
        return response.json()
