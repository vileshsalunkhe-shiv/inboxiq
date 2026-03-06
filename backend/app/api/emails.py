"""Email endpoints."""

from __future__ import annotations

from datetime import datetime
import traceback
from email.utils import getaddresses

from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi_limiter.depends import RateLimiter
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
import structlog

from app.api.deps import get_current_user
from app.database import get_db
from app.models import AIQueue, Email, User
from app.schemas.email import AttachmentMetadata, EmailBodyOut, EmailList, EmailOut
from app.schemas.email_actions import (
    BulkActionRequest,
    BulkActionResponse,
    ComposeEmailRequest,
    ForwardEmailRequest,
    MessageActionResponse,
    ReadStatusRequest,
    ReplyEmailRequest,
    SimpleActionResponse,
    StarStatusRequest,
)
from app.services.auth_service import AuthService
from app.services.gmail_service import GmailService

router = APIRouter(prefix="/emails", tags=["emails"])
logger = structlog.get_logger()


def _parse_addresses(value: str | None) -> list[str]:
    if not value:
        return []
    return [addr for _, addr in getaddresses([value]) if addr]


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
                body_preview=e.snippet,  # Fixed: map snippet → body_preview
                received_date=e.received_at,  # Fixed: map received_at → received_date
                is_unread=e.is_unread,  # Fixed: add is_unread
                is_starred=False,  # Fixed: default False (column doesn't exist yet)
                category=e.category,
                ai_summary=e.ai_summary,
                ai_confidence=e.ai_confidence,
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
            body_preview=e.snippet,  # Fixed: map snippet → body_preview
            received_date=e.received_at,  # Fixed: map received_at → received_date
            is_unread=e.is_unread,  # Fixed: add is_unread
            is_starred=False,  # Fixed: default False (column doesn't exist yet)
            category=e.category,
            ai_summary=e.ai_summary,
            ai_confidence=e.ai_confidence,
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
        body_preview=email.snippet,  # Fixed: map snippet → body_preview
        received_date=email.received_at,  # Fixed: map received_at → received_date
        is_unread=email.is_unread,  # Fixed: add is_unread
        is_starred=False,  # Fixed: default False (column doesn't exist yet)
        category=email.category,
        ai_summary=email.ai_summary,
        ai_confidence=email.ai_confidence,
    )


@router.get("/{gmail_id}/body", response_model=EmailBodyOut)
async def get_email_body(
    gmail_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> EmailBodyOut:
    """Fetch full email body from Gmail API, with caching."""
    print(f"🔍 EMAIL BODY REQUEST: gmail_id={gmail_id}, user_id={current_user.id}, user_email={current_user.email}")
    logger.info(
        "email_body_request",
        gmail_id=gmail_id,
        user_id=str(current_user.id),
        user_email=current_user.email,
    )
    
    stmt = select(Email).where(Email.gmail_id == gmail_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    
    if not email:
        # Detailed diagnostics
        any_user_stmt = select(Email).where(Email.gmail_id == gmail_id)
        any_result = await db.execute(any_user_stmt)
        any_email = any_result.scalar_one_or_none()
        
        # Count total emails for this user
        count_stmt = select(func.count()).select_from(Email).where(Email.user_id == current_user.id)
        count_result = await db.execute(count_stmt)
        total_emails = count_result.scalar_one()
        
        if any_email:
            print(f"❌ USER MISMATCH: gmail_id={gmail_id}, requested_user={current_user.id}, email_user={any_email.user_id}, total_emails={total_emails}")
            logger.error(
                "email_body_user_mismatch",
                gmail_id=gmail_id,
                requested_user_id=str(current_user.id),
                email_user_id=str(any_email.user_id),
                total_emails_for_user=total_emails,
            )
        else:
            print(f"❌ EMAIL NOT FOUND: gmail_id={gmail_id}, user_id={current_user.id}, total_emails_for_user={total_emails}")
            logger.error(
                "email_body_not_found",
                gmail_id=gmail_id,
                user_id=str(current_user.id),
                total_emails_for_user=total_emails,
                hint="Email may not have synced yet due to rate limiting",
            )
        
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Email not synced yet. Please refresh your inbox.",
        )

    # Check if body is already cached
    if email.body_fetched_at and (email.body_text or email.body_html):
        logger.info(
            "email_body_cache_hit",
            gmail_id=gmail_id,
            has_text=bool(email.body_text),
            has_html=bool(email.body_html),
            cached_at=email.body_fetched_at.isoformat() if email.body_fetched_at else None,
        )
        return EmailBodyOut(
            message_id=email.gmail_id,
            html_body=email.body_html,
            text_body=email.body_text,
            has_attachments=bool(email.has_attachments),
            attachments=[],
            fetched_at=email.body_fetched_at,
        )

    # Fetch from Gmail API
    logger.info("email_body_fetching_from_gmail", gmail_id=gmail_id, email_subject=email.subject)
    
    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    gmail_service = GmailService()

    try:
        body_data = await gmail_service.get_email_body(access_token, email.gmail_id)
        logger.info(
            "email_body_fetch_success",
            gmail_id=gmail_id,
            has_text=bool(body_data.get("text")),
            has_html=bool(body_data.get("html")),
            has_attachments=body_data.get("has_attachments", False),
        )
    except Exception as exc:
        logger.error(
            "email_body_fetch_failed",
            user_id=current_user.id,
            gmail_id=gmail_id,
            error_type=type(exc).__name__,
            error_message=str(exc),
            traceback=traceback.format_exc(),
        )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Failed to fetch email body from Gmail",
        )

    attachments_metadata: list[AttachmentMetadata] = []
    for idx, part in enumerate(body_data.get("parts", []) or []):
        if part.get("filename"):
            attachments_metadata.append(
                AttachmentMetadata(
                    index=idx,
                    filename=part["filename"],
                    mime_type=part.get("mimeType", "application/octet-stream"),
                    size=part.get("body", {}).get("size", 0),
                )
            )

    email.body_text = body_data.get("text")
    email.body_html = body_data.get("html")
    email.has_attachments = body_data.get("has_attachments", False)
    email.body_fetched_at = datetime.utcnow()
    await db.commit()

    return EmailBodyOut(
        message_id=email.gmail_id,
        html_body=email.body_html,
        text_body=email.body_text,
        has_attachments=bool(email.has_attachments),
        attachments=attachments_metadata,
        fetched_at=email.body_fetched_at,
    )


