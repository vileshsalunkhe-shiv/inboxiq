"""Authentication and token management service."""

from __future__ import annotations

from datetime import datetime
from typing import Optional

import httpx
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models import RefreshToken, User
from app.utils.security import (
    create_access_token,
    create_refresh_token,
    decrypt_token,
    encrypt_token,
    hash_token,
)


GOOGLE_OAUTH_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
GOOGLE_OAUTH_TOKEN_URL = "https://oauth2.googleapis.com/token"
GOOGLE_SCOPES = [
    "https://www.googleapis.com/auth/gmail.modify",  # Allows read, send, modify, and delete
    "openid",
    "email",
]


class AuthService:
    """Encapsulates OAuth and JWT logic."""

    def __init__(self, db: AsyncSession):
        self.db = db

    def build_google_auth_url(self, redirect_uri: Optional[str] = None) -> str:
        """Generate Google OAuth authorization URL."""
        redirect = redirect_uri or settings.google_redirect_uri
        scope = " ".join(GOOGLE_SCOPES)
        params = {
            "client_id": settings.google_client_id,
            "redirect_uri": redirect,
            "response_type": "code",
            "scope": scope,
            "access_type": "offline",
            "prompt": "consent",
        }
        query = "&".join([f"{k}={httpx.QueryParams({k: v})[k]}" for k, v in params.items()])
        return f"{GOOGLE_OAUTH_AUTH_URL}?{query}"

    async def exchange_code_for_tokens(self, code: str, redirect_uri: Optional[str] = None) -> dict:
        """Exchange authorization code for Google OAuth tokens."""
        redirect = redirect_uri or settings.google_redirect_uri
        data = {
            "code": code,
            "client_id": settings.google_client_id,
            "client_secret": settings.google_client_secret,
            "redirect_uri": redirect,
            "grant_type": "authorization_code",
        }
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.post(GOOGLE_OAUTH_TOKEN_URL, data=data)
            if response.status_code != 200:
                # Log the full error response from Google
                error_detail = response.text
                import structlog
                logger = structlog.get_logger()
                logger.error(
                    "google_oauth_token_exchange_failed",
                    status_code=response.status_code,
                    error_detail=error_detail,
                    client_id_prefix=data['client_id'][:20],
                    redirect_uri=data['redirect_uri'],
                    code_prefix=data['code'][:20] if data['code'] else None,
                )
            response.raise_for_status()
            return response.json()

    async def get_google_user_profile(self, access_token: str) -> dict:
        """Get user profile from Google using access token."""
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.get(
                "https://www.googleapis.com/oauth2/v2/userinfo",
                headers={"Authorization": f"Bearer {access_token}"}
            )
            response.raise_for_status()
            return response.json()

    async def store_google_tokens(self, user: User, tokens: dict) -> None:
        """Encrypt and store Google tokens on the user."""
        encrypted = encrypt_token(tokens.get("refresh_token", ""))
        user.google_refresh_token = encrypted
        self.db.add(user)
        await self.db.commit()

    async def create_token_pair(self, user_id: str) -> tuple[str, str, int]:
        """Create access and refresh tokens for a user."""
        access_token = create_access_token(user_id, settings.access_token_exp_minutes)
        refresh_token, expires_at = create_refresh_token(user_id, settings.refresh_token_exp_days)
        self.db.add(
            RefreshToken(
                user_id=user_id,
                token_hash=hash_token(refresh_token),
                expires_at=expires_at,
            )
        )
        await self.db.commit()
        return access_token, refresh_token, settings.access_token_exp_minutes * 60

    async def rotate_refresh_token(self, refresh_token: str) -> tuple[str, str, int]:
        """Rotate refresh token and issue new token pair."""
        payload = self.decode_token(refresh_token)
        user_id = payload.get("sub")
        stmt = select(RefreshToken).where(RefreshToken.token_hash == hash_token(refresh_token))
        result = await self.db.execute(stmt)
        token_row = result.scalar_one_or_none()
        if not token_row or token_row.revoked:
            raise ValueError("Refresh token revoked or invalid")
        token_row.revoked = True
        await self.db.commit()
        return await self.create_token_pair(user_id)

    def decode_token(self, token: str) -> dict:
        """Decode a JWT token."""
        try:
            return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        except JWTError as exc:
            raise ValueError("Invalid token") from exc

    async def get_user_from_access_token(self, token: str) -> User:
        """Fetch user from access token."""
        payload = self.decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            raise ValueError("Invalid token subject")
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise ValueError("User not found")
        return user

    async def refresh_google_access_token(self, encrypted_refresh_token: str) -> dict:
        """Refresh Gmail access token using stored refresh token."""
        refresh_token = decrypt_token(encrypted_refresh_token)
        data = {
            "client_id": settings.google_client_id,
            "client_secret": settings.google_client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token",
        }
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.post(GOOGLE_OAUTH_TOKEN_URL, data=data)
            response.raise_for_status()
            return response.json()

    async def get_google_access_token(self, user: User) -> str:
        """Get a valid Google access token for the user."""
        if not user.google_refresh_token:
            raise ValueError("User has no Google refresh token")
        
        # Refresh the access token using stored refresh token
        tokens = await self.refresh_google_access_token(user.google_refresh_token)
        return tokens.get("access_token")
