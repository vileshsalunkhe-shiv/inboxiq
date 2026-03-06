# Linear Updates - Feature Complete Implementation

**Date:** 2026-03-04
**Workspace:** vs-work-with-shiv
**Team:** INB (InboxIQ)
**Sprint:** Feature Complete (2 weeks)

---

## 📋 New Issues to Create

### Week 1: Backend APIs

**INB-22: Email Action APIs**
- Title: [Backend] Implement email action APIs (compose, reply, forward, archive, delete)
- Description: Build complete email management API endpoints for iOS app
- Priority: High
- Estimate: 3 days
- Labels: backend, api, email
- Assignee: DEV-BE-premium (sub-agent)
- Dependencies: None
- Acceptance Criteria:
  - [ ] POST /emails/compose (send new email)
  - [ ] POST /emails/{id}/reply (reply to email)
  - [ ] POST /emails/{id}/forward (forward email)
  - [ ] POST /emails/{id}/archive (archive email)
  - [ ] DELETE /emails/{id} (delete email)
  - [ ] PUT /emails/{id}/read (mark read/unread)
  - [ ] PUT /emails/{id}/star (star/unstar)
  - [ ] POST /emails/bulk (bulk operations)
  - [ ] Pydantic schemas for all requests/responses
  - [ ] Error handling and validation
  - [ ] Tests passing

**INB-23: Calendar CRUD APIs**
- Title: [Backend] Implement calendar event CRUD operations
- Description: Build calendar management API endpoints (create, update, delete, RSVP)
- Priority: High
- Estimate: 2 days
- Labels: backend, api, calendar
- Assignee: DEV-BE-premium (sub-agent)
- Dependencies: INB-22 (optional, can work in parallel)
- Acceptance Criteria:
  - [ ] POST /calendar/events (create event)
  - [ ] PUT /calendar/events/{id} (update event)
  - [ ] DELETE /calendar/events/{id} (delete event)
  - [ ] POST /calendar/events/{id}/rsvp (RSVP to invitation)
  - [ ] Pydantic schemas for all requests/responses
  - [ ] Google Calendar API integration
  - [ ] Error handling for edge cases
  - [ ] Tests passing

**INB-24: Daily Digest Testing & Verification**
- Title: [Backend] Test and verify daily digest email delivery
- Description: Ensure digest service works end-to-end (backend already built, needs testing)
- Priority: Medium
- Estimate: 0.5 day
- Labels: backend, digest, testing
- Assignee: Shiv
- Dependencies: None (digest service already exists)
- Acceptance Criteria:
  - [ ] Test digest generation (preview endpoint)
  - [ ] Verify email template renders correctly
  - [ ] Test scheduling (cron job or manual trigger)
  - [ ] Confirm email delivery to real inbox
  - [ ] Test all preference options (frequency, timezone, toggles)

---

### Week 2: iOS Implementation

**INB-25: Design System & UI Polish**
- Title: [iOS] Implement design system and dark mode support
- Description: Build complete design system (colors, fonts, spacing) and ensure all views support dark mode
- Priority: High
- Estimate: 2 days
- Labels: ios, ui, design-system, dark-mode
- Assignee: DEV-MOBILE-premium (sub-agent)
- Dependencies: None
- Acceptance Criteria:
  - [ ] DesignSystem.swift (colors, fonts, spacing, corner radius)
  - [ ] All views use semantic colors (support dark mode)
  - [ ] EmptyStateView component
  - [ ] LoadingStateView component (shimmer)
  - [ ] ErrorBanner component
  - [ ] ComingSoonBadge component
  - [ ] Tested in both light and dark themes
  - [ ] All mockup screens implemented

**INB-26: Email Action Views**
- Title: [iOS] Build email action views (compose, reply, archive, delete)
- Description: Implement complete email management UI
- Priority: High
- Estimate: 3 days
- Labels: ios, email, ui
- Assignee: DEV-MOBILE-premium (sub-agent)
- Dependencies: INB-22 (backend APIs), INB-25 (design system)
- Acceptance Criteria:
  - [ ] ComposeEmailView (new email with attachments)
  - [ ] ReplyView (reply/reply-all/forward)
  - [ ] Swipe actions (archive left, delete right)
  - [ ] Bulk select mode (long-press to enter)
  - [ ] Email detail actions (reply, forward, archive buttons)
  - [ ] Mark read/unread functionality
  - [ ] Star/unstar functionality
  - [ ] All actions integrated with backend APIs
  - [ ] Error handling (toast notifications)
  - [ ] Success feedback (haptics + toast)

