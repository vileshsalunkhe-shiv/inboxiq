"""Schemas for digest settings."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class DigestSettingsIn(BaseModel):
    enabled: bool
    preferred_time: str  # Format: "HH:MM" e.g. "07:00"


class DigestSettingsOut(BaseModel):
    enabled: bool
    preferred_time: str
    last_sent_at: datetime | None

    class Config:
        from_attributes = True


class DigestSendResponse(BaseModel):
    message_id: str
    sent_at: str
    recipient: str
