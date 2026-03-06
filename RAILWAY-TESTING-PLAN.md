# Railway Testing Plan - 2026-03-05

**Goal:** Test all backend features on production (Railway)  
**Timeline:** 1-2 hours  
**Status:** Ready to begin

---

## What We're Testing

### Backend (Railway Production)

**Completed Features:**
1. ✅ OAuth login (Google)
2. ✅ Email sync (Gmail API)
3. ✅ AI categorization (7 categories)
4. ✅ Calendar integration (OAuth + events)
5. ✅ Email action APIs (8 endpoints)
6. ✅ Pagination (emails + calendar)

**Not Yet Tested on Railway:**
- Email action APIs (compose, reply, forward, archive, delete, star)
- Pagination
- Latest OAuth fixes (MissingGreenlet)

---

## Pre-Testing Checklist

### 1. Verify Railway Deployment

```bash
# Check Railway is running
curl https://inboxiq-production-5368.up.railway.app/health

# Expected: 200 OK
# {"status": "healthy"}
```

---

### 2. Check Environment Variables

**Required variables:**
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `CLAUDE_API_KEY`
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_SECRET_KEY`
- `ENCRYPTION_KEY`

**Verify:**
```bash
# In Railway dashboard
railway variables
```

**Missing any? Add them:**
```bash
railway variables set VARIABLE_NAME=value
```

---

### 3. Database Migrations

**Check if migrations are current:**
```bash
# Connect to Railway
railway run bash

# Inside Railway container
alembic current
alembic heads

# If migrations needed
alembic upgrade head
```

---

## Test Suite

### Test 1: Health Check (1 min)

**Endpoint:** `GET /health`

```bash
curl https://inboxiq-production-5368.up.railway.app/health
```

**Expected:**
```json
{
  "status": "healthy",
  "database": "connected",
  "redis": "connected"
}
```

**Status:** ⬜ Not tested

---

### Test 2: OAuth Flow (5 min)

**Test from iOS simulator:**

1. Open InboxIQ app
2. Tap "Sign in with Google"
3. Authorize in Safari
4. Verify redirect back to app with tokens

**Watch Railway logs:**
```bash
railway logs --tail 100
```

**Look for:**
```
✅ ios_oauth_callback_received
✅ Token exchange 200 OK
✅ Userinfo fetch 200 OK
✅ ios_oauth_step_2_user_resolved  ← Should appear now!
✅ ios_oauth_callback_success
```

**Expected:** Successful login, no MissingGreenlet error

**Status:** ⬜ Not tested

---

### Test 3: Email Sync (5 min)

**After OAuth, check email sync:**

1. Wait 10 seconds for initial sync
2. Check inbox tab in app
3. Verify emails appear

**Watch Railway logs:**
```bash
railway logs | grep -i "email\|sync"
```

**Check database:**
```bash
railway run bash
psql $DATABASE_URL -c "SELECT COUNT(*) FROM emails WHERE user_id=(SELECT id FROM users LIMIT 1);"
```

**Expected:** 
- Emails appear in app
- Database shows inserted emails
- No sync errors in logs

**Status:** ⬜ Not tested

---

### Test 4: AI Categorization (2 min)

**Verify categories are applied:**

1. Check inbox - emails should have colored badges
2. Tap "Categories" filter
3. Verify 7 categories with counts

**Check database:**
```bash
railway run bash
psql $DATABASE_URL -c "SELECT category, COUNT(*) FROM emails GROUP BY category;"
```

**Expected:**
```
category          | count
------------------+-------
Urgent            | 3
Action Required   | 5
Finance           | 2
FYI               | 10
Newsletter        | 4
Receipt           | 1
Spam              | 0
```

**Status:** ⬜ Not tested

---

### Test 5: Calendar Integration (5 min)

**Test calendar OAuth + events:**

1. Navigate to Calendar tab
2. If prompted, authorize Google Calendar
3. Verify events appear (next 7 days)

**Watch Railway logs:**
```bash
railway logs | grep -i "calendar"
```

**Check database:**
```bash
railway run bash
psql $DATABASE_URL -c "SELECT COUNT(*) FROM calendar_events WHERE user_id=(SELECT id FROM users LIMIT 1);"
```

**Expected:**
- Calendar events display
- Database shows calendar_events table populated
- No errors in logs

**Status:** ⬜ Not tested

---

### Test 6: Email Action APIs (15 min)

**Test each endpoint using curl:**

#### 6a. Compose Email

```bash
# Get JWT token from app (UserDefaults or Keychain)
TOKEN="your-jwt-token"

