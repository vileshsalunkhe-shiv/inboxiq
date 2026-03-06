# Today's Plan - March 5, 2026

**Goal:** Build email action UIs  
**Backend:** Already complete (8 APIs ready) ✅  
**Focus:** iOS UI development

---

## Email Action UIs to Build (Priority Order)

### 1. Archive/Delete/Star (Swipe Actions) - 2 hours
**Backend APIs:** ✅ Ready (`POST /{id}/archive`, `DELETE /{id}`, `PUT /{id}/star`)

**iOS Work:**
- Add swipe actions to email list cells
- Archive (left swipe → "Archive" button)
- Delete (left swipe → "Delete" button)
- Star/unstar (right swipe → star icon)
- Confirmation dialog for delete
- Update UI after action
- Error handling

**Files to modify:**
- `Views/Inbox/EmailListView.swift`
- `Views/Inbox/EmailRowView.swift`

---

### 2. Compose Email UI - 2 hours
**Backend API:** ✅ Ready (`POST /emails/compose`)

**iOS Work:**
- Create `ComposeEmailView.swift`
- Fields: To, Subject, Body
- Attachment picker (optional)
- Send button
- Cancel button (confirmation if draft)
- Loading indicator while sending
- Success/error messages
- Navigate to Inbox after send

**New files:**
- `Views/Email/ComposeEmailView.swift`

**Integration:**
- Add "Compose" button to Inbox toolbar
- Modal presentation

---

### 3. Reply/Reply All UI - 2 hours
**Backend API:** ✅ Ready (`POST /emails/{id}/reply`)

**iOS Work:**
- Create `ReplyEmailView.swift`
- Pre-fill: To (original sender), Subject (Re: ...)
- Quote original message
- Reply / Reply All toggle
- Send button
- Cancel button
- Loading/success/error states

**New files:**
- `Views/Email/ReplyEmailView.swift`

**Integration:**
- Add Reply button to email detail view
- Modal presentation

---

### 4. Forward Email UI - 1 hour
**Backend API:** ✅ Ready (`POST /emails/{id}/forward`)

**iOS Work:**
- Create `ForwardEmailView.swift`
- Fields: To (empty), Subject (Fwd: ...)
- Quote original message (with "--- Forwarded Message ---")
- Attachment handling (if original had attachments)
- Send button
- Cancel button

**New files:**
- `Views/Email/ForwardEmailView.swift`

**Integration:**
- Add Forward button to email detail view

---

## Testing After Each Feature

**Manual test checklist:**
- [ ] UI renders correctly
- [ ] API call succeeds
- [ ] UI updates after action
- [ ] Error handling works
- [ ] Loading states display
- [ ] Success confirmation shown

---

## End of Day Goal

**Minimum viable email actions:**
- ✅ Archive email (swipe)
- ✅ Delete email (swipe + confirmation)
- ✅ Star email (swipe)
- ✅ Compose new email
- ✅ Reply to email
- ✅ Forward email

**Total time estimate:** 6-8 hours (full day)

---

## Tomorrow (March 6)

**If email actions complete today:**
- Calendar CRUD APIs (backend)
- Calendar event creation UI (iOS)
- Calendar event editing UI (iOS)

**If email actions incomplete:**
- Finish remaining email UIs
- Test thoroughly
- Then move to calendar

---

## Agent Strategy

**Option A: Manual Development**
- You build each UI yourself in Xcode
- Faster for simple views
- Full control

**Option B: Sub-Agent Development**
- Spawn DEV-MOBILE-premium for each UI
- Faster for complex views
- Review code before integration

**Option C: Hybrid**
- You build simple ones (archive/delete/star)
- Agent builds complex ones (compose/reply/forward)

**Your choice - let me know which approach you prefer.**

---

## Notes

- Backend APIs all tested and working ✅
- Design system ready for new views ✅
- Email action schemas defined ✅
- Just need iOS UI layer

**This is the critical week - all core features must be done by Friday (March 9).**
