# Quick Start - Railway Testing

**Goal:** Test backend APIs on Railway production  
**Time:** 1-2 hours

---

## Step 1: Health Check (30 seconds)

```bash
curl https://inboxiq-production-5368.up.railway.app/health
```

**Expected:** `{"status": "healthy"}`

**✅ Pass / ❌ Fail:** _______

---

## Step 2: OAuth Test (5 min)

**Using iOS Simulator:**
1. Open InboxIQ app
2. Tap "Sign in with Google"
3. Complete OAuth in Safari
4. Verify successful login

**Watch Railway logs:**
```bash
railway logs --tail 50
```

**Look for:** `ios_oauth_callback_success` (no MissingGreenlet error)

**✅ Pass / ❌ Fail:** _______

---

## Step 3: Email Sync (2 min)

1. Wait 10 seconds after login
2. Check inbox tab
3. Verify emails appear

**✅ Pass / ❌ Fail:** _______

---

## Step 4: Get JWT Token

**From iOS app (Xcode):**
```swift
// In debugger console
po UserDefaults.standard.string(forKey: "auth_token")
```

**Copy token:**
```bash
export TOKEN="paste-your-jwt-token-here"
```

---

## Step 5: Test Email Actions (10 min)

### Compose
```bash
curl -X POST https://inboxiq-production-5368.up.railway.app/emails/compose \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"to": ["vilesh.salunkhe@gmail.com"], "subject": "Test from Railway", "body": "Testing compose API"}'
```

**✅ Pass / ❌ Fail:** _______

---

### Archive
```bash
# Get email ID from app or database
EMAIL_ID="your-email-id"

curl -X POST https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID/archive \
  -H "Authorization: Bearer $TOKEN"
```

**✅ Pass / ❌ Fail:** _______

---

### Star
```bash
curl -X PUT https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID/star \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"starred": true}'
```

**✅ Pass / ❌ Fail:** _______

---

### Mark Read
```bash
curl -X PUT https://inboxiq-production-5368.up.railway.app/emails/$EMAIL_ID/read \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"read": true}'
```

**✅ Pass / ❌ Fail:** _______

---

## Step 6: Check Database (5 min)

```bash
railway run bash

# Inside Railway container
psql $DATABASE_URL

# Check email count
SELECT COUNT(*) FROM emails;

# Check categories
SELECT category, COUNT(*) FROM emails GROUP BY category;

# Check calendar
SELECT COUNT(*) FROM calendar_events;

# Exit
\q
exit
```

**✅ Pass / ❌ Fail:** _______

---

## Step 7: Test Error Handling (2 min)

### Invalid token
```bash
curl https://inboxiq-production-5368.up.railway.app/emails \
  -H "Authorization: Bearer invalid-token"
```

**Expected:** `401 Unauthorized`

**✅ Pass / ❌ Fail:** _______

---

## Summary

| Test | Status | Notes |
|------|--------|-------|
| Health check | ⬜ | |
| OAuth | ⬜ | |
| Email sync | ⬜ | |
| Compose | ⬜ | |
| Archive | ⬜ | |
| Star | ⬜ | |
| Mark read | ⬜ | |
| Database | ⬜ | |
| Error handling | ⬜ | |

**Total:** ___ / 9 passed

---

## If Tests Fail

1. Check Railway logs: `railway logs --tail 100`
2. Check error message
3. Report to Shiv with:
   - Which test failed
   - Error message
   - Railway log snippet

---

## After Testing

**If all pass:**
- Mark INB-22 (Email actions) → Done
- Move to iOS integration

**If failures:**
- Document issues
- Fix + redeploy
- Retest

---

**Full test plan:** `/projects/inboxiq/RAILWAY-TESTING-PLAN.md`  
**Start time:** ________  
**End time:** ________  
**Duration:** ________
