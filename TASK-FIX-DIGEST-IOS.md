# Task: Fix Daily Digest iOS Issues

**Agent:** DEV-MOBILE-premium
**Priority:** HIGH (Demo tomorrow)
**Time Estimate:** 15-20 minutes
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/daily-digest-ios-fixes/`

---

## Objective
Fix high-priority UX issue found in Sundar's review WITHOUT breaking existing functionality.

---

## Issue to Fix

### HIGH PRIORITY: UI Flicker on Settings Load ⚠️

**Issue:** When the Settings view appears, it shows default values (enabled=true, time=7:00 AM) while fetching actual preferences from the backend. If the user's actual preference is different, the UI flickers as values change. This looks unprofessional during a demo.

**Fix:** Add a loading state that shows a `ProgressView` while preferences are being fetched for the first time.

**File:** `ios/Views/Settings/SettingsView.swift`

**Changes:**

```swift
// Add new @State variable at top of SettingsView
@State private var isLoadingPreferences: Bool = true

// Update the .task modifier
.task {
    await loadPreferences()
    isLoadingPreferences = false  // Set to false after loading
}

// Wrap the Daily Digest section in a loading check
Section {
    if isLoadingPreferences {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
        .padding()
    } else {
        // Existing Daily Digest section content
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable Daily Digest", isOn: $digestEnabled)
                .tint(AppColors.primary)
            
            // ... rest of existing content
        }
    }
} header: {
    Label("Daily Digest", systemImage: "envelope.fill")
}
```

**Alternative (Better UX):** Show a skeleton/redacted view instead of ProgressView:

```swift
if isLoadingPreferences {
    VStack(alignment: .leading, spacing: 12) {
        // Skeleton toggle
        HStack {
            Text("Enable Daily Digest")
                .redacted(reason: .placeholder)
            Spacer()
        }
        
        // Skeleton time picker
        Text("Preferred Time")
            .redacted(reason: .placeholder)
        
        // Skeleton button
        Button {} label: {
            Text("Send Test Digest Now")
        }
        .disabled(true)
        .redacted(reason: .placeholder)
    }
} else {
    // Existing content
}
```

---

## CRITICAL CONSTRAINTS

### DO NOT BREAK EXISTING FUNCTIONALITY
- **Only modify SettingsView.swift Daily Digest section**
- **Do not touch other Settings sections (Profile, Notifications, etc.)**
- **Do not modify existing Services (AuthViewModel, SyncService, EmailActionService, etc.)**
- **Do not change navigation or tab structure**
- **Test that other Settings sections still work**

### Files You Can Modify
✅ `ios/Views/Settings/SettingsView.swift` (ONLY Daily Digest section)
✅ `ios/Services/DigestService.swift` (if needed for error handling)
✅ `ios/Models/DigestModels.swift` (if needed)

### Files You CANNOT Modify
❌ `ios/Views/Home/HomeView.swift`
❌ `ios/Views/Home/EmailListView.swift`
❌ `ios/Views/Detail/EmailDetailView.swift`
❌ `ios/Services/SyncService.swift`
❌ `ios/Services/EmailActionService.swift`
❌ `ios/Services/APIClient.swift`
❌ `ios/ViewModels/AuthViewModel.swift`

---

## Output Structure

Create this directory structure in your output folder:

```
daily-digest-ios-fixes/
├── README.md                           # What was fixed
├── ios/
│   └── Views/
│       └── Settings/
│           └── SettingsView.swift     # UPDATED with loading state
└── INTEGRATION.md                     # How to apply fixes
```

---

## Testing Requirements

Before marking complete, test on iOS Simulator:

1. **Loading state appears:**
   - Clean build and run app
   - Navigate to Settings tab
   - Verify ProgressView or skeleton appears briefly
   - Verify UI doesn't flicker when preferences load

2. **Settings still work after loading:**
   - Toggle "Enable Daily Digest" → should update
   - Change preferred time → should save
   - Tap "Send Test Digest Now" → should send
   - Verify toast notifications appear

3. **Other Settings sections unaffected:**
   - Profile section still works
   - Notifications section still works
   - Navigation still works
   - No crashes or errors

4. **Error handling still works:**
   - Disconnect internet
   - Navigate to Settings
   - Verify loading state times out gracefully
   - Verify error message appears

---

## Success Criteria

✅ Loading state appears when fetching preferences
✅ No UI flicker when preferences load
✅ All Settings functionality still works
✅ Other Settings sections unaffected
✅ App builds without errors
✅ README and integration docs complete

---

## Design System Consistency

**Must use existing components:**
- `ProgressView()` or `.redacted(reason: .placeholder)` for loading
- `AppColors.primary` for tint colors
- `AppSpacing` for padding/margins
- `AppTypography` for text styles

**Do not:**
- Create custom loading spinners
- Use hard-coded colors
- Break existing Design System patterns

---

## Notes

- **Original file location:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/daily-digest-ios/ios/Views/Settings/SettingsView.swift`
- **Sundar's review:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SUNDAR-DIGEST-REVIEW.md`
- **Test on:** iPhone 15 Pro simulator (iOS 17+)

**This is a simple fix** - should take 10-15 minutes. Focus on making the loading state smooth and professional for the demo.

---

**Good luck! 🔥**
