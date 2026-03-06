# Existing Features Test Plan - 2026-03-05 16:03 CST

**Goal:** Verify all working features still work before integrating digest fixes
**User:** vilesh.salunkhe@gmail.com (user_id: 1ae0ee58-a04f-47b2-ba79-5779bff48b65)
**Railway URL:** https://inboxiq-production-5368.up.railway.app

---

## Test Checklist

### 1. Backend Health ✅
**Endpoint:** GET /health
**Expected:** 200 OK, {"status": "ok"}

```bash
curl https://inboxiq-production-5368.up.railway.app/health
```

---

### 2. OAuth Authentication ✅
**Endpoint:** POST /api/auth/callback/ios
**Expected:** JWT token returned
**Status:** Fixed MissingGreenlet bug on 2026-03-04

**Test:** Open iOS app → Login screen → Sign in with Google → Should succeed

---

### 3. Email Sync ✅
**Endpoint:** POST /api/emails/sync
**Expected:** Emails synced to database
**Status:** Working (with Gmail rate limiting on some emails)

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
  https://inboxiq-production-5368.up.railway.app/api/emails/sync
```

**iOS Test:** Open app → Inbox tab → Should see emails (50 displayed)

---

### 4. Email Actions ✅

#### 4.1 Archive Email
**Endpoint:** POST /api/emails/{email_id}/archive
**Tested:** 2026-03-05 ~14:32 CST
**Status:** ✅ PASS

**iOS Test:** Swipe email left → Tap Archive → Email disappears

#### 4.2 Star Email
**Endpoint:** POST /api/emails/{email_id}/star
**Tested:** 2026-03-05 ~14:35 CST
**Status:** ✅ PASS

**iOS Test:** Swipe email right → Tap Star → Star appears

#### 4.3 Compose Email
**Endpoint:** POST /api/emails/compose
**Tested:** 2026-03-05 ~14:38 CST
**Status:** ✅ PASS

**iOS Test:** Tap compose button → Fill form → Send → Should succeed

#### 4.4 Reply to Email
**Endpoint:** POST /api/emails/{email_id}/reply
**Tested:** 2026-03-05 ~14:41 CST
**Status:** ✅ PASS

**iOS Test:** Open email → Tap Reply → Write reply → Send → Should succeed

#### 4.5 Forward Email
**Endpoint:** POST /api/emails/{email_id}/forward
**Tested:** 2026-03-05 ~14:44 CST
**Status:** ✅ PASS

**iOS Test:** Open email → Tap Forward → Add recipient → Send → Should succeed

---

### 5. Calendar Integration ✅
**Endpoint:** GET /api/calendar/events
**Tested:** 2026-03-03 (OAuth flow working)
**Status:** ✅ Working

**iOS Test:** Open Calendar tab → Should see upcoming events

---

### 6. AI Categorization ✅
**Endpoint:** GET /api/emails with categories
**Tested:** 2026-03-03 21:31 CST
**Status:** ✅ Working (7 categories)

**iOS Test:** Inbox shows category badges (Urgent, Action Required, Finance, etc.)

---

## Known Issues (Not Testing - Already Documented)

### Blocked by Gmail Rate Limiting:
- ❌ Delete email (crashes - resolveBackendId fails for unsynced emails)
- ❌ Email body loading (404 - emails not synced to backend)
- ⚠️ Mark read/unread (envelope changes but doesn't persist on summary)

**Documented in:**
- `LINEAR-ISSUE-DELETE-EMAIL.md`
- `LINEAR-ISSUE-EMAIL-BODY.md`
- `LINEAR-ISSUE-MARK-READ-STATE.md`

**Status:** Deferred to post-demo (need to fix Gmail rate limiting first)

---

## Test Execution Order

**Phase 1: Backend Smoke Test (5 min)**
1. Health check
2. OAuth callback (via iOS app)
3. Email sync

**Phase 2: iOS Feature Test (10 min)**
4. Archive email
5. Star email
6. Compose email
7. Reply to email
8. Forward email
9. Calendar view
10. Category badges

**Total Time:** ~15 minutes

---

## Success Criteria

✅ All tests pass (6/7 features working)
✅ No new crashes or errors
✅ No regressions from previous testing session
✅ Ready to integrate digest fixes

---

## If Tests Fail

**Stop immediately and debug:**
1. Identify which feature broke
2. Check Railway logs
3. Review recent code changes
4. Restore from backup if needed

**DO NOT PROCEED to digest integration if tests fail**

---

## Next Step After Tests Pass

**Integrate digest fixes:**
1. Copy backend fixes to main codebase
2. Deploy to Railway
3. Copy iOS fixes to Xcode project
4. Test digest feature end-to-end

---

**Ready to start testing?**
