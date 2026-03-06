# Linear Issue: Delete Email Crashes - Backend Sync Required

**Status:** Blocked (Gmail API rate limiting prevents email sync)  
**Priority:** High  
**Effort:** 2-3 hours  
**Created:** 2026-03-05 14:52 CST

---

## Summary

Delete email functionality crashes because it requires emails to be synced to backend database first. Gmail API rate limiting (429 errors) prevents emails from syncing, causing the delete operation to fail.

---

## Current Behavior

**User action:** Tap "Delete" button on an email  
**Expected:** Email deleted from Gmail, backend, and iOS  
**Actual:** App crashes with `EXC_BREAKPOINT` or freezes

---

## Root Cause

**Dependency chain:**
1. iOS stores email in CoreData ✅
2. Backend must also have email in PostgreSQL (requires sync) ❌
3. Delete operation calls `resolveBackendId()` which queries backend
4. If email not in backend → lookup fails → crash

**Why emails aren't in backend:**
- Gmail API returns 429 rate limit errors during sync
- Some emails sync successfully, others don't
- iOS has emails that backend doesn't
- Delete can't proceed without backend ID

**Error logs:**
```
ERROR: Failed to fetch message 19cbf939a6b6fb2b: HttpError 429
"Too many concurrent requests for user"
```

---

## Technical Details

### Backend Implementation ✅ Works

**Endpoint:** `DELETE /emails/{email_id}`

**What it does:**
1. Finds email in database by ID
2. Calls Gmail API to trash the message
3. Deletes from PostgreSQL
4. Deletes cascade to `ai_queue` table (fixed today)

**Status:** Backend code works perfectly when email exists in database

**Evidence:**
```
INFO: DELETE /emails/170 HTTP/1.1" 200 OK  ← Backend succeeded
```

### iOS Implementation ⚠️ Partially Works

**File:** `ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift`

**Flow:**
```swift
func deleteEmail() async {
    1. Call EmailActionService.shared.deleteEmail(email: email)
    2. Delete from CoreData
    3. Dismiss view
}
```

**EmailActionService.deleteEmail:**
```swift
func deleteEmail(email: EmailEntity) async throws {
    let backendId = try await resolveBackendId(for: email)  ← CRASHES HERE
    ...
}

private func resolveBackendId(for email: EmailEntity) async throws -> Int {
    // Queries backend: GET /emails
    // Finds email by gmailId
    // If not found → throws error → CRASH
}
```

**The problem:** `resolveBackendId` assumes email exists in backend, but rate limiting prevents this.

---

## Solutions (Ranked)

### Option 1: Fix Gmail Rate Limiting (Root Cause) ⭐ RECOMMENDED
**Effort:** 2-3 hours  
**Blocks:** Email body feature, Delete email, Any backend-dependent operations

**Implementation:**
- Reduce sync batch size from 20 → 5 emails
- Add exponential backoff on 429 errors
- Implement retry queue for failed syncs
- Add delays between sync attempts

**Benefits:**
- Fixes delete email ✅
- Fixes email body loading ✅
- Fixes all sync-dependent features ✅
- Permanent solution

**Files to modify:**
- `backend/app/services/sync_service.py`
- `backend/app/services/gmail_service.py`

---

### Option 2: Graceful Fallback in Delete
**Effort:** 30 minutes  
**Status:** Quick fix, not ideal

**Implementation:**
```swift
func deleteEmail(email: EmailEntity) async throws {
    // Try to get backend ID
    guard let backendId = try? await resolveBackendId(for: email) else {
        // Email not synced to backend - delete locally only
        // Show warning: "Email deleted locally. Will sync to Gmail later."
        return
    }
    
    // Proceed with full delete (Gmail + backend + local)
    ...
}
```

**Pros:** App doesn't crash  
**Cons:** Inconsistent state (email still in Gmail/backend)

---

### Option 3: Background Sync Queue
**Effort:** 4-6 hours  
**Status:** Best long-term solution

**Architecture:**
- Delete operations go into local queue
- Background worker syncs deletions to backend/Gmail
- Retry failed operations
- Show sync status to user

**Pros:** Robust, handles offline scenarios  
**Cons:** Complex, requires infrastructure changes

---

## Testing Results

**Test Date:** 2026-03-05 14:30-14:50 CST

### Attempt 1: Database Constraint Error ❌
```
ERROR: null value in column "email_id" of relation "ai_queue" violates not-null constraint
```
**Fix:** Added `cascade="all, delete-orphan"` to relationship ✅  
**Deployed:** 14:35 CST

### Attempt 2: Backend Success, iOS Freeze ❌
```
INFO: DELETE /emails/170 HTTP/1.1" 200 OK
```
Backend deleted successfully, but iOS didn't dismiss view.

**Attempted fix:** Wrapped CoreData operations in `@MainActor.run`  
**Result:** Still crashed with `EXC_BREAKPOINT`

### Attempt 3: Crash with No Console Output ❌
**Error:** `Thread 1: EXC_BREAKPOINT (code=1, subcode=0x180ea2a84)`  
**Xcode console:** No error messages printed  
**Diagnosis:** Fatal error before any logging happens

**Root cause identified:** `resolveBackendId()` throws error when email not found in backend

---

## Dependencies

**Blocked by:**
- Gmail API rate limiting preventing email sync
- Same issue blocking "Email Body" feature

**Blocks:**
- Full delete functionality
- Bulk delete operations
- Any operations requiring backend email ID

---

## Workarounds Attempted

1. ✅ Fixed cascade delete for `ai_queue` relationship
2. ⚠️ Added `@MainActor` for CoreData operations
3. ⚠️ Tried graceful error handling
4. ❌ Local-only delete (V rejected - wants full functionality)

---

## Recommended Next Steps

**Option A: Fix Rate Limiting Now (2-3 hours)**
- Pause feature testing
- Implement rate limit handling
- Test delete + email body features
- Resume testing once fixed

**Option B: Document and Move On (Current)**
- Create Linear issue (this document)
- Test other features (compose, reply, forward)
- Return to delete when rate limiting is fixed
- Archive works fine (tested ✅)

**Option C: Implement Option 2 (Graceful Fallback) (30 min)**
- Quick fix to unblock testing
- Delete works for synced emails
- Shows warning for unsynced emails
- Can improve later

---

## Success Criteria

When fixed, delete should:
- [ ] Remove email from Gmail (trash it)
- [ ] Remove email from backend database
- [ ] Remove email from iOS CoreData
- [ ] Dismiss EmailDetailView
- [ ] Return to inbox
- [ ] Email no longer visible in list
- [ ] No crashes or freezes
- [ ] Works for ALL emails (synced or not)

---

## Files Involved

**Backend:**
- `app/api/emails.py` - DELETE endpoint (working ✅)
- `app/models/email.py` - Cascade delete (fixed ✅)
- `app/services/gmail_service.py` - Gmail delete (working ✅)

**iOS:**
- `Views/Detail/EmailDetailView.swift` - Delete button + logic
- `Services/EmailActionService.swift` - resolveBackendId() (fails for unsynced emails)
- `Views/Components/ToastView.swift` - Error feedback

---

## Related Issues

- INB-XX: Email Body Feature (same root cause - rate limiting)
- INB-XX: Gmail Sync Rate Limiting (should create this)

---

**Created:** 2026-03-05 14:52 CST  
**Time Spent:** 45 minutes debugging  
**Status:** Documented, ready to resume when rate limiting is fixed
