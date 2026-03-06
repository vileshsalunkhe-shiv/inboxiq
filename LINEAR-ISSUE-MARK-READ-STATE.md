# Mark Read/Unread State Persistence Issue

**Status:** 🟡 DOCUMENTED - DEFERRED
**Priority:** Medium
**Date:** 2026-03-05 15:28 CST

## Issue
Mark as read/unread toggle works at the envelope level (visual changes visible), but changes don't persist when navigating to summary page. State synchronization/persistence problem between CoreData and UI refresh logic.

## Test Result
- **Action:** Toggle email read/unread status
- **Expected:** Email envelope shows read/unread state, state persists across navigation
- **Actual:** Envelope changes visible, but doesn't reflect on summary page after navigation
- **Status:** ❌ FAIL (state persistence issue)

## Root Cause
Unknown - requires investigation of:
- CoreData update logic in EmailActionService
- UI refresh/binding in EmailDetailView → HomeView → EmailListView
- Backend sync confirmation and state propagation

## Recommended Fix
1. Verify CoreData save is completing successfully
2. Check if UI is observing CoreData changes properly (@FetchRequest, objectWillChange)
3. Ensure backend API confirms state change
4. Add logging to trace state changes through the stack

## Impact
- Non-critical for MVP demo
- Affects user experience when marking emails
- Backend API likely working (archive/star work fine)

## Deferred Reason
V needs to present to partners tomorrow - focusing on:
1. Daily digest email
2. Polished UI
3. Calendar CRUD + search

This can be fixed post-demo.

---

**Related Issues:**
- Delete email (blocked by rate limiting)
- Email body loading (blocked by rate limiting)
