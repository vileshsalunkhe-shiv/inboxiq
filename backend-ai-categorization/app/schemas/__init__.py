"""Pydantic schemas for API."""

from app.schemas.auth import TokenPair, GoogleAuthRequest, GoogleCallbackRequest, RefreshRequest
from app.schemas.email import EmailOut, EmailList, EmailFilter
from app.schemas.sync import SyncResponse
from app.schemas.digest import DigestSettingsIn, DigestSettingsOut, DigestSendResponse

__all__ = [
    "TokenPair",
    "GoogleAuthRequest",
    "GoogleCallbackRequest",
    "RefreshRequest",
    "EmailOut",
    "EmailList",
    "EmailFilter",
    "SyncResponse",
    "DigestSettingsIn",
    "DigestSettingsOut",
    "DigestSendResponse",
]
