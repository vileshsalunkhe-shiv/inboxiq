"""Schemas for email action endpoints."""

from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field


class EmailAttachment(BaseModel):
    """Attachment payload for composed emails."""

    filename: str
    content_type: str = Field(default="application/octet-stream")
    data: str = Field(description="Base64-encoded attachment data")


class ComposeEmailRequest(BaseModel):
    """Request to compose a new email."""

    to: list[EmailStr]
    subject: str
    body: str
    cc: list[EmailStr] | None = None
    bcc: list[EmailStr] | None = None
    attachments: list[EmailAttachment] | None = None


class ReplyEmailRequest(BaseModel):
    """Request to reply to an email."""

    body: str
    reply_all: bool = False


class ForwardEmailRequest(BaseModel):
    """Request to forward an email."""

    to: list[EmailStr]
    body: str | None = None


class MessageActionResponse(BaseModel):
    """Response payload for message send actions."""

    message_id: str
    status: str


class SimpleActionResponse(BaseModel):
    """Response payload for simple Gmail actions."""

    status: str


class ReadStatusRequest(BaseModel):
    """Request to toggle read/unread status."""

    read: bool


class StarStatusRequest(BaseModel):
    """Request to toggle star status."""

    starred: bool


class BulkActionRequest(BaseModel):
    """Request payload for bulk email actions."""

    email_ids: list[int]
    action: str = Field(description="archive|delete|read|star")
    value: bool | None = Field(default=None, description="Required for read/star actions")


class BulkActionResponse(BaseModel):
    """Response payload for bulk actions."""

    success_count: int
    failed_ids: list[int]
