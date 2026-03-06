# Daily Digest Toggle Error (Intermittent)

**Status:** 🟡 DOCUMENTED - POST-DEMO
**Priority:** Low
**Date:** 2026-03-05 17:31 CST

## Issue
The "Enable Daily Digest" toggle sometimes shows error "Unable to update..." despite the toggle state changing correctly and the backend returning 200 OK.

## Observed Behavior
- Toggle switch changes state (on/off) ✅
- Backend PUT /api/digest/settings returns 200 OK ✅
- Error toast appears: "Unable to update..." ❌
- Button state updates correctly (enabled/disabled based on toggle) ✅
- Functionality works despite error message ✅

## Technical Context
- **Backend:** `/api/digest/settings` endpoint works correctly (200 OK in logs)
- **iOS:** SettingsView.swift with DigestService.swift
- **Possible Cause:** Error handling in iOS might be catching a non-error response or there's a race condition in the UI update

## Test Result
- **Toggle functionality:** ✅ WORKS (state persists, backend updates)
- **User experience:** ⚠️ Confusing error message despite success
- **Impact:** Low (doesn't block functionality, just shows misleading error)

## Recommended Fix
1. Review DigestService.swift error handling
2. Check SettingsView.swift toast logic
3. Add better logging to identify what triggers the error toast
4. Verify response parsing in updatePreferences() method

## Deferred Reason
- Feature is functional for demo
- Error is cosmetic (misleading toast)
- "Send Test Digest" works perfectly
- Digest email sends successfully

Can be fixed post-demo during UI polish phase.

---

**Related:**
- Daily Digest feature: ✅ COMPLETE (17:30 CST)
- Digest email: ✅ WORKING (looks great on phone)
- Backend: ✅ DEPLOYED
- iOS: ✅ INTEGRATED
