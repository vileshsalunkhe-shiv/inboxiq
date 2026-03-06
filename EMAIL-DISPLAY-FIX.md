# Email Display Fix - 2026-03-05 09:10 CST

## Problem
iOS app shows empty inbox with decoding error: "The data couldn't be read because it is missing"

## Root Cause
Backend-iOS field name and type mismatches:

| iOS Expected | Backend Sends | Issue |
|--------------|---------------|-------|
| `id: UUID` | `id: "159"` (String) | Type mismatch |
| `snippet` | `body_preview` | Name mismatch |
| `receivedAt` | `received_date` | Name mismatch |
| `syncedAt` | (not sent) | Missing field |
| `isUnread` | `is_unread` | Case mismatch |
| (missing) | `is_starred` | iOS struct missing field |

## Solution
Updated iOS Email struct with:
1. **CodingKeys enum** - Maps snake_case JSON to camelCase Swift
2. **Custom decoder** - Handles missing `syncedAt`, parses date strings
3. **Type changes** - `id: String` instead of `UUID`
4. **Field renames** - `snippet` → `bodyPreview`, `receivedAt` → `receivedDate`
5. **New field** - Added `isStarred: Bool`

## Files to Update
Replace `/ios/InboxIQ/InboxIQ/Models/Email.swift` with:
`/projects/inboxiq/EMAIL-STRUCT-FIX-V2.swift`

**V2 keeps existing field names** (`snippet`, `receivedAt`) - no other files need changes!
Only adds CodingKeys mapping to handle backend's different naming.

## Testing Steps
1. Replace Email.swift in Xcode
2. Build and run on simulator
3. Login with vilesh.salunkhe@gmail.com
4. Trigger email sync
5. Verify emails display in inbox

## Secondary Issue: Gmail Rate Limiting
Backend is hitting Google's "Too many concurrent requests" limit during sync.

**Cause:** Batch API requests happening too fast

**Solution (for later):**
- Add exponential backoff retry logic
- Reduce concurrent batch size
- Implement request throttling

**For now:** Rate limit errors are transient. Sync will succeed on retry.

## Status
- ✅ Email struct fix created
- ⏳ Awaiting Xcode integration and testing
- ⏳ Rate limiting fix deferred to later

---

**Next:** Replace Email.swift in Xcode and test
