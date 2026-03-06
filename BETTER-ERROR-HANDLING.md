# Better Error Handling & Logging - Email Body Feature

**Deployed:** 2026-03-05 14:16 CST  
**Goal:** Understand why email body 404 errors are happening

---

## Changes Made

### Backend: Comprehensive Diagnostic Logging

**File:** `backend/app/api/emails.py`

**Added structured logging for:**

1. **Every request:**
   ```python
   logger.info("email_body_request", gmail_id=..., user_id=..., user_email=...)
   ```

2. **Cache hits:**
   ```python
   logger.info("email_body_cache_hit", has_text=..., has_html=..., cached_at=...)
   ```

3. **Gmail fetches:**
   ```python
   logger.info("email_body_fetching_from_gmail", gmail_id=..., email_subject=...)
   logger.info("email_body_fetch_success", has_text=..., has_html=..., has_attachments=...)
   ```

4. **404 errors with diagnostics:**
   ```python
   logger.error("email_body_not_found", 
                gmail_id=..., 
                user_id=..., 
                total_emails_for_user=...,  # ← KEY: Shows if ANY emails exist
                hint="Email may not have synced yet due to rate limiting")
   ```

5. **User ID mismatches:**
   ```python
   logger.error("email_body_user_mismatch",
                requested_user_id=...,
                email_user_id=...,
                total_emails_for_user=...)
   ```

**Better error message:**
- Before: `"Email not found"`
- After: `"Email not synced yet. Please refresh your inbox."`

---

### iOS: User-Friendly Error Messages

**File:** `ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift`

**Specific error handling:**

```swift
catch let error as AppError {
    switch error {
    case .network(let message) where message.contains("404"):
        // 404 = Email not in database yet
        bodyLoadError = "Email not synced yet. Try pulling to refresh the inbox."
        
    case .auth:
        // Auth expired
        bodyLoadError = "Authentication expired. Please log in again."
        
    default:
        // Other errors
        bodyLoadError = "Failed to load: \(error.localizedDescription)"
    }
}
```

**User benefits:**
- Clear explanation of what went wrong
- Actionable next steps (pull to refresh)
- Retry-friendly messaging

---

## What the Logs Will Tell Us

### Scenario 1: Email Not in Database

**Log output:**
```json
{
  "event": "email_body_not_found",
  "gmail_id": "19cbf939a6b6fb2b",
  "user_id": "1ae0ee58-a04f-47b2-ba79-5779bff48b65",
  "total_emails_for_user": 17,
  "hint": "Email may not have synced yet due to rate limiting"
}
```

**Interpretation:**
- Email exists in iOS CoreData but not in backend PostgreSQL
- User HAS 17 emails in database (sync is working)
- This specific email failed to sync (likely rate limited)

**Solution:** Wait for rate limits to clear, sync again

---

### Scenario 2: User ID Mismatch

**Log output:**
```json
{
  "event": "email_body_user_mismatch",
  "gmail_id": "19cbf939a6b6fb2b",
  "requested_user_id": "1ae0ee58-a04f-47b2-ba79-5779bff48b65",
  "email_user_id": "different-uuid-here",
  "total_emails_for_user": 17
}
```

**Interpretation:**
- Email exists in database but belongs to different user
- Authentication or user ID issue

**Solution:** Check auth tokens, user ID mapping

---

### Scenario 3: Successful Fetch from Gmail

**Log output:**
```json
{
  "event": "email_body_request",
  "gmail_id": "19cbf939a6b6fb2b",
  "user_id": "1ae0ee58-a04f-47b2-ba79-5779bff48b65"
}
{
  "event": "email_body_fetching_from_gmail",
  "gmail_id": "19cbf939a6b6fb2b",
  "email_subject": "Test Email"
}
{
  "event": "email_body_fetch_success",
  "has_text": true,
  "has_html": true,
  "has_attachments": false
}
```

**Interpretation:**
- Email found in database ✅
- Fetched full body from Gmail API ✅
- Response sent to iOS ✅

**Solution:** Working as expected!

---

### Scenario 4: Cached Body

**Log output:**
```json
{
  "event": "email_body_request",
  "gmail_id": "19cbf939a6b6fb2b"
}
{
  "event": "email_body_cache_hit",
  "has_text": true,
  "has_html": true,
  "cached_at": "2026-03-05T20:15:00Z"
}
```

**Interpretation:**
- Email found in database ✅
- Body already cached (no Gmail API call needed) ✅
- Fast response ✅

**Solution:** Perfect!

---

## Testing Steps

**After deployment (~2 min):**

1. **In iOS app:**
   - Pull down to refresh inbox
   - Wait for sync to complete
   - Tap any email
   - Tap "Load Full Email"

2. **In Railway logs:**
   - Look for `email_body_request` event
   - Check the subsequent log event:
     - `email_body_not_found` → Email not synced (rate limited)
     - `email_body_user_mismatch` → Auth/user issue
     - `email_body_fetching_from_gmail` → Found, fetching...
     - `email_body_cache_hit` → Found, cached

3. **Key diagnostic:**
   - `total_emails_for_user` field tells us if sync is working at all
   - If it's 0 → No emails synced (bigger problem)
   - If it's >0 → Sync working, but specific email failed

---

## Expected Outcome

**Most likely scenario:**

```json
{
  "event": "email_body_not_found",
  "total_emails_for_user": 17,
  "hint": "Email may not have synced yet due to rate limiting"
}
```

**This confirms:** iOS has emails that backend doesn't (due to rate limiting during sync)

**Solution:** 
1. Wait 10-15 minutes for Gmail rate limits to reset
2. Trigger sync again (pull to refresh)
3. Newly synced emails will work with "Load Full Email"

---

## Deployment

**Run:**
```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/DEPLOY-BETTER-ERRORS.sh
```

**Wait:** ~2 minutes for Railway deployment

**Test:** Pull to refresh → Try loading email body → Check logs

---

**Files Modified:**
- ✅ `backend/app/api/emails.py` - Comprehensive logging
- ✅ `ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift` - Better error messages

**Status:** Ready to deploy 🚀
