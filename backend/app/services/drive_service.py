"""Google Drive service for InboxIQ."""

from __future__ import annotations

import asyncio
import io
import logging
from datetime import datetime, timedelta
from typing import Any

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError
from googleapiclient.http import MediaIoBaseUpload
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import User
from app.services.auth_service import AuthService

logger = logging.getLogger(__name__)


class DriveService:
    """Provides Google Drive API operations."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.auth_service = AuthService(db)

    async def _get_user(self, user_id: str) -> User:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise ValueError("User not found")
        return user

    async def _build_client(self, access_token: str) -> Any:
        creds = Credentials(token=access_token)
        return await asyncio.to_thread(build, "drive", "v3", credentials=creds)

    async def upload_file(
        self,
        user_id: str,
        file_content: bytes,
        filename: str,
        mime_type: str,
        folder_id: str | None = None,
    ) -> dict:
        """Upload a file to Google Drive."""
        user = await self._get_user(user_id)
        access_token = await self.auth_service.get_google_access_token(user)
        service = await self._build_client(access_token)

        body: dict[str, Any] = {"name": filename}
        if folder_id:
            body["parents"] = [folder_id]

        media = MediaIoBaseUpload(io.BytesIO(file_content), mimetype=mime_type, resumable=False)
        request = service.files().create(
            body=body,
            media_body=media,
            fields="id,name,mimeType,webViewLink,createdTime,size",
        )
        return await asyncio.to_thread(request.execute)

    async def list_files(
        self,
        user_id: str,
        limit: int = 30,
        order_by: str = "modifiedTime desc",
    ) -> dict:
        """List user's Drive files created by InboxIQ."""
        user = await self._get_user(user_id)
        access_token = await self.auth_service.get_google_access_token(user)
        service = await self._build_client(access_token)

        request = service.files().list(
            pageSize=limit,
            orderBy=order_by,
            spaces="appDataFolder",
            q="trashed=false",
            fields="files(id,name,mimeType,webViewLink,modifiedTime,size,thumbnailLink),nextPageToken",
        )
        return await asyncio.to_thread(request.execute)

    async def get_file_metadata(self, user_id: str, file_id: str) -> dict:
        """Get metadata for a specific file."""
        user = await self._get_user(user_id)
        access_token = await self.auth_service.get_google_access_token(user)
        service = await self._build_client(access_token)

        request = service.files().get(
            fileId=file_id,
            fields="id,name,mimeType,webViewLink,modifiedTime,size,thumbnailLink,webContentLink,exportLinks",
        )
        return await asyncio.to_thread(request.execute)

    # get_download_url removed (security: no permanent URLs)

__all__ = ["DriveService", "HttpError"]
