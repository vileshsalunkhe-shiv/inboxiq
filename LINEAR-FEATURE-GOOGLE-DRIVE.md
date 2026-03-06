# Feature: Google Drive Integration

**Type:** Feature Request
**Priority:** Medium
**Status:** Backlog
**Date:** 2026-03-05 17:34 CST

---

## Feature Overview

Integrate Google Drive with InboxIQ to allow users to save email attachments directly to Drive and access Drive files from within the app.

---

## User Stories

**As a user, I want to:**
1. Save email attachments to Google Drive with one tap
2. View my recent Drive files from InboxIQ
3. Share Drive files via email from InboxIQ
4. Search Drive files from within the app
5. Open Drive files in the native Google Drive app

---

## Core Functionality

### 1. Email Attachment → Drive
**Feature:** Save attachments to Google Drive
- **UI:** "Save to Drive" button on email detail view
- **Action:** Upload attachment to user's Drive (configurable folder)
- **Feedback:** Toast confirmation with Drive link
- **Options:** Choose folder, rename file

### 2. Drive File Browser
**Feature:** Browse recent Drive files in app
- **UI:** New "Drive" tab or section in app
- **Display:** List of recent files (last 20-30)
- **Actions:** Open in Drive app, share via email, preview (if supported)
- **Filters:** File type (Docs, Sheets, PDFs, Images)

### 3. Compose with Drive Files
**Feature:** Attach Drive files to new emails
- **UI:** "Attach from Drive" button in compose screen
- **Action:** Share Drive link in email body or attach file
- **Options:** Share as link vs download and attach

### 4. Drive Search
**Feature:** Search Drive files from InboxIQ
- **UI:** Search bar in Drive section
- **Action:** Query Drive API for files
- **Results:** List of matching files with preview

---

## Technical Requirements

### Backend (FastAPI)

**OAuth Scopes Required:**
- `https://www.googleapis.com/auth/drive.file` (files created by app)
- OR `https://www.googleapis.com/auth/drive` (full access)

**New Endpoints:**
```python
POST   /api/drive/upload          # Upload email attachment to Drive
GET    /api/drive/files            # List recent Drive files
GET    /api/drive/search           # Search Drive files
POST   /api/drive/share            # Get shareable link for file
GET    /api/drive/download/{id}    # Download file from Drive
```

**Database Changes:**
- Add `drive_folder_id` to User model (default upload folder)
- Optional: Track uploaded files in `drive_uploads` table

**Dependencies:**
- `google-api-python-client` (already installed for Gmail/Calendar)
- Drive API v3

### iOS (SwiftUI)

**New Views:**
- `DriveView.swift` - Main Drive file browser
- `DriveFilePicker.swift` - File picker for compose
- `DriveUploadSheet.swift` - Upload confirmation with folder picker

**New Services:**
- `DriveService.swift` - API client for Drive endpoints
- `DriveFileCache.swift` - Cache recent files

**Models:**
- `DriveFile.swift` - File metadata (id, name, mimeType, webViewLink, etc.)
- `DriveFolder.swift` - Folder metadata

**UI Integration:**
- Add "Drive" tab to TabView (optional, or integrate into Settings)
- Add "Save to Drive" button to EmailDetailView
- Add "Attach from Drive" to ComposeView

---

## API Examples

### Upload Attachment to Drive
**Request:**
```bash
POST /api/drive/upload
{
  "attachment_id": "att_123",
  "email_id": "email_456",
  "folder_id": "folder_789",  # optional
  "filename": "Invoice.pdf"   # optional rename
}
```

**Response:**
```json
{
  "file_id": "1a2b3c4d5e",
  "name": "Invoice.pdf",
  "web_view_link": "https://drive.google.com/file/d/1a2b3c4d5e/view",
  "created_time": "2026-03-05T17:34:00Z"
}
```

### List Recent Files
**Request:**
```bash
GET /api/drive/files?limit=30&order_by=modified_desc
```

