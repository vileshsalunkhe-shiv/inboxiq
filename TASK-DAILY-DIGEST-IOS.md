# Task: Daily Digest Email - iOS UI

**Agent:** DEV-MOBILE-premium
**Priority:** HIGH (Partner demo tomorrow)
**Time Estimate:** 2-3 hours
**Output Directory:** `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/daily-digest-ios/`

---

## Objective
Implement iOS UI for daily digest feature. Users can configure digest preferences and send test digest emails from Settings.

---

## Requirements

### 1. Daily Digest Settings Section
**Location:** Add to Settings tab (existing SettingsView)

**UI Components:**
- Section header: "Daily Digest" with icon (📧 or 📨)
- Toggle: "Enable Daily Digest" (on by default)
- Time picker: "Preferred Time" (default 7:00 AM)
- Button: "Send Test Digest Now" (primary button)
- Text: "Last sent: [timestamp]" or "Never sent" (small, gray text)
- Info text: "Receive a daily email summary of your inbox and calendar"

**Layout:**
```
┌─────────────────────────────┐
│ Daily Digest        📧      │
├─────────────────────────────┤
│ Enable Daily Digest    [ON] │
│                             │
│ Preferred Time              │
│ [7:00 AM            ▼]     │
│                             │
│ ┌─────────────────────────┐ │
│ │  Send Test Digest Now   │ │
│ └─────────────────────────┘ │
│                             │
│ Last sent: Today at 7:00 AM │
│                             │
│ ℹ️ Receive a daily summary  │
│   of your inbox and calendar│
└─────────────────────────────┘
```

### 2. Digest Service
**File:** `Services/DigestService.swift`

**Methods:**
```swift
class DigestService {
    // Preview digest HTML (for future preview screen)
    func previewDigest() async throws -> DigestPreview
    
    // Send digest email now
    func sendDigest() async throws -> DigestResult
    
    // Get user preferences (optional if backend provides it)
    func getPreferences() async throws -> DigestPreferences
    
    // Update user preferences (optional if backend provides it)
    func updatePreferences(_ prefs: DigestPreferences) async throws
}
```

**Models:**
```swift
struct DigestPreview: Codable {
    let html: String
    let generatedAt: Date
    let emailCount: Int
    let calendarEventCount: Int
}

struct DigestResult: Codable {
    let success: Bool
    let messageId: String?
    let sentAt: Date
    let recipient: String
}

struct DigestPreferences: Codable {
    var enabled: Bool
    var preferredTime: Date  // Store as HH:mm time
    var lastSentAt: Date?
}
```

**API Integration:**
- `GET /api/digest/preview` → `previewDigest()`
- `POST /api/digest/send` → `sendDigest()`
- Use existing `APIClient.swift` patterns (JWT auth, error handling)

### 3. Settings View Updates
**File:** `Views/Settings/SettingsView.swift`

**Changes:**
- Add new section between existing sections
- Import `DigestService`
- Add state variables:
  - `@State private var digestEnabled: Bool = true`
  - `@State private var preferredTime: Date = Date()`
  - `@State private var lastSentAt: Date?`
  - `@State private var isSending: Bool = false`
  - `@State private var showSuccessToast: Bool = false`
  - `@State private var showErrorToast: Bool = false`
  - `@State private var toastMessage: String = ""`

**Button Behavior:**
1. User taps "Send Test Digest Now"
2. Show loading state (disable button, show spinner)
3. Call `DigestService.sendDigest()`
4. On success:
   - Update `lastSentAt` timestamp
   - Show success toast: "Digest sent to your email!"
   - Re-enable button
5. On error:
   - Show error toast: "Failed to send digest. Try again."
   - Re-enable button

**Time Picker:**
- Display only hours and minutes (no date)
- Use `.wheel` style for better UX
- Format: "7:00 AM" (12-hour with AM/PM)
- Save preference when user changes time (debounce if backend API exists)

### 4. Toast Notifications
**Use Existing ToastView:**
- Success: Green background, checkmark icon
- Error: Red background, exclamation icon
- Duration: 3 seconds auto-dismiss

