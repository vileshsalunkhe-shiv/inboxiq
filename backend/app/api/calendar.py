"""
Calendar API Endpoints

Google Calendar integration endpoints for OAuth and event management.
"""

import logging
import secrets
import uuid
import json
import base64
from datetime import datetime
from typing import Optional, List
from fastapi import APIRouter, HTTPException, Depends, Query
from fastapi.responses import RedirectResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.database import get_db
from app.models.user import User
from app.services.calendar_service import calendar_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/calendar", tags=["calendar"])


def encode_state(user_id: uuid.UUID, csrf_token: str) -> str:
    """Encode user_id and CSRF token into state parameter."""
    data = {"user_id": str(user_id), "csrf": csrf_token}
    json_str = json.dumps(data)
    encoded = base64.urlsafe_b64encode(json_str.encode()).decode()
    return encoded


def decode_state(state: str) -> dict:
    """Decode state parameter to get user_id and CSRF token."""
    try:
        decoded = base64.urlsafe_b64decode(state.encode()).decode()
        return json.loads(decoded)
    except Exception as e:
        logger.error(f"Failed to decode state: {e}")
        raise HTTPException(status_code=400, detail="Invalid state parameter")


# Pydantic models
class CalendarAuthResponse(BaseModel):
    authorization_url: str
    state: str


class CalendarTokens(BaseModel):
    access_token: str
    refresh_token: Optional[str]
    expiry: Optional[str]


class CalendarEvent(BaseModel):
    id: str
    summary: str
    description: Optional[str] = None
    start: str
    end: str
    location: Optional[str] = None
    attendees: List[str] = []
    html_link: str


class CreateEventRequest(BaseModel):
    summary: str
    start_time: datetime
    end_time: datetime
    description: Optional[str] = None
    location: Optional[str] = None
    attendees: Optional[List[str]] = None


@router.get("/auth/initiate", response_model=CalendarAuthResponse)
async def initiate_calendar_auth(
    user_id: uuid.UUID = Query(..., description="User ID"),
    db: AsyncSession = Depends(get_db)
):
    """
    Initiate Google Calendar OAuth flow.
    
    Returns authorization URL and state token.
    """
    try:
        # Verify user exists
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Generate CSRF token
        csrf_token = secrets.token_urlsafe(32)
        
        # Encode user_id and CSRF token into state
        state = encode_state(user_id, csrf_token)
        
        # Get authorization URL
        auth_url = calendar_service.get_authorization_url(state)
        
        logger.info(f"Calendar auth initiated for user {user_id}")
        
        return {
            "authorization_url": auth_url,
            "state": state
        }
    
    except Exception as e:
        logger.error(f"Failed to initiate calendar auth: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/callback")
async def calendar_auth_callback(
    code: str = Query(..., description="Authorization code"),
    state: str = Query(..., description="State token with user_id"),
    db: AsyncSession = Depends(get_db)
):
    """
    Handle Google Calendar OAuth callback.
    
    Exchanges authorization code for tokens and stores them.
    """
    try:
        # Decode state to get user_id and verify CSRF
        state_data = decode_state(state)
        user_id = uuid.UUID(state_data["user_id"])
        # csrf_token = state_data["csrf"]  # TODO: Verify CSRF token
        
        # Verify user exists
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Exchange code for tokens
        tokens = calendar_service.exchange_code_for_tokens(code)
        
        # Store tokens in database
        user.calendar_access_token = tokens["access_token"]
        user.calendar_refresh_token = tokens.get("refresh_token")
        
        # Parse and store token expiry if available
        if "expiry" in tokens:
            try:
                # Tokens typically return expiry as ISO string or datetime
                if isinstance(tokens["expiry"], str):
                    user.calendar_token_expiry = datetime.fromisoformat(tokens["expiry"].replace('Z', '+00:00'))
                else:
                    user.calendar_token_expiry = tokens["expiry"]
            except Exception as e:
                logger.warning(f"Could not parse token expiry: {e}")
        
        await db.commit()
        await db.refresh(user)
        
        logger.info(f"Calendar tokens stored for user {user_id}")
        
        # Return success response
        return {
            "success": True,
            "message": "Calendar connected successfully",
            "user_id": str(user_id),
            "has_refresh_token": user.calendar_refresh_token is not None,
            "token_expiry": user.calendar_token_expiry.isoformat() if user.calendar_token_expiry else None
        }
    
    except Exception as e:
        logger.error(f"Calendar auth callback failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/events", response_model=List[CalendarEvent])
async def list_calendar_events(
    user_id: uuid.UUID = Query(..., description="User ID"),
    max_results: int = Query(10, ge=1, le=100),
    db: AsyncSession = Depends(get_db)
):
    """
    List upcoming calendar events for user.
    
    Returns events from user's primary Google Calendar.
    """
    try:
        # Get user
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if user has authorized calendar access
        if not user.calendar_access_token:
            raise HTTPException(
                status_code=401,
                detail="Calendar not connected. Please authorize first."
            )
        
        # List events using stored tokens
        events = calendar_service.list_events(
            access_token=user.calendar_access_token,
            refresh_token=user.calendar_refresh_token,
            max_results=max_results
        )
        
        return events
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to list events: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/events", response_model=CalendarEvent)
async def create_calendar_event(
    event: CreateEventRequest,
    user_id: uuid.UUID = Query(..., description="User ID"),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new calendar event.
    
    Creates event in user's primary Google Calendar.
    """
    try:
        # Get user
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if user has authorized calendar access
        if not user.calendar_access_token:
            raise HTTPException(
                status_code=401,
                detail="Calendar not connected. Please authorize first."
            )
        
        # Create event using stored tokens
        created_event = calendar_service.create_event(
            access_token=user.calendar_access_token,
            summary=event.summary,
            start_time=event.start_time,
            end_time=event.end_time,
            description=event.description,
            location=event.location,
            attendees=event.attendees,
            refresh_token=user.calendar_refresh_token
        )
        
        return created_event
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create event: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/status")
async def calendar_connection_status(
    user_id: uuid.UUID = Query(..., description="User ID"),
    db: AsyncSession = Depends(get_db)
):
    """
    Check if user has connected Google Calendar.
    """
    try:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if user has valid calendar tokens
        has_calendar = user.calendar_access_token is not None
        is_expired = False
        
        if has_calendar and user.calendar_token_expiry:
            is_expired = user.calendar_token_expiry < datetime.utcnow()
        
        return {
            "connected": has_calendar,
            "email": user.email,
            "has_refresh_token": user.calendar_refresh_token is not None,
            "token_expiry": user.calendar_token_expiry.isoformat() if user.calendar_token_expiry else None,
            "is_expired": is_expired
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to check calendar status: {e}")
        raise HTTPException(status_code=500, detail=str(e))