**INB-27: Calendar CRUD Views**
- Title: [iOS] Build calendar event management views
- Description: Implement create/edit/delete event UI
- Priority: High
- Estimate: 2 days
- Labels: ios, calendar, ui
- Assignee: DEV-MOBILE-premium (sub-agent)
- Dependencies: INB-23 (backend APIs), INB-25 (design system)
- Acceptance Criteria:
  - [ ] CreateEventView (full form: title, date/time, location, guests)
  - [ ] EditEventView (same as create, pre-filled)
  - [ ] Delete event confirmation
  - [ ] RSVP buttons (Accept, Maybe, Decline)
  - [ ] Date/time pickers (iOS native)
  - [ ] Location autocomplete
  - [ ] Guest email autocomplete
  - [ ] Calendar selector (if multiple calendars)
  - [ ] Integrated with backend APIs
  - [ ] Error handling and validation

**INB-28: Daily Digest Settings UI**
- Title: [iOS] Build daily digest settings screen
- Description: Add digest preferences section to Settings tab
- Priority: Medium
- Estimate: 1 day
- Labels: ios, settings, digest
- Assignee: DEV-MOBILE-premium (sub-agent)
- Dependencies: INB-24 (backend testing), INB-25 (design system)
- Acceptance Criteria:
  - [ ] Enable/disable toggle
  - [ ] Time picker (6am, 9am, 12pm, 3pm, 6pm, 9pm)
  - [ ] Frequency selector (Daily, Weekly, Off)
  - [ ] Timezone picker
  - [ ] Toggle: Include action items
  - [ ] Toggle: Include summaries
  - [ ] Toggle: Include calendar preview
  - [ ] Preview Digest button (sends test email)
  - [ ] Settings saved to backend
  - [ ] Settings loaded on app launch

**INB-29: Settings Screen Redesign**
- Title: [iOS] Redesign Settings with grouped sections and coming soon features
- Description: Implement professional Settings screen with future feature hints
- Priority: Medium
- Estimate: 1 day
- Labels: ios, settings, ui
- Assignee: DEV-MOBILE-premium (sub-agent)
- Dependencies: INB-25 (design system)
- Acceptance Criteria:
  - [ ] Grouped sections (Account, Digest, Notifications, AI, Appearance, Storage, About)
  - [ ] Coming soon badges on future features
  - [ ] Theme selector (System, Light, Dark)
  - [ ] Text size selector (System, Small, Medium, Large)
  - [ ] Privacy Policy link
  - [ ] Terms of Service link
  - [ ] Contact Support link
  - [ ] Version info
  - [ ] Sign Out button

---

### Week 2: Polish & Launch

**INB-30: Search Interface (Placeholder)**
- Title: [iOS] Add search bar with "Coming Soon" state
- Description: Show search UI but display coming soon modal when tapped
- Priority: Low
- Estimate: 0.5 day
- Labels: ios, search, placeholder
- Assignee: DEV-MOBILE-premium (sub-agent)
- Dependencies: INB-25 (design system)
- Acceptance Criteria:
  - [ ] Search bar in navigation (Inbox tab)
  - [ ] Tap → "Coming Soon" modal
  - [ ] Recent searches placeholder
  - [ ] Suggested searches placeholder
  - [ ] Feature description (what search will do)

**INB-31: App Icon & Launch Screen**
- Title: [Assets] Create app icon and launch screen
- Description: Design and integrate professional app icon (Concept 1: AI Envelope)
- Priority: High
- Estimate: 0.5 day
- Labels: design, assets
- Assignee: Shiv
- Dependencies: None
- Acceptance Criteria:
  - [ ] 1024×1024 app icon created (Canva)
  - [ ] All iOS sizes generated (Xcode)
  - [ ] Launch screen designed (branded splash)
  - [ ] Imported to Xcode asset catalog
  - [ ] Tested on simulator and device

