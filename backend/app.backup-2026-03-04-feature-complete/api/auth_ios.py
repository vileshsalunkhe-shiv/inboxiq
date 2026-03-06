"""iOS-specific auth endpoints."""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Body, Query, Request
from fastapi.responses import RedirectResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.exc import SQLAlchemyError
from pydantic import BaseModel
from urllib.parse import urlencode
import structlog
import httpx
import traceback
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.api.deps import get_current_user
from app.database import get_db
from app.config import settings
from app.models.user import User
from app.schemas.auth import TokenPair
from app.services.auth_service import AuthService

# Rate limit auth endpoints to reduce brute-force and abuse risk.
limiter = Limiter(key_func=get_remote_address)

router = APIRouter()
logger = structlog.get_logger()


class IOSLoginRequest(BaseModel):
    code: str


@router.post("/auth/ios/login")  # Custom response, not standard TokenPair
@limiter.limit("5/minute")  # Security: limit login attempts per IP
async def ios_login(
    request: Request,  # SlowAPI requires Request in signature for rate limiting
    login_request: IOSLoginRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenPair:
    """
    iOS OAuth login endpoint.
    
    The iOS app gets the auth code from Google and sends it here.
    We exchange it for tokens using the iOS redirect URI.
    """
    auth_service = AuthService(db)
    
    try:
        logger.info(
            "ios_oauth_login_attempt",
            code_prefix=login_request.code[:20] if login_request.code else None,
        )
        
        # Exchange code for tokens using iOS redirect URI
        # CRITICAL: This must match what iOS used to get the code
        token_data = await auth_service.exchange_code_for_tokens(
            code=login_request.code,
            redirect_uri="com.googleusercontent.apps.535816296321-0l834ob6tluso0d4hr8igp4ehe80mc4b:/oauth2redirect"  # iOS redirect URI
        )
        
        # Get user profile
        profile = await auth_service.get_google_user_profile(token_data["access_token"])
        email = profile.get("email")
        
        if not email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email not found in Google profile"
            )
        
        # Find or create user
        user = await auth_service.get_or_create_user(email)
        logger.info("ios_user_resolved", email=email, user_id=user.id)
        
        # Store Google tokens
        await auth_service.store_google_tokens(user, token_data)
        
        # Create JWT tokens
        access_token, refresh_token, expires_in = await auth_service.create_token_pair(
            str(user.id)
        )
        
        logger.info("ios_oauth_login_success", user_id=user.id, email=email)
        
        # Return tokens with user email for iOS convenience
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "expires_in": expires_in,
            "user_email": email  # Added for iOS
        }
        
    except httpx.HTTPStatusError as e:
        logger.error("ios_oauth_login_failed", error_type=type(e).__name__, status_code=e.response.status_code)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="Google OAuth failed"
        ) from e
    except SQLAlchemyError as e:
        logger.error("ios_oauth_login_failed", error_type=type(e).__name__)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database error"
        ) from e
    except HTTPException:
        raise
    except Exception as e:
        logger.error("ios_oauth_login_failed", error_type=type(e).__name__)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="OAuth login failed"
        ) from e


@router.get("/auth/ios/callback")
@limiter.limit("10/minute")  # Security: rate limit OAuth callbacks per IP
async def ios_oauth_callback(
    request: Request,  # SlowAPI requires Request in signature for rate limiting
    code: str = Query(..., description="Authorization code from Google"),
    state: Optional[str] = Query(None, description="State parameter for CSRF protection"),
    error: Optional[str] = Query(None, description="Error from OAuth provider"),
    db: AsyncSession = Depends(get_db),
):
    """
    OAuth callback endpoint for iOS.
    
    Flow:
    1. User authorizes in browser
    2. Google redirects here with code
    3. Backend exchanges code for Google tokens
    4. Backend creates/updates user
    5. Backend generates JWT tokens
    6. Backend redirects to iOS app with JWT tokens
    """
    if error:
        logger.error("ios_oauth_callback_error", error=error)
        # Redirect to app with error
        error_params = urlencode({"error": error})
        return RedirectResponse(url=f"inboxiq://login?{error_params}")
    
    auth_service = AuthService(db)
    
    try:
        logger.info("ios_oauth_callback_received", code_prefix=code[:20] if code else None)
        
        # Exchange code for Google tokens using Web client
        # This uses the backend's redirect URI
        token_data = await auth_service.exchange_code_for_tokens(
            code=code,
            redirect_uri=f"{settings.api_base_url}/auth/ios/callback"
        )
        
        # Get user profile from Google
        profile = await auth_service.get_google_user_profile(token_data["access_token"])
        email = profile.get("email")
        
        if not email:
            logger.error("ios_oauth_callback_no_email")
            error_params = urlencode({"error": "no_email"})
            return RedirectResponse(url=f"inboxiq://login?{error_params}")
        
        # Find or create user
        logger.info("ios_oauth_step_1_before_get_or_create_user", email=email)
        user = await auth_service.get_or_create_user(email)
        logger.info("ios_oauth_step_2_user_resolved", email=email, user_id=user.id)
        
        # Store Google tokens in database
        logger.info("ios_oauth_step_3_before_store_tokens")
        await auth_service.store_google_tokens(user, token_data)
        logger.info("ios_oauth_step_4_tokens_stored")
        
        # Generate JWT tokens for the app
        logger.info("ios_oauth_step_5_before_create_token_pair")
        access_token, refresh_token, expires_in = await auth_service.create_token_pair(
            str(user.id)
        )
        logger.info("ios_oauth_step_6_token_pair_created")
        
        logger.info("ios_oauth_callback_success", user_id=user.id, email=email)
        
        # Redirect to iOS app with JWT tokens AND user_id
        params = urlencode({
            "access_token": access_token,
            "refresh_token": refresh_token,
            "user_email": email,
            "user_id": str(user.id),  # Backend user ID for API calls
            "expires_in": str(expires_in)
        })
        return RedirectResponse(url=f"inboxiq://login?{params}")
        
    except httpx.HTTPStatusError as e:
        logger.error(
            "ios_oauth_callback_failed",
            error_type=type(e).__name__,
            status_code=e.response.status_code,
        )
        error_params = urlencode({"error": "oauth_failed"})
        return RedirectResponse(url=f"inboxiq://login?{error_params}")
    except SQLAlchemyError as e:
        logger.error(
            "ios_oauth_callback_failed",
            error_type=type(e).__name__,
        )
        error_params = urlencode({"error": "db_error"})
        return RedirectResponse(url=f"inboxiq://login?{error_params}")
    except Exception as e:
        logger.error(
            "ios_oauth_callback_failed",
            error_type=type(e).__name__,
            error_message=str(e),
            traceback=traceback.format_exc()
        )
        error_params = urlencode({"error": "auth_failed"})
        return RedirectResponse(url=f"inboxiq://login?{error_params}")


@router.post("/auth/logout")
async def logout(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """
    Logout endpoint - revokes refresh token.

    Requires valid, non-expired JWT access token.
    """
    auth_service = AuthService(db)

    try:
        # Security: only a valid access token can revoke refresh tokens.
        await auth_service.revoke_refresh_token(str(current_user.id))

        logger.info("user_logged_out", user_id=current_user.id)

        return {"message": "Logged out successfully"}

    except Exception as e:
        logger.error("logout_failed", error_type=type(e).__name__)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Logout failed",
        ) from e
