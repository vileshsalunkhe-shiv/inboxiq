"""Daily digest service for InboxIQ."""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timedelta
from email.message import EmailMessage
from email.utils import parseaddr
from pathlib import Path
from typing import Any

from jinja2 import Environment, FileSystemLoader, select_autoescape
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import Email, User
from app.services.auth_service import AuthService
from app.services.calendar_service import GoogleCalendarService
from app.services.gmail_service import GmailService

logger = logging.getLogger(__name__)


class DigestService:
    """Generates and sends daily digest emails."""

    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.gmail = GmailService()
        self.calendar = GoogleCalendarService()
        self.auth = AuthService(db)
        templates_dir = Path(__file__).resolve().parents[1] / "templates"
        self.env = Environment(
            loader=FileSystemLoader(str(templates_dir)),
            autoescape=select_autoescape(["html", "xml"]),
        )

    async def _get_user(self, user_id: str) -> User:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise ValueError("User not found")
        return user

    @staticmethod
    def _truncate(value: str | None, limit: int) -> str:
        if not value:
            return ""
        if len(value) <= limit:
            return value
        return value[: max(0, limit - 1)] + "…"

    @staticmethod
    def _normalize_category(value: str | None) -> str:
        if not value:
            return "other"
        normalized = value.strip().lower().replace("-", " ").replace("_", " ")
        if "urgent" in normalized:
            return "urgent"
        if "action" in normalized:
            return "action required"
        if "finance" in normalized:
            return "finance"
        if normalized == "fyi" or "fyi" in normalized:
            return "fyi"
        if "newsletter" in normalized:
            return "newsletter"
        return "other"

    @staticmethod
    def _format_sender(value: str | None) -> tuple[str, str]:
        if not value:
            return "", ""
        name, email = parseaddr(value)
        return name or email, email

    @staticmethod
    def _format_datetime(value: datetime | None) -> str:
        if not value:
            return ""
        return value.strftime("%b %d, %I:%M %p")

    async def _get_calendar_events(self, user: User) -> list[dict[str, Any]]:
        if not user.calendar_access_token:
            return []

        time_min = datetime.utcnow()
        time_max = time_min + timedelta(hours=24)
        try:
            events = await asyncio.to_thread(
                self.calendar.list_events,
                user.calendar_access_token,
                user.calendar_refresh_token,
                10,
                time_min,
                time_max,
            )
        except Exception as exc:
            logger.warning("calendar_events_failed", exc_info=exc)
            return []

        formatted = []
        for event in events:
            formatted.append(
                {
                    "title": event.get("summary") or "Untitled event",
                    "start_time": event.get("start"),
                    "location": event.get("location"),
                    "html_link": event.get("html_link"),
                }
            )
        return formatted

    async def get_digest_data(self, user_id: str) -> dict[str, Any]:
        user = await self._get_user(user_id)

        period_end = datetime.utcnow()
        period_start = period_end - timedelta(hours=24)

        stmt = (
            select(Email)
            .where(Email.user_id == user.id, Email.received_at >= period_start)
            .order_by(Email.received_at.desc())
        )
        result = await self.db.execute(stmt)
        emails = result.scalars().all()

        unread_count = sum(1 for email in emails if email.is_unread)

        category_map = {
            "urgent": 0,
            "action required": 0,
            "finance": 0,
            "fyi": 0,
            "newsletter": 0,
            "other": 0,
        }

        urgent_candidates: list[Email] = []
        for email in emails:
            normalized = self._normalize_category(email.category)
            if normalized not in category_map:
                normalized = "other"
            category_map[normalized] += 1
            if normalized in {"urgent", "action required"}:
                urgent_candidates.append(email)

        urgent_emails = []
        for email in urgent_candidates[:5]:
            sender_name, sender_email = self._format_sender(email.sender)
            urgent_emails.append(
                {
                    "subject": self._truncate(email.subject, 60),
                    "sender_name": sender_name,
                    "sender_email": sender_email,
                    "snippet": self._truncate(email.snippet, 100),
                    "timestamp": self._format_datetime(email.received_at),
                    "link": (
                        f"https://mail.google.com/mail/u/0/#inbox/{email.gmail_id}"
                        if email.gmail_id
                        else "#"
                    ),
                }
            )

        calendar_events = await self._get_calendar_events(user)

        category_breakdown = [
            {"name": "Urgent", "count": category_map["urgent"]},
            {"name": "Action Required", "count": category_map["action required"]},
            {"name": "Finance", "count": category_map["finance"]},
            {"name": "FYI", "count": category_map["fyi"]},
            {"name": "Newsletter", "count": category_map["newsletter"]},
            {"name": "Other", "count": category_map["other"]},
        ]

        return {
            "generated_at": period_end.isoformat() + "Z",
            "digest_date": period_end.strftime("%B %d, %Y"),
            "period_start": period_start.isoformat() + "Z",
            "period_end": period_end.isoformat() + "Z",
            "email_count": len(emails),
            "unread_count": unread_count,
            "urgent_emails": urgent_emails,
            "calendar_events": calendar_events,
            "calendar_event_count": len(calendar_events),
            "category_breakdown": category_breakdown,
            "user_email": user.email,
        }

    async def generate_digest_html(self, user_id: str) -> tuple[str, dict[str, Any]]:
        data = await self.get_digest_data(user_id)
        template = self.env.get_template("digest_email.html")
        html = template.render(**data)
        return html, data

    async def send_digest_email(self, user_id: str) -> dict[str, Any]:
        user = await self._get_user(user_id)
        html, data = await self.generate_digest_html(user_id)

        subject = f"Your Daily InboxIQ Digest - {data['digest_date']}"
        message = EmailMessage()
        message["From"] = user.email
        message["To"] = user.email
        message["Subject"] = subject
        message.set_content("Your InboxIQ digest is ready. Please view in an HTML-capable email client.")
        message.add_alternative(html, subtype="html")

        access_token = await self.auth.get_google_access_token(user)
        response = await self.gmail.send_message(access_token, message.as_bytes())

        user.last_digest_sent_at = datetime.utcnow()
        self.db.add(user)
        await self.db.commit()

        return {
            "message_id": response.get("id"),
            "sent_at": datetime.utcnow().isoformat() + "Z",
            "recipient": user.email,
        }
