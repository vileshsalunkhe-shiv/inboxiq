"""Email endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.database import get_db
from app.models import Email, User
from app.schemas.email import EmailList, EmailOut

router = APIRouter(prefix="/emails", tags=["emails"])


@router.get("", response_model=EmailList)
async def list_emails(
    category: str | None = Query(default=None),
    start_date: str | None = Query(default=None),
    end_date: str | None = Query(default=None),
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> EmailList:
    """List emails with optional filters."""
    filters = [Email.user_id == current_user.id]
    if category:
        filters.append(Email.category == category)
    if start_date:
        filters.append(Email.received_at >= start_date)
    if end_date:
        filters.append(Email.received_at <= end_date)

    stmt = select(Email).where(and_(*filters)).order_by(Email.received_at.desc()).limit(limit).offset(offset)
    result = await db.execute(stmt)
    items = result.scalars().all()

    count_stmt = select(func.count()).select_from(Email).where(and_(*filters))
    count_result = await db.execute(count_stmt)
    total = count_result.scalar_one()

    return EmailList(
        items=[EmailOut(
            id=str(e.id),
            gmail_id=e.gmail_id,
            subject=e.subject,
            sender=e.sender,
            category=e.category,
            snippet=e.snippet,
            received_at=e.received_at,
        ) for e in items],
        total=total,
    )


@router.get("/{email_id}", response_model=EmailOut)
async def get_email(
    email_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> EmailOut:
    """Get a single email by ID."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")
    return EmailOut(
        id=str(email.id),
        gmail_id=email.gmail_id,
        subject=email.subject,
        sender=email.sender,
        category=email.category,
        snippet=email.snippet,
        received_at=email.received_at,
    )
