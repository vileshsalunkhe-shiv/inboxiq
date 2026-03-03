# Google Calendar Integration Setup

This guide walks you through setting up Google Calendar integration for InboxIQ.

## Prerequisites

- Google Account
- Google Cloud Console access
- InboxIQ backend running

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name: `InboxIQ Calendar`
4. Click "Create"

## Step 2: Enable Google Calendar API

1. In Google Cloud Console, select your project
2. Go to "APIs & Services" → "Library"
3. Search for "Google Calendar API"
4. Click "Enable"

## Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" → "OAuth consent screen"
2. Select "External" (or "Internal" if you have a Google Workspace)
3. Click "Create"

**Fill in details:**
- App name: `InboxIQ`
- User support email: Your email
- Developer contact: Your email
- Click "Save and Continue"

**Scopes:**
- Click "Add or Remove Scopes"
- Add these scopes:
  - `https://www.googleapis.com/auth/calendar.readonly`
  - `https://www.googleapis.com/auth/calendar.events`
- Click "Update" → "Save and Continue"

**Test users (if External):**
- Add your email as a test user
- Click "Save and Continue"

## Step 4: Create OAuth Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. Application type: "Web application"
4. Name: `InboxIQ Backend`

**Authorized redirect URIs:**
```
http://localhost:8000/api/calendar/callback
https://your-production-domain.com/api/calendar/callback
```

5. Click "Create"
6. **Copy Client ID and Client Secret** - you'll need these!

## Step 5: Configure Environment Variables

Add to `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/.env`:

```bash
# Google Calendar API
GOOGLE_CALENDAR_CLIENT_ID=your_client_id_here.apps.googleusercontent.com
GOOGLE_CALENDAR_CLIENT_SECRET=your_client_secret_here
GOOGLE_CALENDAR_REDIRECT_URI=http://localhost:8000/api/calendar/callback
```

## Step 6: Install Dependencies

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Activate virtual environment
source .venv/bin/activate

# Install calendar dependencies
pip install -r requirements-calendar.txt
```

## Step 7: Test the Integration

### 1. Start the backend
```bash
uvicorn app.main:app --reload --port 8000
```

### 2. Initiate OAuth flow
Open in browser or use curl:
```bash
curl "http://localhost:8000/api/calendar/auth/initiate?user_id=1"
```

This returns:
```json
{
  "authorization_url": "https://accounts.google.com/o/oauth2/auth?...",
  "state": "random_state_token"
}
```

### 3. Authorize in browser
1. Open the `authorization_url` in your browser
2. Sign in with Google
3. Grant permissions
4. You'll be redirected to the callback URL

### 4. Check connection status
```bash
curl "http://localhost:8000/api/calendar/status?user_id=1"
```

## API Endpoints

### Initiate OAuth
```
GET /api/calendar/auth/initiate?user_id={id}
```

### OAuth Callback (handled automatically)
```
GET /api/calendar/auth/callback?code={code}&state={state}&user_id={id}
```

### List Events
```
GET /api/calendar/events?user_id={id}&max_results=10
```

### Create Event
```
POST /api/calendar/events?user_id={id}
Content-Type: application/json

{
  "summary": "Team Meeting",
  "start_time": "2026-03-10T14:00:00",
  "end_time": "2026-03-10T15:00:00",
  "description": "Discuss Q2 goals",
  "location": "Conference Room A",
  "attendees": ["teammate@example.com"]
}
```

### Check Connection Status
```
GET /api/calendar/status?user_id={id}
```

## Rate Limits

Google Calendar API limits:
- **Queries per day:** 1,000,000
- **Queries per 100 seconds per user:** 500

The integration includes automatic rate limiting and retry logic.

## Security Best Practices

1. **Never commit credentials** - Keep `.env` file out of version control
2. **Use HTTPS in production** - Update redirect URI for production
3. **Refresh tokens** - Store refresh tokens securely in database
4. **Token encryption** - Encrypt tokens at rest
5. **Scope minimization** - Only request necessary scopes

## Next Steps

### Database Migration (TODO)
Add calendar token storage to User model:

```python
# In app/models/user.py
class User(Base):
    # ... existing fields ...
    calendar_access_token = Column(String, nullable=True)
    calendar_refresh_token = Column(String, nullable=True)
    calendar_token_expiry = Column(DateTime, nullable=True)
```

Create migration:
```bash
alembic revision --autogenerate -m "add_calendar_tokens"
alembic upgrade head
```

### Frontend Integration
1. Add "Connect Calendar" button in iOS app
2. Open OAuth URL in web view
3. Handle callback redirect
4. Show calendar events in app

### Features to Add
- [ ] Auto-sync calendar events with email categories
- [ ] Suggest meeting times from email requests
- [ ] Create events from email actions
- [ ] Smart scheduling based on calendar availability
- [ ] Calendar event reminders in digest

## Troubleshooting

### "invalid_grant" Error
- Check that redirect URI exactly matches the one in Google Console
- Ensure you're using the correct Client ID and Secret
- Try creating new credentials

### "Access Not Configured" Error
- Verify Google Calendar API is enabled
- Wait a few minutes for API enablement to propagate

### 401 Unauthorized
- Token may be expired - implement token refresh
- Check that user has valid stored tokens

### Rate Limit Errors
- The service automatically handles rate limits with exponential backoff
- If persistent, check Google Cloud Console quota page

## Resources

- [Google Calendar API Documentation](https://developers.google.com/calendar/api/guides/overview)
- [OAuth 2.0 Guide](https://developers.google.com/identity/protocols/oauth2)
- [Python Quickstart](https://developers.google.com/calendar/api/quickstart/python)

---

**Integration Status:** ✅ Core API ready | ⚠️ Database migration needed | 🚧 Frontend integration pending
