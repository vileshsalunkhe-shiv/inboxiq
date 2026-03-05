"""Digest API endpoints."""

from __future__ import annotations

import logging
from datetime import time

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.database import get_db
from app.main import limiter
from app.models import User
from app.schemas.digest import DigestSettingsIn, DigestSettingsOut
from app.services.digest_service import DigestService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/digest", tags=["digest"])


class DigestPreviewResponse(BaseModel):
    html: str
    generated_at: str
    email_count: int
    calendar_event_count: int


class DigestSendResponse(BaseModel):
    success: bool
    message_id: str | None
    sent_at: str
    recipient: str


@router.get("/preview", response_model=DigestPreviewResponse)
@limiter.limit("10/minute")
async def preview_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DigestPreviewResponse:
    """Return HTML preview of the daily digest email."""
    service = DigestService(db)
    try:
        html, data = await service.generate_digest_html(str(current_user.id))
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("digest_preview_failed")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate digest preview",
        ) from exc

    return DigestPreviewResponse(
        html=html,
        generated_at=data["generated_at"],
        email_count=data["email_count"],
        calendar_event_count=data["calendar_event_count"],
    )


@router.post("/send", response_model=DigestSendResponse)
@limiter.limit("5/minute")
async def send_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DigestSendResponse:
    """Generate and send the daily digest email via Gmail API."""
    service = DigestService(db)
    try:
        result = await service.send_digest_email(str(current_user.id))
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc
    except Exception as exc:
        logger.exception("digest_send_failed")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to send digest email",
        ) from exc

    return DigestSendResponse(
        success=True,
        message_id=result.get("message_id"),
        sent_at=result.get("sent_at"),
        recipient=result.get("recipient"),
    )


@router.get("/settings", response_model=DigestSettingsOut)
@limiter.limit("20/minute")
async def get_digest_settings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DigestSettingsOut:
    """Get the current user's digest preferences."""
    preferred_time = (
        current_user.digest_time.strftime("%H:%M") if current_user.digest_time else "07:00"
    )
    return DigestSettingsOut(
        enabled=current_user.digest_enabled,
        preferred_time=preferred_time,
        last_sent_at=current_user.last_digest_sent_at,
    )


@router.put("/settings", response_model=DigestSettingsOut)
@limiter.limit("20/minute")
async def update_digest_settings(
    settings: DigestSettingsIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DigestSettingsOut:
    """Update the current user's digest preferences."""
    try:
        hour, minute = map(int, settings.preferred_time.split(":"))
        digest_time = time(hour, minute)
    except (TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="preferred_time must be in HH:MM format",
        ) from exc

    current_user.digest_enabled = settings.enabled
    current_user.digest_time = digest_time

    await db.commit()
    await db.refresh(current_user)

    return DigestSettingsOut(
        enabled=current_user.digest_enabled,
        preferred_time=current_user.digest_time.strftime("%H:%M"),
        last_sent_at=current_user.last_digest_sent_at,
    )
