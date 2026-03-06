# Task: Google Drive Integration - Backend

**Agent:** DEV-BE-premium
**Priority:** HIGH (Demo tomorrow)
**Time Estimate:** 2-3 hours
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/drive-backend/`

---

## Objective
Implement Google Drive API integration backend for InboxIQ. Enable users to upload email attachments to Drive and list recent Drive files.

**READ FIRST:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/LINEAR-FEATURE-GOOGLE-DRIVE.md`

---

## Phase 1 Implementation (MVP)

Focus on core functionality only:
1. Upload email attachments to Drive
2. List recent Drive files
3. Get Drive file download link

**DO NOT implement yet:**
- Search (Phase 2)
- Folder management (Phase 2)
- Share permissions (Phase 3)

---

## Requirements

### 1. OAuth Scope Addition
**File:** `app/services/auth_service.py` or OAuth config

**Add scope:**
```python
DRIVE_SCOPE = "https://www.googleapis.com/auth/drive.file"
# This scope allows access only to files created by the app
```

**Update existing OAuth flow:**
- Add Drive scope to Google OAuth request
- Store Drive tokens in `user_google_tokens` table (already exists for Gmail/Calendar)

### 2. New API Endpoints

**File:** `app/api/drive.py`

```python
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/drive", tags=["drive"])

@router.post("/upload")
async def upload_to_drive(
    email_id: str,
    attachment_index: int,
    folder_id: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DriveUploadResponse:
    """
    Upload an email attachment to Google Drive.
    
    - email_id: Database ID of email with attachment
    - attachment_index: Index of attachment in email (0-based)
    - folder_id: Optional Drive folder ID (default: root or "InboxIQ Uploads")
    """
    pass

@router.get("/files")
async def list_drive_files(
    limit: int = 30,
    order_by: str = "modifiedTime desc",
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DriveFileListResponse:
    """List recent Drive files created by InboxIQ."""
    pass

@router.get("/files/{file_id}")
async def get_drive_file(
    file_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DriveFileResponse:
    """Get metadata for a specific Drive file."""
    pass

@router.get("/files/{file_id}/download-url")
async def get_download_url(
    file_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DriveDownloadUrlResponse:
    """Get a download URL for a Drive file."""
    pass
```

### 3. Drive Service

**File:** `app/services/drive_service.py`

```python
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload, MediaIoBaseUpload
import io

class DriveService:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def upload_file(
        self,
        user_id: UUID,
        file_content: bytes,
        filename: str,
        mime_type: str,
        folder_id: str | None = None,
    ) -> dict:
        """Upload a file to Google Drive."""
        # Get user's Drive access token
        # Build Drive API service
        # Upload file
        # Return file metadata
        pass
    
    async def list_files(
        self,
        user_id: UUID,
        limit: int = 30,
        order_by: str = "modifiedTime desc",
    ) -> list[dict]:
        """List user's Drive files created by InboxIQ."""
        pass
    
    async def get_file_metadata(
        self,
        user_id: UUID,
        file_id: str,
    ) -> dict:
        """Get metadata for a specific file."""
        pass
    
    async def get_download_url(
        self,
        user_id: UUID,
        file_id: str,
    ) -> str:
        """Get a temporary download URL for a file."""
        pass
```

**Key Methods:**
- Use `googleapiclient.discovery.build('drive', 'v3', credentials=creds)`
- Handle token refresh (use existing auth_service patterns)
- Error handling for quota limits, auth errors
- Proper async/await patterns (use `asyncio.to_thread` for Drive API calls)

### 4. Schemas

**File:** `app/schemas/drive.py`

```python
from pydantic import BaseModel
from datetime import datetime

class DriveUploadRequest(BaseModel):
    email_id: str
    attachment_index: int
    folder_id: str | None = None
    rename_to: str | None = None

class DriveUploadResponse(BaseModel):
    file_id: str
    name: str
    mime_type: str
    web_view_link: str
    created_time: datetime
    size: int

class DriveFileResponse(BaseModel):
    id: str
    name: str
    mime_type: str
    web_view_link: str
    modified_time: datetime
    size: int
    thumbnail_link: str | None = None

class DriveFileListResponse(BaseModel):
    files: list[DriveFileResponse]
    next_page_token: str | None = None

class DriveDownloadUrlResponse(BaseModel):
    download_url: str
    expires_at: datetime
```

