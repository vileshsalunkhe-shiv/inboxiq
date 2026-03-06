# Three Remaining Fixes - 2026-03-05 09:45 CST

## Issue #1: Emails not loading automatically on login ✅ WILL FIX
**Problem:** User has to manually tap "Sync" button after login  
**Root Cause:** No auto-sync triggered after authentication

**Fix:** Add `.task` modifier to HomeView to sync on appear

```swift
// In HomeView.swift, add after NavigationStack closing brace:
.task {
    await emailViewModel.refresh(context: viewContext)
}
```

**Location:** After line ~118 in `/ios/InboxIQ/InboxIQ/Views/Home/HomeView.swift`

---

## Issue #2: HTML tags showing in email body ✅ WILL FIX
**Problem:** Email previews showing raw HTML like `&quot;`, `&#39;`, etc.

**Root Cause:** Backend sends HTML entities in `body_preview`, iOS displays them as-is

**Fix:** Strip HTML and decode entities when saving to CoreData

Add this helper to SyncService:

```swift
private func stripHTML(_ html: String) -> String {
    // Remove HTML tags
    var text = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    
    // Decode common HTML entities
    text = text
        .replacingOccurrences(of: "&quot;", with: "\"")
        .replacingOccurrences(of: "&#39;", with: "'")
        .replacingOccurrences(of: "&amp;", with: "&")
        .replacingOccurrences(of: "&lt;", with: "<")
        .replacingOccurrences(of: "&gt;", with: ">")
        .replacingOccurrences(of: "&nbsp;", with: " ")
        .replacingOccurrences(of: "&#x27;", with: "'")
    
    // Remove excessive whitespace
    text = text.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
    text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
    
    return text.trimmingCharacters(in: .whitespacesAndNewlines)
}
```

Then use it:
```swift
email.snippet = stripHTML(emailPayload.snippet ?? "")
```

**Location:** `/ios/InboxIQ/InboxIQ/Services/SyncService.swift` around line 140

---

## Issue #3: Not showing latest emails ✅ NEED TO CHECK
**Problem:** Latest emails not appearing after sync

**Possible causes:**
1. Date parsing failing (returning nil, defaulting to current date)
2. Sync only fetching old emails from backend
3. CoreData not refreshing UI after save

**Debug steps:**
1. Check Xcode console for date parsing errors
2. Verify backend returns latest emails in curl test
3. Check if CoreData save is calling `try viewContext.save()`

**Most likely:** Date parsing issue. Current code:

```swift
if let date = self.parseDate(emailPayload.receivedAt) {
    email.receivedAt = date
} else {
    email.receivedAt = Date()  // Falls back to NOW
}
```

If parsing fails, ALL emails get current date → all sort to top → confusing order.

**Check parseDate() function** - Verify it handles backend's ISO8601 format:
```
"2026-03-05T15:22:25"
```

---

## Apply All Fixes

**File 1: HomeView.swift** - Auto-sync on login
**File 2: SyncService.swift** - Strip HTML from snippets
**File 3: SyncService.swift** - Verify date parsing

---

**Next:** I'll apply fixes #1 and #2 now, then we'll debug #3 based on console logs.
