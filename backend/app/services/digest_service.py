"""Daily digest service."""

from __future__ import annotations

from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import DigestSettings, Email, User
from app.services.ai_service import AIService
from app.services.auth_service import AuthService
from app.services.gmail_service import GmailService


class DigestService:
    """Generates and sends digest emails."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.ai = AIService()
        self.gmail = GmailService()
        self.auth = AuthService(db)

    async def get_settings(self, user_id: str) -> DigestSettings:
        """Fetch digest settings for user, create defaults if missing."""
        result = await self.db.execute(select(DigestSettings).where(DigestSettings.user_id == user_id))
        settings_row = result.scalar_one_or_none()
        if settings_row:
            return settings_row
        settings_row = DigestSettings(user_id=user_id, frequency_hours=settings.default_digest_frequency_hours)
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
        html = f"<h1>InboxIQ Digest</h1><p>{payload.get('insights', '')}</p>"

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

        access_payload = await self.auth.refresh_google_access_token(user.google_tokens_encrypted)
        access_token = access_payload["access_token"]

        raw_message = self._format_digest_email(user.email, payload)
        response = await self.gmail.send_message(access_token, raw_message)
        return response.get("id")
