# InboxIQ - Feature Complete Plan (Option C)

**Date:** 2026-03-04
**Goal:** Production-ready iOS app for App Store submission
**Timeline:** 1-2 weeks
**Quality Bar:** 5-star App Store experience

---

## 🎯 Complete Feature List

### ✅ Already Built (Phase 1 Complete)

**Authentication:**
- [x] Google OAuth login
- [x] JWT token management
- [x] Secure token storage (Keychain)
- [x] Logout

**Email Core:**
- [x] Fetch emails via Gmail API
- [x] Display inbox (list view)
- [x] Email detail view
- [x] Pull-to-refresh sync
- [x] AI categorization (7 categories)
- [x] Category badges with colors

**Calendar:**
- [x] Fetch Google Calendar events
- [x] Display events (list view)
- [x] Event detail view
- [x] OAuth for calendar scope

**UI Foundation:**
- [x] Tab navigation (Inbox, Calendar, Settings)
- [x] Basic Settings screen
- [x] Category filter UI (7 buttons)

---

## 🚧 Missing Critical Features (Must Build)

### 1. Daily Digest Email 📧

**Backend (Already exists - needs testing):**
- [x] Digest service (`app/services/digest_service.py`)
- [x] Digest settings model (frequency, timezone, preferences)
- [x] Email template (`digest_email.html`)
- [x] Cron job scheduler (needs deployment)

**iOS (Need to build):**
- [ ] **Digest Settings UI** (in Settings tab)
  - Time picker (6am, 9am, 12pm, 3pm, 6pm, 9pm)
  - Frequency selector (Daily, Weekly, Off)
  - Timezone picker
  - Preview digest button
  - Toggle: Include action items
  - Toggle: Include summaries
  - Toggle: Include calendar preview

**Implementation:**
- Settings screen section: "Daily Digest"
- API endpoint: `PUT /digest/settings` (update preferences)
- API endpoint: `POST /digest/preview` (generate preview)
- Test: Send test digest to verify email delivery

**Priority:** P0 (Unique differentiator)
**Timeline:** 1 day (iOS) + 0.5 day (backend testing)

---

### 2. Standard Email Actions ✉️

**iOS Features to Build:**

#### A. Compose New Email
- [ ] **Compose Button** (floating action button on Inbox)
- [ ] **Compose View** (full screen modal)
  - To: field (autocomplete from contacts)
  - Cc/Bcc: fields (collapsible)
  - Subject: field
  - Body: text editor (rich text optional)
  - Attachments button (photo library, files)
  - Send button (validates fields)
  - Cancel button (with confirmation)

#### B. Reply / Reply All / Forward
- [ ] **Reply Button** (in email detail)
- [ ] **Reply All Button** (if multiple recipients)
- [ ] **Forward Button** (in email detail)
- [ ] **Reply View** (similar to compose, pre-filled)
  - Original message quoted
  - Recipient pre-filled
  - Subject: "Re: ..." or "Fwd: ..."

#### C. Email Management Actions
- [ ] **Archive** (swipe left, button in detail)
- [ ] **Delete** (swipe right, button in detail)
- [ ] **Mark Read/Unread** (swipe action, button)
- [ ] **Star/Unstar** (button in detail, list indicator)
- [ ] **Move to Folder** (if Gmail labels)
- [ ] **Spam** (report spam, move to spam folder)

#### D. Bulk Actions
- [ ] **Select Mode** (long-press email to enter)
- [ ] **Multi-select** (tap emails to select)
- [ ] **Bulk Archive** (bottom toolbar)
- [ ] **Bulk Delete** (bottom toolbar)
- [ ] **Bulk Mark Read** (bottom toolbar)
- [ ] **Select All** (button)

**Backend APIs Needed:**
- `POST /emails/compose` (send new email)
- `POST /emails/{id}/reply` (reply to email)
- `POST /emails/{id}/forward` (forward email)
- `POST /emails/{id}/archive` (archive email)
- `DELETE /emails/{id}` (delete email)
- `PUT /emails/{id}/read` (mark read/unread)
- `PUT /emails/{id}/star` (star/unstar)
- `POST /emails/{id}/spam` (report spam)
- `POST /emails/bulk` (bulk operations)

