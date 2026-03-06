# Task: Email Body iOS UI

**Agent:** DEV-MOBILE-premium  
**Estimated Time:** 1-2 hours  
**Output Location:** `/projects/inboxiq/ios-email-body/`

## Context

InboxIQ iOS app currently shows email snippets in the inbox list and detail view. We need to add a "Load Full Email" button that fetches and displays the complete email body.

## Current State

**EmailDetailView:** Shows AI summary, snippet, sender, date, action buttons  
**API Integration:** Working JWT auth + email sync  
**Design System:** Custom button styles available in `DesignSystem/`

## Requirements

### 1. EmailDetailView Enhancement

**Location:** `ios/InboxIQ/InboxIQ/Views/Home/EmailDetailView.swift`

**Current Layout:**
```
- Header (from, to, date)
- AI Summary section
- Body snippet
- Action buttons (Reply, Forward, Archive, etc.)
```

**New Layout:**
```
- Header (from, to, date)
- AI Summary section
- Body snippet (short preview)
- "Load Full Email" button  ← NEW
- Full body content (when loaded) ← NEW
- Action buttons (Reply, Forward, Archive, etc.)
```

### 2. "Load Full Email" Button

**Design:**
- Style: `ButtonStyle.secondary` (from design system)
- Icon: SF Symbol `doc.text` or `arrow.down.doc`
- Label: "Load Full Email"
- Position: Below snippet, above action buttons
- State: Show/hide based on whether full body loaded

**Button States:**
- **Before loading:** "Load Full Email" (enabled)
- **Loading:** "Loading..." (disabled, with spinner)
- **After loading:** Hide button (body now visible)

### 3. New Service: EmailBodyService

**Location:** `ios/InboxIQ/InboxIQ/Services/EmailBodyService.swift` (new file)

**Purpose:** Fetch full email body from backend API

**API Endpoint:** `GET /api/emails/{email_id}/body`

**Response Model:**
```swift
struct EmailBody: Codable {
    let emailId: String
    let bodyText: String?
    let bodyHtml: String?
    let hasAttachments: Bool
    let fetchedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case emailId = "email_id"
        case bodyText = "body_text"
        case bodyHtml = "body_html"
        case hasAttachments = "has_attachments"
        case fetchedAt = "fetched_at"
    }
}
```

**Service Method:**
```swift
class EmailBodyService {
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    func fetchEmailBody(emailId: String) async throws -> EmailBody {
        let endpoint = "/api/emails/\(emailId)/body"
        let response: EmailBody = try await apiClient.request(
            endpoint: endpoint,
            method: "GET"
        )
        return response
    }
}
```

### 4. EmailDetailView State Management

**Add State Variables:**
```swift
@State private var fullBody: EmailBody?
@State private var isLoadingBody = false
@State private var bodyLoadError: String?
```

**Add Service:**
```swift
private let bodyService = EmailBodyService()
```

**Add Load Method:**
```swift
private func loadFullBody() async {
    isLoadingBody = true
    bodyLoadError = nil
    
    do {
        fullBody = try await bodyService.fetchEmailBody(emailId: email.id)
    } catch {
        bodyLoadError = "Failed to load email body: \(error.localizedDescription)"
    }
    
    isLoadingBody = false
}
```

### 5. Body Content Display

**HTML Rendering (Preferred):**
- Use `WKWebView` for rendering HTML body
- Supports formatted text, images, links
- Proper email styling

**Plain Text Fallback:**
- If HTML not available, show plain text
- Use `Text()` with proper formatting

