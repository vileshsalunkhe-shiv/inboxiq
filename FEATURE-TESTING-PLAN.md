# Feature Testing Plan - InboxIQ

**Date:** 2026-03-05 14:28 CST  
**Goal:** Test all completed features systematically

---

## Testing Order (Priority)

### 1. Email Actions (High Priority - Just Built)
✅ Backend APIs complete (8 endpoints)  
❓ iOS UIs need testing (built by DEV-MOBILE-premium yesterday)

**Features to test:**
- [ ] Archive email
- [ ] Delete email  
- [ ] Star/unstar email
- [ ] Mark read/unread
- [ ] Compose new email
- [ ] Reply to email
- [ ] Forward email
- [ ] Bulk actions (archive/delete multiple)

**Test location:** EmailDetailView + EmailListView  
**Expected time:** 15-20 minutes

---

### 2. AI Email Categorization (Already Built)
✅ Backend complete (Claude API integration)  
✅ iOS UI complete (category badges + filters)

**Features to test:**
- [ ] New emails auto-categorized (7 categories)
- [ ] Category badge shows on emails
- [ ] Filter by category works
- [ ] Categories: Urgent, Action Required, Finance, FYI, Newsletter, Receipt, Spam
- [ ] AI confidence score displays
- [ ] Category can be manually changed

**Test location:** HomeView (inbox list)  
**Expected time:** 5 minutes

---

### 3. Calendar Integration (Previously Built)
✅ Backend OAuth + events API  
✅ iOS calendar view

**Features to test:**
- [ ] Calendar tab visible
- [ ] Events load from Google Calendar
- [ ] Event details display correctly
- [ ] OAuth flow works (if reconnecting)
- [ ] Events sync properly

**Test location:** CalendarView tab  
**Expected time:** 5 minutes

---

### 4. Email Sync (Core Feature)
✅ Backend sync with Gmail API  
✅ iOS CoreData integration

**Features to test:**
- [ ] Pull to refresh syncs new emails
- [ ] Auto-sync on login works
- [ ] Email count updates
- [ ] Newest emails appear at top
- [ ] Dates display correctly
- [ ] Snippets show (no HTML tags)

**Test location:** HomeView inbox  
**Expected time:** 5 minutes

---

### 5. Backend Health (Railway Production)
✅ Deployed to Railway  
✅ All endpoints operational

**Tests:**
- [ ] Health check endpoint
- [ ] Email list endpoint (pagination)
- [ ] Email sync endpoint
- [ ] AI categorization endpoint
- [ ] Email action endpoints (8 APIs)
- [ ] Calendar endpoints

**Test location:** Railway logs + API testing  
**Expected time:** 10 minutes

---

## Testing Checklist Format

For each test, record:
- ✅ Pass (works as expected)
- ⚠️ Partial (works but has issues)
- ❌ Fail (broken)
- 🔄 Skipped (blocked or not tested)

**Document issues found:**
- What happened
- What was expected
- Steps to reproduce
- Error messages (if any)

---

## Start Here: Email Actions Testing

**Most important to test first** (just built yesterday)

### Setup
1. Open InboxIQ app in simulator
2. Navigate to inbox (should already be there)
3. Tap any email to open EmailDetailView

### Test 1: Archive Email ⭐
**Steps:**
1. In EmailDetailView, find "Archive" button
2. Tap "Archive"
3. **Expected:** 
   - Confirmation or immediate action
   - Email disappears from inbox
   - Returns to inbox list
   - Email no longer visible (filtered out)

**Result:** [ ] Pass / [ ] Partial / [ ] Fail  
**Notes:**

---

### Test 2: Delete Email ⭐
**Steps:**
1. Open any email
2. Tap "Delete" button
3. **Expected:**
   - Confirmation dialog: "Are you sure?"
   - Tap "Delete" → Email removed
   - Returns to inbox
   - Email gone from list

**Result:** [ ] Pass / [ ] Partial / [ ] Fail  
**Notes:**

---

### Test 3: Star Email
**Steps:**
1. Open any unstarred email
2. Find star button (toolbar or detail view)
3. Tap star button
4. **Expected:**
   - Star fills in / changes color
   - Returns to inbox
   - Email shows star in inbox list

**Result:** [ ] Pass / [ ] Partial / [ ] Fail  
**Notes:**

---

### Test 4: Mark Read/Unread
**Steps:**
1. Open any email
2. Find read/unread toggle button (toolbar)
3. Tap button
4. **Expected:**
   - Button icon changes (envelope.open ↔ envelope.badge)
   - Returns to inbox
   - Email read/unread state changes in list

**Result:** [ ] Pass / [ ] Partial / [ ] Fail  
**Notes:**

---

### Test 5: Compose New Email
**Steps:**
1. Find "Compose" button (likely in HomeView toolbar or fab)
2. Tap "Compose"
3. Fill in:
   - To: (your email address)
   - Subject: "Test Email from InboxIQ"
   - Body: "This is a test message"
4. Tap "Send"
5. **Expected:**
   - Sheet/modal appears with compose form
   - Form fields work
   - "Send" button enabled when valid
   - Success message on send
   - Sheet dismisses
   - Email appears in Gmail (check on web)

**Result:** [ ] Pass / [ ] Partial / [ ] Fail  
**Notes:**

---

### Test 6: Reply to Email
**Steps:**
1. Open any email
2. Tap "Reply" button (bottom toolbar)
3. Reply sheet appears
4. Type reply message: "This is a test reply"
5. Tap "Send"
6. **Expected:**
   - Reply sheet shows original message quoted
   - To: field pre-filled with sender
   - Subject: prefixed with "Re:"
   - Send works
   - Reply appears in Gmail thread

**Result:** [ ] Pass / [ ] Partial / [ ] Fail  
**Notes:**

---

### Test 7: Forward Email
**Steps:**
1. Open any email
2. Tap "Forward" button (bottom toolbar)
3. Forward sheet appears
4. Enter recipient: (your email)
5. Optional: Add comment
6. Tap "Send"
7. **Expected:**
   - Forward sheet shows original message
   - To: field empty (user must enter)
   - Subject: prefixed with "Fwd:"
   - Send works
   - Forwarded email arrives in Gmail

**Result:** [ ] Pass / [ ] Partial / [ ] Fail  
**Notes:**

---

### Test 8: Swipe Actions (If Implemented)
**Steps:**
1. In inbox list, swipe left on any email
2. **Expected:**
   - Swipe reveals action buttons (archive, delete, star)
   - Tap action → Executes immediately
   - Email updates/disappears as appropriate

**Result:** [ ] Pass / [ ] Partial / [ ] Fail  
**Notes:**

---

## Quick Start Instructions

**To begin testing:**

1. **Make sure iOS app is rebuilt:**
   ```
   Cmd + B (in Xcode)
   ```

2. **Launch simulator**

3. **Start with Email Actions** (most critical)

4. **Record results** as you go

5. **Paste any errors or issues** you encounter

---

**Ready to start?** Let me know when you're ready, and I'll guide you through each test! 🚀

**First test:** Archive email - Go ahead and try it!
