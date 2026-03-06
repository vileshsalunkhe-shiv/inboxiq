# Task: Daily Digest Email - Backend

**Agent:** DEV-BE-premium
**Priority:** HIGH (Partner demo tomorrow)
**Time Estimate:** 2-3 hours
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/daily-digest-backend/`

---

## Objective
Implement backend API for daily digest email feature. Users receive a daily email summary of their inbox (unread count, top urgent emails, today's calendar events, category breakdown).

---

## Requirements

### 1. Digest Preview API
**Endpoint:** `GET /api/digest/preview`
**Auth:** Required (JWT)
**Purpose:** Generate and return HTML preview of what the digest email will look like

**Response:**
```json
{
  "html": "<html>...</html>",
  "generated_at": "2026-03-05T15:37:00Z",
  "email_count": 25,
  "calendar_event_count": 3
}
```

**Content to Include:**
- Header with InboxIQ branding
- Unread email count (last 24 hours)
- Top 5 urgent/action-required emails:
  - Subject (truncate at 60 chars)
  - Sender name and email
  - Snippet (first 100 chars)
  - Timestamp
  - Link to email (can be placeholder for now)
- Today's calendar events (next 24 hours):
  - Event title
  - Start time
  - Location (if present)
- Category breakdown (pie chart or simple list):
  - Urgent: X emails
  - Action Required: X emails
  - Finance: X emails
  - FYI: X emails
  - Newsletter: X emails
  - Other: X emails
- Footer with "Manage preferences" link (placeholder)

### 2. Send Digest API
**Endpoint:** `POST /api/digest/send`
**Auth:** Required (JWT)
**Purpose:** Generate digest HTML and send via Gmail API

**Response:**
```json
{
  "success": true,
  "message_id": "abc123",
  "sent_at": "2026-03-05T15:37:00Z",
  "recipient": "user@example.com"
}
```

**Behavior:**
- Generate digest HTML (same as preview)
- Send email via Gmail API to user's own email address
- Subject: "Your Daily InboxIQ Digest - [Date]"
- From: User's own email (sent to self)
- Update user's `last_digest_sent_at` timestamp

### 3. User Digest Preferences
**Add to User model:**
- `digest_enabled` (boolean, default True)
- `digest_time` (time, default "07:00:00")
- `last_digest_sent_at` (datetime, nullable)

**Migration Required:** Create Alembic migration for new columns

**Optional:** If time allows, add `GET/PATCH /api/user/digest-preferences` endpoints

### 4. Digest Service
**File:** `app/services/digest_service.py`

**Key Methods:**
- `generate_digest_html(user_id: UUID) -> str` - Generates HTML content
- `send_digest_email(user_id: UUID) -> dict` - Sends email via Gmail
- `get_digest_data(user_id: UUID) -> dict` - Gathers all data (emails, calendar, counts)

**Data Sources:**
- Emails: Query last 24 hours, filter by categories
- Calendar: Query next 24 hours from Google Calendar API
- Use existing `gmail_service.py` for sending email
- Use existing `calendar_service.py` for events

### 5. HTML Email Template
**Requirements:**
- Responsive design (mobile-friendly)
- Inline CSS (email clients don't support external stylesheets)
- InboxIQ branding colors (use existing Design System colors)
- Professional layout (table-based for email compatibility)
- All images must be inline (data URIs or external CDN)

**Libraries:**
- Use Jinja2 for templating (already in dependencies)
- Consider using `premailer` for CSS inlining (optional)

---

## Technical Constraints

### DO NOT BREAK EXISTING FUNCTIONALITY
- Do not modify existing API endpoints
- Do not modify existing service methods
- Only ADD new code, don't refactor existing code
- Test that existing features still work after changes

### Gmail API Integration
- Reuse existing OAuth tokens from `user_google_tokens` table
- Use existing `gmail_service.py` methods where possible
- Handle rate limits gracefully (digest is low priority)
- Email format: `message/rfc822` or `text/html`

### Database
- Create migration for user table changes
- Use async SQLAlchemy patterns (existing codebase style)
- Don't break existing user queries

### Error Handling
- Handle Gmail API errors (401, 429, 500)
- Handle missing calendar access gracefully
- Return meaningful error messages
- Log errors for debugging

---

## Output Structure

Create this directory structure in your output folder:

```
daily-digest-backend/
├── README.md                           # What you built, how to integrate
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── digest.py              # New API endpoints
│   │   ├── services/
│   │   │   └── digest_service.py      # Digest logic
│   │   └── templates/
│   │       └── digest_email.html      # Jinja2 email template
│   ├── alembic/
│   │   └── versions/
│   │       └── 007_add_digest_preferences.py  # Migration
│   └── tests/
│       └── test_digest.py             # Unit tests (optional but nice)
└── INTEGRATION.md                     # Step-by-step integration instructions
```

---

## Testing Requirements

Before marking complete, test:
1. **Preview endpoint:** Returns valid HTML with real data
2. **Send endpoint:** Successfully sends email via Gmail API
3. **Migration:** Runs without errors, adds columns correctly
4. **No regressions:** Existing endpoints still work (auth, sync, email actions)

**Test Commands:**
```bash
# Test preview
curl -H "Authorization: Bearer $TOKEN" \
  https://inboxiq-production-5368.up.railway.app/api/digest/preview

# Test send
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://inboxiq-production-5368.up.railway.app/api/digest/send

# Check migration
cd backend && alembic upgrade head
```

---

## Integration Steps (For Later)

1. Copy files to main codebase:
   - `app/api/digest.py` → `backend/app/api/`
   - `app/services/digest_service.py` → `backend/app/services/`
   - `app/templates/digest_email.html` → `backend/app/templates/`
   - Migration → `backend/alembic/versions/`

2. Register API router in `app/main.py`:
   ```python
   from app.api import digest
   app.include_router(digest.router, prefix="/api", tags=["digest"])
   ```

3. Run migration on Railway:
   ```bash
   railway run alembic upgrade head
   ```

4. Test in production environment

---

## Dependencies

**Already Available:**
- Jinja2 (for templates)
- SQLAlchemy (for user model)
- Gmail API (via `gmail_service.py`)
- Calendar API (via `calendar_service.py`)

**May Need to Add:**
- `premailer` (for CSS inlining) - optional

---

## Success Criteria

✅ Preview endpoint returns formatted HTML digest
✅ Send endpoint sends email to user's Gmail successfully
✅ Email displays correctly in Gmail web/mobile
✅ Migration adds user preferences columns
✅ No existing functionality broken
✅ Code follows existing patterns (async, error handling)
✅ README and integration docs complete

---

## Notes

- **User for testing:** vilesh.salunkhe@gmail.com (user_id: 1ae0ee58-a04f-47b2-ba79-5779bff48b65)
- **Railway URL:** https://inboxiq-production-5368.up.railway.app
- **Existing services to reference:**
  - `app/services/gmail_service.py` - Email sending
  - `app/services/calendar_service.py` - Calendar events
  - `app/api/auth_ios.py` - JWT auth patterns
  - `app/models/user.py` - User model

**Priority:** Get preview and send working first, preferences can be simplified if time is tight.

**Questions?** Document them in README.md and continue with best judgment.

---

**Good luck! 🔥**
