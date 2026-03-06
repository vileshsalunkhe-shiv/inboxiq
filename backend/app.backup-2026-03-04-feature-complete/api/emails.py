"""Email endpoints."""

from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user
from app.database import get_db
from app.models import AIQueue, Email, User
from app.schemas.email import EmailList, EmailOut
from app.services.auth_service import AuthService
from app.services.gmail_service import GmailService

router = APIRouter(prefix="/emails", tags=["emails"])


@router.get("", response_model=EmailList)
async def list_emails(
    page_token: str | None = Query(default=None, description="Gmail pageToken for pagination"),
    max_results: int = Query(default=50, ge=1, le=100, description="Results per page"),
    category: str | None = Query(default=None),
    start_date: str | None = Query(default=None),
    end_date: str | None = Query(default=None),
    limit: int = Query(default=50, le=200),
    offset: int = Query(default=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> EmailList:
    """List emails with Gmail pageToken pagination (legacy filters supported)."""
    legacy_mode = any([category, start_date, end_date, offset != 0])

    if legacy_mode:
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
            emails=[EmailOut(
                id=str(e.id),
                gmail_id=e.gmail_id,
                subject=e.subject,
                sender=e.sender,
                category=e.category,
                ai_summary=e.ai_summary,
                ai_confidence=e.ai_confidence,
                snippet=e.snippet,
                received_at=e.received_at,
            ) for e in items],
            next_page_token=None,
            has_more=(offset + len(items)) < total,
            total_fetched=len(items),
        )

    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    gmail_service = GmailService()

    data = await gmail_service.list_messages(
        access_token,
        page_token=page_token,
        max_results=max_results,
    )
    message_ids = [msg["id"] for msg in data.get("messages", [])]
    next_page_token = data.get("nextPageToken")

    emails_by_gmail_id: dict[str, Email] = {}
    new_emails: list[Email] = []
    if message_ids:
        # Fetch Gmail messages first (reduces DB queries to a single lookup)
        messages = await gmail_service.get_messages_batch(access_token, message_ids)

        existing_stmt = select(Email).where(
            Email.user_id == current_user.id,
            Email.gmail_id.in_(message_ids),
        )
        existing_result = await db.execute(existing_stmt)
        existing_emails = existing_result.scalars().all()
        existing_ids = {e.gmail_id for e in existing_emails}
        emails_by_gmail_id = {e.gmail_id: e for e in existing_emails}

        for message in messages:
            if not message:  # Skip None results from batch errors
                continue

            message_id = message.get("id")
            if not message_id or message_id in existing_ids:
                continue

            headers = {h["name"].lower(): h["value"] for h in message.get("payload", {}).get("headers", [])}
            subject = headers.get("subject")
            sender = headers.get("from")
            snippet = message.get("snippet")
            internal_date = message.get("internalDate")
            received_at = datetime.utcfromtimestamp(int(internal_date) / 1000) if internal_date else datetime.utcnow()

            email = Email(
                user_id=current_user.id,
                gmail_id=message_id,
                subject=subject,
                sender=sender,
                snippet=snippet,
                received_at=received_at,
            )
            db.add(email)
            await db.flush()
            db.add(AIQueue(email_id=email.id))
            new_emails.append(email)
            emails_by_gmail_id[message_id] = email

    if new_emails:
        await db.commit()

    ordered_emails = [emails_by_gmail_id[mid] for mid in message_ids if mid in emails_by_gmail_id]

    return EmailList(
        emails=[EmailOut(
            id=str(e.id),
            gmail_id=e.gmail_id,
            subject=e.subject,
            sender=e.sender,
            category=e.category,
            ai_summary=e.ai_summary,
            ai_confidence=e.ai_confidence,
            snippet=e.snippet,
            received_at=e.received_at,
        ) for e in ordered_emails],
        next_page_token=next_page_token,
        has_more=next_page_token is not None,
        total_fetched=len(ordered_emails),
    )


@router.get("/{email_id}", response_model=EmailOut)
async def get_email(
    email_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> EmailOut:
    """Get a single email by ID."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
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


@router.patch("/{email_id}/archive")
async def archive_email(
    email_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Archive an email (removes from inbox, syncs to Gmail)."""
    # Get email from database
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")
    
    # Get Google access token
    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    
    # Archive in Gmail
    gmail_service = GmailService()
    try:
        await gmail_service.archive_message(access_token, email.gmail_id)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gmail API error: {str(e)}")
    
    # Update local database
    email.is_archived = True
    await db.commit()
    
    return {"status": "archived", "email_id": email_id}


@router.delete("/{email_id}")
async def delete_email(
    email_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Delete an email (moves to trash in Gmail, removes from database)."""
    # Get email from database
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")
    
    # Get Google access token
    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    
    # Delete in Gmail (move to trash)
    gmail_service = GmailService()
    try:
        await gmail_service.delete_message(access_token, email.gmail_id)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gmail API error: {str(e)}")
    
    # Remove from local database
    await db.delete(email)
    await db.commit()
    
    return {"status": "deleted", "email_id": email_id}


@router.patch("/{email_id}/read")
async def mark_email_as_read(
    email_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Mark an email as read (syncs to Gmail)."""
    # Get email from database
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")
    
    # Get Google access token
    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    
    # Mark as read in Gmail
    gmail_service = GmailService()
    try:
        await gmail_service.mark_as_read(access_token, email.gmail_id)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gmail API error: {str(e)}")
    
    # Update local database
    email.is_unread = False
    await db.commit()
    
    return {"status": "read", "email_id": email_id}


@router.patch("/{email_id}/unread")
async def mark_email_as_unread(
    email_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Mark an email as unread (syncs to Gmail)."""
    # Get email from database
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")
    
    # Get Google access token
    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    
    # Mark as unread in Gmail
    gmail_service = GmailService()
    try:
        await gmail_service.mark_as_unread(access_token, email.gmail_id)
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gmail API error: {str(e)}")
    
    # Update local database
    email.is_unread = True
    await db.commit()
    
    return {"status": "unread", "email_id": email_id}
