"""Sync schemas."""

from pydantic import BaseModel


class SyncResponse(BaseModel):
    """Sync response payload."""

    status: str
    emails_synced: int
