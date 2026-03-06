# Linear Issue: Email Body Feature - Gmail Rate Limiting

**Status:** Blocked (Gmail API rate limiting)  
**Priority:** Medium  
**Effort:** 2-3 hours  
**Created:** 2026-03-05 14:26 CST

---

## Summary

"Load Full Email" button is implemented but returns 404 errors due to Gmail API rate limiting preventing emails from syncing to backend database.

---

## Current State

### ✅ What Works
- Backend endpoint: `GET /api/emails/{gmail_id}/body` ✅
- iOS UI: "Load Full Email" button in EmailDetailView ✅
- Email body schema + migration ✅
- iOS HTML rendering (EmailBodyWebView) ✅
- Error handling + user-friendly messages ✅

### ❌ What's Blocked
- Backend sync hits Gmail API rate limits (429 errors)
- Emails fail to sync → Not in database → 404 on body request
- iOS has emails in CoreData that backend doesn't have

### 🔍 Root Cause
Gmail API returns `429 Too many concurrent requests for user` during sync:
```
ERROR: Failed to fetch message 19cbf939a6b6fb2b in batch: HttpError 429
```

**Why this happens:**
- Backend syncs 20 emails at a time (using batch API)
- Gmail per-user rate limits are aggressive
- Multiple sync attempts (auto-refresh, pull-to-refresh) compound the issue
- Some emails succeed, some fail → partial sync

---

## Technical Details

### Backend Implementation
**Files:**
- `backend/app/api/emails.py` - Body endpoint with diagnostic logging
- `backend/app/services/gmail_service.py` - `get_email_body()` method
- `backend/app/models/email.py` - Body columns (body_text, body_html, body_fetched_at)
- `backend/app/schemas/email.py` - EmailBodyOut schema
- `backend/alembic/versions/006_add_email_body_columns.py` - Migration

**Endpoint:**
```python
@router.get("/{gmail_id}/body", response_model=EmailBodyOut)
async def get_email_body(gmail_id: str, ...):
    # Queries: Email.gmail_id == gmail_id AND Email.user_id == current_user.id
    # Returns: body_text, body_html, has_attachments, fetched_at
```

**Logging added:**
- Request logging (gmail_id, user_id)
- Diagnostic info (total_emails_for_user)
- Cache hits/misses
- Gmail fetch success/failure

### iOS Implementation
**Files:**
- `ios/InboxIQ/InboxIQ/Services/EmailBodyService.swift` - API client
- `ios/InboxIQ/InboxIQ/Views/Components/EmailBodyWebView.swift` - HTML renderer
- `ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift` - Button + UI

**Flow:**
1. User taps "Load Full Email" button
2. Calls `bodyService.fetchEmailBody(gmailId: email.gmailId)`
3. Backend fetches from Gmail API (if not cached)
4. Returns body → Renders in EmailBodyWebView

**Error messages:**
- 404: "Email not synced yet. Try pulling to refresh the inbox."
- Auth: "Authentication expired. Please log in again."
- Generic: "Failed to load email body. Tap to retry."

---

## Solutions (Ranked by Effort)

### Option 1: Wait for Gmail Rate Limits to Clear (0 effort)
**Time:** 30-60 minutes between sync attempts  
**Pros:** No code changes, rate limits reset naturally  
**Cons:** Poor UX, unpredictable behavior

### Option 2: Reduce Sync Aggressiveness (1-2 hours)
**Changes:**
- Reduce sync limit from 20 → 5 emails per batch
- Add 1-2 second delays between batches
- Implement exponential backoff on 429 errors
- Cache Gmail API responses more aggressively

**Files to modify:**
- `backend/app/services/sync_service.py`
- `backend/app/services/gmail_service.py`

**Pros:** Fewer rate limit errors, more reliable sync  
**Cons:** Slower sync, still possible to hit limits

### Option 3: Background Job Queue (4-6 hours)
**Architecture:**
- Move email sync to async job queue (Celery/Redis)
- Rate limit at job queue level (max N requests per minute)
- Retry failed syncs with exponential backoff
- Show sync progress to user

**Pros:** Best long-term solution, scalable  
**Cons:** Adds complexity, requires infrastructure changes

### Option 4: Lazy Load Body on Demand (2-3 hours) ⭐ RECOMMENDED
**Changes:**
- Don't require email to be in database first
- When user taps "Load Full Email", fetch directly from Gmail API
- Cache result in database for future requests
- Show loading state while fetching

**Implementation:**
```python
# Modified endpoint logic
if not email:
    # Email not in DB yet - fetch directly from Gmail
    gmail_service = GmailService()
    body_data = await gmail_service.get_email_body(access_token, gmail_id)
    
    # Optionally: Create email record now (or skip if not needed)
    # Return body immediately without requiring DB record
    return EmailBodyOut(
        email_id=gmail_id,
        body_text=body_data["text"],
        body_html=body_data["html"],
        ...
    )
```

**Pros:** 
- Works regardless of sync status
- User can load ANY email body
- No dependency on email being in database

**Cons:**
- May still hit rate limits on body fetch (less likely)
- No caching if email not in DB

---

## Testing Steps (When Fixed)

1. Deploy backend changes (rate limit handling)
2. Wait 30 minutes for Gmail quota to reset
3. In iOS app:
   - Pull to refresh inbox
   - Wait for sync to complete (check logs)
   - Tap any email
   - Tap "Load Full Email"
   - **Expected:** Full body loads successfully

4. Verify in Railway logs:
   ```
   🔍 EMAIL BODY REQUEST: gmail_id=XXX
   ✅ Found in database, total_emails_for_user=20
   ✅ Fetching from Gmail API...
   ✅ Fetch success: has_text=true, has_html=true
   ```

---

## Success Criteria

- [ ] User can tap "Load Full Email" on any synced email
- [ ] Full email body loads within 2-3 seconds
- [ ] HTML emails render properly with formatting
- [ ] Plain text emails display cleanly
- [ ] Attachments indicator shows when present
- [ ] Second tap on same email uses cached body (instant)
- [ ] Error messages are user-friendly and actionable
- [ ] No 404 errors for synced emails

---

## Dependencies

**Blocked by:**
- Gmail API rate limiting issue

**Blocks:**
- None (feature is standalone)

---

## Estimated Timeline

**If Option 4 (Lazy Load) is chosen:**
- Implementation: 2 hours
- Testing: 30 minutes
- Deployment: 15 minutes
- **Total: ~3 hours**

**If Option 2 (Rate Limit Handling) is chosen:**
- Implementation: 1 hour
- Testing: 1 hour (need to wait for rate limits)
- Deployment: 15 minutes
- **Total: ~2-3 hours**

---

## Notes

- Feature is 90% complete (code works, infrastructure is blocking)
- Both backend and iOS implementations are production-ready
- Migration already deployed to Railway
- Just needs rate limiting solution to unblock

**Recommendation:** Implement Option 4 (Lazy Load) - simplest solution that bypasses the sync issue entirely.

---

## Related Issues

- Email sync rate limiting (should be its own issue)
- Gmail API quota management
- Background sync reliability

---

**Created:** 2026-03-05 14:26 CST  
**Worked on:** 2 agents + 2 hours debugging  
**Status:** Ready to resume when prioritized
