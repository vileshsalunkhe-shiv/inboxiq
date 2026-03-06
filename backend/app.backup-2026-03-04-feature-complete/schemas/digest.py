"""Digest schemas."""

from __future__ import annotations

from datetime import time
from pydantic import BaseModel


class DigestSettingsIn(BaseModel):
    """Update digest settings."""

    enabled: bool = True
    frequency_hours: int = 12
    preferred_time: time | None = None
    timezone: str = "America/Chicago"
    include_action_items: bool = True
    include_summaries: bool = True


class DigestSettingsOut(DigestSettingsIn):
    """Digest settings response."""

    user_id: str


class DigestSendResponse(BaseModel):
    """Response for manual digest send."""

    status: str
    message: str
