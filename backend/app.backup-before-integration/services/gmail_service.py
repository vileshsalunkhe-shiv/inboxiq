"""Gmail API integration."""

from __future__ import annotations

import base64
from typing import Any

import asyncio
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from googleapiclient.http import BatchHttpRequest

from app.config import settings


class GmailService:
    """Provides Gmail API operations."""

    async def build_client(self, access_token: str) -> Any:
        """Build a Gmail API client from access token."""
        creds = Credentials(token=access_token)
        return await asyncio.to_thread(build, "gmail", "v1", credentials=creds)

    async def list_messages(
        self,
        access_token: str,
        query: str | None = None,
        page_token: str | None = None,
        max_results: int | None = None,
    ) -> dict:
        """List Gmail messages with optional search query and pagination."""
        service = await self.build_client(access_token)
        request = service.users().messages().list(
            userId=settings.gmail_api_user,
            q=query,
            pageToken=page_token,
            maxResults=max_results,
        )
        return await asyncio.to_thread(request.execute)

    async def get_message(self, access_token: str, message_id: str) -> dict:
        """Fetch a Gmail message by ID."""
        service = await self.build_client(access_token)
        request = service.users().messages().get(userId=settings.gmail_api_user, id=message_id, format="metadata")
        return await asyncio.to_thread(request.execute)

    async def get_messages_batch(self, access_token: str, message_ids: list[str]) -> list[dict]:
        """
        Fetch multiple Gmail messages in a single batch request.
        
        This is much more efficient than calling get_message() in a loop (N+1 problem).
        Returns a list of message dictionaries in the same order as message_ids.
        """
        if not message_ids:
            return []
        
        service = await self.build_client(access_token)
        
        # Storage for results (order matters)
        results: dict[str, dict] = {}
        errors: dict[str, Exception] = {}
        
        def callback(request_id: str, response: dict, exception: Exception):
            """Callback for each batch request."""
            if exception:
                errors[request_id] = exception
            else:
                results[request_id] = response
        
        def create_batch():
            """Create and execute batch request synchronously."""
            batch = service.new_batch_http_request(callback=callback)
            for msg_id in message_ids:
                batch.add(
                    service.users().messages().get(
                        userId=settings.gmail_api_user,
                        id=msg_id,
                        format="metadata"
                    ),
                    request_id=msg_id
                )
            batch.execute()
        
        # Execute batch in thread pool
        await asyncio.to_thread(create_batch)
        
        # Log any errors but don't fail the whole batch
        if errors:
            import logging
            logger = logging.getLogger(__name__)
            for msg_id, error in errors.items():
                logger.error(f"Failed to fetch message {msg_id} in batch: {error}")
        
        # Return results in same order as input message_ids
        return [results.get(msg_id) for msg_id in message_ids if msg_id in results]

    async def get_history(self, access_token: str, start_history_id: str, page_token: str | None = None) -> dict:
        """Retrieve history changes since historyId."""
        service = await self.build_client(access_token)
        request = service.users().history().list(
            userId=settings.gmail_api_user,
            startHistoryId=start_history_id,
            pageToken=page_token,
            historyTypes=["messageAdded"],
        )
        return await asyncio.to_thread(request.execute)

    async def send_message(self, access_token: str, raw_message: bytes) -> dict:
        """Send an email via Gmail API."""
        service = await self.build_client(access_token)
        body = {"raw": base64.urlsafe_b64encode(raw_message).decode()}
        request = service.users().messages().send(userId=settings.gmail_api_user, body=body)
        return await asyncio.to_thread(request.execute)

    async def archive_message(self, access_token: str, message_id: str) -> dict:
        """Archive a message (remove INBOX label)."""
        service = await self.build_client(access_token)
        body = {"removeLabelIds": ["INBOX"]}
        request = service.users().messages().modify(userId=settings.gmail_api_user, id=message_id, body=body)
        return await asyncio.to_thread(request.execute)

    async def delete_message(self, access_token: str, message_id: str) -> None:
        """Delete a message (move to trash)."""
        service = await self.build_client(access_token)
        request = service.users().messages().trash(userId=settings.gmail_api_user, id=message_id)
        await asyncio.to_thread(request.execute)

    async def mark_as_read(self, access_token: str, message_id: str) -> dict:
        """Mark a message as read (remove UNREAD label)."""
        service = await self.build_client(access_token)
        body = {"removeLabelIds": ["UNREAD"]}
        request = service.users().messages().modify(userId=settings.gmail_api_user, id=message_id, body=body)
        return await asyncio.to_thread(request.execute)

    async def mark_as_unread(self, access_token: str, message_id: str) -> dict:
        """Mark a message as unread (add UNREAD label)."""
        service = await self.build_client(access_token)
        body = {"addLabelIds": ["UNREAD"]}
        request = service.users().messages().modify(userId=settings.gmail_api_user, id=message_id, body=body)
        return await asyncio.to_thread(request.execute)