# Compose email
curl -X POST https://inboxiq-production-5368.up.railway.app/emails/compose \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to": ["test@example.com"],
    "subject": "Test from Railway",
    "body": "This is a test email sent from Railway production."
  }'
```

**Expected:** `200 OK`, email sent

**Status:** ⬜ Not tested

---

#### 6b. Reply to Email

```bash
# Get email ID from database or app
EMAIL_ID="email-id-from-app"

curl -X POST https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID/reply \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "reply_all": false,
    "body": "This is a test reply from Railway."
  }'
```

**Expected:** `200 OK`, reply sent

**Status:** ⬜ Not tested

---

#### 6c. Forward Email

```bash
curl -X POST https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID/forward \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "to": ["forward@example.com"],
    "body": "Forwarding this for review."
  }'
```

**Expected:** `200 OK`, forward sent

**Status:** ⬜ Not tested

---

#### 6d. Archive Email

```bash
curl -X POST https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID/archive \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:** `200 OK`, email archived

**Status:** ⬜ Not tested

---

#### 6e. Star Email

```bash
curl -X PUT https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID/star \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"starred": true}'
```

**Expected:** `200 OK`, email starred

**Status:** ⬜ Not tested

---

#### 6f. Mark Read/Unread

```bash
curl -X PUT https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID/read \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"read": true}'
```

**Expected:** `200 OK`, email marked read

**Status:** ⬜ Not tested

---

#### 6g. Delete Email

```bash
curl -X DELETE https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:** `204 No Content`, email deleted

**Status:** ⬜ Not tested

---

#### 6h. Bulk Actions

```bash
curl -X POST https://inboxiq-production-5368.up.railway.app/emails/bulk-archive \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email_ids": ["id1", "id2", "id3"]
  }'
```

**Expected:** `200 OK`, multiple emails archived

**Status:** ⬜ Not tested

---

### Test 7: Pagination (5 min)

#### Emails Pagination

```bash
# Page 1 (first 20)
curl "https://inboxiq-production-5368.up.railway.app/emails?page=1&page_size=20" \
  -H "Authorization: Bearer $TOKEN"

# Page 2 (next 20)
curl "https://inboxiq-production-5368.up.railway.app/emails?page=2&page_size=20" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:**
- Page 1 returns 20 emails
- Page 2 returns next 20 (or fewer if less than 40 total)
- `total_pages`, `current_page` fields present

**Status:** ⬜ Not tested

---

#### Calendar Pagination

```bash
# Page 1 (first 20 events)
curl "https://inboxiq-production-5368.up.railway.app/calendar/events?page=1&page_size=20" \
  -H "Authorization: Bearer $TOKEN"

# Page 2
curl "https://inboxiq-production-5368.up.railway.app/calendar/events?page=2&page_size=20" \
  -H "Authorization: Bearer $TOKEN"
```

**Expected:** Same as emails pagination

**Status:** ⬜ Not tested

---

### Test 8: Error Handling (5 min)

**Test error scenarios:**

#### Invalid Token
```bash
curl https://inboxiq-production-5368.up.railway.app/emails \
  -H "Authorization: Bearer invalid-token"
```

**Expected:** `401 Unauthorized`

