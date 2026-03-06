"""Gmail sync endpoints."""

from __future__ import annotations

import traceback
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi_limiter.depends import RateLimiter
from sqlalchemy.ext.asyncio import AsyncSession
import structlog

from app.api.deps import get_current_user
from app.database import get_db
from app.schemas.sync import SyncResponse
from app.services.sync_service import SyncService
from app.models import User

router = APIRouter(prefix="/emails", tags=["sync"])
logger = structlog.get_logger()


@router.post("/sync", response_model=SyncResponse, dependencies=[Depends(RateLimiter(times=10, minutes=1))])
async def sync_emails(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncResponse:
    """Trigger manual Gmail sync."""
    try:
        logger.info("sync_started", user_id=current_user.id, email=current_user.email)
        service = SyncService(db)
        emails_synced = await service.sync_user(str(current_user.id))
        logger.info("sync_completed", user_id=current_user.id, emails_synced=emails_synced)
        return SyncResponse(status="success", emails_synced=emails_synced)
    except Exception as e:
        logger.error(
            "sync_failed",
            user_id=current_user.id,
            error_type=type(e).__name__,
            error_message=str(e),
            traceback=traceback.format_exc()
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Sync failed: {str(e)}"
        )
