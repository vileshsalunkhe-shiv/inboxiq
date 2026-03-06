"""Email schemas - FIXED to match iOS expectations."""

from __future__ import annotations

from datetime import datetime
from pydantic import BaseModel, Field


class EmailOut(BaseModel):
    """Email response payload - matches iOS Email struct."""

    # Keep id as string (DB has integer, that's fine)
    id: str
    gmail_id: str
    subject: str | None = None
    sender: str | None = None
    
    # Rename fields to match iOS
    body_preview: str | None = Field(None, alias="snippet")
    received_date: datetime | None = Field(None, alias="received_at")
    
    # Add missing fields
    is_unread: bool = True
    is_starred: bool = False  # Default False (column doesn't exist in DB yet)
    
    # Keep existing fields
    category: str | None = None
    ai_summary: str | None = None
    ai_confidence: float | None = None
    
    class Config:
        from_attributes = True
        populate_by_name = True  # Allow both field name and alias


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