**INB-32: End-to-End Testing & QA**
- Title: [QA] Comprehensive testing (functional, performance, accessibility)
- Description: Full regression testing across all features and devices
- Priority: High
- Estimate: 2 days
- Labels: testing, qa
- Assignee: Shiv + Founders
- Dependencies: All INB-22 through INB-31
- Acceptance Criteria:
  - [ ] Functional testing (all features work)
  - [ ] Performance testing (smooth 60fps, fast launch)
  - [ ] Accessibility testing (VoiceOver, Dynamic Type)
  - [ ] Security testing (OAuth, SSL pinning, token storage)
  - [ ] Dark mode testing (all screens)
  - [ ] Multi-device testing (SE, 14 Pro, 15 Pro Max)
  - [ ] Network scenarios (offline, slow, errors)
  - [ ] Edge cases (empty states, errors, rate limits)
  - [ ] Bug list documented
  - [ ] Critical bugs fixed

**INB-33: App Store Preparation**
- Title: [App Store] Create screenshots, legal pages, and listing content
- Description: Prepare all assets for App Store submission
- Priority: High
- Estimate: 1 day
- Labels: app-store, marketing
- Assignee: Shiv + V
- Dependencies: INB-32 (testing complete)
- Acceptance Criteria:
  - [ ] 5 screenshots per device size (6.7", 6.5", 5.5")
  - [ ] Privacy Policy hosted (Railway or static site)
  - [ ] Terms of Service hosted
  - [ ] App Store description written
  - [ ] Keywords optimized (100 characters)
  - [ ] Support URL configured
  - [ ] Age rating justification ready
  - [ ] TestFlight build uploaded
  - [ ] Internal beta testing (founders)

**INB-34: App Store Submission**
- Title: [App Store] Submit InboxIQ v1.0 to App Store
- Description: Final submission and launch
- Priority: High
- Estimate: 0.5 day (+ 1-2 weeks review)
- Labels: app-store, launch
- Assignee: V (Apple Developer account owner)
- Dependencies: INB-33 (assets ready)
- Acceptance Criteria:
  - [ ] App Store Connect filled out
  - [ ] Build submitted for review
  - [ ] Monitoring for Apple feedback
  - [ ] Respond to reviewer questions
  - [ ] App approved
  - [ ] Release strategy decided (manual or automatic)
  - [ ] 🎉 App live on App Store!

---

## 📊 Issues to Update (Already Complete)

**Mark as Done:**
- INB-14: ✅ Calendar integration
- INB-15: ✅ Calendar router deployment
- INB-16: ✅ Backend AI categorization
- INB-17: ✅ iOS AI category UI
- INB-18: ✅ iOS calendar URL encoding fix
- INB-21: ✅ Backend pagination

**Close (Deferred to Phase 2):**
- INB-19: [UI Detail] Daily digest hourly picker (Deferred)
- INB-20: [Process] UI customization tracking (Documented)

---

## 📈 Sprint Overview

**Sprint:** Feature Complete (2 weeks)
**Start:** 2026-03-04
**End:** 2026-03-18 (estimated)

**Week 1 Focus:** Backend APIs (3 issues, 5.5 days)
**Week 2 Focus:** iOS UI + Polish (7 issues, 10 days)
**Final Days:** Testing + App Store (3 issues, 3.5 days)

**Total:** 13 new issues
**Estimated:** 19 days of work (with parallel execution: 14 days)

---

## 🚀 Execution Plan

**Today (2026-03-04):**
1. ✅ Create backup
2. ✅ Update Linear (this document)
3. 🔄 Spawn DEV-BE-premium → INB-22 (Email action APIs)
4. 🔄 Create app icon (Canva) → INB-31

**Week 1 (Days 2-5):**
- DEV-BE-premium continues → INB-23 (Calendar CRUD)
- Shiv tests → INB-24 (Daily digest)
- Sundar reviews backend when complete

**Week 2 (Days 6-12):**
- DEV-MOBILE-premium → INB-25 (Design system)
- DEV-MOBILE-premium → INB-26 (Email actions UI)
- DEV-MOBILE-premium → INB-27 (Calendar CRUD UI)
- DEV-MOBILE-premium → INB-28 (Digest settings)
- DEV-MOBILE-premium → INB-29 (Settings redesign)
- DEV-MOBILE-premium → INB-30 (Search placeholder)

**Final Days (Days 13-14):**
- INB-32: Full QA (Shiv + Founders)
- INB-33: App Store assets (Shiv + V)
- INB-34: Submit to App Store (V)

---

**Ready to create these issues in Linear?**

You can:
1. Create them manually in Linear UI
2. Or I can build the Linear integration skill and automate it
3. Or paste this into Linear as a project brief
