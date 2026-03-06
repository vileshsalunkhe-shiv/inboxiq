# InboxIQ MVP - Feature Status
**Updated:** 2026-03-05 07:36 CST

---

## ✅ COMPLETE (Read-Only App)

### Authentication
- ✅ Google OAuth login (iOS + Backend)
- ✅ Token storage (Keychain)
- ✅ Token refresh
- ✅ Sign out

### Email (Read-Only)
- ✅ Email sync (Gmail API)
- ✅ Email list view
- ✅ Email detail view
- ✅ AI categorization (7 categories)
- ✅ Category filtering
- ✅ Pull to refresh

### Calendar (Read-Only)
- ✅ Google Calendar OAuth
- ✅ Event sync (next 7 days)
- ✅ Event list view
- ✅ Event details

### UI/Design
- ✅ Design system (Colors, Typography, Spacing)
- ✅ Dark mode support
- ✅ App icon (VS Labs branding)
- ✅ Launch screen
- ✅ 3-tab navigation

### Settings
- ✅ Settings screen
- ✅ Version info
- ✅ Sign out button

---

## 🔨 MUST BUILD (This Week)

### Email Actions (Priority 1)
**Backend:** ✅ All APIs complete (8 endpoints)
**iOS:** ❌ No UI yet

**Need to build:**
- ❌ Compose email view
- ❌ Reply email view
- ❌ Forward email view
- ❌ Archive button/swipe
- ❌ Delete button/swipe (with confirmation)
- ❌ Star/unstar button/swipe
- ❌ Mark read/unread

**Time estimate:** 6-8 hours (Day 1-2)

---

### Calendar CRUD (Priority 2)
**Backend:** ❌ No APIs yet
**iOS:** ❌ No UI yet

**Need to build (Backend):**
- ❌ POST /calendar/events (create event)
- ❌ PUT /calendar/events/{id} (update event)
- ❌ DELETE /calendar/events/{id} (delete event)

**Need to build (iOS):**
- ❌ Create event view (form)
- ❌ Edit event view (form)
- ❌ Delete event (confirmation)

**Time estimate:** 6-8 hours (Day 3)

---

### Daily Digest (Priority 3)
**Backend:** ✅ APIs complete
**iOS:** ❌ Settings UI missing

**Need to build:**
- ❌ Digest frequency picker (Settings)
- ❌ Digest time picker (Settings)
- ❌ Test digest delivery (backend cron)

**Time estimate:** 2-3 hours (Day 4)

---

### Search (Priority 4)
**Backend:** ❌ No APIs yet
**iOS:** ❌ No UI yet

**Need to build (Backend):**
- ❌ GET /emails/search?q={query}
- ❌ GET /calendar/search?q={query}

**Need to build (iOS):**
- ❌ Search bar (tab toolbar)
- ❌ Search results view
- ❌ Filter by category/date

**Time estimate:** 4-5 hours (Day 4)

---

## ⏳ OPTIONAL (If Time)

### Push Notifications
- ❌ Apple Push Notification setup
- ❌ Backend FCM/APNs integration
- ❌ iOS notification permissions
- ❌ Badge counts

**Complexity:** High (requires Apple Developer setup)
**Time estimate:** 8-10 hours

---

### Advanced Email Actions
- ❌ Swipe gesture customization
- ❌ Bulk actions (select multiple)
- ❌ Move to folder/label
- ❌ Spam reporting

**Time estimate:** 4-6 hours

---

### UI Polish
- ❌ Animations/transitions
- ❌ Empty states
- ❌ Error state illustrations
- ❌ Onboarding tutorial

**Time estimate:** 6-8 hours

---

## 📊 Progress Summary

**Completed:** 15 features (read-only app)
**Must Build:** 23 features (interactive app)
**Optional:** 10+ features (polish)

**Overall Progress:** ~40% complete (by feature count)
**Time to MVP:** 5 days (if focused)

---

## 🎯 This Week's Goal

**By Friday (March 9):**
- ✅ All email actions working
- ✅ Calendar CRUD working
- ✅ Daily digest configured
- ✅ Search functional
- ✅ End-to-end testing complete

**Then:**
- Week 2: Railway deployment + TestFlight
- Week 3: App Store submission

---

## Strategy Options

### Option A: Manual (You Build)
- Pros: Full control, learn iOS deeply
- Cons: Slower, more tedious
- Time: ~40 hours

### Option B: Agent-Heavy (Agents Build)
- Pros: Faster, parallel work
- Cons: Review overhead, integration bugs
- Time: ~20 hours (with reviews)

### Option C: Hybrid (Split Work)
- Pros: Balance speed and control
- Cons: Context switching
- Time: ~25-30 hours

**Recommendation:** Option B (agent-heavy) given timeline

---

**Next:** Build email action UIs today (Day 1)
