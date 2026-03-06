# Task: Google Drive Integration - iOS UI

**Agent:** DEV-MOBILE-premium
**Priority:** HIGH (Demo tomorrow)
**Time Estimate:** 2-3 hours
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/drive-ios/`

---

## Objective
Build iOS UI for Google Drive integration in InboxIQ. Enable users to upload email attachments to Drive and view recent Drive files.

**READ FIRST:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/LINEAR-FEATURE-GOOGLE-DRIVE.md`

---

## Phase 1 Implementation (MVP)

Focus on core UI only:
1. "Save to Drive" button on email detail view
2. Drive files list view (optional tab or Settings section)
3. Success/error toasts

**DO NOT implement yet:**
- Search UI (Phase 2)
- Folder picker (Phase 2)
- File preview (Phase 3)

---

## Requirements

### 1. Drive Service (API Client)

**File:** `Services/DriveService.swift`

```swift
import Foundation

final class DriveService {
    static let shared = DriveService()
    
    private init() {}
    
    func uploadAttachment(emailId: String, attachmentIndex: Int) async throws -> DriveFile {
        let response: DriveUploadResponse = try await APIClient.shared.request(
            "/drive/upload",
            method: "POST",
            body: [
                "email_id": emailId,
                "attachment_index": attachmentIndex
            ]
        )
        return DriveFile(from: response)
    }
    
    func listFiles(limit: Int = 30) async throws -> [DriveFile] {
        let response: DriveFileListResponse = try await APIClient.shared.request(
            "/drive/files?limit=\(limit)"
        )
        return response.files.map { DriveFile(from: $0) }
    }
    
    func getDownloadUrl(fileId: String) async throws -> URL {
        let response: DriveDownloadUrlResponse = try await APIClient.shared.request(
            "/drive/files/\(fileId)/download-url"
        )
        return URL(string: response.downloadUrl)!
    }
}
```

### 2. Drive Models

**File:** `Models/DriveModels.swift`

```swift
import Foundation

struct DriveFile: Identifiable, Codable {
    let id: String
    let name: String
    let mimeType: String
    let webViewLink: String
    let modifiedTime: Date
    let size: Int
    let thumbnailLink: String?
}

struct DriveUploadResponse: Codable {
    let fileId: String
    let name: String
    let mimeType: String
    let webViewLink: String
    let createdTime: Date
    let size: Int
}

struct DriveFileListResponse: Codable {
    let files: [DriveFileResponse]
    let nextPageToken: String?
}

struct DriveFileResponse: Codable {
    let id: String
    let name: String
    let mimeType: String
    let webViewLink: String
    let modifiedTime: Date
    let size: Int
    let thumbnailLink: String?
}

struct DriveDownloadUrlResponse: Codable {
    let downloadUrl: String
    let expiresAt: Date
}
```

### 3. Email Detail View Update

**File:** `Views/Detail/EmailDetailView.swift`

**Add "Save to Drive" button for each attachment:**

```swift
// In attachment section
ForEach(Array(email.attachments.enumerated()), id: \.offset) { index, attachment in
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Image(systemName: "doc.fill")
            Text(attachment.filename)
            Spacer()
        }
        
        HStack(spacing: 12) {
            SecondaryButton(
                title: "Save to Drive",
                icon: "arrow.down.doc",
                action: {
                    Task {
                        await saveToDrive(attachmentIndex: index)
                    }
                }
            )
            .disabled(isSavingToDrive)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .cornerRadius(8)
}

// Add state
@State private var isSavingToDrive = false
@State private var showDriveSuccess = false
@State private var driveSuccessMessage = ""

// Add function
private func saveToDrive(attachmentIndex: Int) async {
    isSavingToDrive = true
    defer { isSavingToDrive = false }
    
    do {
        let driveFile = try await DriveService.shared.uploadAttachment(
            emailId: email.id,
            attachmentIndex: attachmentIndex
        )
        driveSuccessMessage = "Saved to Drive: \(driveFile.name)"
        showDriveSuccess = true
    } catch {
        // Show error toast
    }
}
```