**Gmail API Calls:**
- `users.messages.send` (compose, reply, forward)
- `users.messages.modify` (labels: archive, star, read)
- `users.messages.trash` (delete)
- `users.drafts.create` (save draft)

**Priority:** P0 (Essential email app functionality)
**Timeline:** 3-4 days (iOS) + 2 days (backend)

---

### 3. Calendar Event Management 📅

**iOS Features to Build:**

#### A. Create Event
- [ ] **Create Button** (top-right on Calendar tab)
- [ ] **Create Event View** (full screen modal)
  - Title: text field
  - Date: date picker (all-day toggle)
  - Start Time: time picker
  - End Time: time picker
  - Location: text field (optional)
  - Description: text editor (optional)
  - Add Guests: email autocomplete (optional)
  - Calendar: picker (if multiple calendars)
  - Save button
  - Cancel button

#### B. Edit Event
- [ ] **Edit Button** (in event detail)
- [ ] **Edit Event View** (same as create, pre-filled)
- [ ] **Delete Event** (button in edit view)
- [ ] **Update confirmation** (toast notification)

#### C. Event Actions
- [ ] **RSVP** (Accept, Maybe, Decline) - if invited
- [ ] **Add to Apple Calendar** (export event)
- [ ] **Share Event** (share link)
- [ ] **Duplicate Event** (create copy)

#### D. Calendar Views (Optional for v1.0)
- [ ] Month view (calendar grid)
- [ ] Week view (horizontal scroll)
- [ ] Day view (time slots)
- Toggle between List / Month / Week

**Backend APIs Needed:**
- `POST /calendar/events` (create event)
- `PUT /calendar/events/{id}` (update event)
- `DELETE /calendar/events/{id}` (delete event)
- `POST /calendar/events/{id}/rsvp` (respond to invitation)

**Google Calendar API Calls:**
- `events.insert` (create)
- `events.update` (edit)
- `events.delete` (delete)
- `events.patch` (RSVP)

**Priority:** P0 (Completes calendar feature)
**Timeline:** 2-3 days (iOS) + 1 day (backend)

---

## 🎨 UI/UX Polish (Must-Have for App Store)

### Design System
- [ ] Color palette (light + dark mode)
- [ ] Typography system
- [ ] Spacing constants
- [ ] Reusable components

### States
- [ ] Empty states (inbox, calendar, search)
- [ ] Loading states (shimmer, spinners)
- [ ] Error states (with retry)
- [ ] Success states (toasts)

### Dark Mode
- [ ] All views support dark mode
- [ ] Test in both themes
- [ ] Semantic color naming

### Accessibility
- [ ] VoiceOver labels
- [ ] Dynamic Type support
- [ ] Sufficient contrast ratios
- [ ] Tap targets 44×44 minimum

### Haptic Feedback
- [ ] Button taps
- [ ] Swipe actions
- [ ] Pull-to-refresh
- [ ] Selection mode

### Animations
- [ ] List updates (insert, delete)
- [ ] Tab transitions
- [ ] Modal presentations
- [ ] Category filter selection

**Priority:** P1 (App Store quality)
**Timeline:** 2-3 days

---

## 🔍 Advanced Features (Should-Have)

### Search
- [ ] Search bar (top of inbox)
- [ ] Search emails by:
  - Subject
  - Sender
  - Body content
  - Date range
  - Category
- [ ] Recent searches
- [ ] Search suggestions
- [ ] Filter search results

**Backend:**
- [ ] Index emails for search (PostgreSQL full-text search)
- [ ] API: `GET /emails/search?q=<query>`

**Priority:** P1 (Expected in email apps)
**Timeline:** 1-2 days

---

