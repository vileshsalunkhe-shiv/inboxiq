"""Gmail sync endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends
from fastapi_limiter.depends import RateLimiter
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.database import get_db
from app.schemas.sync import SyncResponse
from app.services.sync_service import SyncService
from app.models import User

router = APIRouter(prefix="/emails", tags=["sync"])


@router.post("/sync", response_model=SyncResponse, dependencies=[Depends(RateLimiter(times=10, minutes=1))])
async def sync_emails(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncResponse:
    """Trigger manual Gmail sync."""
    service = SyncService(db)
    emails_synced = await service.sync_user(str(current_user.id))
    return SyncResponse(status="success", emails_synced=emails_synced)
