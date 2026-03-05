"""Gmail API integration."""

from __future__ import annotations

import base64
from email.message import EmailMessage
from email.utils import formatdate
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
            userId=settings.gmail_api_authenticated_user,  # "me" = authenticated user
            q=query,
            pageToken=page_token,
            maxResults=max_results,
        )
        return await asyncio.to_thread(request.execute)

    async def get_message(self, access_token: str, message_id: str, format: str = "metadata") -> dict:
        """Fetch a Gmail message by ID."""
        service = await self.build_client(access_token)
        request = service.users().messages().get(
            userId=settings.gmail_api_authenticated_user,
            id=message_id,
            format=format,
        )
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
                        userId=settings.gmail_api_authenticated_user,
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
            userId=settings.gmail_api_authenticated_user,
            startHistoryId=start_history_id,
            pageToken=page_token,
            historyTypes=["messageAdded"],
        )
        return await asyncio.to_thread(request.execute)

    def build_email_message(
        self,
        from_email: str,
        to: list[str],
        subject: str,
        body: str,
        cc: list[str] | None = None,
        bcc: list[str] | None = None,
        attachments: list[dict[str, str]] | None = None,
        in_reply_to: str | None = None,
        references: str | None = None,
    ) -> bytes:
        """Build a raw RFC 2822 email message."""
        message = EmailMessage()
        message["From"] = from_email
        message["To"] = ", ".join(to)
        message["Subject"] = subject
        message["Date"] = formatdate(localtime=True)
        if cc:
            message["Cc"] = ", ".join(cc)
        if bcc:
            message["Bcc"] = ", ".join(bcc)
        if in_reply_to:
            message["In-Reply-To"] = in_reply_to
        if references:
            message["References"] = references

        message.set_content(body or "")

        if attachments:
            for attachment in attachments:
                filename = attachment.get("filename")
                content_type = attachment.get("content_type", "application/octet-stream")
                data = attachment.get("data", "")
                maintype, subtype = content_type.split("/", 1) if "/" in content_type else (content_type, "octet-stream")
                message.add_attachment(
                    base64.b64decode(data),
                    maintype=maintype,
                    subtype=subtype,
                    filename=filename,
                )

        return message.as_bytes()

    def _decode_body_data(self, data: str | None) -> str | None:
        if not data:
            return None
        padding = "=" * (-len(data) % 4)
        return base64.urlsafe_b64decode((data + padding).encode()).decode("utf-8", errors="replace")

    def extract_plain_text(self, payload: dict) -> str | None:
        """Extract plain text from a Gmail message payload."""
        mime_type = payload.get("mimeType")
        body = payload.get("body", {})
        data = body.get("data")
        if mime_type == "text/plain" and data:
            return base64.urlsafe_b64decode(data.encode()).decode("utf-8", errors="replace")

        for part in payload.get("parts", []) or []:
            text = self.extract_plain_text(part)
            if text:
                return text

        return None

    def extract_body_parts(self, payload: dict) -> tuple[str | None, str | None, bool]:
        """Extract text/plain and text/html parts, plus attachment indicator."""
        text: str | None = None
        html: str | None = None
        has_attachments = False

        parts = [payload]
        while parts:
            part = parts.pop(0)
            mime_type = part.get("mimeType")
            body = part.get("body", {})
            data = body.get("data")

            filename = part.get("filename")
            if filename and body.get("attachmentId"):
                has_attachments = True

            if mime_type == "text/plain" and data and text is None:
                text = self._decode_body_data(data)
            elif mime_type == "text/html" and data and html is None:
                html = self._decode_body_data(data)

            for subpart in part.get("parts", []) or []:
                parts.append(subpart)

        return text, html, has_attachments

    async def get_email_body(self, access_token: str, message_id: str) -> dict:
        """Fetch full Gmail message body (text + html) and attachment indicator."""
        service = await self.build_client(access_token)
        request = service.users().messages().get(
            userId=settings.gmail_api_authenticated_user,
            id=message_id,
            format="full",
        )
        message = await asyncio.to_thread(request.execute)
        payload = message.get("payload", {}) or {}
        text, html, has_attachments = self.extract_body_parts(payload)
        return {
            "text": text,
            "html": html,
            "has_attachments": has_attachments,
        }

    async def send_message(self, access_token: str, raw_message: bytes, thread_id: str | None = None) -> dict:
        """Send an email via Gmail API."""
        service = await self.build_client(access_token)
        body: dict[str, Any] = {"raw": base64.urlsafe_b64encode(raw_message).decode()}
        if thread_id:
            body["threadId"] = thread_id
        request = service.users().messages().send(userId=settings.gmail_api_authenticated_user, body=body)
        return await asyncio.to_thread(request.execute)

    async def archive_message(self, access_token: str, message_id: str) -> dict:
        """Archive a message (remove INBOX label)."""
        service = await self.build_client(access_token)
        body = {"removeLabelIds": ["INBOX"]}
        request = service.users().messages().modify(userId=settings.gmail_api_authenticated_user, id=message_id, body=body)
        return await asyncio.to_thread(request.execute)

    async def delete_message(self, access_token: str, message_id: str) -> None:
        """Delete a message (move to trash)."""
        service = await self.build_client(access_token)
        request = service.users().messages().trash(userId=settings.gmail_api_authenticated_user, id=message_id)
        await asyncio.to_thread(request.execute)

    async def mark_as_read(self, access_token: str, message_id: str) -> dict:
        """Mark a message as read (remove UNREAD label)."""
        service = await self.build_client(access_token)
        body = {"removeLabelIds": ["UNREAD"]}
        request = service.users().messages().modify(userId=settings.gmail_api_authenticated_user, id=message_id, body=body)
        return await asyncio.to_thread(request.execute)

    async def mark_as_unread(self, access_token: str, message_id: str) -> dict:
        """Mark a message as unread (add UNREAD label)."""
        service = await self.build_client(access_token)
        body = {"addLabelIds": ["UNREAD"]}
        request = service.users().messages().modify(userId=settings.gmail_api_authenticated_user, id=message_id, body=body)
        return await asyncio.to_thread(request.execute)

    async def add_star(self, access_token: str, message_id: str) -> dict:
        """Star a message (add STARRED label)."""
        service = await self.build_client(access_token)
        body = {"addLabelIds": ["STARRED"]}
        request = service.users().messages().modify(userId=settings.gmail_api_authenticated_user, id=message_id, body=body)
        return await asyncio.to_thread(request.execute)

    async def remove_star(self, access_token: str, message_id: str) -> dict:
        """Unstar a message (remove STARRED label)."""
        service = await self.build_client(access_token)
        body = {"removeLabelIds": ["STARRED"]}
        request = service.users().messages().modify(userId=settings.gmail_api_authenticated_user, id=message_id, body=body)
        return await asyncio.to_thread(request.execute)
