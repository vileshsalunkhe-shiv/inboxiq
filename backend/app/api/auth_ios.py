"""iOS-specific auth endpoints."""

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from pydantic import BaseModel
import structlog

from app.database import get_db
from app.config import settings
from app.models.user import User
from app.schemas.auth import TokenPair
from app.services.auth_service import AuthService

router = APIRouter()
logger = structlog.get_logger()


class IOSLoginRequest(BaseModel):
    code: str


@router.post("/auth/ios/login")  # Custom response, not standard TokenPair
async def ios_login(
    request: IOSLoginRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenPair:
    """
    iOS OAuth login endpoint.
    
    The iOS app gets the auth code from Google and sends it here.
    We exchange it for tokens using the iOS redirect URI.
    """
    auth_service = AuthService(db)
    
    try:
        logger.info("ios_oauth_login_attempt", code_prefix=request.code[:20] if request.code else None)
        
        # Exchange code for tokens using iOS redirect URI
        # CRITICAL: This must match what iOS used to get the code
        token_data = await auth_service.exchange_code_for_tokens(
            code=request.code,
            redirect_uri="inboxiq://oauth/callback"  # iOS redirect URI
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
        result = await db.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        
        if not user:
            # Create new user
            user = User(email=email)
            db.add(user)
            await db.commit()
            await db.refresh(user)
            logger.info("ios_new_user_created", email=email)
        
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
        
    except Exception as e:
        logger.error("ios_oauth_login_failed", error=str(e), error_type=type(e).__name__)
        if isinstance(e, HTTPException):
            raise
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"OAuth login failed: {str(e)}"
        )