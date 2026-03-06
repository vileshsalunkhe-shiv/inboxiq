# Task: Google Drive iOS - Critical Attachment Bug Fix

**Agent:** DEV-MOBILE-premium
**Session Label:** drive-ios-critical-fix
**Timeout:** 45 minutes
**Output:** `/projects/inboxiq/drive-ios-critical-fix/`

---

## Context

Google Drive integration has 1 critical iOS bug identified by Sundar that will BREAK the demo. Fix this ONLY. Do NOT change anything else.

**Existing Code Location:** `/projects/inboxiq/drive-ios-view-only/`

---

## Critical Issue #1: Hardcoded Attachment Logic (DEMO BLOCKER)

**File:** `ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift`

**Problem:**
- Hardcoded to always show "Attachment 1"
- Uses `body.hasAttachments ? [0] : []` (only shows index 0)
- Won't work with 0 attachments (shows button anyway)
- Won't work with 3+ attachments (only shows first one)
- Filename is hardcoded as "Attachment 1" instead of real filename

**Current Broken Code:**
```swift
// WRONG:
ForEach(attachmentIndices(for: body), id: \.self) { index in
    SecondaryButton(
        title: "Attachment 1",  // ❌ HARDCODED
        systemImage: "arrow.up.doc",
        action: { ... }
    )
}

private func attachmentIndices(for body: EmailBody) -> [Int] {
    return body.hasAttachments ? [0] : []  // ❌ ONLY SHOWS INDEX 0
}
```

---

## Fix Requirements

### Part 1: Update Backend EmailBody Schema (Coordinate with Backend Agent)

**File:** `backend/app/schemas/email.py`

**Add new schema:**
```python
from pydantic import BaseModel
from typing import List, Optional

class AttachmentMetadata(BaseModel):
    """Metadata for email attachment"""
    index: int
    filename: str
    mime_type: str
    size: int  # bytes

class EmailBody(BaseModel):
    """Email body response with attachment metadata"""
    message_id: str
    html_body: Optional[str] = None
    text_body: Optional[str] = None
    has_attachments: bool = False
    attachments: List[AttachmentMetadata] = []  # ✅ ADD THIS FIELD
```

**Update email body endpoint:**
```python
# In backend/app/api/emails.py, get_email_body endpoint
# When returning EmailBody, populate attachments array:

attachments_metadata = []
for idx, part in enumerate(parts):
    if part.get("filename"):
        attachments_metadata.append(
            AttachmentMetadata(
                index=idx,
                filename=part["filename"],
                mime_type=part.get("mimeType", "application/octet-stream"),
                size=part.get("body", {}).get("size", 0)
            )
        )

return EmailBody(
    message_id=message_id,
    html_body=html_body,
    text_body=text_body,
    has_attachments=len(attachments_metadata) > 0,
    attachments=attachments_metadata  # ✅ INCLUDE THIS
)
```

### Part 2: Update iOS EmailBody Struct

**File:** `ios/InboxIQ/InboxIQ/Models/Email.swift`

**Add new struct:**
```swift
struct AttachmentInfo: Codable, Identifiable {
    let index: Int
    let filename: String
    let mimeType: String
    let size: Int
    
    var id: Int { index }
    
    enum CodingKeys: String, CodingKey {
        case index, filename
        case mimeType = "mime_type"
        case size
    }
}

struct EmailBody: Codable {
    let messageId: String
    let htmlBody: String?
    let textBody: String?
    let hasAttachments: Bool
    let attachments: [AttachmentInfo]  // ✅ ADD THIS FIELD
    
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case htmlBody = "html_body"
        case textBody = "text_body"
        case hasAttachments = "has_attachments"
        case attachments
    }
}
```

### Part 3: Fix EmailDetailView.swift

**File:** `ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift`

