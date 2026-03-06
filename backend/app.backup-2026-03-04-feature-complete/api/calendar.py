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
from sqlalchemy.exc import SQLAlchemyError
from pydantic import BaseModel
import redis.asyncio as redis
from googleapiclient.errors import HttpError

from app.api.deps import get_current_user
from app.config import settings
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


async def store_csrf_token(user_id: uuid.UUID, csrf_token: str) -> None:
    """Store CSRF token in Redis for later validation."""
    redis_client = redis.from_url(settings.redis_url, encoding="utf-8", decode_responses=True)
    key = f"calendar:csrf:{user_id}"
    await redis_client.set(key, csrf_token, ex=600)  # 10 minute expiry
    await redis_client.close()


async def validate_csrf_token(user_id: uuid.UUID, csrf_token: str) -> None:
    """Validate CSRF token stored in Redis."""
    redis_client = redis.from_url(settings.redis_url, encoding="utf-8", decode_responses=True)
    key = f"calendar:csrf:{user_id}"
    stored = await redis_client.get(key)
    if not stored or stored != csrf_token:
        await redis_client.close()
        raise HTTPException(status_code=400, detail="Invalid CSRF token")
    await redis_client.delete(key)
    await redis_client.close()


# Pydantic models
class CalendarAuthResponse(BaseModel):
    authorization_url: str
    state: str


class CalendarTokens(BaseModel):
    access_token: str
    refresh_token: Optional[str]
    expiry: Optional[str]


class CalendarAttendee(BaseModel):
    email: Optional[str] = None
    display_name: Optional[str] = None


class CalendarEvent(BaseModel):
    id: str
    summary: str
    description: Optional[str] = None
    start: str
    end: str
    location: Optional[str] = None
    attendees: List[CalendarAttendee] = []
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
        
        # Store CSRF token for validation in callback
        await store_csrf_token(user_id, csrf_token)

        # Get authorization URL
        auth_url = calendar_service.get_authorization_url(state)
        
        logger.info(f"Calendar auth initiated for user {user_id}")
        
        return {
            "authorization_url": auth_url,
            "state": state
        }
    
    except SQLAlchemyError as e:
        logger.error(f"Failed to initiate calendar auth: {e}")
        raise HTTPException(status_code=500, detail="Database error") from e
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to initiate calendar auth: {e}")
        raise HTTPException(status_code=500, detail="Calendar auth initiation failed") from e


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
        csrf_token = state_data.get("csrf")
        if not csrf_token:
            raise HTTPException(status_code=400, detail="Missing CSRF token")
        await validate_csrf_token(user_id, csrf_token)
        
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
    
    except HttpError as e:
        logger.error(f"Calendar auth callback failed: {e}")
        raise HTTPException(status_code=502, detail="Google Calendar OAuth failed") from e
    except SQLAlchemyError as e:
        logger.error(f"Calendar auth callback failed: {e}")
        raise HTTPException(status_code=500, detail="Database error") from e
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Calendar auth callback failed: {e}")
        raise HTTPException(status_code=500, detail="Calendar auth callback failed") from e


@router.get("/events", response_model=List[CalendarEvent])
async def list_calendar_events(
    current_user: User = Depends(get_current_user),
    time_min: Optional[str] = Query(None, description="Start of time range (ISO8601)"),
    time_max: Optional[str] = Query(None, description="End of time range (ISO8601)"),
    max_results: int = Query(10, ge=1, le=50),
    db: AsyncSession = Depends(get_db)
):
    """
    List calendar events for user within a time range.
    
    Defaults to next 7 days if no range is provided.
    """
    try:
        # User is already authenticated via get_current_user dependency
        user = current_user
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Check if user has authorized calendar access
        if not user.calendar_access_token:
            raise HTTPException(
                status_code=401,
                detail="Calendar not connected. Please authorize first."
            )
        
        parsed_time_min: Optional[datetime] = None
        parsed_time_max: Optional[datetime] = None
        if time_min:
            parsed_time_min = datetime.fromisoformat(time_min.replace("Z", "+00:00"))
        if time_max:
            parsed_time_max = datetime.fromisoformat(time_max.replace("Z", "+00:00"))
        
        # List events using stored tokens
        events = calendar_service.list_events(
            access_token=user.calendar_access_token,
            refresh_token=user.calendar_refresh_token,
            max_results=max_results,
            time_min=parsed_time_min,
            time_max=parsed_time_max
        )
        
        return events
    
    except HTTPException:
        raise
    except HttpError as e:
        logger.error(f"Failed to list events: {e}")
        raise HTTPException(status_code=502, detail="Google Calendar API error") from e
    except SQLAlchemyError as e:
        logger.error(f"Failed to list events: {e}")
        raise HTTPException(status_code=500, detail="Database error") from e
    except Exception as e:
        logger.error(f"Failed to list events: {e}")
        raise HTTPException(status_code=500, detail="Failed to list calendar events") from e


@router.post("/events", response_model=CalendarEvent)
async def create_calendar_event(
    event: CreateEventRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new calendar event.
    
    Creates event in user's primary Google Calendar.
    """
    try:
        # User is already authenticated via get_current_user dependency
        user = current_user
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
    except HttpError as e:
        logger.error(f"Failed to create event: {e}")
        raise HTTPException(status_code=502, detail="Google Calendar API error") from e
    except SQLAlchemyError as e:
        logger.error(f"Failed to create event: {e}")
        raise HTTPException(status_code=500, detail="Database error") from e
    except Exception as e:
        logger.error(f"Failed to create event: {e}")
        raise HTTPException(status_code=500, detail="Failed to create calendar event") from e


@router.get("/status")
async def calendar_connection_status(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Check if user has connected Google Calendar.
    """
    try:
        # User is already authenticated via get_current_user dependency
        user = current_user
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
    except SQLAlchemyError as e:
        logger.error(f"Failed to check calendar status: {e}")
        raise HTTPException(status_code=500, detail="Database error") from e
    except Exception as e:
        logger.error(f"Failed to check calendar status: {e}")
        raise HTTPException(status_code=500, detail="Failed to check calendar status") from e
