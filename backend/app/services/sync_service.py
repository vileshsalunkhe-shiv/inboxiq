"""Gmail delta sync logic."""

from __future__ import annotations

import asyncio
from datetime import datetime
from typing import Iterable

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models import AIQueue, Email, User
from app.services.auth_service import AuthService
from app.services.gmail_service import GmailService
import structlog

logger = structlog.get_logger()


class SyncService:
    """Synchronizes Gmail messages for a user."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.gmail = GmailService()
        self.auth = AuthService(db)

    async def sync_user(self, user_id: str) -> int:
        """Sync new emails for a user and queue AI processing."""
        user = await self._get_user(user_id)
        if not user.google_refresh_token:
            raise ValueError("User has no Google tokens")

        access_payload = await self.auth.refresh_google_access_token(user.google_refresh_token)
        access_token = access_payload["access_token"]

        message_ids: list[str] = []
        history_id = user.last_history_id

        if history_id:
            message_ids = await self._fetch_delta_message_ids(access_token, history_id)
        else:
            message_ids = await self._fetch_initial_message_ids(access_token)

        created = 0
        for message_id in message_ids:
            created += await self._upsert_email(access_token, user.id, message_id)
            await asyncio.sleep(0.05)  # rate limiting

        if message_ids:
            user.last_history_id = await self._fetch_latest_history_id(access_token)
            self.db.add(user)
            await self.db.commit()

        return created

    async def _get_user(self, user_id: str) -> User:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise ValueError("User not found")
        return user

    async def _fetch_initial_message_ids(self, access_token: str) -> list[str]:
        data = await self.gmail.list_messages(access_token, query="newer_than:7d")
        return [msg["id"] for msg in data.get("messages", [])]

    async def _fetch_delta_message_ids(self, access_token: str, history_id: str) -> list[str]:
        ids: list[str] = []
        page_token = None
        while True:
            history = await self.gmail.get_history(access_token, history_id, page_token)
            for entry in history.get("history", []):
                for msg in entry.get("messagesAdded", []):
                    ids.append(msg["message"]["id"])
            page_token = history.get("nextPageToken")
            if not page_token:
                break
            await asyncio.sleep(0.1)
        return ids

    async def _fetch_latest_history_id(self, access_token: str) -> str:
        profile = await self.gmail.build_client(access_token)
        request = profile.users().getProfile(userId="me")
        response = await asyncio.to_thread(request.execute)
        return response.get("historyId", "")

    async def _upsert_email(self, access_token: str, user_id: str, message_id: str) -> int:
        result = await self.db.execute(select(Email).where(Email.gmail_id == message_id))
        if result.scalar_one_or_none():
            return 0

        message = await self.gmail.get_message(access_token, message_id)
        headers = {h["name"].lower(): h["value"] for h in message.get("payload", {}).get("headers", [])}
        subject = headers.get("subject")
        sender = headers.get("from")
        snippet = message.get("snippet")
        internal_date = message.get("internalDate")
        received_at = datetime.utcfromtimestamp(int(internal_date) / 1000) if internal_date else None

        email = Email(
            user_id=user_id,
            gmail_id=message_id,
            subject=subject,
            sender=sender,
            snippet=snippet,
            received_at=received_at,
        )
        self.db.add(email)
        await self.db.flush()
        self.db.add(AIQueue(email_id=email.id))
        await self.db.commit()

        logger.info("email_synced", user_id=user_id, gmail_id=message_id)
        return 1
