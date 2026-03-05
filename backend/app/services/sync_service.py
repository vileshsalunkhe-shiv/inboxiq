"""Gmail delta sync logic."""

from __future__ import annotations

import asyncio
from datetime import datetime
from typing import Iterable

from sqlalchemy import func, select
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

        # Check if user has ANY emails - if not, do initial sync even if history_id exists
        email_count_stmt = select(func.count()).select_from(Email).where(Email.user_id == user.id)
        email_count_result = await self.db.execute(email_count_stmt)
        has_emails = email_count_result.scalar_one() > 0

        message_ids: list[str] = []
        history_id = user.last_history_id

        if history_id and has_emails:
            logger.info("sync_delta_mode", user_id=user_id, history_id=history_id)
            message_ids = await self._fetch_delta_message_ids(access_token, history_id)
            
            # Fallback: If delta returns few/no results, also fetch recent emails
            # This handles cases where Gmail's history API misses recent messages
            if len(message_ids) < 5:
                logger.info("sync_delta_fallback", user_id=user_id, delta_count=len(message_ids))
                recent_ids = await self._fetch_initial_message_ids(access_token)
                # Merge unique IDs (set removes duplicates)
                message_ids = list(set(message_ids + recent_ids))
                logger.info("sync_after_fallback", user_id=user_id, total_count=len(message_ids))
        else:
            logger.info("sync_initial_mode", user_id=user_id, has_emails=has_emails, history_id=history_id)
            message_ids = await self._fetch_initial_message_ids(access_token)

        logger.info("sync_message_ids_found", user_id=user_id, count=len(message_ids))

        # Process emails in batches to avoid rate limits
        created = 0
        batch_size = 10  # Process 10 emails at a time
        
        for i in range(0, len(message_ids), batch_size):
            batch = message_ids[i:i + batch_size]
            logger.info("sync_batch_processing", batch_num=i//batch_size + 1, batch_size=len(batch))
            
            for message_id in batch:
                created += await self._upsert_email(access_token, user.id, message_id)
            
            # Longer delay between batches (2 seconds) to respect rate limits
            if i + batch_size < len(message_ids):
                await asyncio.sleep(2.0)

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
        # Increased from 20 to 100 for better initial state and delta fallback
        data = await self.gmail.list_messages(access_token, query="newer_than:7d", max_results=100)
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

        # Retry logic with exponential backoff for rate limits
        max_retries = 3
        retry_delay = 1.0  # Start with 1 second
        
        for attempt in range(max_retries):
            try:
                message = await self.gmail.get_message(access_token, message_id)
                break  # Success - exit retry loop
            except Exception as e:
                # Skip deleted/missing emails (404 errors) gracefully
                if "404" in str(e) or "not found" in str(e).lower():
                    logger.warning("email_not_found_skipping", message_id=message_id, error=str(e))
                    return 0
                
                # Handle rate limit (429) with exponential backoff
                if "429" in str(e) or "rateLimitExceeded" in str(e):
                    if attempt < max_retries - 1:
                        logger.warning(
                            "rate_limit_retry",
                            message_id=message_id,
                            attempt=attempt + 1,
                            retry_delay=retry_delay
                        )
                        await asyncio.sleep(retry_delay)
                        retry_delay *= 2  # Exponential backoff
                        continue
                    else:
                        # Max retries reached - skip this email
                        logger.error("rate_limit_max_retries", message_id=message_id)
                        return 0
                
                # Re-raise other errors
                raise
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
        await self.db.refresh(email)  # ✅ Refresh to get database-generated ID
        self.db.add(AIQueue(email_id=email.id))
        await self.db.commit()

        logger.info("email_synced", user_id=user_id, gmail_id=message_id)
        return 1
