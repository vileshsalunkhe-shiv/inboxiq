"""Public action endpoints for email digests."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path
from urllib.parse import quote

from fastapi import APIRouter, Depends, Request
from fastapi.responses import RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import Email, User
from app.services.auth_service import AuthService
from app.services.gmail_service import GmailService
from app.utils.action_tokens import validate_action_token

router = APIRouter(prefix="/actions", tags=["actions"])

TEMPLATES_DIR = Path(__file__).resolve().parents[1] / "templates"
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


def _compose_reply_url(email: Email) -> str:
    subject = f"Re: {email.subject or ''}".strip()
    to_addr = email.sender or ""
    return (
        "https://mail.google.com/mail/u/0/?view=cm&fs=1"
        f"&to={quote(to_addr)}&su={quote(subject)}"
    )


@router.get("/{action_token}")
async def handle_action(
    action_token: str,
    request: Request,
    db: AsyncSession = Depends(get_db),
):
    """Handle public action links from digest emails."""
    try:
        token_row, payload = await validate_action_token(db, action_token)
        user_id = payload.get("sub")
        email_id = payload.get("email_id")
        action = payload.get("action")

        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise ValueError("User not found")

        email_result = await db.execute(select(Email).where(Email.id == email_id))
        email = email_result.scalar_one_or_none()
        if not email:
            raise ValueError("Email not found")

        auth_service = AuthService(db)
        gmail_service = GmailService()

        if action == "reply":
            token_row.used_at = datetime.utcnow()
            db.add(token_row)
            await db.commit()
            return RedirectResponse(_compose_reply_url(email))

        access_token = await auth_service.get_google_access_token(user)

        if action == "archive":
            await gmail_service.archive_message(access_token, email.gmail_id)
            email.is_archived = True
        elif action == "delete":
            await gmail_service.delete_message(access_token, email.gmail_id)
        else:
            raise ValueError("Unknown action")

        token_row.used_at = datetime.utcnow()
        db.add(token_row)
        db.add(email)
        await db.commit()

        message = f"✅ Email {action}d successfully! You can close this tab."
        return templates.TemplateResponse(
            "action_success.html",
            {"request": request, "message": message},
        )
    except Exception as exc:  # noqa: BLE001 - return safe error page
        return templates.TemplateResponse(
            "action_error.html",
            {"request": request, "message": str(exc)},
            status_code=400,
        )
