"""Email schemas."""

from __future__ import annotations

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel


class EmailOut(BaseModel):
    """Email response payload - matches iOS expectations."""

    id: str
    gmail_id: str
    subject: str | None = None
    sender: str | None = None
    body_preview: str | None = None  # Renamed from snippet
    received_date: datetime | None = None  # Renamed from received_at
    is_unread: bool = True  # Added for iOS
    is_starred: bool = False  # Added for iOS (column doesn't exist yet, default False)
    category: str | None = None
    ai_summary: str | None = None
    ai_confidence: float | None = None


class AttachmentMetadata(BaseModel):
    """Metadata for email attachment."""

    index: int
    filename: str
    mime_type: str
    size: int


class EmailBodyOut(BaseModel):
    """Email body response with attachment metadata."""

    message_id: str
    html_body: Optional[str] = None
    text_body: Optional[str] = None
    has_attachments: bool = False
    attachments: List[AttachmentMetadata] = []
    fetched_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class EmailList(BaseModel):
    """Paginated email list (Gmail pageToken based)."""

    emails: list[EmailOut]
    next_page_token: str | None = None
    has_more: bool
    total_fetched: int


class EmailFilter(BaseModel):
    """Filters for email queries."""

    category: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
