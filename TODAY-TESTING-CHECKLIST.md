# Today's Plan - March 5, 2026

**Goal:** Build email action UIs (compose, reply, forward, archive, delete, star)

---

## Morning Tests (2-3 hours)

### 1. Backend OAuth (Local)
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend
uvicorn app.main:app --reload
```
- [ ] Start backend locally
- [ ] Open iOS app, tap "Sign in with Google"
- [ ] Complete OAuth in Safari
- [ ] Verify redirect back to app with tokens
- [ ] Check backend logs for errors

### 2. Email Sync
- [ ] First sync completes (last 7 days)
- [ ] Emails display in inbox
- [ ] AI categories applied (check badges)
- [ ] Pull to refresh works
- [ ] Email detail view opens

### 3. Calendar Integration
- [ ] Calendar OAuth flow completes
- [ ] Events sync (next 7 days)
- [ ] Events display in Calendar tab
- [ ] Event details correct (time, attendees, location)

### 4. UI/UX
- [ ] App icon displays
- [ ] Launch screen shows (VS Labs branding)
- [ ] Navigation works (3 tabs)
- [ ] Light mode renders correctly
- [ ] Dark mode renders correctly
- [ ] Settings screen loads

---

## Bug Documentation

**When you find a bug:**
1. Create Linear issue (tag: `bug`, `deployment`)
2. Priority: Critical / High / Medium / Low
3. Include: Steps to reproduce, expected vs actual result
4. Let Shiv know if Critical (blocks deployment)

---

## Critical Bugs = Stop & Fix
- App crashes
- OAuth broken
- Email sync fails
- Data corruption

## High Priority = Fix Today
- UI glitches
- Performance issues (>5 sec sync)
- Incorrect data
- Missing error handling

## Medium/Low = Later
- Polish
- Minor performance
- Edge cases

---

## End of Day

**Report:**
- [ ] Total bugs found: ___
- [ ] Critical: ___
- [ ] High: ___
- [ ] Medium: ___
- [ ] Low: ___

**Next:**
- Tomorrow: Fix bugs + Railway deployment test
- Day 3: TestFlight build
- Day 4-5: Beta testing

---

**Testing on:** [Your device/simulator]  
**iOS Version:** [Version]  
**Time Started:** ___  
**Time Completed:** ___
