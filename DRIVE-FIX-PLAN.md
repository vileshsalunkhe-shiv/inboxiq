# Google Drive Integration - Fix Plan

**Date:** 2026-03-05 21:15 CST
**Goal:** Fix 6 security/functionality issues before demo (2026-03-06)
**Status:** Not yet integrated (code in separate directories)

---

## Current State

**Agent-Generated Code (Not Integrated):**
- Backend: `/drive-backend/`, `/drive-backend-fixes/`
- iOS: `/drive-ios/`, `/drive-ios-view-only/`, `/drive-ios-fixes/`

**Sundar's Verdict:** NEEDS WORK (6 issues found)

---

## Issues to Fix (Priority Order)

### 🔴 CRITICAL #1: iOS Hardcoded Attachment Bug (DEMO BLOCKER)

**File:** `ios/Views/Detail/EmailDetailView.swift`

**Problem:** 
- Hardcoded to always show "Attachment 1" 
- Only shows 1 button regardless of actual attachment count
- Won't work in demo with 0 or multiple attachments

**Fix:**
- Backend: Add `attachments[]` array to EmailBody response (filename, size, index)
- iOS: Dynamically iterate `body.attachments` array
- Display real filenames, handle 0 or multiple attachments

**Implementation:**
1. Update backend `EmailBody` schema with `attachments: List[AttachmentMetadata]`
2. Update iOS `EmailBody` struct with `attachments: [AttachmentInfo]`
3. Replace hardcoded logic in `EmailDetailView.swift`
4. Test with 0, 1, and 3+ attachment emails

---

### 🔴 CRITICAL #2: Improper File Access (PRIVACY VIOLATION)

**File:** `backend/app/services/drive_service.py`

**Problem:**
- `list_files()` returns ALL user's Drive files (not just app-created)
- Major privacy violation
- Could expose personal/work documents

**Fix:**
```python
# In drive_service.py, list_files method
request = service.files().list(
    pageSize=limit,
    orderBy=order_by,
    spaces="appDataFolder",  # ✅ ADD THIS LINE
    q="trashed=false",
    fields="files(id,name,mimeType,webViewLink,modifiedTime,size,thumbnailLink),nextPageToken",
)
```

**Alternative:** Track uploaded files in database, only list those IDs

---

### 🔴 CRITICAL #3: Permanent Download URLs (SECURITY RISK)

**File:** `backend/app/services/drive_service.py`

**Problem:**
- `webContentLink` creates permanent public URLs
- Files accessible forever, even after deletion from app
- `expires_at` field is misleading (gives false security)

**Fix (Option A - Recommended):**
- Remove `get_download_url` endpoint entirely for demo
- Not critical for demo functionality

**Fix (Option B - Future):**
- Proxy downloads through backend (stream file)
- Generate short-lived signed URLs
- More complex, defer to post-demo

**Implementation:** Comment out or remove endpoint for now

---

### 🔴 CRITICAL #4: No File Validation (ABUSE RISK)

**File:** `backend/app/api/drive.py`

**Problem:**
- No file size limits (could upload gigabytes)
- No MIME type validation (security risk)
- Open to abuse

**Fix:**
```python
# In drive.py, upload_to_drive method (AFTER decoding)
file_bytes = _decode_base64url(data)

# ✅ ADD THESE CHECKS
if len(file_bytes) > 10 * 1024 * 1024:  # 10MB limit
    raise HTTPException(
        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, 
        detail="File size exceeds 10MB limit"
    )

allowed_mime_types = [
    "application/pdf",
    "image/jpeg",
    "image/png",
    "image/gif",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
]
if mime_type not in allowed_mime_types:
    raise HTTPException(
        status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, 
        detail=f"Unsupported file type: {mime_type}"
    )
```

---

### 🟠 HIGH PRIORITY #5: Inefficient Attachment Handling

**File:** `backend/app/api/drive.py`

**Problem:**
- Fetches entire email body (`format="full"`) just to get 1 attachment
- Exposes sensitive email data unnecessarily
- Performance issue for large emails

