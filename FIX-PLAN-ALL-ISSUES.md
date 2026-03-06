# Fix Plan: All Testing Issues

**Started:** 2026-03-05 15:07 CST  
**Estimated Time:** 2-3 hours  
**Goal:** Working app with all 7 features functional

---

## Priority Order (Most Impact First)

### 1. Gmail Rate Limiting ⭐ HIGHEST PRIORITY
**Time:** 1-1.5 hours  
**Impact:** Unblocks delete + email body + reliable sync  
**Files:** `backend/app/services/sync_service.py`, `gmail_service.py`

**Changes:**
- Reduce batch size from 20 → 5 emails
- Add exponential backoff on 429 errors
- Implement retry queue with delays
- Add rate limit detection and throttling

**Benefits:**
- ✅ Delete email works (emails in database)
- ✅ Email body loading works
- ✅ Reliable sync
- ✅ No more 429 errors

---

### 2. Sent Emails in Inbox Filter
**Time:** 15-20 minutes  
**Impact:** Clean inbox (only received emails)  
**Files:** `backend/app/api/emails.py`, `backend/app/services/sync_service.py`

**Changes:**
- Filter out sent emails from inbox query
- Use Gmail label: `-in:sent` or check sender != user
- Update sync to skip sent folder

**Benefits:**
- ✅ Inbox shows only received emails
- ✅ Cleaner UI

---

### 3. Read/Unread UI Refresh
**Time:** 20-30 minutes  
**Impact:** Visual feedback works  
**Files:** `ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift`

**Changes:**
- Force CoreData refresh after read/unread toggle
- Ensure view observes changes
- Update list immediately

**Benefits:**
- ✅ Instant visual feedback
- ✅ Better UX

---

### 4. Delete Email (Re-test After #1)
**Time:** 10 minutes (testing only)  
**Impact:** Feature works after rate limiting fixed  
**Files:** Already fixed, just needs testing

**Changes:**
- None needed - will work once emails sync properly

**Benefits:**
- ✅ Full delete functionality
- ✅ All 7 features working

---

## Implementation Order

### Phase 1: Backend Fixes (1.5 hours)
1. ✅ Fix Gmail rate limiting (1 hour)
2. ✅ Deploy to Railway (5 min)
3. ✅ Filter sent emails from inbox (15 min)
4. ✅ Deploy to Railway (5 min)

### Phase 2: iOS Fixes (30 min)
1. ✅ Fix read/unread UI refresh (20 min)
2. ✅ Rebuild and test (10 min)

### Phase 3: Testing (30 min)
1. ✅ Test email sync (no 429 errors)
2. ✅ Test delete email (should work now)
3. ✅ Test email body loading (should work now)
4. ✅ Test read/unread UI (should update now)
5. ✅ Verify sent emails not in inbox
6. ✅ Full regression test (all 7 features)

---

## Success Criteria

**After fixes:**
- [ ] No Gmail 429 rate limit errors
- [ ] All emails sync to backend successfully
- [ ] Delete email works (no crashes)
- [ ] Email body loads successfully
- [ ] Read/unread toggle updates UI immediately
- [ ] Inbox shows only received emails (no sent)
- [ ] All 7 features pass testing: Archive ✅ Delete ✅ Star ✅ Compose ✅ Reply ✅ Forward ✅ Read/Unread ✅

---

## Rollback Plan

If issues occur:
- Backend: Git revert last commits
- iOS: Git revert changes
- Railway: Rollback deployment

---

**Ready to start with #1: Gmail Rate Limiting!**
