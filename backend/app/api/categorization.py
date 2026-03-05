"""Email categorization endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.database import get_db
from app.models import Email, User
from app.schemas.email import EmailOut
from app.services.ai_categorization_service import AICategorizationService, CATEGORIES

router = APIRouter(tags=["categorization"])


@router.post("/emails/{email_id}/categorize", response_model=EmailOut)
async def categorize_email(
    email_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> EmailOut:
    """Categorize a single email using Claude."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    service = AICategorizationService()
    result = await service.categorize_email(email.subject, email.sender, email.snippet, email.body)
    email.category = result.category
    email.ai_summary = result.summary
    email.ai_confidence = result.confidence
    await db.commit()

    return EmailOut(
        id=str(email.id),
        gmail_id=email.gmail_id,
        subject=email.subject,
        sender=email.sender,
        body_preview=email.snippet,  # Fixed: map snippet → body_preview
        received_date=email.received_at,  # Fixed: map received_at → received_date
        is_unread=email.is_unread,  # Fixed: add is_unread
        is_starred=False,  # Fixed: default False (column doesn't exist yet)
        category=email.category,
        ai_summary=email.ai_summary,
        ai_confidence=email.ai_confidence,
    )


@router.post("/emails/categorize-all")
async def categorize_all(
    limit: int = Query(default=200, le=500),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Categorize all uncategorized emails for the current user."""
    stmt = (
        select(Email)
        .where(Email.user_id == current_user.id, Email.category.is_(None))
        .order_by(Email.received_at.desc())
        .limit(limit)
    )
    result = await db.execute(stmt)
    emails = result.scalars().all()
    if not emails:
        return {"processed": 0, "limit": limit}

    service = AICategorizationService()
    processed = 0
    for email in emails:
        ai_result = await service.categorize_email(email.subject, email.sender, email.snippet, email.body)
        email.category = ai_result.category
        email.ai_summary = ai_result.summary
        email.ai_confidence = ai_result.confidence
        processed += 1

    await db.commit()
    return {"processed": processed, "limit": limit}


@router.get("/categories/stats")
async def category_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Return count of emails per category for the current user."""
    stmt = (
        select(Email.category, func.count())
        .where(Email.user_id == current_user.id)
        .group_by(Email.category)
    )
    result = await db.execute(stmt)
    rows = result.all()

    stats = {category: 0 for category in CATEGORIES}
    stats["Uncategorized"] = 0
    for category, count in rows:
        key = category or "Uncategorized"
        stats[key] = count

    return {"stats": stats}
