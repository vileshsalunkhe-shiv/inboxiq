# Temporary patch to add /auth/login endpoint for iOS compatibility
# Add this to app/api/auth.py after the google_callback endpoint

from pydantic import BaseModel

class LoginRequest(BaseModel):
    """iOS login request with OAuth code."""
    code: str

class LoginResponse(BaseModel):
    """iOS login response with tokens and email."""
    accessToken: str
    refreshToken: str
    userEmail: str

@router.post("/login", response_model=LoginResponse)
async def login(payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> LoginResponse:
    """iOS-compatible login endpoint that exchanges OAuth code for tokens."""
    from app.config import settings
    import httpx
    
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
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if not user:
        user = User(email=email)
        db.add(user)
        await db.commit()
        await db.refresh(user)
        
        # Create default digest settings
        from app.models.digest_settings import DigestSettings
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