### 5. Database Changes (Optional)

**File:** `alembic/versions/008_add_drive_folder.py`

```python
def upgrade() -> None:
    # Add optional default Drive folder ID to users
    op.add_column("users", sa.Column("drive_default_folder_id", sa.String(255), nullable=True))
    
def downgrade() -> None:
    op.drop_column("users", "drive_default_folder_id")
```

**Note:** This is optional - can default to root folder if not set

---

## Integration with Existing Code

### Get Email Attachment Data

```python
# In drive.py endpoint
from app.services.gmail_service import GmailService

gmail_service = GmailService(db)
email = await db.get(Email, email_id)
attachment_data = await gmail_service.get_attachment(
    user.id,
    email.gmail_id,
    attachment_index
)
```

### OAuth Token Management

```python
# Reuse existing pattern from gmail_service.py
from app.services.auth_service import AuthService

auth_service = AuthService(db)
access_token = await auth_service.get_google_access_token(user, scope="drive")
```

---

## Testing Requirements

**Before marking complete:**

1. **Upload endpoint works:**
   ```bash
   # Get an email with attachment
   email_id=$(curl -H "Authorization: Bearer $TOKEN" \
     https://inboxiq-production-5368.up.railway.app/emails | jq -r '.emails[0].id')
   
   # Upload attachment to Drive
   curl -X POST -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d "{\"email_id\": \"$email_id\", \"attachment_index\": 0}" \
     https://inboxiq-production-5368.up.railway.app/drive/upload
   ```

2. **List files works:**
   ```bash
   curl -H "Authorization: Bearer $TOKEN" \
     https://inboxiq-production-5368.up.railway.app/drive/files
   ```

3. **No regressions:**
   ```bash
   # Existing features still work
   curl https://inboxiq-production-5368.up.railway.app/health
   ```

---

## Output Structure

```
drive-backend/
├── README.md                           # What was built
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── drive.py              # New Drive API endpoints
│   │   ├── services/
│   │   │   └── drive_service.py      # Drive logic
│   │   └── schemas/
│   │       └── drive.py              # Pydantic models
│   └── alembic/
│       └── versions/
│           └── 008_add_drive_folder.py  # Optional migration
└── INTEGRATION.md                     # Integration steps
```

---

## Critical Constraints

### DO NOT BREAK EXISTING FUNCTIONALITY
- Don't modify OAuth flow for Gmail/Calendar
- Don't modify existing endpoints
- Test that email sync still works
- Test that digest still works

### Files You Can Modify
✅ Create new file: `app/api/drive.py`
✅ Create new file: `app/services/drive_service.py`
✅ Create new file: `app/schemas/drive.py`
✅ Update: `app/main.py` (add router only)
✅ Update: `app/api/__init__.py` (add import)
✅ Optional: Create migration 008

### Files You CANNOT Modify
❌ `app/api/auth_ios.py`
❌ `app/api/emails.py`
❌ `app/api/digest.py`
❌ `app/services/gmail_service.py`
❌ Existing database models (except adding optional column)

---

## Dependencies

**Already Available:**
- `google-api-python-client`
- `google-auth`
- OAuth token storage (user_google_tokens table)

**May Need to Add:**
- None (Drive API uses same client as Gmail/Calendar)

---

## Error Handling

**Must handle:**
- OAuth token expired → refresh
- Drive API quota exceeded → 429 error with retry-after
- File not found → 404
- Attachment doesn't exist → 404
- Invalid folder_id → 400

---

## Success Criteria

✅ Upload endpoint uploads attachments to Drive
✅ List endpoint returns recent files
✅ Download URL endpoint returns valid link
✅ OAuth scopes include Drive
✅ No existing features broken
✅ README documents how to use
✅ Integration guide explains how to deploy

---

## Notes

- **Test User:** vilesh.salunkhe@gmail.com (user_id: 1ae0ee58-a04f-47b2-ba79-5779bff48b65)
- **Railway URL:** https://inboxiq-production-5368.up.railway.app
- **Spec:** See LINEAR-FEATURE-GOOGLE-DRIVE.md for full context
- **DO NOT DEPLOY:** Code will be reviewed by Sundar first

**Priority:** Get upload + list working. Download URL is nice-to-have.

---

**Good luck! 🔥**
