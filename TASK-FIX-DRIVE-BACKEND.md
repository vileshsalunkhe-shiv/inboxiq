# Task: Fix Google Drive Backend Issues (Sundar Review)

**Agent:** DEV-BE-premium
**Priority:** CRITICAL (Demo tomorrow)
**Time Estimate:** 30-45 minutes
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/drive-backend-fixes/`

---

## Objective
Fix critical and high-priority security issues found in Sundar's Google Drive backend review.

**READ:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SUNDAR-DRIVE-REVIEW.md`

---

## Issues to Fix

### 1. CRITICAL: Improper File Access in list_files 🔴

**File:** `drive-backend/backend/app/services/drive_service.py`

**Issue:** Currently lists ALL user's Drive files. Should only list files created by this app.

**Fix:**
```python
# In drive_service.py, list_files method
request = service.files().list(
    pageSize=limit,
    orderBy=order_by,
    spaces="appDataFolder",  # ← ADD THIS
    q="trashed=false",
    fields="files(id,name,mimeType,webViewLink,modifiedTime,size,thumbnailLink),nextPageToken",
)
```

### 2. CRITICAL: Remove Download URL Endpoint 🔴

**File:** `drive-backend/backend/app/api/drive.py`

**Issue:** `get_download_url` returns permanent public links - security risk.

**Fix:** **Remove the endpoint entirely** (not needed for demo):
```python
# DELETE this endpoint from drive.py:
# @router.get("/files/{file_id}/download-url")
# async def get_download_url(...) -> DriveDownloadUrlResponse:
#     ...
```

**Also remove from drive_service.py:**
```python
# DELETE get_download_url method
```

### 3. CRITICAL: Add File Size/Type Validation 🔴

**File:** `drive-backend/backend/app/api/drive.py`

**Issue:** No validation before uploading files.

**Fix:**
```python
# In drive.py, upload_to_drive method, BEFORE uploading:

# Validate file size (10MB limit)
file_bytes = _decode_base64url(data)
if len(file_bytes) > 10 * 1024 * 1024:  # 10MB
    raise HTTPException(
        status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
        detail="File size exceeds 10MB limit"
    )

# Validate MIME type
allowed_mime_types = [
    "application/pdf",
    "image/jpeg",
    "image/png",
    "image/gif",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",  # DOCX
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",  # XLSX
]
if mime_type not in allowed_mime_types:
    raise HTTPException(
        status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
        detail=f"Unsupported file type: {mime_type}"
    )
```

### 4. HIGH: Optimize Attachment Handling

**File:** `drive-backend/backend/app/api/drive.py`

**Issue:** Fetches full email message unnecessarily.

**Fix:**
```python
# In drive.py, upload_to_drive method:
# Instead of _collect_attachments, parse payload directly:

parts = message.get("payload", {}).get("parts", [])
if not parts:
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="No attachments found"
    )

if payload.attachment_index >= len(parts):
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Attachment index out of range"
    )

part = parts[payload.attachment_index]
filename = part.get("filename")
mime_type = part.get("mimeType")
attachment_id = part.get("body", {}).get("attachmentId")

if not (filename and mime_type and attachment_id):
    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Attachment metadata not found"
    )
```

---

## Output Structure

```
drive-backend-fixes/
├── README.md                           # What was fixed
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── drive.py              # UPDATED (remove endpoint, add validation)
│   │   └── services/
│   │       └── drive_service.py      # UPDATED (restrict file list, remove download URL)
└── INTEGRATION.md                     # How to apply fixes
```

---

## Testing

**After fixes, verify:**
1. Upload still works
2. List files returns ONLY app-created files
3. File size validation triggers for >10MB
4. MIME type validation triggers for unsupported types
5. Download URL endpoint is gone (404)

---

## Critical Constraints

- DO NOT break upload functionality
- DO NOT modify OAuth scopes (already correct)
- Test that existing features still work

---

**PRIORITY ORDER:**
1. Fix file list restriction (security)
2. Add file validation (security)
3. Remove download URL endpoint (security)
4. Optimize attachment handling (performance)

---

**Good luck! 🔥**
