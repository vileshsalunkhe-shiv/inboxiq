# InboxIQ API Documentation

**Version:** 0.3.0  
**Base URL:** `https://api.inboxiq.app` (Production) | `http://localhost:8000` (Development)  
**Last Updated:** March 2, 2026

---

## Table of Contents

1. [Authentication](#authentication)
2. [Gmail Integration](#gmail-integration)
3. [Calendar Integration](#calendar-integration) ✨ NEW
4. [Email Management](#email-management)
5. [User Management](#user-management)
6. [Categories](#categories)
7. [Error Handling](#error-handling)
8. [Rate Limiting](#rate-limiting)
9. [Webhooks](#webhooks)

---

## Authentication

All API requests (except OAuth callbacks) require authentication via JWT Bearer tokens.

### Request Headers

```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### POST /auth/register

Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!",
  "full_name": "John Doe"
}
```

**Response:** `201 Created`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "full_name": "John Doe",
  "created_at": "2026-03-02T10:30:00Z"
}
```

---

### POST /auth/login

Authenticate user and receive JWT tokens.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePassword123!"
}
```

**Response:** `200 OK`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900
}
```

---

### POST /auth/refresh

Refresh expired access token using refresh token.

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:** `200 OK`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 900
}
```

---

## Gmail Integration

### GET /gmail/auth/initiate

Initiate Gmail OAuth 2.0 authorization flow.

**Query Parameters:**
- `user_id` (required): User ID

**Response:** `200 OK`
```json
{
  "authorization_url": "https://accounts.google.com/o/oauth2/auth?...",
  "state": "random_csrf_token"
}
```

**Usage:**
```bash
curl "http://localhost:8000/gmail/auth/initiate?user_id=1"
```

Redirect user to `authorization_url` in browser.

---

### GET /gmail/auth/callback

OAuth callback endpoint (handled automatically by Google).

**Query Parameters:**
- `code` (required): Authorization code
- `state` (required): CSRF state token
- `user_id` (required): User ID

**Response:** `302 Redirect`
Redirects to frontend with success/error status.

---

### GET /gmail/emails

Fetch user's Gmail emails.

**Query Parameters:**
- `user_id` (required): User ID
- `max_results` (optional): Number of emails (default: 50, max: 100)
- `query` (optional): Gmail search query (e.g., "is:unread")

**Response:** `200 OK`
```json
{
  "emails": [
    {
      "id": "18d4c2f1a2b3c4d5",
      "thread_id": "18d4c2f1a2b3c4d5",
      "subject": "Q2 Planning Meeting",
      "from": {
        "name": "Sarah Johnson",
        "email": "sarah@company.com"
      },
      "to": [
        {
          "name": "You",
          "email": "user@example.com"
        }
      ],
      "date": "2026-03-02T14:30:00Z",
      "snippet": "Hi team, let's schedule our Q2 planning...",
      "category": "work",
      "labels": ["INBOX", "IMPORTANT"],
      "is_read": false,
      "has_attachments": true
    }
  ],
  "next_page_token": "CAUQ5QEIABgBIhQKC...",
  "result_size_estimate": 150
}
```

**Example:**
```bash
curl -H "Authorization: Bearer $TOKEN" \
  "http://localhost:8000/gmail/emails?user_id=1&max_results=10&query=is:unread"
```

---

### POST /gmail/emails/send

Send an email via Gmail.

**Request:**
```json
{
  "to": ["recipient@example.com"],
  "cc": ["cc@example.com"],
  "bcc": ["bcc@example.com"],
  "subject": "Meeting Follow-up",
  "body": "Hi team,\n\nThanks for today's meeting...",
  "body_html": "<p>Hi team,</p><p>Thanks for today's meeting...</p>",
  "attachments": [
    {
      "filename": "report.pdf",
      "content": "base64_encoded_content",
      "mime_type": "application/pdf"
    }
  ]
}
```

**Response:** `200 OK`
```json
{
  "id": "18d4c2f1a2b3c4d5",
  "thread_id": "18d4c2f1a2b3c4d5",
  "label_ids": ["SENT"]
}
```

---

## Calendar Integration ✨ NEW

### GET /api/calendar/auth/initiate

Initiate Google Calendar OAuth 2.0 authorization flow.

**Query Parameters:**
- `user_id` (required): User ID

**Response:** `200 OK`
```json
{
  "authorization_url": "https://accounts.google.com/o/oauth2/auth?client_id=...",
  "state": "random_csrf_token_32_chars"
}
```

**Example:**
```bash
curl "http://localhost:8000/api/calendar/auth/initiate?user_id=1"
```

**Usage Flow:**
1. Call this endpoint to get authorization URL
2. Redirect user to `authorization_url` in browser
3. User grants Calendar permissions
4. User redirected back to callback endpoint

**Scopes Requested:**
- `https://www.googleapis.com/auth/calendar.readonly` - Read calendar events
- `https://www.googleapis.com/auth/calendar.events` - Create/modify events

---

### GET /api/calendar/auth/callback

OAuth callback endpoint (handled automatically by Google).

**Query Parameters:**
- `code` (required): Authorization code from Google
- `state` (required): CSRF state token
- `user_id` (required): User ID

**Response:** `302 Redirect`
Redirects to `/calendar/success` on success.

**Error Codes:**
- `401 Unauthorized` - Invalid state token or user not found
- `500 Internal Server Error` - Token exchange failed

---

### GET /api/calendar/events

List upcoming calendar events.

**Query Parameters:**
- `user_id` (required): User ID
- `max_results` (optional): Number of events (default: 10, range: 1-100)

**Response:** `200 OK`
```json
[
  {
    "id": "abc123xyz",
    "summary": "Team Standup",
    "description": "Daily team sync meeting",
    "start": "2026-03-03T10:00:00-06:00",
    "end": "2026-03-03T10:30:00-06:00",
    "location": "Conference Room A",
    "attendees": [
      "teammate1@example.com",
      "teammate2@example.com"
    ],
    "html_link": "https://calendar.google.com/calendar/event?eid=..."
  },
  {
    "id": "def456uvw",
    "summary": "Lunch with Client",
    "description": null,
    "start": "2026-03-03T12:00:00-06:00",
    "end": "2026-03-03T13:00:00-06:00",
    "location": "Downtown Restaurant",
    "attendees": [
      "client@company.com"
    ],
    "html_link": "https://calendar.google.com/calendar/event?eid=..."
  }
]
```

**Example:**
```bash
curl "http://localhost:8000/api/calendar/events?user_id=1&max_results=5"
```

**Notes:**
- Returns events from user's primary Google Calendar
- Events sorted by start time (earliest first)
- Time range: Current time to +7 days
- Requires valid calendar OAuth tokens

**Error Codes:**
- `401 Unauthorized` - Calendar not connected or tokens expired
- `404 Not Found` - User not found
- `500 Internal Server Error` - Google Calendar API error

---

### POST /api/calendar/events

Create a new calendar event.

**Query Parameters:**
- `user_id` (required): User ID

**Request Body:**
```json
{
  "summary": "Q2 Planning Meeting",
  "start_time": "2026-03-10T14:00:00",
  "end_time": "2026-03-10T15:00:00",
  "description": "Quarterly planning session for Q2 2026",
  "location": "Conference Room B",
  "attendees": [
    "teammate1@example.com",
    "teammate2@example.com",
    "manager@example.com"
  ]
}
```

**Response:** `200 OK`
```json
{
  "id": "ghi789rst",
  "summary": "Q2 Planning Meeting",
  "description": "Quarterly planning session for Q2 2026",
  "start": "2026-03-10T14:00:00-06:00",
  "end": "2026-03-10T15:00:00-06:00",
  "location": "Conference Room B",
  "attendees": [
    "teammate1@example.com",
    "teammate2@example.com",
    "manager@example.com"
  ],
  "html_link": "https://calendar.google.com/calendar/event?eid=..."
}
```

**Example:**
```bash
curl -X POST "http://localhost:8000/api/calendar/events?user_id=1" \
  -H "Content-Type: application/json" \
  -d '{
    "summary": "Team Sync",
    "start_time": "2026-03-10T10:00:00",
    "end_time": "2026-03-10T11:00:00",
    "description": "Weekly team sync meeting"
  }'
```

**Field Details:**
- `summary` (required): Event title/name
- `start_time` (required): ISO 8601 datetime
- `end_time` (required): ISO 8601 datetime
- `description` (optional): Event details
- `location` (optional): Event location
- `attendees` (optional): Array of email addresses

**Notes:**
- Times use America/Chicago timezone by default
- Attendees receive email invitations
- Calendar invites include video conferencing link (Google Meet)
- Supports recurring events (future enhancement)

**Error Codes:**
- `400 Bad Request` - Invalid datetime format or end before start
- `401 Unauthorized` - Calendar not connected
- `404 Not Found` - User not found
- `500 Internal Server Error` - Failed to create event

---

### GET /api/calendar/status

Check if user has connected Google Calendar.

**Query Parameters:**
- `user_id` (required): User ID

**Response:** `200 OK`
```json
{
  "connected": true,
  "email": "user@example.com"
}
```

**Example:**
```bash
curl "http://localhost:8000/api/calendar/status?user_id=1"
```

**Response Fields:**
- `connected` (boolean): True if user has valid calendar tokens
- `email` (string): User's email address

**Use Cases:**
- Check if user needs to authorize Calendar access
- Display connection status in UI
- Conditionally show calendar features

---

## Email Management

### GET /emails

List user's categorized emails.

**Query Parameters:**
- `category` (optional): Filter by category (work, personal, finance, shopping, travel, newsletters)
- `page` (optional): Page number (default: 1)
- `page_size` (optional): Items per page (default: 50, max: 100)
- `is_read` (optional): Filter by read status (true/false)
- `has_attachments` (optional): Filter by attachments (true/false)

**Response:** `200 OK`
```json
{
  "emails": [...],
  "total": 245,
  "page": 1,
  "page_size": 50,
  "total_pages": 5
}
```

---

### GET /emails/{email_id}

Get full email details.

**Path Parameters:**
- `email_id` (required): Email ID

**Response:** `200 OK`
```json
{
  "id": "18d4c2f1a2b3c4d5",
  "subject": "Q2 Planning Meeting",
  "from": {
    "name": "Sarah Johnson",
    "email": "sarah@company.com"
  },
  "to": [...],
  "cc": [...],
  "bcc": [...],
  "date": "2026-03-02T14:30:00Z",
  "body_text": "Hi team...",
  "body_html": "<p>Hi team...</p>",
  "category": "work",
  "ai_summary": "Meeting invitation for Q2 planning discussion",
  "attachments": [
    {
      "filename": "agenda.pdf",
      "mime_type": "application/pdf",
      "size": 245678,
      "attachment_id": "abc123"
    }
  ],
  "labels": ["INBOX", "IMPORTANT"],
  "is_read": false,
  "is_starred": false
}
```

---

### PUT /emails/{email_id}/category

Update email category.

**Path Parameters:**
- `email_id` (required): Email ID

**Request:**
```json
{
  "category": "work"
}
```

**Response:** `200 OK`
```json
{
  "id": "18d4c2f1a2b3c4d5",
  "category": "work",
  "updated_at": "2026-03-02T15:30:00Z"
}
```

---

### DELETE /emails/{email_id}

Move email to trash (soft delete).

**Path Parameters:**
- `email_id` (required): Email ID

**Response:** `204 No Content`

---

## User Management

### GET /users/me

Get current authenticated user's profile.

**Response:** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "full_name": "John Doe",
  "created_at": "2026-01-15T10:30:00Z",
  "gmail_connected": true,
  "calendar_connected": true,
  "last_sync": "2026-03-02T15:45:00Z",
  "email_count": 1247,
  "subscription_tier": "pro"
}
```

---

### PUT /users/me

Update user profile.

**Request:**
```json
{
  "full_name": "John Smith",
  "notification_preferences": {
    "email_notifications": true,
    "push_notifications": true,
    "digest_frequency": "daily"
  }
}
```

**Response:** `200 OK`
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "full_name": "John Smith",
  "notification_preferences": {...}
}
```

---

## Categories

### GET /categories

List all email categories.

**Response:** `200 OK`
```json
{
  "categories": [
    {
      "id": "work",
      "name": "Work",
      "description": "Professional emails and work-related communication",
      "color": "#4A90E2",
      "icon": "briefcase",
      "count": 342
    },
    {
      "id": "personal",
      "name": "Personal",
      "description": "Personal correspondence and family emails",
      "color": "#7ED321",
      "icon": "user",
      "count": 128
    }
  ]
}
```

---

## Error Handling

### Error Response Format

All errors follow this structure:

```json
{
  "error": {
    "code": "INVALID_TOKEN",
    "message": "The provided token is invalid or expired",
    "details": {
      "field": "refresh_token",
      "reason": "Token signature verification failed"
    }
  }
}
```

### HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 204 | No Content | Request successful, no response body |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Authentication required or failed |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation error |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Temporary service outage |

### Common Error Codes

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `INVALID_TOKEN` | 401 | JWT token invalid or expired |
| `CALENDAR_NOT_CONNECTED` | 401 | User hasn't authorized Calendar |
| `GMAIL_NOT_CONNECTED` | 401 | User hasn't authorized Gmail |
| `USER_NOT_FOUND` | 404 | User ID doesn't exist |
| `EMAIL_NOT_FOUND` | 404 | Email ID doesn't exist |
| `INVALID_CATEGORY` | 400 | Invalid category name |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests |
| `OAUTH_STATE_MISMATCH` | 401 | CSRF state token mismatch |
| `TOKEN_EXCHANGE_FAILED` | 500 | Google OAuth token exchange failed |

---

## Rate Limiting

### Rate Limits

| Endpoint Pattern | Limit | Window |
|------------------|-------|--------|
| `/auth/*` | 5 requests | 1 minute |
| `/gmail/*` | 100 requests | 1 minute |
| `/api/calendar/*` | 60 requests | 1 minute |
| `/emails/*` | 200 requests | 1 minute |
| Global | 1000 requests | 1 hour |

### Rate Limit Headers

Response includes rate limit information:

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1709410800
```

### Rate Limit Exceeded Response

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later.",
    "details": {
      "retry_after": 45
    }
  }
}
```

---

## Webhooks

### Gmail Push Notifications (Coming Soon)

Subscribe to real-time Gmail updates via webhooks.

---

## SDK & Libraries

### Python SDK (Coming Soon)

```python
from inboxiq import InboxIQClient

client = InboxIQClient(api_key="your_api_key")
emails = client.emails.list(category="work")
```

### JavaScript SDK (Coming Soon)

```javascript
import InboxIQ from '@inboxiq/sdk';

const client = new InboxIQ({ apiKey: 'your_api_key' });
const emails = await client.emails.list({ category: 'work' });
```

---

## Changelog

### Version 0.3.0 (March 2, 2026)
- ✨ Added Google Calendar integration endpoints
- ✨ Added calendar OAuth flow
- ✨ Added event listing and creation
- ✨ Added calendar connection status endpoint

### Version 0.2.0 (February 28, 2026)
- Added email search
- Added category management
- Improved error handling

### Version 0.1.0 (February 23, 2026)
- Initial API release
- Gmail integration
- Basic email management

---

## Support

**Issues:** Report bugs via Linear (Team: INB)  
**Documentation:** Updates welcome via PR  
**API Status:** https://status.inboxiq.app

---

**Last Updated:** March 2, 2026  
**API Version:** 0.3.0  
**Maintained by:** InboxIQ Team