**Fix:**
```python
# In drive.py, upload_to_drive method
# Instead of _collect_attachments, parse payload directly
parts = message.get("payload", {}).get("parts", [])
if not parts:
    raise HTTPException(status_code=404, detail="No attachments found")

if payload.attachment_index >= len(parts):
    raise HTTPException(status_code=404, detail="Attachment index out of range")
    
part = parts[payload.attachment_index]
filename = part.get("filename")
mime_type = part.get("mimeType")
attachment_id = part.get("body", {}).get("attachmentId")

if not (filename and mime_type and attachment_id):
    raise HTTPException(status_code=404, detail="Attachment metadata not found")

# Continue to fetch attachment data with attachment_id
```

---

### 🟡 MEDIUM PRIORITY #6: Missing Loading State

**File:** `ios/Views/Detail/EmailDetailView.swift`

**Problem:**
- No loading indicator when fetching full email body
- User could tap "Save to Drive" before attachments loaded
- Leads to confusing errors

**Fix:**
```swift
// In EmailDetailView.swift
SecondaryButton(
    title: driveButtonTitle(for: index),
    systemImage: "arrow.up.doc",
    action: {
        Task {
            await saveToDrive(attachmentIndex: index)
        }
    }
)
.disabled(isSavingToDrive || isLoadingBody)  // ✅ ADD isLoadingBody

// Show loading indicator above buttons
if isLoadingBody {
    ProgressView("Loading attachments...")
        .padding()
}
```

---

## Implementation Strategy

### Option A: Fix All Issues Before Integration (RECOMMENDED)

**Time Estimate:** 2-3 hours

**Steps:**
1. Spawn DEV-BE-premium to fix backend issues (#2, #3, #4, #5)
2. Spawn DEV-MOBILE-premium to fix iOS issues (#1, #6)
3. V tests both fixes
4. Integrate into main codebase
5. Deploy backend to Railway
6. Test end-to-end

**Benefits:**
- Clean, secure code from the start
- No security vulnerabilities in production
- Professional demo experience

**Risks:**
- Takes time (late night work)
- Could break existing functionality

---

### Option B: Fix Critical Only, Defer Others (FASTER)

**Time Estimate:** 1 hour

**Steps:**
1. Fix iOS hardcoded bug (#1) - MUST FIX for demo
2. Fix file access privacy (#2) - MUST FIX for security
3. Remove download URL endpoint (#3) - Quick fix
4. Add file validation (#4) - Quick fix
5. DEFER: Attachment efficiency (#5) - Not demo-breaking
6. DEFER: Loading state (#6) - Nice to have

**Benefits:**
- Faster to implement
- Core functionality works for demo
- Can polish post-demo

**Risks:**
- Less polished
- Performance issues remain

---

### Option C: Defer Google Drive to Post-Demo

**Time Estimate:** 0 hours (skip for now)

**Benefits:**
- Focus on Daily Digest + UI Polish (already done)
- No risk of breaking working features
- More time for demo rehearsal

**Risks:**
- One less impressive feature to show
- Drive pushed to v1.1

---

## Recommendation

**Option A (Fix All Issues)** if V wants Drive in demo and has 2-3 hours tonight.

**Option C (Defer Drive)** if V wants to focus on polishing existing features and practicing demo flow.

Demo is already strong with:
- ✅ Daily Digest (impressive automated feature)
- ✅ UI Polish (professional appearance)
- ✅ Email Actions (archive, star, compose, reply, forward)
- ✅ Calendar Integration (OAuth + events)

Google Drive is "nice to have" but not critical for showing core value proposition.

---

## V's Decision Needed

1. **Include Drive in demo?** (Yes/No)
2. **If Yes, which option?** (A: Fix all, B: Fix critical only)
3. **If No, defer to when?** (Post-demo, v1.1)

---

**Created:** 2026-03-05 21:15 CST
**Awaiting V's direction**
