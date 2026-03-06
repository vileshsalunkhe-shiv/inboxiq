# Task: Google Drive iOS - View-Only Integration

**Agent:** DEV-MOBILE-premium
**Priority:** HIGH (Demo tomorrow)
**Time Estimate:** 30-40 minutes
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/drive-ios-view-only/`

---

## Objective
Enable Drive file viewing/browsing in InboxIQ iOS app. **DO NOT implement upload functionality** (email body endpoint is broken).

**Demo Goal:** Show users can browse their Drive files from InboxIQ and open them in the Drive app.

---

## Requirements

### What to BUILD ✅

#### 1. Complete DriveListView
**File:** `Views/Drive/DriveListView.swift`

**Full functionality:**
- List Drive files with DriveService.listFiles()
- Display file name, MIME type icon, modified date
- Pull to refresh
- Loading state (skeleton shimmer)
- Empty state ("No Drive files yet")
- Tap file → opens in Google Drive app (using webViewLink)
- Error handling with toast

**Example:**
```swift
struct DriveListView: View {
    @State private var files: [DriveFile] = []
    @State private var isLoading = false
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    // Skeleton shimmer (3-5 rows)
                    VStack(spacing: 12) {
                        ForEach(0..<5) { _ in
                            DriveFileRowSkeleton()
                        }
                    }
                } else if let error = error {
                    Text("Error: \(error)")
                } else if files.isEmpty {
                    EmptyStateView(
                        icon: "folder",
                        title: "No Drive files yet",
                        message: "Files uploaded from InboxIQ will appear here"
                    )
                } else {
                    List(files) { file in
                        DriveFileRow(file: file)
                            .onTapGesture {
                                openInDrive(file)
                            }
                    }
                    .refreshable {
                        await loadFiles()
                    }
                }
            }
            .navigationTitle("Drive Files")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { Task { await loadFiles() } }) {
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
    
    private func openInDrive(_ file: DriveFile) {
        if let url = URL(string: file.webViewLink) {
            UIApplication.shared.open(url)
        }
    }
}
```

#### 2. DriveFileRow Component
**File:** `Views/Drive/DriveFileRow.swift`

```swift
struct DriveFileRow: View {
    let file: DriveFile
    
    var body: some View {
        HStack(spacing: 12) {
            // File icon based on MIME type
            Image(systemName: iconForMimeType(file.mimeType))
                .font(.system(size: 32))
                .foregroundColor(colorForMimeType(file.mimeType))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(AppTypography.body)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(formatFileSize(file.size))
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(formatDate(file.modifiedTime))
                        .font(AppTypography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
    }
    
    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType.contains("pdf") { return "doc.fill" }
        if mimeType.contains("image") { return "photo.fill" }
        if mimeType.contains("spreadsheet") || mimeType.contains("excel") { return "tablecells.fill" }
        if mimeType.contains("document") || mimeType.contains("word") { return "doc.text.fill" }
        if mimeType.contains("presentation") || mimeType.contains("powerpoint") { return "play.rectangle.fill" }
        if mimeType.contains("video") { return "video.fill" }
        if mimeType.contains("audio") { return "music.note" }
        return "doc.fill"
    }
    
    private func colorForMimeType(_ mimeType: String) -> Color {
        if mimeType.contains("pdf") { return .red }
        if mimeType.contains("image") { return .blue }
        if mimeType.contains("spreadsheet") { return .green }
        if mimeType.contains("document") { return .blue }
        return AppColors.primary
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
```

#### 3. Add Drive Navigation
**Option A:** Add Drive Tab to TabView (if space available)

**File:** `Views/ContentView.swift` or main TabView file

```swift
TabView(selection: $selectedTab) {
    // ... existing tabs (Inbox, Calendar, Settings)
    
    DriveListView()
        .tabItem {
            Label("Drive", systemImage: "folder")
        }
        .tag(Tab.drive) // Add new Tab.drive case to enum
}
```

**Option B:** Add Drive Section to Settings (if no space for new tab)

**File:** `Views/Settings/SettingsView.swift`

```swift
Section {
    NavigationLink(destination: DriveListView()) {
        Label("Drive Files", systemImage: "folder")
    }
} header: {
    Text("Storage")
}
```

---

### What to REMOVE ❌

#### Remove "Save to Drive" Button from EmailDetailView
**File:** `Views/Detail/EmailDetailView.swift`

**Find and REMOVE or COMMENT OUT:**
```swift
// REMOVE THIS ENTIRE SECTION:
// ForEach(attachmentIndices(for: body), id: \.self) { index in
//     SecondaryButton(
//         title: "Save to Drive",
//         systemImage: "arrow.up.doc",
//         action: { await saveToDrive(attachmentIndex: index) }
//     )
// }
```

**Or just comment it out:**
```swift
// TODO: Re-enable when email body endpoint works
// ForEach(attachmentIndices(for: body), id: \.self) { index in
//     SecondaryButton(...) 
// }
```

---

## Design System Compliance

**Must use:**
- `AppColors` for colors
- `AppSpacing` for padding
- `AppTypography` for text
- Skeleton shimmer for loading (`.redacted(reason: .placeholder)`)
- `EmptyStateView` for empty state (if available)

---

## Files to Create/Update

```
drive-ios-view-only/
├── README.md
├── ios/
│   ├── Services/
│   │   └── DriveService.swift         # Already exists, use as-is
│   ├── Models/
│   │   └── DriveModels.swift          # Already exists, use as-is
│   └── Views/
│       ├── Drive/
│       │   ├── DriveListView.swift    # CREATE - full implementation
│       │   └── DriveFileRow.swift     # CREATE - file row component
│       ├── ContentView.swift          # UPDATE - add Drive tab (Option A)
│       └── Settings/
│           └── SettingsView.swift     # UPDATE - add Drive link (Option B)
└── INTEGRATION.md
```

---

## Testing

**Before marking complete:**
1. App builds without errors
2. DriveListView accessible (tab or Settings)
3. Loading state shows skeleton
4. Empty state shows message
5. Files list displays correctly
6. Tap file → opens in Google Drive app
7. Pull to refresh works
8. EmailDetailView has NO Drive button

---

## Success Criteria

✅ DriveListView shows list of Drive files
✅ Tap file opens in Google Drive app
✅ Loading state (skeleton shimmer)
✅ Empty state (friendly message)
✅ Pull to refresh works
✅ "Save to Drive" button removed from EmailDetailView
✅ App builds without errors
✅ Design System used consistently

---

## Notes

- **Demo focus:** Browse Drive files, open in Drive app
- **Skip:** Upload functionality (email body broken)
- **Backend:** Already fixed by other agent (list files working)
- **Test location:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/`

---

**Good luck! 🔥**
