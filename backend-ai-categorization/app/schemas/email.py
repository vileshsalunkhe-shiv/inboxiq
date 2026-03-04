"""Email schemas."""

from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel


class EmailOut(BaseModel):
    """Email response payload."""

    id: str
    gmail_id: str
    subject: str | None = None
    sender: str | None = None
    category: str | None = None
    ai_summary: str | None = None
    ai_confidence: float | None = None
    snippet: str | None = None
    received_at: datetime | None = None


class EmailList(BaseModel):
    """Paginated email list."""

    items: list[EmailOut]
    total: int


class EmailFilter(BaseModel):
    """Filters for email queries."""

    category: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
