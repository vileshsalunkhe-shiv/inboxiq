# Task: Build Email Action UIs
**Agent:** DEV-MOBILE-premium  
**Due:** Today (6-8 hours)  
**Priority:** Critical (MVP blocker)

---

## Context

**Backend APIs:** ✅ All complete (8 endpoints in `/backend/app/api/emails.py`)  
**Design System:** ✅ Available (`/ios/InboxIQ/InboxIQ/DesignSystem/`)  
**Current State:** Read-only app (can view emails, cannot interact)  
**Goal:** Make app interactive (compose, reply, forward, archive, delete, star)

---

## Deliverables (6 UIs)

### 1. Email Swipe Actions (Archive, Delete, Star)
**Location:** Modify `Views/Inbox/EmailListView.swift` or `EmailRowView.swift`

**Requirements:**
- Left swipe → Archive button (purple)
- Left swipe → Delete button (red, requires confirmation dialog)
- Right swipe → Star/Unstar toggle (gold star icon)
- Update email list after action (remove archived/deleted, update star state)
- Loading indicator during API call
- Error toast if API fails
- Success haptic feedback

**Backend APIs:**
- `POST /emails/{email_id}/archive` → 200 OK
- `DELETE /emails/{email_id}` → 204 No Content
- `PUT /emails/{email_id}/star` → 200 OK (body: `{"starred": true/false}`)

---

### 2. Compose Email View
**New file:** `Views/Email/ComposeEmailView.swift`

**Requirements:**
- Navigation bar: Cancel (left), Send (right, disabled until valid)
- Fields:
  - To: TextField (comma-separated emails, EmailStr validation)
  - Subject: TextField
  - Body: TextEditor (multi-line)
- Optional: Attachment picker (use Base64 encoding)
- Send button triggers API call
- Loading spinner while sending
- Success → dismiss view, show toast "Email sent"
- Error → show alert with error message
- Cancel → show confirmation if draft has content

**Backend API:**
- `POST /emails/compose`
- Body: `{"to": ["email@example.com"], "subject": "...", "body": "...", "attachments": [...]}`
- Response: 200 OK

**Integration:**
- Add "Compose" button to Inbox toolbar (top-right, pencil icon)
- Present as modal sheet

---

### 3. Reply Email View
**New file:** `Views/Email/ReplyEmailView.swift`

**Requirements:**
- Navigation bar: Cancel, Send
- Pre-filled fields:
  - To: Original sender email
  - Subject: "Re: [original subject]"
- Reply/Reply All toggle (segmented control)
- Body: TextEditor (empty, cursor at top)
- Quote original message below (gray background, smaller font)
- Format: "On [date], [sender] wrote: > [original body]"
- Send button triggers API call
- Success → dismiss, show toast "Reply sent"

**Backend API:**
- `POST /emails/{email_id}/reply`
- Body: `{"reply_all": false, "body": "..."}`
- Response: 200 OK

**Integration:**
- Add Reply button to email detail view (toolbar)
- Present as modal sheet

---

### 4. Forward Email View
**New file:** `Views/Email/ForwardEmailView.swift`

**Requirements:**
- Navigation bar: Cancel, Send
- Fields:
  - To: Empty TextField (comma-separated emails)
  - Subject: Pre-filled "Fwd: [original subject]"
  - Body: TextEditor (empty, cursor at top)
- Quote original message below:
  - Header: "---------- Forwarded message ---------"
  - From: [sender]
  - Date: [date]
  - Subject: [subject]
  - Body: [original body]
- Optional: Show original attachments (if any)
- Send button triggers API call
- Success → dismiss, show toast "Email forwarded"

**Backend API:**
- `POST /emails/{email_id}/forward`
- Body: `{"to": ["email@example.com"], "body": "...", "attachments": [...]}`
- Response: 200 OK

**Integration:**
- Add Forward button to email detail view (toolbar)
- Present as modal sheet

---

### 5. Mark Read/Unread
**Location:** Email detail view or swipe action

**Requirements:**
- Toggle read/unread status
- Update UI (bold/unbold title in list)
- Update badge count (if shown)
- API call in background
- Error → revert UI change, show toast

