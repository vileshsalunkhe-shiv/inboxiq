"""Daily digest service."""

from __future__ import annotations

import uuid
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path
from typing import Any

from jinja2 import Environment, FileSystemLoader, select_autoescape
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import DigestSettings, Email, User
from app.services.ai_service import AIService
from app.services.auth_service import AuthService
from app.services.gmail_service import GmailService
from app.utils.action_tokens import create_action_token


class DigestService:
    """Generates and sends digest emails."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.ai = AIService()
        self.gmail = GmailService()
        self.auth = AuthService(db)

    async def get_settings(self, user_id: str) -> DigestSettings:
        """Fetch digest settings for user, create defaults if missing."""
        user_uuid = uuid.UUID(user_id)
        result = await self.db.execute(select(DigestSettings).where(DigestSettings.user_id == user_uuid))
        settings_row = result.scalar_one_or_none()
        if settings_row:
            return settings_row
        # Create default settings if missing
        settings_row = DigestSettings(
            user_id=user_uuid,
            enabled=True,
            frequency_hours=24,
            timezone="America/Chicago",
            include_action_items=True,
            include_summaries=True
        )
        self.db.add(settings_row)
        await self.db.commit()
        return settings_row

    async def update_settings(self, user_id: str, payload: dict[str, Any]) -> DigestSettings:
        """Update digest settings."""
        settings_row = await self.get_settings(user_id)
        for key, value in payload.items():
            setattr(settings_row, key, value)
        settings_row.updated_at = datetime.utcnow()
        self.db.add(settings_row)
        await self.db.commit()
        return settings_row

    async def generate_digest_payload(self, user_id: str) -> dict[str, Any] | None:
        """Generate digest data for the last N hours."""
        settings_row = await self.get_settings(user_id)
        period_end = datetime.utcnow()
        period_start = period_end - timedelta(hours=settings_row.frequency_hours)

        stmt = select(Email).where(
            Email.user_id == user_id,
            Email.received_at >= period_start,
            Email.received_at < period_end,
        )
        result = await self.db.execute(stmt)
        emails = result.scalars().all()
        if not emails:
            return None

        payload = {
            "period_start": period_start.isoformat(),
            "period_end": period_end.isoformat(),
            "email_count": len(emails),
            "emails": [
                {
                    "id": e.id,
                    "subject": e.subject,
                    "sender": e.sender,
                    "category": e.category,
                    "snippet": e.snippet,
                }
                for e in emails
            ],
        }
        ai_summary = await self.ai.summarize_digest(payload)
        payload.update(ai_summary)
        return payload

    def _format_digest_email(self, user_email: str, payload: dict[str, Any]) -> bytes:
        """Format digest email as MIME message."""
        message = MIMEMultipart("alternative")
        message["to"] = user_email
        message["from"] = f"InboxIQ Digest <{user_email}>"
        message["subject"] = f"InboxIQ Digest - {payload['email_count']} emails"

        text = f"InboxIQ Digest\n\nEmail count: {payload['email_count']}\nInsights: {payload.get('insights', '')}"

        templates_dir = Path(__file__).resolve().parents[1] / "templates"
        env = Environment(
            loader=FileSystemLoader(str(templates_dir)),
            autoescape=select_autoescape(["html", "xml"]),
        )
        template = env.get_template("digest_email.html")
        html = template.render(
            insights=payload.get("insights", ""),
            emails=payload.get("emails", []),
        )

        message.attach(MIMEText(text, "plain"))
        message.attach(MIMEText(html, "html"))
        return message.as_bytes()

    async def send_digest(self, user_id: str) -> str | None:
        """Send digest email via Gmail API."""
        payload = await self.generate_digest_payload(user_id)
        if not payload:
            return None

        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one()

        # Add action links per email
        for email in payload.get("emails", []):
            email_id = email.get("id")
            archive_token = await create_action_token(self.db, user_id, email_id, "archive")
            delete_token = await create_action_token(self.db, user_id, email_id, "delete")
            reply_token = await create_action_token(self.db, user_id, email_id, "reply")
            base_url = settings.frontend_base_url.rstrip("/")
            email["archive_url"] = f"{base_url}/actions/{archive_token}"
            email["delete_url"] = f"{base_url}/actions/{delete_token}"
            email["reply_url"] = f"{base_url}/actions/{reply_token}"

        access_token = await self.auth.get_google_access_token(user)

        raw_message = self._format_digest_email(user.email, payload)
        response = await self.gmail.send_message(access_token, raw_message)
        return response.get("id")
