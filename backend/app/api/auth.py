"""Auth endpoints."""

from __future__ import annotations

import httpx
from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models import User
from app.models.digest_settings import DigestSettings
from app.schemas.auth import GoogleAuthRequest, GoogleCallbackRequest, RefreshRequest, TokenPair
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/google/authorize")
async def google_authorize(payload: GoogleAuthRequest, db: AsyncSession = Depends(get_db)) -> dict:
    """Return Google OAuth authorization URL."""
    auth_service = AuthService(db)
    return {"url": auth_service.build_google_auth_url(payload.redirect_uri)}


@router.post("/google/callback", response_model=TokenPair)
async def google_callback(payload: GoogleCallbackRequest, db: AsyncSession = Depends(get_db)) -> TokenPair:
    """Exchange Google OAuth code and issue JWTs."""
    auth_service = AuthService(db)
    tokens = await auth_service.exchange_code_for_tokens(payload.code, payload.redirect_uri)
    access_token = tokens.get("access_token")
    if not access_token:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing access token")

    async with httpx.AsyncClient(timeout=10) as client:
        response = await client.get(
            "https://www.googleapis.com/oauth2/v2/userinfo",
            headers={"Authorization": f"Bearer {access_token}"},
        )
        response.raise_for_status()
        profile = response.json()

    email = profile.get("email")
    if not email:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing email")

    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if not user:
        user = User(email=email)
        db.add(user)
        await db.commit()
        await db.refresh(user)
        
        # Create default digest settings for new user
        digest_settings = DigestSettings(
            user_id=user.id,
            enabled=True,
            frequency_hours=24,
            timezone="America/Chicago",
            include_action_items=True,
            include_summaries=True
        )
        db.add(digest_settings)
        await db.commit()

    if tokens.get("refresh_token"):
        await auth_service.store_google_tokens(user, tokens)

    access_jwt, refresh_jwt, expires_in = await auth_service.create_token_pair(str(user.id))
    return TokenPair(access_token=access_jwt, refresh_token=refresh_jwt, expires_in=expires_in)


@router.post("/refresh", response_model=TokenPair)
async def refresh_tokens(payload: RefreshRequest, db: AsyncSession = Depends(get_db)) -> TokenPair:
    """Rotate refresh token and issue new token pair."""
    auth_service = AuthService(db)
    try:
        access_jwt, refresh_jwt, expires_in = await auth_service.rotate_refresh_token(payload.refresh_token)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc
    return TokenPair(access_token=access_jwt, refresh_token=refresh_jwt, expires_in=expires_in)


@router.post("/logout")
async def logout(
    authorization: str | None = Header(default=None),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Revoke refresh tokens for a user (simple logout)."""
    if not authorization:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing authorization")
    token = authorization.replace("Bearer ", "")
    auth_service = AuthService(db)
    try:
        payload = auth_service.decode_token(token)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc
    user_id = payload.get("sub")
    if user_id:
        from app.models import RefreshToken
        await db.execute(
            RefreshToken.__table__.update().where(RefreshToken.user_id == user_id).values(revoked=True)
        )
        await db.commit()
    return {"status": "ok"}