### Attachments
- [ ] Display attachment indicators in list
- [ ] View attachments in detail
- [ ] Download attachments
- [ ] Preview attachments (PDF, images, docs)
- [ ] Add attachments when composing

**Backend:**
- [ ] Fetch attachment metadata
- [ ] Stream attachment downloads
- [ ] Upload attachments (multipart/form-data)

**Priority:** P1 (Common use case)
**Timeline:** 2 days

---

### Notifications
- [ ] Push notification permission request
- [ ] Register device token with backend
- [ ] Receive notifications for:
  - New urgent emails
  - Calendar event reminders (15 min before)
  - Daily digest ready
- [ ] Notification settings (in Settings)
- [ ] Deep links (tap notification → open email/event)

**Backend:**
- [ ] APNs integration (Apple Push Notification service)
- [ ] Device token storage
- [ ] Notification queue
- [ ] Batch notification sender

**Priority:** P1 (Engagement driver)
**Timeline:** 2-3 days

---

### Offline Mode
- [ ] Cache emails locally (CoreData)
- [ ] Cache calendar events locally
- [ ] Sync when online
- [ ] Offline indicator (no network banner)
- [ ] Queue actions (send email when online)

**Priority:** P2 (Nice-to-have)
**Timeline:** 2-3 days

---

## 📱 App Store Requirements

### Assets
- [ ] **App Icon** (1024×1024)
  - Designed and polished
  - All sizes generated (@2x, @3x)
- [ ] **Launch Screen**
  - Branded splash screen
  - Matches app style
- [ ] **Screenshots** (5 screens, multiple device sizes)
  - iPhone 6.7" (1290 × 2796 px) - Pro Max
  - iPhone 6.5" (1242 × 2688 px) - Plus
  - iPhone 5.5" (1242 × 2208 px) - SE
  - Screenshots:
    1. Hero: Inbox with AI categories
    2. Email detail with summary
    3. Calendar view
    4. Compose new email
    5. Settings & customization

### Legal & Compliance
- [ ] **Privacy Policy** (hosted page)
  - What data we collect
  - How we use it
  - Third-party services (Google, Anthropic)
  - User rights
  - Contact info
- [ ] **Terms of Service** (hosted page)
  - Usage terms
  - Limitations
  - Liability
  - Termination
- [ ] **Age Rating Justification**
  - No objectionable content
  - Email/calendar access reasoning
- [ ] **Export Compliance** (encryption declaration)

### App Store Listing
- [ ] **App Name:** InboxIQ
- [ ] **Subtitle:** AI-Powered Email Assistant
- [ ] **Description** (compelling copy)
  - Hook (problem/solution)
  - Key features (bullet points)
  - Benefits (save time, stay organized)
  - Call to action
- [ ] **Keywords** (100 characters)
  - email, AI, assistant, productivity, calendar
- [ ] **Category:** Productivity
- [ ] **Support URL** (website or support email)
- [ ] **Marketing URL** (optional, website)

**Priority:** P0 (Required for submission)
**Timeline:** 1 day (create content), 0.5 day (design assets)

---

## 🧪 Testing & QA

### Functional Testing
- [ ] All features work on multiple devices
- [ ] Test with real Gmail account
- [ ] Test with Google Workspace account
- [ ] Test with large inbox (1000+ emails)
- [ ] Test with minimal inbox (0 emails)
- [ ] Test offline scenarios
- [ ] Test error scenarios (network failure, API errors)

### Performance Testing
- [ ] App launch time < 2 seconds
- [ ] Smooth 60fps scrolling
- [ ] Memory usage < 100MB idle
- [ ] Network efficiency (minimal API calls)
- [ ] Battery impact (background sync)

### Security Testing
- [ ] OAuth flow secure (no token leaks)
- [ ] Keychain storage encrypted
- [ ] SSL pinning working
- [ ] No sensitive data in logs
- [ ] Rate limiting respected

### Accessibility Testing
- [ ] VoiceOver navigation works
- [ ] Dynamic Type scales correctly
- [ ] Color contrast meets WCAG AA
- [ ] All interactive elements labeled