@router.post(
    "/compose",
    response_model=MessageActionResponse,
    dependencies=[Depends(RateLimiter(times=30, minutes=1))],
)
async def compose_email(
    payload: ComposeEmailRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageActionResponse:
    """Send a new email via Gmail API."""
    try:
        logger.info("email_compose_started", user_id=current_user.id, to=payload.to)
        auth_service = AuthService(db)
        access_token = await auth_service.get_google_access_token(current_user)
        gmail_service = GmailService()
        raw_message = gmail_service.build_email_message(
            from_email=current_user.email,
            to=[str(addr) for addr in payload.to],
            subject=payload.subject,
            body=payload.body,
            cc=[str(addr) for addr in payload.cc] if payload.cc else None,
            bcc=[str(addr) for addr in payload.bcc] if payload.bcc else None,
            attachments=[attachment.model_dump() for attachment in payload.attachments]
            if payload.attachments
            else None,
        )
        response = await gmail_service.send_message(access_token, raw_message)
        message_id = response.get("id", "")
        logger.info("email_compose_sent", user_id=current_user.id, message_id=message_id)
        return MessageActionResponse(message_id=message_id, status="sent")
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "email_compose_failed",
            user_id=current_user.id,
            error_type=type(exc).__name__,
            error_message=str(exc),
            traceback=traceback.format_exc(),
        )
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Compose failed: {exc}")