### 5. Design System Consistency
**Must Use:**
- `PrimaryButton` for "Send Test Digest Now" button
- `AppColors` for colors
- `AppTypography` for text styles
- `AppSpacing` for margins/padding
- Consistent with existing Settings sections

---

## Technical Constraints

### DO NOT BREAK EXISTING FUNCTIONALITY
- Do not modify existing Settings sections (Profile, Notifications, etc.)
- Do not modify existing Services (AuthViewModel, SyncService, etc.)
- Only ADD new code to SettingsView
- Ensure app still builds and runs after changes

### Error Handling
- Handle network errors gracefully
- Handle 401 (token expired) → show re-login prompt
- Handle 429 (rate limit) → show "Try again in a few minutes"
- Handle 500 (server error) → show "Something went wrong"

### Persistence (Optional)
- Digest preferences can be stored in UserDefaults temporarily
- Backend will persist `lastSentAt` (fetch on Settings load)
- Time picker value syncs with UserDefaults

---

## Output Structure

Create this directory structure in your output folder:

```
daily-digest-ios/
├── README.md                           # What you built, how to integrate
├── ios/
│   ├── Services/
│   │   └── DigestService.swift        # New service for digest API
│   ├── Models/
│   │   └── DigestModels.swift         # Codable structs
│   └── Views/
│       └── Settings/
│           └── SettingsView.swift     # Updated with digest section
└── INTEGRATION.md                     # Step-by-step integration instructions
```

---

## Testing Requirements

Before marking complete, test:
1. **UI renders correctly:** Digest section appears in Settings
2. **Toggle works:** Enable/disable digest preference
3. **Time picker works:** Change time, value updates
4. **Send button works:** Tapping button calls API
5. **Loading state:** Button shows spinner while sending
6. **Success flow:** Toast shows, lastSentAt updates
7. **Error flow:** Toast shows error message
8. **No regressions:** Other Settings sections still work

**Test on iOS Simulator:**
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ
xcodebuild -scheme InboxIQ -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

---

## Integration Steps (For Later)

1. Copy files to main iOS project:
   ```bash
   cp ios/Services/DigestService.swift \
     /path/to/ios/InboxIQ/InboxIQ/Services/
   
   cp ios/Models/DigestModels.swift \
     /path/to/ios/InboxIQ/InboxIQ/Models/
   
   # Manually merge SettingsView changes (don't overwrite entire file)
   ```

2. Add files to Xcode project (if not auto-detected)

3. Build and test on simulator

4. Test on physical device (optional)

---

## Dependencies

**Already Available:**
- `APIClient.swift` (for network requests)
- `ToastView.swift` (for notifications)
- Design System components (PrimaryButton, AppColors, etc.)
- `SettingsView.swift` (extend this file)

**No New Dependencies Required**

---

## Success Criteria

✅ Daily Digest section renders in Settings
✅ Toggle, time picker, and button work correctly
✅ Send button calls backend API
✅ Success and error states display properly
✅ Toast notifications work
✅ No existing functionality broken
✅ Design System applied consistently
✅ README and integration docs complete

---

## UI/UX Notes

**User Flow:**
1. User opens Settings → sees Daily Digest section
2. User taps "Send Test Digest Now"
3. Button shows loading state
4. Email sends in background
5. Toast confirms: "Digest sent to your email!"
6. User checks their email → sees formatted digest

**Edge Cases:**
- If backend returns 401 → show "Please log in again"
- If no network → show "Check your internet connection"
- If digest already sent today → still allow (it's a test button)

**Future Enhancements (Not Required Now):**
- Preview digest HTML in app (WebView modal)
- Schedule digest for specific time (push notification)
- Customize digest content (select categories)

---

## Notes

- **Backend endpoints:** DEV-BE-premium is building these in parallel
- **API base URL:** https://inboxiq-production-5368.up.railway.app
- **Test user:** vilesh.salunkhe@gmail.com (JWT token from AuthViewModel)
- **Existing code references:**
  - `Services/APIClient.swift` - Network patterns
  - `Views/Settings/SettingsView.swift` - Settings UI structure
  - `DesignSystem/` - All design components

**Priority:** Get UI and API integration working first, preferences persistence can be simplified if time is tight.

**Questions?** Document them in README.md and continue with best judgment.

---

**Good luck! 🔥**
