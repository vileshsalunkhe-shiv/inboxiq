# InboxIQ Third-Party Integrations

**Complete guide to external service integrations**

This document provides comprehensive documentation for all third-party service integrations used in InboxIQ.

---

## Table of Contents

1. [Overview](#overview)
2. [Gmail Integration](#gmail-integration)
3. [Google Calendar Integration](#google-calendar-integration)
4. [Anthropic Claude AI](#anthropic-claude-ai)
5. [Apple Push Notifications](#apple-push-notifications)
6. [Security Best Practices](#security-best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Overview

InboxIQ integrates with the following external services:

| Service | Purpose | Auth Method | Status |
|---------|---------|-------------|--------|
| Gmail API | Email access and management | OAuth 2.0 | ✅ Active |
| Google Calendar API | Calendar integration | OAuth 2.0 | ✅ Active |
| Anthropic Claude | AI email categorization | API Key | ✅ Active |
| Apple APNs | Push notifications | Certificate | ✅ Active |

### Integration Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ InboxIQ Backend                                               │
│                                                                │
│  ┌────────────────┐    ┌──────────────────┐                  │
│  │ Gmail Service  │───▶│ OAuth Manager    │                  │
│  └────────────────┘    └──────────────────┘                  │
│                               │                               │
│  ┌────────────────┐           │ Token Storage                │
│  │ Calendar Svc   │───────────┤                              │
│  └────────────────┘           │                               │
│                               ▼                               │
│  ┌────────────────┐    ┌──────────────────┐                  │
│  │ AI Service     │    │ PostgreSQL DB    │                  │
│  └────────────────┘    └──────────────────┘                  │
│                                                                │
└──────────────────────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
   ┌─────────┐   ┌──────────┐   ┌──────────┐
   │ Gmail   │   │ Calendar │   │ Claude   │
   │ API     │   │ API      │   │ API      │
   └─────────┘   └──────────┘   └──────────┘
```

---

## Gmail Integration

### Overview

Gmail integration provides email access and management via OAuth 2.0 authentication.

**Capabilities:**
- Read emails (inbox, sent, drafts, trash)
- Send emails with attachments
- Modify labels and categories
- Search emails with Gmail query syntax
- Batch operations for efficiency

### Setup Steps

#### 1. Google Cloud Console Setup

```bash
# Navigate to Google Cloud Console
open https://console.cloud.google.com/

# Create or select project
# 1. Click "Select a project" → "New Project"
# 2. Name: "InboxIQ Gmail Integration"
# 3. Click "Create"
```

#### 2. Enable Gmail API

```bash
# In Google Cloud Console:
# 1. Go to "APIs & Services" → "Library"
# 2. Search "Gmail API"
# 3. Click "Enable"
```

#### 3. Configure OAuth Consent Screen

**Application Details:**
- App name: `InboxIQ`
- User support email: Your email
- Developer contact: Your email

**Scopes to Add:**
```
https://www.googleapis.com/auth/gmail.readonly
https://www.googleapis.com/auth/gmail.send
https://www.googleapis.com/auth/gmail.modify
https://www.googleapis.com/auth/gmail.labels
```

#### 4. Create OAuth Credentials

```bash
# In Google Cloud Console:
# 1. Go to "APIs & Services" → "Credentials"
# 2. Click "Create Credentials" → "OAuth client ID"
# 3. Application type: "Web application"
# 4. Name: "InboxIQ Backend"
```

**Authorized Redirect URIs:**
```
http://localhost:8000/gmail/auth/callback
https://api.inboxiq.app/gmail/auth/callback
```

#### 5. Configure Environment

Add to `.env`:
```bash
# Gmail API Configuration
GOOGLE_GMAIL_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_GMAIL_CLIENT_SECRET=your_client_secret
GOOGLE_GMAIL_REDIRECT_URI=http://localhost:8000/gmail/auth/callback
```

### OAuth Flow

#### Initiate Authorization

```python
# Backend: Initiate OAuth
GET /gmail/auth/initiate?user_id=1

Response:
{
  "authorization_url": "https://accounts.google.com/o/oauth2/auth?...",
  "state": "csrf_token_32_chars"
}
```

#### User Authorization

1. Redirect user to `authorization_url`
2. User signs in with Google
3. User grants permissions
4. Google redirects to callback URL with authorization code

#### Token Exchange

```python
# Automatic callback handling
GET /gmail/auth/callback?code=AUTH_CODE&state=CSRF_TOKEN&user_id=1

# Backend exchanges code for tokens:
{
  "access_token": "ya29.a0...",
  "refresh_token": "1//0g...",
  "expires_in": 3600,
  "scope": "https://www.googleapis.com/auth/gmail.readonly ...",
  "token_type": "Bearer"
}
```

### API Usage Examples

#### Fetch Emails

```python
import requests

response = requests.get(
    "http://localhost:8000/gmail/emails",
    params={
        "user_id": 1,
        "max_results": 50,
        "query": "is:unread category:primary"
    },
    headers={"Authorization": f"Bearer {jwt_token}"}
)

emails = response.json()["emails"]
```

#### Send Email

```python
response = requests.post(
    "http://localhost:8000/gmail/emails/send",
    json={
        "to": ["recipient@example.com"],
        "subject": "Hello from InboxIQ",
        "body": "This is a test email.",
        "body_html": "<p>This is a <b>test</b> email.</p>"
    },
    headers={"Authorization": f"Bearer {jwt_token}"}
)
```

### Rate Limits

**Gmail API Quotas:**
- **Daily quota:** 1,000,000,000 quota units
- **Per-minute quota:** 250 quota units per user
- **Batch requests:** Up to 100 requests per batch

**Cost per operation:**
- Read message: 5 units
- Send message: 100 units
- List messages: 5 units

### Error Handling

```python
# Common Gmail API errors:

# 401 Unauthorized - Token expired
{
  "error": "invalid_grant",
  "error_description": "Token has been expired or revoked"
}
# Solution: Refresh access token using refresh_token

# 403 Forbidden - Insufficient permissions
{
  "error": "insufficient_permission",
  "error_description": "Insufficient Permission"
}
# Solution: Request additional scopes in OAuth flow

# 429 Too Many Requests - Rate limit exceeded
{
  "error": "rateLimitExceeded",
  "error_description": "Rate Limit Exceeded"
}
# Solution: Implement exponential backoff
```

---

## Google Calendar Integration

### Overview

Google Calendar integration enables calendar access, event viewing, and event creation via OAuth 2.0.

**Capabilities:**
- View upcoming calendar events
- Create calendar events
- Update existing events
- Delete events
- Manage attendees and invitations

### Setup Steps

For complete setup instructions, see [GOOGLE-CALENDAR-SETUP.md](GOOGLE-CALENDAR-SETUP.md).

#### Quick Setup

1. **Enable Calendar API** in Google Cloud Console
2. **Configure OAuth Consent Screen** (same as Gmail)
3. **Add Calendar Scopes:**
   ```
   https://www.googleapis.com/auth/calendar.readonly
   https://www.googleapis.com/auth/calendar.events
   ```
4. **Create OAuth Credentials** (same client as Gmail or separate)
5. **Configure Environment:**

```bash
# Calendar API Configuration
GOOGLE_CALENDAR_CLIENT_ID=your_client_id.apps.googleusercontent.com
GOOGLE_CALENDAR_CLIENT_SECRET=your_client_secret
GOOGLE_CALENDAR_REDIRECT_URI=http://localhost:8000/api/calendar/callback
```

### OAuth Flow

#### Initiate Authorization

```bash
curl "http://localhost:8000/api/calendar/auth/initiate?user_id=1"

# Response:
{
  "authorization_url": "https://accounts.google.com/o/oauth2/auth?...",
  "state": "random_state_token"
}
```

#### Authorization & Callback

Same flow as Gmail OAuth - redirect user to authorization URL, grant permissions, callback with code.

### API Usage Examples

#### List Events

```python
import requests

response = requests.get(
    "http://localhost:8000/api/calendar/events",
    params={
        "user_id": 1,
        "max_results": 10
    }
)

events = response.json()

# Example event:
{
  "id": "abc123xyz",
  "summary": "Team Meeting",
  "start": "2026-03-03T10:00:00-06:00",
  "end": "2026-03-03T11:00:00-06:00",
  "location": "Conference Room A",
  "attendees": ["teammate@example.com"],
  "html_link": "https://calendar.google.com/..."
}
```

#### Create Event

```python
response = requests.post(
    "http://localhost:8000/api/calendar/events?user_id=1",
    json={
        "summary": "Project Kickoff",
        "start_time": "2026-03-10T14:00:00",
        "end_time": "2026-03-10T15:30:00",
        "description": "Initial project planning meeting",
        "location": "Zoom",
        "attendees": [
            "alice@company.com",
            "bob@company.com"
        ]
    }
)

created_event = response.json()
print(f"Event created: {created_event['html_link']}")
```

#### Check Connection Status

```python
response = requests.get(
    "http://localhost:8000/api/calendar/status?user_id=1"
)

status = response.json()
if status["connected"]:
    print(f"✅ Calendar connected for {status['email']}")
else:
    print("❌ Calendar not connected - authorize first")
```

### Rate Limits

**Google Calendar API Quotas:**
- **Queries per day:** 1,000,000
- **Queries per 100 seconds per user:** 500
- **Queries per 100 seconds:** 10,000

**Best Practices:**
- Cache calendar data locally
- Use batch requests when possible
- Implement exponential backoff on rate limits

### Token Management

```python
# Calendar tokens are stored with User model
class User(Base):
    calendar_access_token: str | None      # Current access token
    calendar_refresh_token: str | None     # Long-lived refresh token
    calendar_token_expiry: datetime | None # Token expiration time
```

**Token Refresh:**
```python
# Automatic token refresh in calendar_service.py
if credentials.expired:
    credentials.refresh(Request())
    # Update tokens in database
```

### Error Handling

```python
# 401 Unauthorized - Token expired or invalid
{
  "detail": "Calendar not connected. Please authorize first."
}
# Solution: Re-authorize calendar access

# 404 Not Found - User doesn't exist
{
  "detail": "User not found"
}

# 500 Internal Server Error - Google API error
{
  "detail": "Failed to create calendar event: ..."
}
```

---

## Anthropic Claude AI

### Overview

Claude AI powers intelligent email categorization and summarization.

**Model:** `claude-3-sonnet-20240229`  
**Use Cases:**
- Email categorization (6 categories)
- Email summarization
- Smart reply suggestions (future)
- Sentiment analysis (future)

### Setup

```bash
# Get API key from Anthropic
# 1. Sign up at https://console.anthropic.com/
# 2. Navigate to API Keys
# 3. Generate new key

# Add to .env
ANTHROPIC_API_KEY=sk-ant-api03-...
```

### Integration Example

```python
# app/services/ai_service.py
import anthropic

class AIService:
    def __init__(self):
        self.client = anthropic.Anthropic(
            api_key=os.getenv("ANTHROPIC_API_KEY")
        )
    
    def categorize_email(self, subject: str, body: str) -> str:
        """Categorize email using Claude."""
        
        message = self.client.messages.create(
            model="claude-3-sonnet-20240229",
            max_tokens=100,
            messages=[{
                "role": "user",
                "content": f"""Categorize this email into ONE category:
                - work
                - personal
                - finance
                - shopping
                - travel
                - newsletters
                
                Subject: {subject}
                Body: {body[:500]}
                
                Respond with only the category name."""
            }]
        )
        
        return message.content[0].text.strip().lower()
```

### Rate Limits & Costs

**Rate Limits:**
- **Claude 3 Sonnet:** 50 requests/minute
- **Claude 3 Opus:** 5 requests/minute

**Pricing (as of March 2026):**
- **Input:** $3 per million tokens
- **Output:** $15 per million tokens

**Average cost per email categorization:** ~$0.0001

### Best Practices

1. **Batch Processing**: Queue emails and process in batches
2. **Caching**: Cache categorization results
3. **Truncation**: Only send first 500 chars of email body
4. **Error Handling**: Fallback to keyword-based categorization

---

## Apple Push Notifications

### Overview

APNs (Apple Push Notification Service) delivers real-time notifications to iOS app.

**Notification Types:**
- New email alerts
- Calendar event reminders
- Background sync triggers (silent push)

### Setup

#### 1. Apple Developer Account

```bash
# Requirements:
# - Apple Developer account ($99/year)
# - App ID with Push Notifications enabled
# - APNs Certificate or Key (Auth Key recommended)
```

#### 2. Generate APNs Auth Key

```bash
# In Apple Developer Portal:
# 1. Certificates, Identifiers & Profiles
# 2. Keys → Create new Key
# 3. Enable "Apple Push Notifications service (APNs)"
# 4. Download .p8 key file
```

#### 3. Configure Backend

```bash
# Add to .env
APNS_KEY_ID=ABC1234567
APNS_TEAM_ID=DEF7891011
APNS_KEY_PATH=/path/to/AuthKey_ABC1234567.p8
APNS_BUNDLE_ID=com.inboxiq.app
APNS_USE_SANDBOX=true  # false for production
```

### Integration Example

```python
# app/services/push_service.py
import jwt
import time
import requests

class APNsService:
    def __init__(self):
        self.key_id = os.getenv("APNS_KEY_ID")
        self.team_id = os.getenv("APNS_TEAM_ID")
        self.bundle_id = os.getenv("APNS_BUNDLE_ID")
        self.sandbox = os.getenv("APNS_USE_SANDBOX") == "true"
        
        # Load private key
        with open(os.getenv("APNS_KEY_PATH"), 'r') as f:
            self.private_key = f.read()
    
    def generate_token(self) -> str:
        """Generate APNs JWT token."""
        headers = {
            "alg": "ES256",
            "kid": self.key_id
        }
        
        payload = {
            "iss": self.team_id,
            "iat": int(time.time())
        }
        
        return jwt.encode(payload, self.private_key, 
                         algorithm="ES256", headers=headers)
    
    def send_notification(self, device_token: str, 
                         title: str, body: str):
        """Send push notification to device."""
        url = f"https://api{'sandbox' if self.sandbox else ''}.push.apple.com/3/device/{device_token}"
        
        headers = {
            "authorization": f"bearer {self.generate_token()}",
            "apns-topic": self.bundle_id,
            "apns-priority": "10"
        }
        
        payload = {
            "aps": {
                "alert": {
                    "title": title,
                    "body": body
                },
                "badge": 1,
                "sound": "default"
            }
        }
        
        response = requests.post(url, headers=headers, json=payload)
        return response.status_code == 200
```

### Silent Push (Background Sync)

```python
# Trigger background sync without alert
payload = {
    "aps": {
        "content-available": 1  # Triggers background fetch
    },
    "sync_type": "emails"
}
```

---

## Security Best Practices

### 1. Token Storage

**Encrypt tokens at rest:**
```python
from cryptography.fernet import Fernet

class TokenEncryption:
    def __init__(self):
        self.key = os.getenv("ENCRYPTION_KEY").encode()
        self.cipher = Fernet(self.key)
    
    def encrypt(self, token: str) -> str:
        return self.cipher.encrypt(token.encode()).decode()
    
    def decrypt(self, encrypted_token: str) -> str:
        return self.cipher.decrypt(encrypted_token.encode()).decode()
```

### 2. OAuth State Tokens

**Always validate CSRF state tokens:**
```python
import secrets

# Generate state token
state = secrets.token_urlsafe(32)

# Store in session/database with user_id
redis.setex(f"oauth_state:{state}", 300, user_id)

# Validate on callback
stored_user_id = redis.get(f"oauth_state:{state}")
if not stored_user_id or stored_user_id != callback_user_id:
    raise HTTPException(401, "Invalid state token")
```

### 3. Token Refresh

**Implement automatic token refresh:**
```python
def get_valid_access_token(user_id: int) -> str:
    user = get_user(user_id)
    
    # Check if token expired
    if datetime.now() >= user.calendar_token_expiry:
        # Refresh token
        tokens = calendar_service.refresh_access_token(
            user.calendar_refresh_token
        )
        
        # Update database
        user.calendar_access_token = tokens["access_token"]
        user.calendar_token_expiry = datetime.now() + timedelta(seconds=3600)
        db.commit()
    
    return user.calendar_access_token
```

### 4. Environment Variables

**Never commit secrets to version control:**
```bash
# .gitignore
.env
*.p8
credentials.json
```

### 5. API Key Rotation

**Rotate API keys quarterly:**
- Anthropic Claude API key
- APNs auth key (yearly)
- OAuth client secrets (as needed)

---

## Troubleshooting

### Gmail Integration Issues

#### "invalid_grant" Error
**Cause:** Invalid authorization code or expired refresh token  
**Solution:** Re-authorize Gmail access

#### "Insufficient Permission" Error
**Cause:** Missing OAuth scopes  
**Solution:** Add required scopes in OAuth consent screen

#### Rate Limit Exceeded
**Cause:** Too many API requests  
**Solution:** Implement exponential backoff and caching

### Calendar Integration Issues

#### "Calendar not connected" Error
**Cause:** User hasn't authorized Calendar or tokens expired  
**Solution:** Check `/api/calendar/status` and re-authorize

#### "Token expired or invalid" Error
**Cause:** Access token expired and refresh failed  
**Solution:** Verify refresh token is stored and valid

#### Events not appearing
**Cause:** Timezone mismatch or calendar not primary  
**Solution:** Verify timezone in event creation, check calendar ID

### Claude AI Issues

#### Slow Categorization
**Cause:** Synchronous API calls blocking requests  
**Solution:** Use background workers with Redis queue

#### High Costs
**Cause:** Processing full email bodies  
**Solution:** Truncate to first 500 characters

#### Inaccurate Categories
**Cause:** Poor prompt engineering  
**Solution:** Refine categorization prompt with examples

### Push Notification Issues

#### Notifications not delivering
**Cause:** Invalid device token or APNs configuration  
**Solution:** Verify device token registration and APNs credentials

#### Silent push not triggering
**Cause:** iOS background app refresh disabled  
**Solution:** User must enable Background App Refresh in Settings

---

## Monitoring & Logging

### Integration Health Checks

```python
# app/health.py
async def integration_health_check():
    """Check health of all integrations."""
    return {
        "gmail_api": check_gmail_api(),
        "calendar_api": check_calendar_api(),
        "claude_api": check_claude_api(),
        "apns": check_apns_connection()
    }
```

### Error Logging

```python
import structlog

logger = structlog.get_logger()

# Log integration errors
logger.error("calendar_api_error",
    user_id=user.id,
    error=str(e),
    endpoint="/api/calendar/events")
```

---

## Future Integrations (Roadmap)

### Planned Integrations

1. **Microsoft Exchange** - Support for Outlook/Exchange emails
2. **Slack** - Email notifications in Slack
3. **Todoist** - Email-to-task conversion
4. **Zapier** - No-code automation
5. **Webhooks** - Real-time event notifications

---

## Resources

### Official Documentation
- **Gmail API:** https://developers.google.com/gmail/api
- **Google Calendar API:** https://developers.google.com/calendar/api
- **Anthropic Claude:** https://docs.anthropic.com/
- **Apple APNs:** https://developer.apple.com/documentation/usernotifications

### InboxIQ Documentation
- [GOOGLE-CALENDAR-SETUP.md](GOOGLE-CALENDAR-SETUP.md) - Detailed Calendar setup
- [API-DOCUMENTATION.md](API-DOCUMENTATION.md) - Complete API reference
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture

---

**Last Updated:** March 2, 2026  
**Maintained by:** InboxIQ Team  
**Questions?** Contact via Linear (Team: INB)
