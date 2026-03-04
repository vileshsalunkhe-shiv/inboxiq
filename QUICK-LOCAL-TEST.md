# Quick Local OAuth Testing

**Goal:** Test OAuth locally to isolate Railway vs. implementation issue  
**Time:** 10-15 minutes  
**Status:** INB-2 in progress

---

## Step 1: Start PostgreSQL + Redis (Docker)

Docker Desktop should be starting now. Once it's ready (watch for Docker icon in menu bar to stop animating):

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/infrastructure

# Start just PostgreSQL + Redis (not the full stack)
docker compose up postgres redis -d

# Verify they're running
docker compose ps

# Should show:
# inboxiq-postgres   running   0.0.0.0:5433->5432/tcp
# inboxiq-redis      running   0.0.0.0:6379->6379/tcp
```

**Database Details:**
- Host: `localhost`
- Port: `5433` (not default 5432!)
- Database: `inboxiq_dev`
- User: `inboxiq`
- Password: `inboxiq_dev_password`

**Redis Details:**
- Host: `localhost`
- Port: `6379`
- Password: `inboxiq_redis_pass`

---

## Step 2: Configure Backend .env

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Create .env file
cat > .env << 'EOF'
# App
ENVIRONMENT=development
APP_NAME=InboxIQ
API_BASE_URL=http://localhost:8000

# Database (Docker Compose settings)
DATABASE_URL=postgresql+asyncpg://inboxiq:inboxiq_dev_password@localhost:5433/inboxiq_dev

# Auth/JWT
JWT_SECRET=local-dev-secret-change-in-production
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXP_MINUTES=15
REFRESH_TOKEN_EXP_DAYS=30

# Google OAuth - GET THESE FROM RAILWAY OR GCP CONSOLE
GOOGLE_CLIENT_ID=YOUR_CLIENT_ID_HERE
GOOGLE_CLIENT_SECRET=YOUR_CLIENT_SECRET_HERE
GOOGLE_REDIRECT_URI=http://localhost:8000/auth/google/callback

# Encryption (generate with: python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())')
ENCRYPTION_KEY=REPLACE_WITH_GENERATED_KEY

# Sentry (optional)
SENTRY_DSN=

# Redis (Docker Compose settings)
REDIS_URL=redis://:inboxiq_redis_pass@localhost:6379/0

# Claude
CLAUDE_API_KEY=YOUR_CLAUDE_KEY_HERE

# Gmail API
GMAIL_API_USER=me

# Digest
DEFAULT_DIGEST_FREQUENCY_HOURS=12

# Frontend
FRONTEND_BASE_URL=http://localhost:8000
EOF

echo "✅ Created .env file"
echo ""
echo "⚠️  YOU MUST UPDATE THESE VALUES:"
echo "   • GOOGLE_CLIENT_ID"
echo "   • GOOGLE_CLIENT_SECRET"
echo "   • ENCRYPTION_KEY (see command below)"
echo "   • CLAUDE_API_KEY"
echo ""
echo "📋 To generate encryption key:"
echo "   poetry run python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'"
```

---

## Step 3: Get Google OAuth Credentials

You need to copy these from your Railway deployment or Google Cloud Console.

### Option A: Copy from Railway

1. Go to Railway dashboard: https://railway.app/project/inboxiq
2. Open backend service
3. Go to "Variables" tab
4. Copy values:
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_CLIENT_SECRET`
5. Paste into local `.env` file

### Option B: Get from Google Cloud Console

1. Go to: https://console.cloud.google.com/
2. Select InboxIQ project
3. Go to: APIs & Services → Credentials
4. Find your OAuth 2.0 Client ID
5. Copy Client ID and Client Secret
6. **IMPORTANT:** Add `http://localhost:8000/auth/google/callback` to Authorized redirect URIs
7. Paste into local `.env` file

---

## Step 4: Generate Encryption Key

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Generate Fernet key
poetry run python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'

# Copy the output (looks like: gAAAAABh...)
# Paste into .env as ENCRYPTION_KEY=<value>
```

---

## Step 5: Run Database Migrations

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Run migrations to create tables
poetry run alembic upgrade head

# Should see:
# INFO  [alembic.runtime.migration] Running upgrade  -> xxxx, Initial schema
# INFO  [alembic.runtime.migration] Running upgrade xxxx -> yyyy, ...
```

---