**Backend API:**
- `PUT /emails/{email_id}/read` → Body: `{"read": true/false}` → 200 OK

**Integration:**
- Option A: Add to swipe actions (secondary action)
- Option B: Add to email detail toolbar
- Your choice

---

### 6. Confirmation Dialogs
**New file (optional):** `Views/Email/EmailActionConfirmation.swift`

**Requirements:**
- Delete confirmation:
  - Title: "Delete Email?"
  - Message: "This email will be permanently deleted."
  - Buttons: "Cancel" (default), "Delete" (destructive)
- Draft confirmation (Compose/Reply/Forward):
  - Title: "Discard Draft?"
  - Message: "Your draft will not be saved."
  - Buttons: "Cancel", "Discard" (destructive)

---

## Design System Integration

**Use existing design system:**
- Colors: `AppColor.primary`, `.secondary`, `.error`, `.success`
- Typography: `AppTypography.body`, `.headline`, `.caption`
- Spacing: `AppSpacing.medium`, `.large`
- Components: Reuse if available (buttons, text fields)

**Reference:**
- `/ios/InboxIQ/InboxIQ/DesignSystem/Colors.swift`
- `/ios/InboxIQ/InboxIQ/DesignSystem/Typography.swift`
- `/ios/InboxIQ/InboxIQ/DesignSystem/Spacing.swift`

---

## API Integration

**Base URL:** `https://inboxiq-production-5368.up.railway.app` (or localhost for testing)

**Authentication:**
- Include JWT token in Authorization header
- Token stored in UserDefaults (key: "auth_token")
- Handle 401 Unauthorized → sign out user

**Error Handling:**
- Network errors → "No internet connection"
- 400 Bad Request → Show error message from API
- 401 Unauthorized → Sign out user
- 500 Server Error → "Something went wrong. Please try again."

**Example API Call (Swift):**
```swift
func archiveEmail(emailId: String) async throws {
    let url = URL(string: "\(baseURL)/emails/\(emailId)/archive")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    
    let (_, response) = try await URLSession.shared.data(for: request)
    guard (response as? HTTPURLResponse)?.statusCode == 200 else {
        throw EmailError.archiveFailed
    }
}
```

---

## Testing Requirements

**For each UI, test:**
- [ ] UI renders correctly (light + dark mode)
- [ ] API call succeeds
- [ ] Loading state displays
- [ ] Success state updates UI
- [ ] Error state shows message
- [ ] Cancel/back navigation works
- [ ] Keyboard dismisses appropriately

---

## File Structure

**New files to create:**
```
ios/InboxIQ/InboxIQ/
  Views/
    Email/
      ComposeEmailView.swift          (new)
      ReplyEmailView.swift            (new)
      ForwardEmailView.swift          (new)
      EmailActionConfirmation.swift   (new, optional)
  Services/
    EmailActionService.swift          (new, handles API calls)
```

**Files to modify:**
```
ios/InboxIQ/InboxIQ/
  Views/
    Inbox/
      EmailListView.swift             (add swipe actions)
      EmailRowView.swift              (swipe action handlers)
      EmailDetailView.swift           (add reply/forward buttons)
```

---

## Success Criteria

**Definition of Done:**
1. All 6 UIs implemented
2. All backend API integrations working
3. Design system used consistently
4. Error handling complete
5. User feedback (toasts, alerts) implemented
6. Code builds without errors
7. Basic manual testing passed

---

## Notes

- Backend APIs already tested and working ✅
- Email schemas defined in `app/schemas/email_actions.py` ✅
- Use existing `AuthViewModel` pattern for API calls
- Reuse `CategoryBadge` style for buttons (if appropriate)

---

## Time Estimate

- Swipe actions: 1.5 hours
- Compose view: 1.5 hours
- Reply view: 1.5 hours
- Forward view: 1 hour
- Mark read/unread: 0.5 hours
- Confirmation dialogs: 0.5 hours
- API service layer: 1 hour
- Testing + fixes: 1 hour

**Total:** 6-8 hours

---

**Agent: Start working. Output to `/projects/inboxiq/ios-email-actions/` when complete.**
