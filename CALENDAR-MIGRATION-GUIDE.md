# Google Calendar Migration Guide

## What Was Done ✅

### 1. User Model Updated
Added three new columns to store Google Calendar OAuth tokens:

**File:** `backend/app/models/user.py`

```python
# Google Calendar OAuth tokens
calendar_access_token: Mapped[str | None] = mapped_column(Text, nullable=True)
calendar_refresh_token: Mapped[str | None] = mapped_column(Text, nullable=True)
calendar_token_expiry: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
```

### 2. Migration Created
**File:** `backend/alembic/versions/004_add_calendar_tokens.py`

- Adds the three calendar token columns to `users` table
- Includes rollback (downgrade) support

### 3. Calendar API Updated
**File:** `backend/app/api/calendar.py`

Updated endpoints to persist and retrieve tokens:

- **`/calendar/callback`**: Now saves tokens to database after OAuth
- **`/calendar/events` (GET)**: Retrieves tokens from database
- **`/calendar/events` (POST)**: Uses stored tokens to create events
- **`/calendar/status`**: Checks token validity and expiry

---

## How to Run the Migration

### Option A: Local Development (Docker)

1. **Start the database:**
   ```bash
   cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend
   docker-compose up -d postgres
   ```

2. **Run the migration:**
   ```bash
   # Activate venv (if using local Python)
   source venv/bin/activate
   
   # Run migration
   alembic upgrade head
   ```

3. **Verify:**
   ```bash
   # Check migration status
   alembic current
   
   # Should show: 004 (head)
   ```

### Option B: Railway Production

1. **Push code to GitHub:**
   ```bash
   git add .
   git commit -m "Add Google Calendar token storage"
   git push origin develop
   ```

2. **Railway auto-deploys** and runs migrations automatically (via `start.sh`)

---

## Testing the Integration

### 1. Start Backend
```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 2. Test OAuth Flow

**Step 1: Initiate authorization**
```bash
# Get a test user_id from database
USER_ID="<your-user-uuid>"

curl "http://localhost:8000/calendar/auth/initiate?user_id=$USER_ID"
```

Response:
```json
{
  "authorization_url": "https://accounts.google.com/o/oauth2/v2/auth?...",
  "state": "eyJ1c2VyX2lkIjoi..."
}
```

**Step 2: Visit the authorization URL in browser**
- Authorize the app
- You'll be redirected to callback URL
- Tokens will be saved to database

**Step 3: Check connection status**
```bash
curl "http://localhost:8000/calendar/status?user_id=$USER_ID"
```

Response:
```json
{
  "connected": true,
  "email": "user@example.com",
  "has_refresh_token": true,
  "token_expiry": "2026-03-02T23:00:00",
  "is_expired": false
}
```

**Step 4: List events**
```bash
curl "http://localhost:8000/calendar/events?user_id=$USER_ID&max_results=5"
```

---

## Database Schema Changes

```sql
-- Migration 004 adds these columns:
ALTER TABLE users ADD COLUMN calendar_access_token TEXT NULL;
ALTER TABLE users ADD COLUMN calendar_refresh_token TEXT NULL;
ALTER TABLE users ADD COLUMN calendar_token_expiry TIMESTAMP NULL;
```

---

## Next Steps

1. ✅ Run migration locally
2. ✅ Test OAuth flow
3. ✅ Verify tokens are stored
4. [ ] Set up Google Cloud Console OAuth credentials
5. [ ] Configure `.env` with client ID/secret
6. [ ] Test end-to-end calendar integration
7. [ ] Deploy to Railway
8. [ ] Add calendar features to iOS app

---

## Rollback (if needed)

```bash
# Downgrade to previous version
alembic downgrade -1

# This will remove the calendar token columns
```

---

**Migration created:** 2026-03-02 22:05 CST  
**Total time:** 5 minutes ⚡  
**Status:** Ready to run ✅