**Fix the attachment button rendering:**
```swift
// ✅ CORRECT: Iterate actual attachments
if !body.attachments.isEmpty {
    VStack(alignment: .leading, spacing: 8) {
        Text("Attachments")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.secondary)
        
        ForEach(body.attachments) { attachment in
            SecondaryButton(
                title: attachment.filename,  // ✅ REAL FILENAME
                systemImage: attachmentIcon(for: attachment.mimeType),
                action: {
                    Task {
                        await saveToDrive(attachmentIndex: attachment.index)
                    }
                }
            )
            .disabled(isSavingToDrive)
        }
    }
    .padding(.horizontal)
}

// ✅ ADD HELPER: Icon based on MIME type
private func attachmentIcon(for mimeType: String) -> String {
    if mimeType.starts(with: "image/") {
        return "photo"
    } else if mimeType == "application/pdf" {
        return "doc.text"
    } else if mimeType.contains("word") {
        return "doc"
    } else if mimeType.contains("excel") || mimeType.contains("spreadsheet") {
        return "tablecells"
    } else {
        return "paperclip"
    }
}
```

**Remove the old broken helper:**
```swift
// ❌ DELETE THESE:
// private func attachmentIndices(for body: EmailBody) -> [Int] {
//     return body.hasAttachments ? [0] : []
// }
//
// private func attachmentTitle(for index: Int) -> String {
//     return "Attachment 1"
// }
```

---

## DO NOT CHANGE

❌ Do NOT modify Issue #6 (loading state) - DEFERRED to post-demo
❌ Do NOT add DriveListView or Drive tab (view-only feature deferred)
❌ Do NOT modify backend drive_service.py (that's backend agent's job)
✅ ONLY fix the hardcoded attachment bug

---

## Output Structure

```
/projects/inboxiq/drive-ios-critical-fix/
├── README.md
├── ios/
│   ├── Models/
│   │   └── Email.swift              # Updated with AttachmentInfo struct
│   └── Views/
│       └── Detail/
│           └── EmailDetailView.swift  # Fixed attachment iteration
└── INTEGRATION.md
```

**ALSO OUTPUT (Coordinate with Backend):**
```
/projects/inboxiq/drive-ios-critical-fix/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── emails.py           # Updated email body endpoint
│   │   └── schemas/
│   │       └── email.py            # Updated with AttachmentMetadata
```

---

## Testing Instructions (Include in README.md)

**Test Case 1: Email with 0 attachments**
```
Expected: No "Attachments" section shown
Actual: Section hidden when body.attachments.isEmpty
```

**Test Case 2: Email with 1 attachment**
```
Email: "Meeting notes.pdf" (500KB)
Expected: Shows "meeting notes.pdf" button with doc icon
Actual: Displays real filename, tapping uploads correct file
```

**Test Case 3: Email with 3+ attachments**
```
Email: "Proposal.docx" (2MB), "Budget.xlsx" (1MB), "Logo.png" (300KB)
Expected: Shows all 3 buttons with real filenames + appropriate icons
Actual: All attachments visible, each uploads independently
```

**Test Case 4: Different file types**
```
- PDF: Shows "doc.text" icon
- Image: Shows "photo" icon
- Word: Shows "doc" icon
- Excel: Shows "tablecells" icon
- Other: Shows "paperclip" icon
```

---

## Success Criteria

- [ ] AttachmentInfo struct added to Email.swift
- [ ] EmailBody struct includes `attachments: [AttachmentInfo]`
- [ ] Backend EmailBody schema includes `attachments: List[AttachmentMetadata]`
- [ ] Backend email body endpoint populates attachments array
- [ ] EmailDetailView iterates actual attachments (not hardcoded [0])
- [ ] Shows real filenames (not "Attachment 1")
- [ ] Shows appropriate icon per MIME type
- [ ] 0 attachments: No section shown
- [ ] 1 attachment: Shows 1 button with real name
- [ ] 3+ attachments: Shows all with real names
- [ ] README.md documents changes
- [ ] INTEGRATION.md has clear steps

---

## Integration Notes

**Backend Changes Required:**
1. Update `backend/app/schemas/email.py` (add AttachmentMetadata)
2. Update `backend/app/api/emails.py` (populate attachments in response)

**iOS Changes Required:**
1. Update `ios/InboxIQ/InboxIQ/Models/Email.swift` (add AttachmentInfo)
2. Update `ios/InboxIQ/InboxIQ/Views/Detail/EmailDetailView.swift` (fix iteration)

**Coordinate with Backend Agent:** Share schema changes to ensure compatibility

---

**Remember:** This is the MOST CRITICAL fix for the demo. Without it, Drive upload won't work correctly. Fix ONLY this issue, defer Issue #6 (loading state).

**Time Estimate:** 30 minutes
**Priority:** CRITICAL (DEMO BLOCKER)