**Implementation:**
```swift
// After snippet, before action buttons:
if let fullBody = fullBody {
    // Show full body content
    VStack(alignment: .leading, spacing: 12) {
        Divider()
        
        if let html = fullBody.bodyHtml {
            // HTML rendering with WKWebView
            EmailBodyWebView(html: html)
                .frame(minHeight: 200)
        } else if let text = fullBody.bodyText {
            // Plain text fallback
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
        }
        
        if fullBody.hasAttachments {
            Label("This email has attachments", systemImage: "paperclip")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} else if !isLoadingBody {
    // Show "Load Full Email" button
    Button(action: {
        Task {
            await loadFullBody()
        }
    }) {
        Label("Load Full Email", systemImage: "doc.text")
            .frame(maxWidth: .infinity)
    }
    .buttonStyle(.secondary) // Design system style
    .padding(.vertical, 8)
}

if isLoadingBody {
    HStack {
        ProgressView()
        Text("Loading email body...")
            .foregroundColor(.secondary)
    }
    .padding(.vertical, 8)
}

if let error = bodyLoadError {
    Text(error)
        .font(.caption)
        .foregroundColor(.red)
        .padding(.vertical, 4)
}
```

### 6. EmailBodyWebView Component

**Location:** `ios/InboxIQ/InboxIQ/Views/Components/EmailBodyWebView.swift` (new file)

**Purpose:** Render HTML email body using WKWebView

**Implementation:**
```swift
import SwiftUI
import WebKit

struct EmailBodyWebView: UIViewRepresentable {
    let html: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false // Disable internal scrolling
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let styledHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 16px;
                    line-height: 1.5;
                    color: #000000;
                    margin: 0;
                    padding: 16px;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #FFFFFF;
                        background-color: transparent;
                    }
                }
            </style>
        </head>
        <body>
            \(html)
        </body>
        </html>
        """
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }
}
```

### 7. Design System Integration

**Button Style:** Use existing `.secondary` style from design system  
**Colors:** Use `Colors.textPrimary`, `Colors.textSecondary`  
**Typography:** Use `Typography.body` for text  
**Spacing:** Use `Spacing.md` (12pt) for consistent padding

## Deliverables

1. ✅ Modified `EmailDetailView.swift` with button + body display
2. ✅ New `EmailBodyService.swift` with API integration
3. ✅ New `EmailBodyWebView.swift` for HTML rendering
4. ✅ Proper loading states (button → spinner → content)
5. ✅ Error handling and retry logic
6. ✅ Dark mode support for web content

## Testing

**Manual Test Steps:**
1. Open InboxIQ app in simulator
2. Login with test account
3. Tap any email in inbox list
4. Verify: Shows AI summary + snippet + "Load Full Email" button
5. Tap "Load Full Email" button
6. Verify: Button changes to "Loading..." with spinner
7. Wait 1-2 seconds
8. Verify: Full email body appears (formatted HTML)
9. Verify: Button is now hidden
10. Verify: Action buttons still visible below

**Edge Cases:**
- Email with only plain text (no HTML)
- Email with attachments indicator
- Long email body (scrolling)
- Network error during fetch
- Dark mode appearance

## Technical Constraints

- Must use existing `APIClient` for network requests
- Must handle JWT token expiration
- Must support both light and dark mode
- HTML rendering must be responsive (fit screen width)
- Disable WebView internal scrolling (let ScrollView handle it)

## Files to Create/Modify

**New Files:**
- `ios/InboxIQ/InboxIQ/Services/EmailBodyService.swift`
- `ios/InboxIQ/InboxIQ/Views/Components/EmailBodyWebView.swift`

**Modified Files:**
- `ios/InboxIQ/InboxIQ/Views/Home/EmailDetailView.swift`

## Output Format

Place all files in: `/projects/inboxiq/ios-email-body/`

Include:
- All Swift files (full content)
- README.md with integration instructions
- Screenshots or description of changes (optional)

## Success Criteria

- ✅ "Load Full Email" button appears in EmailDetailView
- ✅ Button triggers API call to fetch body
- ✅ Full email body displays after loading
- ✅ HTML emails render properly with formatting
- ✅ Plain text emails display cleanly
- ✅ Loading states work correctly
- ✅ Error messages show for failures
- ✅ Dark mode works for web content
- ✅ Attachments indicator shows when present

---

**Start Time:** 2026-03-05 13:15 CST  
**Expected Completion:** 2026-03-05 14:15-15:15 CST
