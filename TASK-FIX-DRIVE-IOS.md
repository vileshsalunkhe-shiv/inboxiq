# Task: Fix Google Drive iOS Issues (Sundar Review)

**Agent:** DEV-MOBILE-premium  
**Priority:** CRITICAL (Demo tomorrow - demo-breaking bug)
**Time Estimate:** 20-30 minutes
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/drive-ios-fixes/`

---

## Objective
Fix critical demo-breaking bug and medium-priority UX issue found in Sundar's iOS review.

**READ:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SUNDAR-DRIVE-REVIEW.md`

---

## Issues to Fix

### 1. CRITICAL: Hardcoded Attachment Logic 🔴 DEMO-BREAKING

**File:** `drive-ios/ios/Views/Detail/EmailDetailView.swift`

**Issue:** Hardcoded logic shows only "Attachment 1" regardless of actual attachments.

**Current broken code:**
```swift
private func attachmentIndices(for body: EmailBody) -> [Int] {
    return body.hasAttachments ? [0] : []
}
```

**NOTE:** This issue is BLOCKED by backend email body endpoint (currently returns 404 due to Gmail rate limiting).

**Workaround for Demo:**
Since email body endpoint is not working yet, we need a **temporary solution**:

**Option A (Recommended):** **Disable "Save to Drive" button until email body works**
```swift
SecondaryButton(
    title: "Save to Drive (Coming Soon)",
    systemImage: "arrow.up.doc",
    action: { }
)
.disabled(true) // Always disabled until backend ready
.opacity(0.5)
```

**Option B:** **Remove Drive button entirely from EmailDetailView** for now
```swift
// Comment out or remove the entire Drive section
```

**Future Fix (when backend ready):**
```swift
// This will work once backend returns attachment metadata
private func attachmentIndices(for body: EmailBody) -> [Int] {
    return Array(body.attachments.indices)
}

private func attachmentTitle(for index: Int) -> String {
    return body.attachments[index].filename
}

// ForEach over actual attachments
ForEach(body.attachments.indices, id: \.self) { index in
    SecondaryButton(
        title: attachmentTitle(for: index),
        systemImage: "arrow.up.doc",
        action: { await saveToDrive(attachmentIndex: index) }
    )
}
```

### 2. MEDIUM: Missing Loading State for Full Body

**File:** `drive-ios/ios/Views/Detail/EmailDetailView.swift`

**Issue:** Button can be tapped before email body loads.

**Fix:**
```swift
// In the "Save to Drive" button section:
SecondaryButton(
    title: "Save to Drive",
    systemImage: "arrow.up.doc",
    action: { await saveToDrive(attachmentIndex: index) }
)
.disabled(isSavingToDrive || isLoadingBody) // ← ADD isLoadingBody check
```

---

## Recommended Approach for Demo

**Given that email body endpoint is NOT working yet (404 errors):**

1. **Disable Drive button** with "Coming Soon" text
2. **OR remove Drive section** entirely from EmailDetailView
3. **Focus demo on:** Daily Digest (working), Email Actions (working), Calendar (working)
4. **Mention Drive as "upcoming feature"** during demo

**This avoids demo-breaking errors while still showing the feature roadmap.**

---

## Output Structure

```
drive-ios-fixes/
├── README.md                           # What was fixed
├── ios/
│   └── Views/
│       └── Detail/
│           └── EmailDetailView.swift  # UPDATED (disable button or remove section)
└── INTEGRATION.md                     # How to apply
```

---

## Testing

**After fixes, verify:**
1. App builds without errors
2. Email detail view opens normally
3. Drive button is disabled (or removed)
4. No crashes when viewing emails
5. All other features still work (archive, star, compose)

---

## Notes

- **Root cause:** Email body backend endpoint blocked by Gmail rate limiting
- **Status:** Documented in LINEAR-ISSUE-EMAIL-BODY.md
- **Timeline:** Fix rate limiting first, then enable Drive button
- **For demo:** Show Drive as upcoming feature, don't risk crashes

---

**PRIORITY:** Disable or remove Drive button to prevent demo crashes.

**Good luck! 🔥**
