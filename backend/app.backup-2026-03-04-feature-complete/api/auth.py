"""Auth endpoints."""

from __future__ import annotations

import httpx
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import RedirectResponse
from fastapi_limiter.depends import RateLimiter
from urllib.parse import urlencode
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import SQLAlchemyError

from app.api.deps import get_current_user
from app.database import get_db
from app.models import User
from app.schemas.auth import GoogleAuthRequest, GoogleCallbackRequest, RefreshRequest, TokenPair
from app.services.auth_service import AuthService
from pydantic import BaseModel

router = APIRouter(prefix="/auth", tags=["auth"])


# iOS-compatible schemas
class LoginRequest(BaseModel):
    """iOS login request with OAuth code."""
    code: str


class LoginResponse(BaseModel):
    """iOS login response with tokens and email."""
    accessToken: str
    refreshToken: str
    userEmail: str


@router.post("/google/authorize")
async def google_authorize(payload: GoogleAuthRequest, db: AsyncSession = Depends(get_db)) -> dict:
    """Return Google OAuth authorization URL."""
    auth_service = AuthService(db)
    return {"url": auth_service.build_google_auth_url(payload.redirect_uri)}


@router.get("/google/callback")
async def google_callback(code: str, db: AsyncSession = Depends(get_db)):
    """Exchange Google OAuth code and redirect to app with tokens."""
    from app.config import settings
    auth_service = AuthService(db)
    
    try:
        tokens = await auth_service.exchange_code_for_tokens(code, settings.google_redirect_uri)
        access_token = tokens.get("access_token")
        if not access_token:
            params = urlencode({"error": "missing_token"})
            return RedirectResponse(url=f"inboxiq://oauth/callback?{params}")

        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(
                "https://www.googleapis.com/oauth2/v2/userinfo",
                headers={"Authorization": f"Bearer {access_token}"},
            )
            response.raise_for_status()
            profile = response.json()

        email = profile.get("email")
        if not email:
            params = urlencode({"error": "missing_email"})
            return RedirectResponse(url=f"inboxiq://oauth/callback?{params}")

        user = await auth_service.get_or_create_user(email)

        if tokens.get("refresh_token"):
            await auth_service.store_google_tokens(user, tokens)

        access_jwt, refresh_jwt, expires_in = await auth_service.create_token_pair(str(user.id))
        
        # Redirect to app with tokens
        params = urlencode({
            "access_token": access_jwt,
            "refresh_token": refresh_jwt,
            "user_email": email
        })
        return RedirectResponse(url=f"inboxiq://oauth/callback?{params}")
        
    except httpx.HTTPStatusError as exc:
        params = urlencode({"error": "oauth_failed"})
        return RedirectResponse(url=f"inboxiq://oauth/callback?{params}")
    except SQLAlchemyError:
        params = urlencode({"error": "db_error"})
        return RedirectResponse(url=f"inboxiq://oauth/callback?{params}")
    except Exception:
        params = urlencode({"error": "auth_failed"})
        return RedirectResponse(url=f"inboxiq://oauth/callback?{params}")


@router.post(
    "/login",
    response_model=LoginResponse,
    dependencies=[Depends(RateLimiter(times=5, minutes=1))],
)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> LoginResponse:
    """iOS-compatible login endpoint that exchanges OAuth code for tokens."""
    from app.config import settings
    
    auth_service = AuthService(db)
    
    # Exchange code for Google tokens
    tokens = await auth_service.exchange_code_for_tokens(payload.code, settings.google_redirect_uri)
    access_token = tokens.get("access_token")
    if not access_token:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Missing access token")

    # Get user profile from Google
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

    # Find or create user
    user = await auth_service.get_or_create_user(email)

    # Store Google tokens
    if tokens.get("refresh_token"):
        await auth_service.store_google_tokens(user, tokens)

    # Create JWT tokens
    access_jwt, refresh_jwt, _ = await auth_service.create_token_pair(str(user.id))
    
    return LoginResponse(
        accessToken=access_jwt,
        refreshToken=refresh_jwt,
        userEmail=email
    )


@router.post(
    "/refresh",
    response_model=TokenPair,
    dependencies=[Depends(RateLimiter(times=5, minutes=1))],
)
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
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Revoke refresh tokens for a user (simple logout)."""
    # current_user is validated by get_current_user (valid, non-expired token)
    from app.models import RefreshToken
    await db.execute(
        RefreshToken.__table__.update().where(RefreshToken.user_id == current_user.id).values(revoked=True)
    )
    await db.commit()
    return {"status": "ok"}
