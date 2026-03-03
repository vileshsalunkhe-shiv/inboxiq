# Railway Deployment Checklist

## Pre-Deployment Verification ✅

### 1. Local Testing Complete
- [x] Database migration runs successfully (`alembic upgrade head`)
- [x] Backend starts without errors
- [x] Calendar OAuth flow tested end-to-end
- [x] Event listing works (GET `/calendar/events`)
- [x] Event creation works (POST `/calendar/events`)
- [x] Token storage and retrieval verified

### 2. Code Changes
- [x] User model updated with calendar token columns
- [x] Calendar API endpoints updated to use database tokens
- [x] Migration file created (`004_add_calendar_tokens.py`)
- [x] Validation errors fixed (Optional fields with defaults)

---

## Railway Deployment Steps

### Step 1: Commit and Push to GitHub

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq

# Check status
git status

# Add all changes
git add .

# Commit with descriptive message
git commit -m "Add Google Calendar integration with database token storage

- Added calendar token columns to User model (access_token, refresh_token, expiry)
- Created Alembic migration 004_add_calendar_tokens
- Updated calendar API endpoints to persist and retrieve tokens from database
- Fixed CalendarEvent validation (made optional fields have defaults)
- Tested locally: OAuth flow, event listing, event creation all working
"

# Push to develop branch
git push origin develop
```

---

### Step 2: Verify Railway Auto-Deploy

Railway will automatically:
1. Detect the push to `develop` branch
2. Build the Docker image
3. Run database migrations (`alembic upgrade head`)
4. Deploy the updated backend

**Check Railway Dashboard:**
- Go to: https://railway.app/project/YOUR_PROJECT_ID
- Watch the deployment logs
- Look for: "Running upgrade 003 -> 004"

---

### Step 3: Verify Migration on Railway

**Option A: Railway Dashboard**
1. Go to Railway project
2. Click on PostgreSQL service
3. Click "Data" tab
4. Select `users` table
5. Verify new columns exist:
   - `calendar_access_token`
   - `calendar_refresh_token`
   - `calendar_token_expiry`

**Option B: Railway CLI**
```bash
railway run psql $DATABASE_URL -c "\d users"
```

---

### Step 4: Test Calendar Integration on Production

**Get your Railway backend URL:**
```
https://inboxiq-production-5368.up.railway.app
```

**Test OAuth Flow:**
```bash
# Get your user_id from production database
RAILWAY_URL="https://inboxiq-production-5368.up.railway.app"
USER_ID="f72c4e31-3011-4134-933c-069cb95d55d9"

# 1. Check connection status
curl "$RAILWAY_URL/calendar/status?user_id=$USER_ID"

# 2. If not connected, initiate OAuth
curl "$RAILWAY_URL/calendar/auth/initiate?user_id=$USER_ID"

# 3. Visit the authorization_url in browser
# 4. After OAuth, check status again
curl "$RAILWAY_URL/calendar/status?user_id=$USER_ID"

# 5. List events
curl "$RAILWAY_URL/calendar/events?user_id=$USER_ID&max_results=5"
```

---

## Google Cloud Console Configuration

**If calendar integration is new on Railway, configure OAuth credentials:**

### 1. Create OAuth Client (if not already done)

1. Go to: https://console.cloud.google.com/apis/credentials
2. Select your project (or create "InboxIQ Calendar")
3. Click "Create Credentials" → "OAuth 2.0 Client ID"
4. Application type: **Web application**
5. Name: "InboxIQ Calendar - Production"
6. Authorized redirect URIs:
   ```
   https://inboxiq-production-5368.up.railway.app/calendar/callback
   ```
7. Click "Create"
8. Copy **Client ID** and **Client Secret**

### 2. Update Railway Environment Variables

In Railway dashboard → Backend service → Variables:

```bash
GOOGLE_CALENDAR_CLIENT_ID=<your-client-id>
GOOGLE_CALENDAR_CLIENT_SECRET=<your-client-secret>
GOOGLE_CALENDAR_REDIRECT_URI=https://inboxiq-production-5368.up.railway.app/calendar/callback
```

**Save and redeploy.**

---

## Post-Deployment Verification

### Checklist
- [ ] Railway deployment successful (green checkmark)
- [ ] Migration ran without errors (check logs for "Running upgrade 003 -> 004")
- [ ] Backend health check returns 200: `curl https://inboxiq-production-5368.up.railway.app/health`
- [ ] Calendar status endpoint works
- [ ] OAuth flow completes successfully
- [ ] Events can be listed
- [ ] Events can be created

---

## Rollback Plan (if needed)

### If migration fails:
```bash
# SSH into Railway container
railway run bash

# Rollback migration
alembic downgrade -1

# Verify
alembic current
```

### If deployment breaks:
1. Go to Railway dashboard
2. Click "Deployments"
3. Find previous working deployment
4. Click "..." → "Redeploy"

---

## Environment Variables Reference

**Required Environment Variables for Railway:**

```bash
# Google Calendar API
GOOGLE_CALENDAR_CLIENT_ID=<your-google-calendar-client-id>
GOOGLE_CALENDAR_CLIENT_SECRET=<your-google-calendar-client-secret>
GOOGLE_CALENDAR_REDIRECT_URI=https://inboxiq-production-5368.up.railway.app/calendar/callback
```

**Important:**
- Get credentials from Google Cloud Console
- Production values should use Railway URL, not localhost!
- Copy from local `.env` file (DO NOT commit credentials to GitHub)

---

## Success Criteria

✅ **Deployment is successful when:**
1. Railway shows green status
2. Migration 004 appears in `alembic current`
3. Calendar OAuth flow works on production URL
4. Events can be listed from production
5. Events can be created via production API
6. No errors in Railway logs

---

## Troubleshooting

### Issue: Migration doesn't run
**Solution:** Check Railway logs for migration errors, verify `alembic.ini` points to correct database

### Issue: OAuth fails with "invalid_redirect_uri"
**Solution:** Verify redirect URI in Google Cloud Console matches Railway URL exactly

### Issue: Tokens not persisting
**Solution:** Check database columns exist, verify `db.commit()` is called in callback endpoint

### Issue: 500 errors on calendar endpoints
**Solution:** Check Railway logs for detailed traceback, verify Google Calendar API credentials

---

**Created:** 2026-03-02 22:30 CST  
**Status:** Ready for deployment 🚀
