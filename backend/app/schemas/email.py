"""Email schemas."""

from __future__ import annotations

from datetime import datetime
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


class EmailBodyOut(BaseModel):
    """Full email body response."""

    email_id: str
    body_text: str | None = None
    body_html: str | None = None
    has_attachments: bool
    fetched_at: datetime | None = None

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