@router.post(
    "/{email_id}/reply",
    response_model=MessageActionResponse,
    dependencies=[Depends(RateLimiter(times=30, minutes=1))],
)
async def reply_email(
    email_id: int,
    payload: ReplyEmailRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageActionResponse:
    """Reply to an email via Gmail API."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    try:
        auth_service = AuthService(db)
        access_token = await auth_service.get_google_access_token(current_user)
        gmail_service = GmailService()
        message = await gmail_service.get_message(access_token, email.gmail_id, format="metadata")
        headers = {h["name"].lower(): h["value"] for h in message.get("payload", {}).get("headers", [])}

        reply_to_header = headers.get("reply-to") or headers.get("from") or ""
        reply_to_addresses = _parse_addresses(reply_to_header)
        reply_to = reply_to_addresses[0] if reply_to_addresses else ""
        if not reply_to:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Unable to determine reply-to address")

        subject = headers.get("subject", "")
        if subject and not subject.lower().startswith("re:"):
            subject = f"Re: {subject}".strip()
        elif not subject:
            subject = "Re:"

        in_reply_to = headers.get("message-id")
        if not in_reply_to:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing Message-ID for reply")

        references = headers.get("references")
        if references:
            references = f"{references} {in_reply_to}"
        else:
            references = in_reply_to

        to_list = [reply_to]
        cc_list: list[str] | None = None
        if payload.reply_all:
            original_to = _parse_addresses(headers.get("to"))
            original_cc = _parse_addresses(headers.get("cc"))
            exclude = {current_user.email.lower(), reply_to.lower()}
            cc_list = [addr for addr in (original_to + original_cc) if addr and addr.lower() not in exclude]

        raw_message = gmail_service.build_email_message(
            from_email=current_user.email,
            to=to_list,
            subject=subject,
            body=payload.body,
            cc=cc_list,
            in_reply_to=in_reply_to,
            references=references,
        )
        response = await gmail_service.send_message(
            access_token,
            raw_message,
            thread_id=message.get("threadId"),
        )
        message_id = response.get("id", "")
        logger.info("email_reply_sent", user_id=current_user.id, email_id=email_id, message_id=message_id)
        return MessageActionResponse(message_id=message_id, status="sent")
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "email_reply_failed",
            user_id=current_user.id,
            email_id=email_id,
            error_type=type(exc).__name__,
            error_message=str(exc),
            traceback=traceback.format_exc(),
        )
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Reply failed: {exc}")


@router.post(
    "/{email_id}/forward",
    response_model=MessageActionResponse,
    dependencies=[Depends(RateLimiter(times=30, minutes=1))],
)
async def forward_email(
    email_id: int,
    payload: ForwardEmailRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> MessageActionResponse:
    """Forward an email via Gmail API."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    try:
        auth_service = AuthService(db)
        access_token = await auth_service.get_google_access_token(current_user)
        gmail_service = GmailService()
        message = await gmail_service.get_message(access_token, email.gmail_id, format="full")
        headers = {h["name"].lower(): h["value"] for h in message.get("payload", {}).get("headers", [])}

        subject = headers.get("subject", "")
        if subject and not subject.lower().startswith("fwd:"):
            subject = f"Fwd: {subject}".strip()
        elif not subject:
            subject = "Fwd:"

        original_text = gmail_service.extract_plain_text(message.get("payload", {}) or {})
        if not original_text:
            original_text = message.get("snippet", "")

        forwarded_block = (
            "---------- Forwarded message ----------\n"
            f"From: {headers.get('from', '')}\n"
            f"Date: {headers.get('date', '')}\n"
            f"Subject: {headers.get('subject', '')}\n"
            f"To: {headers.get('to', '')}\n\n"
            f"{original_text}"
        )

        body_prefix = payload.body or ""
        body = f"{body_prefix}\n\n{forwarded_block}" if body_prefix else forwarded_block

        raw_message = gmail_service.build_email_message(
            from_email=current_user.email,
            to=[str(addr) for addr in payload.to],
            subject=subject,
            body=body,
        )
        response = await gmail_service.send_message(access_token, raw_message)
        message_id = response.get("id", "")
        logger.info("email_forward_sent", user_id=current_user.id, email_id=email_id, message_id=message_id)
        return MessageActionResponse(message_id=message_id, status="sent")
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "email_forward_failed",
            user_id=current_user.id,
            email_id=email_id,
            error_type=type(exc).__name__,
            error_message=str(exc),
            traceback=traceback.format_exc(),
        )
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Forward failed: {exc}")


@router.post("/{email_id}/archive", response_model=SimpleActionResponse)
async def archive_email_post(
    email_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SimpleActionResponse:
    """Archive an email (remove INBOX label)."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    try:
        auth_service = AuthService(db)
        access_token = await auth_service.get_google_access_token(current_user)
        gmail_service = GmailService()
        await gmail_service.archive_message(access_token, email.gmail_id)
        email.is_archived = True
        await db.commit()
        logger.info("email_archived", user_id=current_user.id, email_id=email_id)
        return SimpleActionResponse(status="archived")
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "email_archive_failed",
            user_id=current_user.id,
            email_id=email_id,
            error_type=type(exc).__name__,
            error_message=str(exc),
            traceback=traceback.format_exc(),
        )
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Archive failed: {exc}")


@router.put("/{email_id}/read", response_model=SimpleActionResponse)
async def update_read_status(
    email_id: int,
    payload: ReadStatusRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SimpleActionResponse:
    """Mark an email as read/unread."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    try:
        auth_service = AuthService(db)
        access_token = await auth_service.get_google_access_token(current_user)
        gmail_service = GmailService()
        if payload.read:
            await gmail_service.mark_as_read(access_token, email.gmail_id)
            email.is_unread = False
            status_label = "read"
        else:
            await gmail_service.mark_as_unread(access_token, email.gmail_id)
            email.is_unread = True
            status_label = "unread"
        await db.commit()
        logger.info("email_read_status_updated", user_id=current_user.id, email_id=email_id, status=status_label)
        return SimpleActionResponse(status=status_label)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "email_read_failed",
            user_id=current_user.id,
            email_id=email_id,
            error_type=type(exc).__name__,
            error_message=str(exc),
            traceback=traceback.format_exc(),
        )
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Read update failed: {exc}")


