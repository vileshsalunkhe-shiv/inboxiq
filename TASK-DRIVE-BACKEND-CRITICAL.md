# Task: Google Drive Backend - Critical Security Fixes

**Agent:** DEV-BE-premium
**Session Label:** drive-backend-critical-fixes
**Timeout:** 45 minutes
**Output:** `/projects/inboxiq/drive-backend-critical-fixes/`

---

## Context

Google Drive integration has 3 critical backend security issues identified by Sundar. Fix ONLY these 3 issues. Do NOT change anything else.

**Existing Code Location:** `/projects/inboxiq/drive-backend/backend/`

---

## Critical Issue #1: File Access Privacy Violation

**File:** `backend/app/services/drive_service.py`

**Problem:** `list_files()` returns ALL user's Drive files (not just app-created)

**Fix:**
```python
# In drive_service.py, list_files method
def list_files(
    self,
    user_id: UUID,
    limit: int = 100,
    page_token: Optional[str] = None,
    order_by: str = "modifiedTime desc",
) -> Dict[str, Any]:
    # ... existing code ...
    
    request = service.files().list(
        pageSize=limit,
        orderBy=order_by,
        spaces="appDataFolder",  # ✅ ADD THIS LINE
        q="trashed=false",
        fields="files(id,name,mimeType,webViewLink,modifiedTime,size,thumbnailLink),nextPageToken",
        pageToken=page_token,
    )
    
    # ... rest of method ...
```

**Why:** Restricts query to only files created by this app (using appDataFolder space)

---

## Critical Issue #2: Permanent Download URLs

**File:** `backend/app/services/drive_service.py`

**Problem:** `get_download_url()` creates permanent public URLs (security risk)

**Fix:** Remove or comment out the entire `get_download_url` method

```python
# REMOVE THIS ENTIRE METHOD (or comment it out):
# def get_download_url(self, user_id: UUID, file_id: str) -> Dict[str, Any]:
#     ... entire method ...
```

**Also update:** `backend/app/api/drive.py` - Remove or comment out the corresponding endpoint:

```python
# REMOVE OR COMMENT OUT:
# @router.get("/files/{file_id}/download-url", response_model=DriveDownloadURL)
# async def get_file_download_url(...):
#     ...
```

**Why:** Permanent URLs are a security risk. For demo, we don't need download functionality. Can implement secure proxy download post-demo.

---

## Critical Issue #3: No File Validation

**File:** `backend/app/api/drive.py`

**Problem:** No file size or MIME type validation on uploads

**Fix:**
```python
# In drive.py, upload_to_drive endpoint
@router.post("/upload", response_model=DriveFileUpload)
async def upload_to_drive(
    payload: DriveUploadPayload,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        # Decode the base64 attachment data
        file_bytes = _decode_base64url(payload.data)
        
        # ✅ ADD FILE SIZE VALIDATION
        MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
        if len(file_bytes) > MAX_FILE_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail="File size exceeds 10MB limit"
            )
        
        # ✅ ADD MIME TYPE VALIDATION
        ALLOWED_MIME_TYPES = [
            "application/pdf",
            "image/jpeg",
            "image/png",
            "image/gif",
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",  # .docx
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",  # .xlsx
            "text/plain",
            "text/csv",
        ]
        if payload.mime_type not in ALLOWED_MIME_TYPES:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=f"Unsupported file type: {payload.mime_type}. Allowed types: PDF, images, Office documents, text files."
            )
        
        # Continue with existing upload logic
        drive_service = DriveService(db)
        # ... rest of method ...
```

**Why:** Prevents abuse (giant files) and security risks (executable files)

---

## DO NOT CHANGE

❌ Do NOT modify Issue #5 (attachment efficiency) - DEFERRED
❌ Do NOT add any other features
❌ Do NOT modify email-related files (those are for iOS agent)
✅ ONLY fix these 3 critical security issues

---

## Output Structure

```
/projects/inboxiq/drive-backend-critical-fixes/
├── README.md
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── drive.py          # Updated with validation
│   │   └── services/
│   │       └── drive_service.py  # Updated with appDataFolder + removed get_download_url
│   └── requirements.txt          # If any new dependencies
└── INTEGRATION.md
```

---

## Testing Instructions (Include in README.md)

```python
# Test 1: File size validation (should reject)
curl -X POST "http://localhost:8000/api/drive/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email_id": "test123",
    "attachment_index": 0,
    "data": "...",  # 15MB file (base64)
    "filename": "large.pdf",
    "mime_type": "application/pdf"
  }'
# Expected: 413 Request Entity Too Large

# Test 2: MIME type validation (should reject)
curl -X POST "http://localhost:8000/api/drive/upload" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email_id": "test123",
    "attachment_index": 0,
    "data": "...",
    "filename": "malware.exe",
    "mime_type": "application/x-executable"
  }'
# Expected: 415 Unsupported Media Type

# Test 3: list_files only shows app files
curl "http://localhost:8000/api/drive/files" \
  -H "Authorization: Bearer $TOKEN"
# Expected: Only files uploaded via InboxIQ, not all Drive files

# Test 4: get_download_url endpoint removed
curl "http://localhost:8000/api/drive/files/abc123/download-url" \
  -H "Authorization: Bearer $TOKEN"
# Expected: 404 Not Found or 501 Not Implemented
```

---

## Success Criteria

- [ ] `list_files()` uses `spaces="appDataFolder"`
- [ ] `get_download_url` method removed or disabled
- [ ] Upload endpoint validates file size (10MB limit)
- [ ] Upload endpoint validates MIME type (whitelist only)
- [ ] All tests pass
- [ ] README.md documents changes
- [ ] INTEGRATION.md has clear integration steps

---

**Remember:** Fix ONLY these 3 critical security issues. Do NOT defer to Issue #5 (attachment efficiency) or Issue #6 (loading state) - those are iOS agent's responsibility.

**Time Estimate:** 30 minutes
**Priority:** CRITICAL (blocking demo)
