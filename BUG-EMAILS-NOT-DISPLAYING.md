# Bug: Emails Not Displaying After Login

**Reported:** 2026-03-05 08:23 CST  
**Priority:** HIGH (blocks testing)  
**Status:** Investigating

---

## Symptoms

1. ✅ OAuth login successful
2. ✅ Backend synced 17 emails to database
3. ❌ iOS app shows empty inbox (no emails visible)

---

## Railway Logs Analysis

### OAuth: ✅ SUCCESS
```
ios_oauth_callback_received
Token exchange 200 OK
Userinfo fetch 200 OK
ios_oauth_callback_user_resolved  ← FIX WORKED!
ios_oauth_callback_success
```

**No MissingGreenlet error!** OAuth fix successful.

---

### Email Sync: ✅ PARTIAL SUCCESS

**Backend synced 18 messages:**
- 17 successfully synced
- 2 not found (deleted/moved)
- Hit Gmail rate limit (429) on subsequent fetch

```
sync_message_ids_found: 18 emails
email_synced: 19cbcab389503bcb ✅
email_synced: 19cbd0de4239cd34 ✅
... (15 more) ...
email_not_found_skipping: 2 emails ⚠️
rateLimitExceeded: 5 emails ❌
```

**Database has 17 emails stored.**

---

### iOS Fetch: ✅ API CALL SUCCEEDED

```
POST /emails/sync HTTP/1.1" 200 OK
GET /emails HTTP/1.1" 200 OK  ← iOS app fetched emails!
```

**Backend returned 200 OK** = emails were sent to iOS app.

---

## Problem: Response Handling

**Backend sent emails, but iOS isn't displaying them.**

**Possible causes:**

1. **iOS parsing issue** - Response format doesn't match expected structure
2. **CoreData not saving** - Emails not persisted to local database
3. **UI not refreshing** - List view not reloading after fetch
4. **Empty response** - Backend returning wrong data structure

---

## Debug Steps

### Step 1: Check Backend Response Format

```bash
# Get JWT token from iOS
TOKEN="your-jwt-token"

# Call emails endpoint
curl -H "Authorization: Bearer $TOKEN" \
  https://inboxiq-production-5368.up.railway.app/emails | jq '.' > /tmp/emails-response.json

# Check format
cat /tmp/emails-response.json | jq 'keys'
```

**Expected structure (from backend schema):**
```json
{
  "emails": [
    {
      "id": "uuid",
      "gmail_id": "...",
      "subject": "...",
      "sender": "...",
      "body_preview": "...",
      "received_date": "...",
      "is_unread": true,
      "is_starred": false,
      "category": "FYI"
    }
  ],
  "total": 17,
  "page": 1,
  "page_size": 20,
  "total_pages": 1
}
```

---

### Step 2: Check iOS Parsing

**In Xcode debugger, after login:**

1. Set breakpoint in `InboxViewModel.fetchEmails()`
2. Check if API call completes
3. Check if response is parsed
4. Check if CoreData saves
5. Check if `@Published emails` updates

**Key areas to check:**
```swift
// InboxViewModel.swift
func fetchEmails() async {
    // 1. API call - does it succeed?
    let response = try await apiClient.get("/emails")
    
    // 2. Parsing - does it match structure?
    let emailsData = response["emails"] as? [[String: Any]]
    
    // 3. CoreData - does it save?
    for emailDict in emailsData {
        let email = EmailEntity(context: context)
        // ... populate fields
    }
    try context.save()
    
    // 4. UI update - does @Published trigger?
    self.emails = fetchedEmails
}
```

---

### Step 3: Check for Known Issues

**From iOS email action UIs agent (this morning):**
- Agent modified `EmailListView.swift`
- Agent modified `EmailRowView.swift`
- Could have broken email fetching logic

**Check if these files were integrated yet:**
```bash
ls -l /projects/inboxiq/ios/InboxIQ/InboxIQ/Views/Home/EmailListView.swift
```

If agent files were copied, they might be missing fetch logic.

---

## Quick Fix Options

### Option A: Check iOS Console Logs

**In Xcode:**
1. Open Console (⌘⇧C)
2. Filter: "InboxIQ"
3. Look for:
   - API errors
   - Parsing errors
   - CoreData errors
   - "No emails found" messages

---

### Option B: Force Refresh

**In iOS app:**
1. Pull down on inbox (pull-to-refresh)
2. Tap "Sync" button (if exists)
3. Check if emails appear

---

### Option C: Restart App

1. Kill app in simulator
2. Rebuild (⌘B)
3. Run again (⌘R)
4. Log in again
5. Check inbox

---

### Option D: Check Database Directly

**Verify emails are in Railway database:**
```bash
railway run bash

psql $DATABASE_URL

-- Check email count
SELECT COUNT(*) FROM emails 
WHERE user_id = '1ae0ee58-a04f-47b2-ba79-5779bff48b65';

-- Check first 5 emails
SELECT id, subject, sender, received_date 
FROM emails 
WHERE user_id = '1ae0ee58-a04f-47b2-ba79-5779bff48b65'
ORDER BY received_date DESC 
LIMIT 5;
```

If emails are there, backend is fine. Problem is iOS.

---

## Next Steps

**Immediate:**
1. Check iOS console logs (Option A)
2. Try force refresh (Option B)
3. Get backend response format (Step 1)

**If still broken:**
1. Check if agent-generated files were integrated
2. Review EmailListView code for fetch logic
3. Add debug logging to iOS fetch code

---

## Test Status Update

| Test | Status | Notes |
|------|--------|-------|
| 1. Health check | ✅ PASS | Backend healthy |
| 2. OAuth | ✅ PASS | No MissingGreenlet! |
| 3. Email sync (backend) | ✅ PASS | 17 emails synced |
| 3. Email sync (iOS display) | ❌ FAIL | Not showing in app |

**Blocker:** Must fix email display before continuing other tests.

---

**Created:** 2026-03-05 08:25 CST  
**Next:** Debug iOS email fetch/display