**Priority:** P0 (Quality gate)
**Timeline:** 2-3 days

---

## 📅 Implementation Timeline (Option C)

### Week 1: Core Features
**Day 1-2: Email Actions**
- Backend: Compose, reply, forward APIs
- iOS: Compose view, reply flow
- Testing: Send/receive emails

**Day 3-4: Email Management**
- Backend: Archive, delete, star, mark read APIs
- iOS: Swipe actions, bulk select mode
- Testing: All email actions work

**Day 5: Calendar Events**
- Backend: Create, update, delete event APIs
- iOS: Create event view, edit event flow
- Testing: Event CRUD operations

**Day 6-7: Daily Digest**
- Backend: Test digest scheduling, email delivery
- iOS: Digest settings UI
- Testing: Send test digests

---

### Week 2: Polish & Launch
**Day 8-9: Search & Attachments**
- Backend: Search indexing, attachment downloads
- iOS: Search bar, attachment viewer
- Testing: Search accuracy, attachment handling

**Day 10: Notifications**
- Backend: APNs integration
- iOS: Push permission, notification handling
- Testing: Send test notifications

**Day 11-12: UI Polish**
- Design system implementation
- Dark mode everywhere
- Empty/loading/error states
- Animations and haptics
- Testing: Visual QA on all screens

**Day 13: App Store Assets**
- Design app icon
- Create launch screen
- Capture screenshots (5 screens, 3 sizes)
- Write privacy policy & terms
- Draft App Store listing

**Day 14: Final QA**
- Full regression testing
- Fix critical bugs
- Performance testing
- Accessibility audit
- Security review

---

## 📊 Feature Priority Matrix

| Feature | Priority | Timeline | Backend | iOS |
|---------|----------|----------|---------|-----|
| Compose email | P0 | 1 day | ✅ | 🔨 |
| Reply/Forward | P0 | 1 day | ✅ | 🔨 |
| Archive/Delete | P0 | 1 day | ✅ | 🔨 |
| Bulk actions | P0 | 0.5 day | ✅ | 🔨 |
| Create event | P0 | 1 day | ✅ | 🔨 |
| Edit/Delete event | P0 | 1 day | ✅ | 🔨 |
| Daily digest UI | P0 | 1 day | ✅ | 🔨 |
| Search | P1 | 2 days | 🔨 | 🔨 |
| Attachments | P1 | 2 days | 🔨 | 🔨 |
| Push notifications | P1 | 3 days | 🔨 | 🔨 |
| UI polish | P1 | 3 days | - | 🔨 |
| App Store assets | P0 | 1 day | - | 🔨 |
| Testing & QA | P0 | 3 days | ✅ | ✅ |

**Legend:**
- ✅ Already built
- 🔨 Need to build
- P0: Must have
- P1: Should have
- P2: Nice to have

---

## 🚀 Next Steps

1. **Review this plan** - Confirm scope and timeline
2. **Prioritize any missing features** - Anything else critical?
3. **Backend first** - Build email action APIs (compose, reply, archive, etc.)
4. **iOS parallel** - Start UI polish while backend builds
5. **Testing continuously** - QA each feature as it's built
6. **App Store prep** - Assets and legal docs in final days

**Total Timeline:** 14 days (2 weeks)
**Team:** Shiv + sub-agents (DEV-BE-premium, DEV-MOBILE-premium, Sundar for reviews)

---

## ❓ Questions for V:

1. **Timeline flexibility?** Can we take 2 full weeks, or need to ship faster?
2. **Feature cuts?** If timeline is tight, what's P2 (can defer to v1.1)?
3. **Daily digest priority?** This is unique - should we highlight it more?
4. **Calendar views?** Do we need month/week view, or is list view sufficient for v1.0?
5. **Offline mode?** Nice-to-have or must-have for your use case?
6. **Who tests?** Just founders, or will you recruit beta testers?

**Ready to build? 🚀**
