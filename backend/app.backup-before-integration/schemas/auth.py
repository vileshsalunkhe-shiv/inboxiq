"""Auth-related schemas."""

from __future__ import annotations

from pydantic import BaseModel, Field


class GoogleAuthRequest(BaseModel):
    """Request to generate Google OAuth URL."""

    redirect_uri: str | None = None


class GoogleCallbackRequest(BaseModel):
    """OAuth callback payload with authorization code."""

    code: str = Field(..., description="Google OAuth authorization code")
    redirect_uri: str | None = None


class TokenPair(BaseModel):
    """Access + refresh token pair."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshRequest(BaseModel):
    """Refresh token rotation request."""

    refresh_token: str