## Step 6: Start Backend Server

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Start server with auto-reload
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**Expected output:**
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started reloader process [xxxxx] using WatchFiles
INFO:     Started server process [xxxxx]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

**Verify backend is running:**
Open browser → http://localhost:8000/health  
Should show: `{"status": "healthy", "database": "connected"}`

---

## Step 7: Update iOS App

You need to point the iOS app to localhost instead of Railway.

### Find the API base URL in iOS code

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ

# Search for Railway URL
grep -r "inboxiq-production" . --include="*.swift" | head -5
```

### Update to localhost

**Option A: If running on simulator (same machine)**
Change to: `http://localhost:8000`

**Option B: If running on physical device**
Find your Mac's local IP:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1
```
Change to: `http://YOUR_MAC_IP:8000` (e.g., `http://192.168.1.123:8000`)

**File to edit:** Likely in:
- `InboxIQ/Services/APIClient.swift`
- `InboxIQ/Config.swift`
- Or search for `baseURL` in Xcode

---

## Step 8: Test OAuth Flow

1. **Open iOS app in Xcode**
2. **Run on simulator** (or device if you updated IP)
3. **Tap "Sign in with Google"**
4. **Complete Google authentication**
5. **Watch backend logs** (in terminal where uvicorn is running)

**Look for these log entries:**

✅ **Success:**
```json
{
  "event": "google_oauth_token_exchange_attempt",
  "redirect_uri": "http://localhost:8000/auth/google/callback",
  ...
}
{
  "event": "google_oauth_token_exchange_response",
  "status_code": 200,
  ...
}
```

❌ **Failure:**
```json
{
  "event": "google_oauth_token_exchange_failed",
  "status_code": 400,
  "error_detail": "{\"error\": \"invalid_grant\"}",
  ...
}
```

---

## Step 9: Analyze Results

### ✅ If OAuth Works Locally

**Root Cause:** Railway-specific issue

**Likely Problems:**
- Railway `GOOGLE_REDIRECT_URI` env var is wrong
- Railway proxy is interfering
- Railway domain doesn't match GCP redirect_uri

**Next Steps:**
1. Check Railway environment variables
2. Verify `GOOGLE_REDIRECT_URI` exactly matches GCP Console
3. Check Railway logs for more details
4. Update INB-1 with findings
5. Fix Railway config

---

### ❌ If OAuth Fails Locally

**Root Cause:** OAuth implementation issue

**Likely Problems:**
- `redirect_uri` mismatch (authorization URL ≠ token exchange)
- Google Cloud Console missing `http://localhost:8000/auth/google/callback`
- Client ID/Secret mismatch
- Code expired (timing issue)

**Next Steps:**
1. Add enhanced logging (see OAuth-Debug-Plan.md Phase 2)
2. Compare exact `redirect_uri` values in logs
3. Verify GCP Console configuration
4. Test with OAuth Playground (Phase 4)
5. Consider implementing test token workaround (INB-3)

---

## Quick Commands Summary

```bash
# Terminal 1: Start Docker services
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/infrastructure
docker compose up postgres redis -d

# Terminal 2: Run backend
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# First time only:
poetry install
poetry run alembic upgrade head

# Every time:
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 3: Xcode - run iOS app on simulator
```

---

## Cleanup When Done

```bash
# Stop backend (Ctrl+C in Terminal 2)

# Stop Docker services
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/infrastructure
docker compose down

# Optional: Remove volumes (deletes data)
docker compose down -v
```

---

## Troubleshooting

### "poetry: command not found"

```bash
brew install poetry
```

### "docker compose: command not found"

Docker Desktop might still be starting. Wait 30-60 seconds and try again.

### "Connection refused" to PostgreSQL

```bash
# Check if container is running
docker compose ps

# Check logs
docker compose logs postgres

# Restart
docker compose restart postgres
```

### "FATAL: password authentication failed"

Double-check DATABASE_URL in .env matches docker-compose.yml:
```
DATABASE_URL=postgresql+asyncpg://inboxiq:inboxiq_dev_password@localhost:5433/inboxiq_dev
```

---

## Success Criteria

✅ Backend running on http://localhost:8000  
✅ /health endpoint returns "healthy"  
✅ iOS app can reach backend  
✅ OAuth flow completes (or fails with clear error)  
✅ Logs show detailed OAuth exchange information  

---

**Status:** Ready to test!  
**Next:** Follow steps above, document results in INB-1