**Response:**
```json
{
  "files": [
    {
      "id": "1a2b3c4d5e",
      "name": "Invoice.pdf",
      "mime_type": "application/pdf",
      "web_view_link": "https://drive.google.com/file/d/1a2b3c4d5e/view",
      "modified_time": "2026-03-05T17:34:00Z",
      "size": 245760,
      "thumbnail_link": "https://..."
    }
  ]
}
```

### Search Files
**Request:**
```bash
GET /api/drive/search?q=invoice&limit=20
```

---

## UI/UX Design

### Email Detail View
```
┌─────────────────────────────┐
│ Subject: Invoice March 2026 │
│ From: billing@company.com   │
├─────────────────────────────┤
│ Email body...               │
│                             │
│ Attachments (2)             │
│ ┌─────────────────────────┐ │
│ │ 📄 Invoice.pdf          │ │
│ │ [Save to Drive]         │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │ 📊 Report.xlsx          │ │
│ │ [Save to Drive]         │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

### Drive Tab
```
┌─────────────────────────────┐
│ Drive           🔍 [Search] │
├─────────────────────────────┤
│ Recent Files                │
│                             │
│ 📄 Invoice.pdf              │
│ Today at 5:34 PM            │
│                             │
│ 📊 Q1 Report.xlsx           │
│ Yesterday at 2:15 PM        │
│                             │
│ 📝 Meeting Notes.docx       │
│ Mar 3 at 10:00 AM           │
└─────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Basic Upload (MVP)
- OAuth scope: `drive.file`
- Upload email attachments to Drive
- Save to default "InboxIQ Uploads" folder
- Show toast confirmation

**Estimate:** 2-3 days

### Phase 2: File Browser
- List recent files
- Open in Drive app
- Search files
- Preview thumbnails

**Estimate:** 2-3 days

### Phase 3: Compose Integration
- Attach Drive files to emails
- Share as link vs download
- Folder picker for uploads

**Estimate:** 1-2 days

---

## Benefits

**For Users:**
- Quick access to important documents
- No need to switch between apps
- Organize email attachments in Drive automatically
- Share Drive files via email easily

**For InboxIQ:**
- Deeper Google Workspace integration
- Competitive advantage (unified inbox + Drive)
- Enterprise appeal (document management)

---

## Dependencies

**Must Have First:**
- Google OAuth working (✅ Already done)
- Email attachment display (⚠️ Blocked by rate limiting)
- Stable backend API (✅ Already done)

**Nice to Have:**
- Push notifications (for Drive file changes)
- Offline support (cache recent files)

---

## Security Considerations

- Request minimal OAuth scope (`drive.file` vs full `drive` access)
- Encrypt Drive tokens in database (already done for Gmail/Calendar)
- Rate limiting on Drive API endpoints
- Validate file types before upload
- Scan for malware (optional, use Drive's built-in scanning)

---

## Testing Plan

**Backend:**
- Upload various file types (PDF, XLSX, DOCX, images)
- Handle large files (>10MB)
- Test Drive API rate limits
- Test OAuth token refresh

**iOS:**
- Upload from email detail view
- Browse Drive files
- Search functionality
- File preview (if supported)
- Error handling (network errors, auth errors)

---

## Success Metrics

- % of users who save attachments to Drive
- Number of Drive files accessed per user
- Email compositions with Drive attachments
- User feedback (feature requests, bugs)

---

## Future Enhancements

- Two-way sync (Drive changes → InboxIQ notifications)
- Drive file sharing permissions management
- Collaborative editing (open Docs/Sheets in browser)
- Drive folder organization
- Starred files
- Offline file access

---

## Notes

- **Google Drive API Quota:** 20,000 requests per 100 seconds per user
- **File Size Limits:** 5TB per file (Drive limit)
- **Cost:** Free tier: 15GB storage (shared with Gmail)
- **Alternative:** Could integrate Dropbox, OneDrive later

---

**Created:** 2026-03-05 17:34 CST  
**Requested By:** V (Vilesh Salunkhe)  
**Status:** Ready for Linear