### 4. Drive Files View (Optional)

**File:** `Views/Drive/DriveListView.swift`

Simple list of recent Drive files:

```swift
import SwiftUI

struct DriveListView: View {
    @State private var files: [DriveFile] = []
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error = error {
                    Text("Error: \(error)")
                } else if files.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("No Drive files yet")
                            .font(.headline)
                        Text("Files uploaded from InboxIQ will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(files) { file in
                        DriveFileRow(file: file)
                    }
                }
            }
            .navigationTitle("Drive Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadFiles) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task {
            await loadFiles()
        }
    }
    
    private func loadFiles() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            files = try await DriveService.shared.listFiles()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct DriveFileRow: View {
    let file: DriveFile
    
    var body: some View {
        HStack {
            Image(systemName: iconForMimeType(file.mimeType))
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.headline)
                Text(formatDate(file.modifiedTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = URL(string: file.webViewLink) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType.contains("pdf") { return "doc.fill" }
        if mimeType.contains("image") { return "photo.fill" }
        if mimeType.contains("spreadsheet") { return "tablecells.fill" }
        if mimeType.contains("document") { return "doc.text.fill" }
        return "doc.fill"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
```

### 5. Integration into App

**Option A:** Add Drive tab to TabView (if room)
**Option B:** Add Drive section to Settings

**Recommendation:** Option B (Settings section) for MVP

---

## Design System Compliance

**Must use:**
- `AppColors` for colors
- `AppSpacing` for padding/margins
- `AppTypography` for text styles
- `SecondaryButton` for "Save to Drive" button
- `ToastView` for success/error messages

---

## Testing Requirements

**Before marking complete:**

1. **App builds without errors:**
   ```bash
   cd ios/InboxIQ
   xcodebuild -scheme InboxIQ -sdk iphonesimulator build
   ```

2. **Manual test on simulator:**
   - Open email with attachment
   - Tap "Save to Drive"
   - See loading state
   - See success toast
   - (Optional) View Drive files list

---

## Output Structure

```
drive-ios/
├── README.md                           # What was built
├── ios/
│   ├── Services/
│   │   └── DriveService.swift         # API client
│   ├── Models/
│   │   └── DriveModels.swift          # Data models
│   └── Views/
│       ├── Detail/
│       │   └── EmailDetailView.swift  # Updated with Save button
│       └── Drive/
│           └── DriveListView.swift    # Optional files list
└── INTEGRATION.md                     # How to integrate
```

---

## Critical Constraints

### DO NOT BREAK EXISTING FUNCTIONALITY
- Don't modify email actions (archive, star, etc.)
- Don't modify existing navigation
- Don't modify Design System
- Test that app still builds

### Files You Can Modify
✅ Create: `Services/DriveService.swift`
✅ Create: `Models/DriveModels.swift`
✅ Create: `Views/Drive/DriveListView.swift`
✅ Update: `Views/Detail/EmailDetailView.swift` (add Save button)
✅ Optional: Update TabView or SettingsView to add Drive section

### Files You CANNOT Modify
❌ `Services/AuthViewModel.swift`
❌ `Services/SyncService.swift`
❌ `Services/EmailActionService.swift`
❌ `Views/Home/EmailListView.swift`
❌ Design System components

---

## Success Criteria

✅ "Save to Drive" button appears on email detail
✅ Tapping button uploads attachment to Drive
✅ Success toast appears
✅ (Optional) Drive files list shows uploaded files
✅ App builds without errors
✅ No regressions in existing features
✅ README documents what was built
✅ Integration guide explains how to add to project

---

## Notes

- **Backend endpoints:** Already built by DEV-BE-premium
- **Test location:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/`
- **Spec:** See LINEAR-FEATURE-GOOGLE-DRIVE.md
- **DO NOT DEPLOY:** Code will be reviewed by Sundar first

**Priority:** Get "Save to Drive" button working. Files list is nice-to-have.

---

**Good luck! 🔥**
