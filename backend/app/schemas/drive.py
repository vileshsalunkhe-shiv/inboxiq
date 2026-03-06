"""Drive schemas."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class DriveUploadRequest(BaseModel):
    """Request to upload a Gmail attachment to Google Drive."""

    email_id: str
    attachment_index: int = Field(ge=0)
    folder_id: str | None = None
    rename_to: str | None = None


class DriveUploadResponse(BaseModel):
    """Response after uploading a file to Drive."""

    file_id: str
    name: str
    mime_type: str
    web_view_link: str
    created_time: datetime | None = None
    size: int | None = None


class DriveFileResponse(BaseModel):
    """Drive file metadata."""

    id: str
    name: str
    mime_type: str | None = None
    web_view_link: str | None = None
    modified_time: datetime | None = None
    size: int | None = None
    thumbnail_link: str | None = None


class DriveFileListResponse(BaseModel):
    """List of Drive files."""

    files: list[DriveFileResponse]
    next_page_token: str | None = None


class DriveDownloadUrlResponse(BaseModel):
    """Download URL payload."""

    download_url: str
    expires_at: datetime
