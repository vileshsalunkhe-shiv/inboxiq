# Agent Coordination Plan - Sundar Review → DEV-BE-premium

**Date:** 2026-03-04 21:15 CST
**Status:** Waiting for Sundar's review

---

## Active Agents

### 1. Sundar (API Design Review)
- **Session:** `agent:sundar:subagent:26e6401a-6ae7-44ff-b90a-80dbacd71596`
- **Started:** 21:12 CST
- **Expected completion:** 21:45 CST (30-60 min)
- **Task:** Review email action API design for security and quality
- **Output location:** TBD (will be in session or as document)

### 2. DEV-BE-premium (API Implementation)
- **Session:** `agent:dev-be-premium:subagent:9b47dd84-4ae4-4942-84ff-4b5220ed07d5`
- **Started:** 21:00 CST
- **Expected completion:** 03:00-05:00 CST (6-8 hours)
- **Task:** Implement 8 email action APIs
- **Output location:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/`

---

## Coordination Plan

### Step 1: Sundar Completes (ETA: 21:45 CST) ✅ WAITING

**Actions when complete:**
1. Read Sundar's review output
2. Save review to file: `SUNDAR-API-DESIGN-REVIEW.md`
3. Extract key recommendations
4. Prepare message for DEV-BE-premium

### Step 2: Forward to DEV-BE-premium (ETA: 21:50 CST)

**Message to send via sessions_send:**

```
Hi DEV-BE-premium,

Sundar has completed a proactive security and quality review of the email action API design.

**Review Location:** /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SUNDAR-API-DESIGN-REVIEW.md

**Key Recommendations:**
[Extract from Sundar's review]

**Critical Issues to Address:**
[List critical issues]

**High Priority Issues:**
[List high priority issues]

**Please incorporate these recommendations as you build the APIs.**

Priority order:
1. Fix all critical issues (blocking)
2. Address high priority issues (should-fix)
3. Consider medium priority suggestions (nice-to-have)

The goal is to build it right the first time - quality over speed.

Thanks!
- Shiv
```

### Step 3: Monitor DEV-BE-premium Progress

**Check-ins:**
- 23:00 CST (2 hours in) - Quick progress check
- 01:00 CST (4 hours in) - Mid-point check
- 03:00 CST (6 hours in) - Near completion, prepare for Sundar final review

### Step 4: Sundar Final Review (When DEV-BE-premium completes)

**After implementation:**
1. Spawn Sundar again for code review
2. Focus: Did recommendations get implemented correctly?
3. Final sign-off before iOS integration

---

## Timeline

```
21:00 CST ─────────► DEV-BE-premium starts (8 hours)
21:12 CST ─────────► Sundar starts design review (45 min)
21:45 CST ─────────► Sundar completes ✓
21:50 CST ─────────► Forward review to DEV-BE-premium
23:00 CST ─────────► Check DEV-BE progress
01:00 CST ─────────► Mid-point check
03:00 CST ─────────► DEV-BE near completion
05:00 CST ─────────► DEV-BE completes (expected)
05:15 CST ─────────► Sundar final review (code)
06:00 CST ─────────► All done, ready for iOS implementation
```

---

## Status Tracking

**Sundar Design Review:**
- [ ] Started: 21:12 CST ✅
- [ ] Completed: ETA 21:45 CST
- [ ] Review forwarded to DEV-BE-premium
- [ ] DEV-BE-premium acknowledged

**DEV-BE-premium Implementation:**
- [ ] Started: 21:00 CST ✅
- [ ] Received Sundar's review
- [ ] Incorporating recommendations
- [ ] 2-hour check-in (23:00)
- [ ] 4-hour check-in (01:00)
- [ ] 6-hour check-in (03:00)
- [ ] Completed
- [ ] Output documented

**Sundar Final Review (Code):**
- [ ] Started
- [ ] Completed
- [ ] Approved for iOS integration

---

## Communication Protocol

**Check Sundar completion:**
```bash
# Check session history for completion
sessions_history --session agent:sundar:subagent:26e6401a-6ae7-44ff-b90a-80dbacd71596
```

**Forward review to DEV-BE-premium:**
```bash
sessions_send \
  --session agent:dev-be-premium:subagent:9b47dd84-4ae4-4942-84ff-4b5220ed07d5 \
  --message "<message content>"
```

**Monitor progress:**
```bash
sessions_history --session <session-key> --limit 5
```

---

## V's Instructions

✅ "Please have BE-premium incorporate these" (21:15 CST)

**Action:** Wait for Sundar, then immediately forward recommendations to DEV-BE-premium

---

## Next Update

I'll notify V when:
1. ✅ Sundar completes design review (~21:45 CST)
2. ✅ Review forwarded to DEV-BE-premium (~21:50 CST)
3. ✅ DEV-BE-premium completes implementation (~05:00 CST tomorrow)
4. ✅ Sundar's final code review complete (~06:00 CST tomorrow)

**Estimated:** All backend APIs complete by 6:00 AM CST tomorrow morning
