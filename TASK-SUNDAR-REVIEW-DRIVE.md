# Task: Code Review - Google Drive Integration

**Agent:** Sundar (Security & Quality Review)
**Priority:** HIGH (Demo tomorrow)
**Time Estimate:** 45-60 minutes
**Output:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SUNDAR-DRIVE-REVIEW.md`

---

## Objective
Review Google Drive integration implementation (backend + iOS) for security issues, code quality, best practices, and production readiness.

---

## What to Review

### Backend Implementation
**Location:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/drive-backend/`

**Files:**
- `backend/app/api/drive.py` - Drive API endpoints (upload, list, download URL)
- `backend/app/services/drive_service.py` - Drive service logic
- `backend/app/schemas/drive.py` - Pydantic models
- `backend/app/services/auth_service.py` - OAuth scope updates
- `backend/app/main.py` - Router registration
- `backend/app/api/__init__.py` - Router exports
- `backend/alembic/versions/008_add_drive_folder.py` - Migration (optional)

**Review Focus:**
1. **Security:**
   - OAuth scope management (drive.file vs full drive access)
   - Token storage and refresh
   - File upload validation (size limits, MIME types)
   - SQL injection risks
   - Path traversal vulnerabilities
   - Rate limiting on Drive API calls

2. **Code Quality:**
   - Error handling (Drive API failures, quota exceeded)
   - Async/await patterns
   - Memory usage (large file uploads)
   - Integration with existing Gmail service
   - Code duplication

3. **Best Practices:**
   - Follows existing codebase patterns
   - Proper use of Drive API (v3)
   - File metadata handling
   - Attachment retrieval from Gmail

4. **Production Readiness:**
   - Quota limit handling (Drive API limits)
   - Large file support
   - Logging and observability
   - Edge cases (missing attachments, invalid file IDs)

### iOS Implementation
**Location:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/drive-ios/`

**Files:**
- `ios/Services/DriveService.swift` - API client
- `ios/Models/DriveModels.swift` - Data models
- `ios/Views/Detail/EmailDetailView.swift` - "Save to Drive" button
- `ios/Views/Drive/DriveListView.swift` - Drive files list (optional)

**Review Focus:**
1. **Security:**
   - API request validation
   - Error message exposure (don't leak sensitive data)
   - Token handling (uses existing APIClient)

2. **Code Quality:**
   - Error handling (network errors, API failures)
   - Memory management (@State usage)
   - UI thread safety
   - Code organization

3. **Best Practices:**
   - Follows Design System
   - Follows existing APIClient patterns
   - SwiftUI best practices
   - Loading states and UX

4. **User Experience:**
   - Button placement on EmailDetailView
   - Loading states (while uploading)
   - Success/error toasts
   - File list display (if implemented)

---

## Review Format

Create: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SUNDAR-DRIVE-REVIEW.md`

**Use same format as previous review:**
- Executive Summary (APPROVED / APPROVED WITH CHANGES / NEEDS WORK)
- Issue count by severity (Critical, High, Medium, Low)
- Recommendation
- Backend Review (Security, Code Quality, Best Practices)
- iOS Review (Security, Code Quality, UX)
- Positive Observations
- Integration Concerns
- Summary of Recommendations (Must Fix, Should Fix, Can Fix)
- Final Verdict

---

## Context

**Feature:** Google Drive Integration (Phase 1 MVP)
**Scope:**
- Upload email attachments to Google Drive
- List recent Drive files
- Get download URLs

**Demo Date:** 2026-03-06 (tomorrow)
**User:** vilesh.salunkhe@gmail.com
**Railway URL:** https://inboxiq-production-5368.up.railway.app

**Feature Spec:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/LINEAR-FEATURE-GOOGLE-DRIVE.md`

**Development Time:**
- Backend: ~4 minutes (DEV-BE-premium)
- iOS: ~10 minutes (DEV-MOBILE-premium)

**Status:** Both complete, NOT deployed yet (waiting for review)

---

## Critical Requirements

**DO NOT:**
- Break existing features (Gmail, Calendar, Digest)
- Introduce security vulnerabilities
- Compromise OAuth token security
- Allow unauthorized file access

**MUST:**
- Use minimal OAuth scopes (`drive.file` preferred)
- Validate all file operations
- Handle Drive API quota limits gracefully
- Provide clear error messages

---

## Focus Areas for Demo

**Prioritize:**
1. Security (OAuth, file access, tokens)
2. UX (button works, toasts show, no crashes)
3. Error handling (graceful failures)
4. Integration (doesn't break email features)

**Deprioritize:**
- Performance optimizations
- Advanced features (not in Phase 1)
- Code style/formatting
- Comprehensive testing

---

## Notes

- **Attachment access:** Backend uses Gmail API to fetch attachments
- **Email body issue:** Currently blocked by rate limiting (documented)
- **OAuth flow:** Already working for Gmail/Calendar
- **Design System:** iOS should follow existing patterns

**Be thorough but pragmatic.** Focus on issues that could break the demo, compromise security, or block integration.

---

**Good luck, Sundar! 🔥**
