# Email Body Feature - 404 Fix Applied

**Issue:** Backend expected integer `email_id`, iOS sent UUID  
**Root Cause:** Backend uses database ID, iOS CoreData uses UUID, no backend ID stored  
**Fix Applied:** Changed endpoint to use `gmail_id` (both systems have this)

---

## Files Fixed

### Backend (1 file)
**File:** `/backend/app/api/emails.py`

**Change:** Endpoint parameter from `email_id: int` → `gmail_id: str`

```python
# BEFORE:
@router.get("/{email_id}/body", response_model=EmailBodyOut)
async def get_email_body(
    email_id: int,  # ❌ Integer database ID
    ...
):
    stmt = select(Email).where(Email.id == email_id, ...)

# AFTER:
@router.get("/{gmail_id}/body", response_model=EmailBodyOut)
async def get_email_body(
    gmail_id: str,  # ✅ Gmail message ID
    ...
):
    stmt = select(Email).where(Email.gmail_id == gmail_id, ...)
```

### iOS (2 files)

**File 1:** `/ios/InboxIQ/InboxIQ/Services/EmailBodyService.swift`

```swift
// BEFORE:
func fetchEmailBody(emailId: String) async throws -> EmailBody {
    let endpoint = "/api/emails/\(emailId)/body"  // ❌ Would use UUID
    
// AFTER:
func fetchEmailBody(gmailId: String) async throws -> EmailBody {
    let endpoint = "/api/emails/\(gmailId)/body"  // ✅ Uses gmail_id
```

**File 2:** `/ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift`

```swift
// BEFORE:
fullBody = try await bodyService.fetchEmailBody(emailId: email.id.uuidString)  // ❌ UUID

// AFTER:
fullBody = try await bodyService.fetchEmailBody(gmailId: email.gmailId)  // ✅ Gmail ID
```

---

## Deployment Steps

### 1. Rebuild iOS App (2 min)
```
Cmd + B  # Build in Xcode
```

**Expected:** Build succeeds ✅

### 2. Deploy Backend to Railway (5 min)

**Option A: Git Push (recommended)**
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq
git add backend/app/api/emails.py
git commit -m "fix: Use gmail_id instead of email_id for body endpoint"
git push origin main
```

Railway will auto-deploy in ~2-3 minutes.

**Option B: Railway CLI**
```bash
cd backend
railway up
```

**Option C: Manual deployment**
1. Go to Railway dashboard
2. Trigger manual deployment
3. Wait for deployment to complete

### 3. Test End-to-End (2 min)

**In iOS Simulator:**
1. Open InboxIQ app
2. Tap any email in inbox
3. Tap "Load Full Email" button
4. **Expected:** Full email body displays (no 404 error)

**Backend logs should show:**
```
INFO: GET /api/emails/19cba787aee9fac3/body HTTP/1.1" 200 OK
```

---

## Why This Fix Works

**Before:**
- iOS: `email.id` = UUID (`C17B5D32-6D5D-46A5-B658-65D0202959F2`)
- Backend: Expects integer ID (`email.id = 1, 2, 3...`)
- Result: 404 Not Found ❌

**After:**
- iOS: `email.gmailId` = Gmail message ID (`19cba787aee9fac3`)
- Backend: Queries by `gmail_id` (unique index in database)
- Result: Email found, body returned ✅

**Why gmail_id works:**
- Both systems store Gmail message IDs
- Gmail message ID is unique per user
- Already indexed in backend database (fast lookups)
- No CoreData migration needed

---

## Rate Limiting Issue (Separate)

**Also seen in logs:** Gmail API rate limiting (429 errors)

```
HttpError 429: "Too many concurrent requests for user."
```

**Already fixed in:** `backend/app/services/sync_service.py`
- Using Gmail batch API (50 emails per request)
- Reduced fallback to 20 emails

**This is working as expected** - Gmail API has per-user quotas, backend handles gracefully.

---

## Testing Checklist

After deployment:

- [ ] Backend deploys successfully on Railway
- [ ] iOS app builds without errors
- [ ] "Load Full Email" button appears in email detail view
- [ ] Tapping button loads full body (no 404 error)
- [ ] HTML emails render properly in WebView
- [ ] Plain text emails display cleanly
- [ ] Error handling works (shows retry button on failures)
- [ ] Attachments indicator shows when present
- [ ] Second request for same email is instant (cached)

---

**Fix Applied:** 2026-03-05 13:33 CST  
**Status:** ✅ Ready to deploy  
**Next:** Deploy backend → Rebuild iOS → Test
