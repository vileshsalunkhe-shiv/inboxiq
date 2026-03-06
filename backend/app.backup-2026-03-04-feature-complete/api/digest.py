"""Digest endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.database import get_db
from app.models import User
from app.schemas.digest import DigestSendResponse, DigestSettingsIn, DigestSettingsOut
from app.services.digest_service import DigestService

router = APIRouter(prefix="/digest", tags=["digest"])


@router.get("/settings", response_model=DigestSettingsOut)
async def get_settings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DigestSettingsOut:
    """Get digest settings for the user."""
    service = DigestService(db)
    settings = await service.get_settings(str(current_user.id))
    return DigestSettingsOut(
        user_id=str(current_user.id),
        enabled=settings.enabled,
        frequency_hours=settings.frequency_hours,
        preferred_time=settings.preferred_time,
        timezone=settings.timezone,
        include_action_items=settings.include_action_items,
        include_summaries=settings.include_summaries,
    )


@router.put("/settings", response_model=DigestSettingsOut)
async def update_settings(
    payload: DigestSettingsIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DigestSettingsOut:
    """Update digest settings."""
    service = DigestService(db)
    settings = await service.update_settings(str(current_user.id), payload.model_dump())
    return DigestSettingsOut(
        user_id=str(current_user.id),
        enabled=settings.enabled,
        frequency_hours=settings.frequency_hours,
        preferred_time=settings.preferred_time,
        timezone=settings.timezone,
        include_action_items=settings.include_action_items,
        include_summaries=settings.include_summaries,
    )


@router.post("/send", response_model=DigestSendResponse)
async def send_digest(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DigestSendResponse:
    """Send digest immediately."""
    service = DigestService(db)
    message_id = await service.send_digest(str(current_user.id))
    if not message_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No emails to digest")
    return DigestSendResponse(status="sent", message="Digest sent")