@router.put("/{email_id}/star", response_model=SimpleActionResponse)
async def update_star_status(
    email_id: int,
    payload: StarStatusRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SimpleActionResponse:
    """Star or unstar an email."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    try:
        auth_service = AuthService(db)
        access_token = await auth_service.get_google_access_token(current_user)
        gmail_service = GmailService()
        if payload.starred:
            await gmail_service.add_star(access_token, email.gmail_id)
            status_label = "starred"
        else:
            await gmail_service.remove_star(access_token, email.gmail_id)
            status_label = "unstarred"
        logger.info("email_star_updated", user_id=current_user.id, email_id=email_id, status=status_label)
        return SimpleActionResponse(status=status_label)
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(
            "email_star_failed",
            user_id=current_user.id,
            email_id=email_id,
            error_type=type(exc).__name__,
            error_message=str(exc),
            traceback=traceback.format_exc(),
        )
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Star update failed: {exc}")


@router.post(
    "/bulk",
    response_model=BulkActionResponse,
    dependencies=[Depends(RateLimiter(times=10, minutes=1))],
)
async def bulk_email_action(
    payload: BulkActionRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> BulkActionResponse:
    """Perform bulk operations on emails."""
    action = payload.action.lower()
    if action not in {"archive", "delete", "read", "star"}:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid bulk action")
    if action in {"read", "star"} and payload.value is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Value is required for read/star actions")

    stmt = select(Email).where(Email.user_id == current_user.id, Email.id.in_(payload.email_ids))
    result = await db.execute(stmt)
    emails = result.scalars().all()
    email_map = {email.id: email for email in emails}

    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)
    gmail_service = GmailService()

    success_count = 0
    failed_ids: list[int] = []

    for email_id in payload.email_ids:
        email = email_map.get(email_id)
        if not email:
            failed_ids.append(email_id)
            continue
        try:
            if action == "archive":
                await gmail_service.archive_message(access_token, email.gmail_id)
                email.is_archived = True
            elif action == "delete":
                await gmail_service.delete_message(access_token, email.gmail_id)
                await db.delete(email)
            elif action == "read":
                if payload.value:
                    await gmail_service.mark_as_read(access_token, email.gmail_id)
                    email.is_unread = False
                else:
                    await gmail_service.mark_as_unread(access_token, email.gmail_id)
                    email.is_unread = True
            elif action == "star":
                if payload.value:
                    await gmail_service.add_star(access_token, email.gmail_id)
                else:
                    await gmail_service.remove_star(access_token, email.gmail_id)
            success_count += 1
        except Exception as exc:
            logger.error(
                "bulk_action_failed",
                user_id=current_user.id,
                email_id=email_id,
                action=action,
                error_type=type(exc).__name__,
                error_message=str(exc),
            )
            failed_ids.append(email_id)

    await db.commit()
    logger.info(
        "bulk_action_completed",
        user_id=current_user.id,
        action=action,
        success_count=success_count,
        failed_count=len(failed_ids),
    )
    return BulkActionResponse(success_count=success_count, failed_ids=failed_ids)


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


@router.delete("/{email_id}", response_model=SimpleActionResponse)
async def delete_email(
    email_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SimpleActionResponse:
    """Delete an email (moves to trash in Gmail, removes from database)."""
    stmt = select(Email).where(Email.id == email_id, Email.user_id == current_user.id)
    result = await db.execute(stmt)
    email = result.scalar_one_or_none()
    if not email:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Email not found")

    auth_service = AuthService(db)
    access_token = await auth_service.get_google_access_token(current_user)

    gmail_service = GmailService()
    try:
        await gmail_service.delete_message(access_token, email.gmail_id)
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Gmail API error: {exc}")

    await db.delete(email)
    await db.commit()

    return SimpleActionResponse(status="deleted")


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
