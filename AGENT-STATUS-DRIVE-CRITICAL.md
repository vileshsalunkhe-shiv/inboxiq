# Agent Status - Google Drive Critical Fixes

**Started:** 2026-03-05 21:20 CST
**Strategy:** Option B - Fix 4 critical issues only
**Time Estimate:** 1 hour total (30 min per agent)

---

## Active Agents (2)

### Agent 1: DEV-BE-premium (Backend Security Fixes)
**Session:** agent:dev-be-premium:subagent:2a2d265d-6dac-4b1b-ad68-d811b19f551c
**Label:** drive-backend-critical-fixes
**Task:** Fix 3 critical backend security issues
**Output:** `/projects/inboxiq/drive-backend-critical-fixes/`
**Timeout:** 45 minutes
**Status:** 🟡 RUNNING

**Issues to Fix:**
- ✅ Issue #2: File access privacy (appDataFolder)
- ✅ Issue #3: Remove permanent download URLs
- ✅ Issue #4: Add file validation (10MB + MIME types)

**Expected Files:**
- backend/app/api/drive.py (validation added)
- backend/app/services/drive_service.py (appDataFolder + removed get_download_url)
- README.md + INTEGRATION.md

---

### Agent 2: DEV-MOBILE-premium (iOS Attachment Bug)
**Session:** agent:dev-mobile-premium:subagent:01b91de7-0027-4b03-b44e-338ea68db4fd
**Label:** drive-ios-critical-fix
**Task:** Fix hardcoded attachment bug (DEMO BLOCKER)
**Output:** `/projects/inboxiq/drive-ios-critical-fix/`
**Timeout:** 45 minutes
**Status:** 🟡 RUNNING

**Issues to Fix:**
- ✅ Issue #1: Hardcoded "Attachment 1" bug

**Expected Files:**
- ios/Models/Email.swift (AttachmentInfo struct)
- ios/Views/Detail/EmailDetailView.swift (fixed iteration)
- backend/app/schemas/email.py (AttachmentMetadata)
- backend/app/api/emails.py (populate attachments)
- README.md + INTEGRATION.md

---

## Monitoring Schedule

- **21:20:** Agents spawned
- **21:35:** First check (15 min)
- **21:50:** Second check (30 min)
- **22:05:** Expected completion (45 min)
- **22:20:** If not done, investigate

---

## Next Steps (After Agents Complete)

1. **Read agent outputs**
2. **Test backend fixes:**
   - list_files only shows app files
   - Upload rejects 15MB file (413 error)
   - Upload rejects .exe file (415 error)
   - get_download_url endpoint removed (404/501)

3. **Test iOS fixes:**
   - Email with 0 attachments: No section
   - Email with 1 attachment: Shows real filename
   - Email with 3+ attachments: Shows all with real names

4. **Integrate into main codebase:**
   - Copy backend files to main project
   - Copy iOS files to Xcode project
   - Register Drive router in main.py
   - Run migration 008 on Railway

5. **Deploy backend to Railway**

6. **Test end-to-end:**
   - Upload email attachment to Drive
   - View uploaded files (only app files shown)
   - Tap file to open in Google Drive app

7. **Update Linear (INB-28)**

---

## Deferred Issues (Not Fixing Now)

❌ **Issue #5:** Inefficient attachment handling (HIGH)
- Fetches full email body unnecessarily
- DEFER to post-demo

❌ **Issue #6:** Missing loading state (MEDIUM)
- No indicator while loading attachments
- DEFER to post-demo

---

## Backup Location

`/Users/openclaw-service/.openclaw/workspace/backups/inboxiq-drive-critical-fixes-2026-03-05-2119/`

**Restore if needed:**
- emails.py.bak
- email_schema.py.bak
- EmailDetailView.swift.bak

---

**Last Updated:** 2026-03-05 21:20 CST
**Next Check:** 21:35 CST (15 min)