**Status:** ⬜ Not tested

---

#### Invalid Email ID
```bash
curl -X POST https://inboxiq-production-5368.up.railway.app/emails/nonexistent-id/reply \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reply_all": false, "body": "test"}'
```

**Expected:** `404 Not Found`

**Status:** ⬜ Not tested

---

#### Malformed Request
```bash
curl -X POST https://inboxiq-production-5368.up.railway.app/emails/compose \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to": "not-an-array"}'
```

**Expected:** `400 Bad Request` with validation error

**Status:** ⬜ Not tested

---

### Test 9: Rate Limiting (2 min)

**Test auth rate limits (5 requests/min):**

```bash
for i in {1..6}; do
  curl https://inboxiq-production-5368.up.railway.app/auth/ios/login \
    -H "Content-Type: application/json" \
    -d '{"code": "invalid"}'
  echo ""
done
```

**Expected:** First 5 requests get 400, 6th gets `429 Too Many Requests`

**Status:** ⬜ Not tested

---

### Test 10: Daily Digest (3 min)

**Verify digest is configured:**

```bash
railway run bash
psql $DATABASE_URL -c "SELECT * FROM digest_settings WHERE user_id=(SELECT id FROM users LIMIT 1);"
```

**Expected:**
```
user_id | enabled | frequency_hours | last_sent_at
--------+---------+-----------------+-------------
1       | true    | 1               | NULL
```

**Note:** Actual delivery requires cron job (not testable via API)

**Status:** ⬜ Not tested

---

## Test Results Summary

**Pass/Fail Tracking:**

| Test | Status | Time | Notes |
|------|--------|------|-------|
| 1. Health check | ⬜ | - | |
| 2. OAuth flow | ⬜ | - | |
| 3. Email sync | ⬜ | - | |
| 4. AI categorization | ⬜ | - | |
| 5. Calendar integration | ⬜ | - | |
| 6a. Compose email | ⬜ | - | |
| 6b. Reply email | ⬜ | - | |
| 6c. Forward email | ⬜ | - | |
| 6d. Archive email | ⬜ | - | |
| 6e. Star email | ⬜ | - | |
| 6f. Mark read/unread | ⬜ | - | |
| 6g. Delete email | ⬜ | - | |
| 6h. Bulk actions | ⬜ | - | |
| 7. Email pagination | ⬜ | - | |
| 8. Calendar pagination | ⬜ | - | |
| 9. Error handling | ⬜ | - | |
| 10. Rate limiting | ⬜ | - | |
| 11. Digest settings | ⬜ | - | |

**Total Tests:** 18  
**Passed:** 0  
**Failed:** 0  
**Not Tested:** 18

---

## After Testing

### If All Tests Pass ✅

1. Update Linear issues:
   - Mark INB-22 (Email actions) → Done
   - Mark INB-21 (Pagination) → Done
2. Update MEMORY.md with completion
3. Move to next phase (iOS integration)

---

### If Tests Fail ❌

1. Document failures in this file
2. Check Railway logs for errors
3. Fix issues locally
4. Redeploy to Railway
5. Retest

---

## Quick Start (Copy-Paste)

```bash
# 1. Health check
curl https://inboxiq-production-5368.up.railway.app/health

# 2. Check Railway logs
railway logs --tail 100

# 3. Test OAuth (use iOS app)
# ...

# 4. Get JWT token from app
# UserDefaults key: "auth_token"
TOKEN="paste-token-here"

# 5. Test compose
curl -X POST https://inboxiq-production-5368.up.railway.app/emails/compose \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to": ["test@example.com"], "subject": "Test", "body": "Hello"}'

# 6. Check database
railway run bash
psql $DATABASE_URL -c "SELECT COUNT(*) FROM emails;"
```

---

**Created:** 2026-03-05 07:59 CST  
**Testing starts:** NOW  
**Estimated time:** 1-2 hours  
**Tester:** V + Shiv
