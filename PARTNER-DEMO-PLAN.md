# Partner Demo Prep Plan - 2026-03-05

**Goal:** Demo-ready InboxIQ for partner presentation tomorrow
**Time Available:** ~6-8 hours (15:30-23:00 CST)
**Priorities:** Daily digest, Polished UI, Calendar CRUD/search

---

## 1. Daily Digest Email ⏰ ~2-3 hours

**Backend Tasks:**
- [ ] Create `/api/digest/preview` endpoint (GET) - returns HTML preview of digest
- [ ] Create `/api/digest/send` endpoint (POST) - sends digest email via Gmail API
- [ ] Create digest email template (HTML/CSS) with:
  - Unread email count
  - Top 5 urgent/action required emails (with subject, sender, snippet)
  - Calendar events for today/tomorrow
  - Category breakdown chart
  - InboxIQ branding
- [ ] Add user preference for digest time (default 7:00 AM)
- [ ] Test sending digest email via Gmail API

**iOS Tasks:**
- [ ] Add "Daily Digest" section to Settings
- [ ] Time picker for preferred digest time
- [ ] "Send Test Digest" button
- [ ] Display last digest sent timestamp

**Priority:** HIGH - Impressive demo feature
**Agent:** DEV-BE-premium (backend), DEV-MOBILE-premium (iOS)
**Estimated Time:** 2-3 hours (parallel development)

---

## 2. Polished UI 🎨 ~2-3 hours

**What "Polished" Means:**
- Consistent spacing, colors, typography (Design System)
- Smooth animations and transitions
- Loading states and error handling
- Empty states (no emails, no calendar events)
- Polish email detail view (better formatting)
- Polish inbox list (consistent heights, better avatars)
- Polish calendar view (event cards, colors)
- Remove any debug UI or placeholder text
- Fix any visual bugs or misalignments

**iOS Tasks:**
- [ ] Audit all screens for design system consistency
- [ ] Add loading skeletons for email list and calendar
- [ ] Add empty state views ("No emails", "No events")
- [ ] Improve email detail formatting (better HTML rendering, attachments display)
- [ ] Polish inbox list (avatar initials, consistent spacing)
- [ ] Polish calendar event cards (time format, all-day events)
- [ ] Add subtle animations (swipe actions, navigation transitions)
- [ ] Remove debug logs/text from UI
- [ ] Test on different screen sizes (iPhone SE, Pro Max)

**Priority:** HIGH - First impressions matter
**Agent:** DEV-MOBILE-premium (UI specialist)
**Estimated Time:** 2-3 hours

---

## 3. Calendar CRUD + Search 📅 ~3-4 hours

**Current State:**
- ✅ Calendar view displays events (OAuth working)
- ❌ No create event
- ❌ No edit event
- ❌ No delete event
- ❌ No search events

**Backend Tasks:**
- [ ] Create `/api/calendar/events` endpoint (POST) - create event via Google Calendar API
- [ ] Create `/api/calendar/events/{event_id}` endpoint (PATCH) - update event
- [ ] Create `/api/calendar/events/{event_id}` endpoint (DELETE) - delete event
- [ ] Create `/api/calendar/search` endpoint (GET) - search calendar events
- [ ] Test all CRUD operations with Google Calendar API

**iOS Tasks:**
- [ ] Add "New Event" button in CalendarView
- [ ] Create EventEditView (create/edit form):
  - Title, date/time pickers
  - Location, description
  - Attendees (optional)
  - Save/Cancel buttons
- [ ] Add swipe actions to event cards (Edit, Delete)
- [ ] Add search bar in CalendarView (filter by title/description)
- [ ] Handle all-day events properly
- [ ] Add loading states for CRUD operations
- [ ] Show success/error toasts

**Priority:** HIGH - Core calendar functionality
**Agent:** DEV-BE-premium (backend), DEV-MOBILE-premium (iOS)
**Estimated Time:** 3-4 hours (parallel development)

---

## Execution Strategy

**Phase 1 (15:30-18:00): Daily Digest** - 2.5 hours
- Spawn DEV-BE-premium for digest backend
- Spawn DEV-MOBILE-premium for digest iOS
- Monitor every 15 minutes
- Test digest email generation and sending

**Phase 2 (18:00-20:30): Calendar CRUD** - 2.5 hours
- Spawn DEV-BE-premium for calendar APIs
- Spawn DEV-MOBILE-premium for calendar UI
- Monitor every 15 minutes
- Test create/edit/delete/search calendar events

**Phase 3 (20:30-23:00): UI Polish** - 2.5 hours
- Spawn DEV-MOBILE-premium for full UI audit and polish
- Monitor every 15 minutes
- Test on multiple devices/screens
- Final demo rehearsal

**Total Time:** ~7.5 hours (fits in available time)

---

## Deferred Issues (Post-Demo)
- Mark read/unread state persistence
- Delete email (blocked by rate limiting)
- Email body loading (blocked by rate limiting)
- Gmail rate limiting fixes
- Sent emails appearing in inbox

---

## Success Criteria for Demo
✅ Daily digest email sends successfully with formatted content
✅ UI looks polished and professional (no rough edges)
✅ Calendar CRUD works (create, edit, delete events)
✅ Calendar search filters events
✅ No crashes or obvious bugs during demo
✅ Smooth navigation and transitions
✅ Loading states and error handling in place

---

**Next Step:** Get V's approval, then start Phase 1 (Daily Digest).
