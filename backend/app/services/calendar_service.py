"""
Google Calendar Service

Handles Google Calendar API integration with OAuth 2.0.
Following api-integration-builder skill patterns.
"""

import logging
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any

from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import Flow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

from app.config import settings

logger = logging.getLogger(__name__)


class GoogleCalendarService:
    """
    Google Calendar API client with OAuth 2.0 authentication.
    """
    
    # Google Calendar API scopes
    SCOPES = [
        'https://www.googleapis.com/auth/calendar.readonly',
        'https://www.googleapis.com/auth/calendar.events'
    ]
    
    def __init__(self):
        """Initialize calendar service."""
        self.client_id = settings.google_calendar_client_id
        self.client_secret = settings.google_calendar_client_secret
        self.redirect_uri = settings.google_calendar_redirect_uri
        
        if not self.client_id or not self.client_secret:
            logger.warning("Google Calendar credentials not configured")
    
    def get_authorization_url(self, state: str) -> str:
        """
        Get Google OAuth authorization URL.
        
        Args:
            state: CSRF protection state token
        
        Returns:
            Authorization URL to redirect user to
        """
        flow = Flow.from_client_config(
            {
                "web": {
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                    "redirect_uris": [self.redirect_uri]
                }
            },
            scopes=self.SCOPES,
            redirect_uri=self.redirect_uri
        )
        
        authorization_url, _ = flow.authorization_url(
            access_type='offline',
            include_granted_scopes='true',
            state=state,
            prompt='consent'  # Force consent to get refresh token
        )
        
        return authorization_url
    
    def exchange_code_for_tokens(self, code: str) -> Dict[str, Any]:
        """
        Exchange authorization code for access and refresh tokens.
        
        Args:
            code: Authorization code from OAuth callback
        
        Returns:
            Token data including access_token and refresh_token
        
        Raises:
            Exception: If token exchange fails
        """
        flow = Flow.from_client_config(
            {
                "web": {
                    "client_id": self.client_id,
                    "client_secret": self.client_secret,
                    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                    "token_uri": "https://oauth2.googleapis.com/token",
                    "redirect_uris": [self.redirect_uri]
                }
            },
            scopes=self.SCOPES,
            redirect_uri=self.redirect_uri
        )
        
        try:
            flow.fetch_token(code=code)
            credentials = flow.credentials
            
            return {
                "access_token": credentials.token,
                "refresh_token": credentials.refresh_token,
                "token_uri": credentials.token_uri,
                "client_id": credentials.client_id,
                "client_secret": credentials.client_secret,
                "scopes": credentials.scopes,
                "expiry": credentials.expiry.isoformat() if credentials.expiry else None
            }
        
        except Exception as e:
            logger.error(f"Token exchange failed: {e}")
            raise Exception(f"Failed to exchange code for tokens: {str(e)}")
    
    def refresh_access_token(self, refresh_token: str) -> Dict[str, Any]:
        """
        Refresh expired access token using refresh token.
        
        Args:
            refresh_token: Valid refresh token
        
        Returns:
            New token data
        """
        credentials = Credentials(
            token=None,
            refresh_token=refresh_token,
            token_uri="https://oauth2.googleapis.com/token",
            client_id=self.client_id,
            client_secret=self.client_secret,
            scopes=self.SCOPES
        )
        
        try:
            credentials.refresh(Request())
            
            return {
                "access_token": credentials.token,
                "refresh_token": credentials.refresh_token,
                "expiry": credentials.expiry.isoformat() if credentials.expiry else None
            }
        
        except Exception as e:
            logger.error(f"Token refresh failed: {e}")
            raise Exception(f"Failed to refresh token: {str(e)}")
    
    def _build_service(self, access_token: str, refresh_token: Optional[str] = None):
        """
        Build Google Calendar API service.
        
        Args:
            access_token: OAuth access token
            refresh_token: Optional refresh token for auto-refresh
        
        Returns:
            Google Calendar API service
        """
        credentials = Credentials(
            token=access_token,
            refresh_token=refresh_token,
            token_uri="https://oauth2.googleapis.com/token",
            client_id=self.client_id,
            client_secret=self.client_secret,
            scopes=self.SCOPES
        )
        
        return build('calendar', 'v3', credentials=credentials)
    
    def list_events(
        self,
        access_token: str,
        refresh_token: Optional[str] = None,
        max_results: int = 10,
        time_min: Optional[datetime] = None,
        time_max: Optional[datetime] = None
    ) -> List[Dict[str, Any]]:
        """
        List upcoming calendar events.
        
        Args:
            access_token: OAuth access token
            refresh_token: Optional refresh token
            max_results: Maximum events to return
            time_min: Start time for events (default: now)
            time_max: End time for events (default: +7 days)
        
        Returns:
            List of calendar events
        """
        try:
            service = self._build_service(access_token, refresh_token)
            
            # Default time range: next 7 days
            if not time_min:
                time_min = datetime.utcnow()
            if not time_max:
                time_max = time_min + timedelta(days=7)
            
            events_result = service.events().list(
                calendarId='primary',
                timeMin=time_min.isoformat() + 'Z',
                timeMax=time_max.isoformat() + 'Z',
                maxResults=max_results,
                singleEvents=True,
                orderBy='startTime'
            ).execute()
            
            events = events_result.get('items', [])
            
            # Format events
            formatted_events = []
            for event in events:
                # Format attendees as objects (iOS expects {email, display_name})
                attendees = []
                for attendee in event.get('attendees', []):
                    attendees.append({
                        'email': attendee.get('email'),
                        'display_name': attendee.get('displayName')
                    })
                
                formatted_events.append({
                    'id': event['id'],
                    'summary': event.get('summary', 'No Title'),
                    'description': event.get('description'),
                    'start': event['start'].get('dateTime', event['start'].get('date')),
                    'end': event['end'].get('dateTime', event['end'].get('date')),
                    'location': event.get('location'),
                    'attendees': attendees if attendees else [],
                    'html_link': event.get('htmlLink')
                })
            
            return formatted_events
        
        except HttpError as e:
            if e.resp.status == 401:
                logger.error("Unauthorized - token may be expired")
                raise Exception("Token expired or invalid")
            else:
                logger.error(f"Google Calendar API error: {e}")
                raise Exception(f"Failed to fetch events: {str(e)}")
    
    def create_event(
        self,
        access_token: str,
        summary: str,
        start_time: datetime,
        end_time: datetime,
        description: Optional[str] = None,
        location: Optional[str] = None,
        attendees: Optional[List[str]] = None,
        refresh_token: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Create a new calendar event.
        
        Args:
            access_token: OAuth access token
            summary: Event title
            start_time: Event start time
            end_time: Event end time
            description: Optional event description
            location: Optional event location
            attendees: Optional list of attendee emails
            refresh_token: Optional refresh token
        
        Returns:
            Created event data
        """
        try:
            service = self._build_service(access_token, refresh_token)
            
            event = {
                'summary': summary,
                'start': {
                    'dateTime': start_time.isoformat(),
                    'timeZone': 'America/Chicago',
                },
                'end': {
                    'dateTime': end_time.isoformat(),
                    'timeZone': 'America/Chicago',
                }
            }
            
            if description:
                event['description'] = description
            
            if location:
                event['location'] = location
            
            if attendees:
                event['attendees'] = [{'email': email} for email in attendees]
            
            created_event = service.events().insert(
                calendarId='primary',
                body=event
            ).execute()
            
            return {
                'id': created_event['id'],
                'summary': created_event.get('summary'),
                'start': created_event['start'].get('dateTime'),
                'end': created_event['end'].get('dateTime'),
                'html_link': created_event.get('htmlLink')
            }
        
        except HttpError as e:
            logger.error(f"Failed to create event: {e}")
            raise Exception(f"Failed to create calendar event: {str(e)}")


# Global service instance
calendar_service = GoogleCalendarService()
