# SyncService Complete Fix - 2026-03-05 09:30 CST

## Root Cause
iOS `SyncService.swift` expects wrong field names from `/emails` API:

**iOS Expected:**
```swift
struct EmailsResponse {
    let items: [EmailPayload]
    let total: Int
}
```

**Backend Actually Returns:**
```json
{
  "emails": [...],
  "next_page_token": null,
  "has_more": false,
  "total_fetched": 10
}
```

## Fix Required

**File:** `/ios/InboxIQ/InboxIQ/Services/SyncService.swift`

### 1. Replace EmailsResponse struct (line ~18):
```swift
struct EmailsResponse: Decodable {
    let emails: [EmailPayload]           // Changed from "items"
    let nextPageToken: String?           // Added
    let hasMore: Bool                    // Added
    let totalFetched: Int                // Changed from "total"
    
    enum CodingKeys: String, CodingKey {
        case emails
        case nextPageToken = "next_page_token"
        case hasMore = "has_more"
        case totalFetched = "total_fetched"
    }
}
```

### 2. Replace all references (4 places):

**Line 67:** 
```swift
// OLD:
print("✅ Fetched \(emailsResponse.items.count) emails from backend")
// NEW:
print("✅ Fetched \(emailsResponse.emails.count) emails from backend")
```

**Line 78:**
```swift
// OLD:
for email in emailsResponse.items {
// NEW:
for email in emailsResponse.emails {
```

**Line 102:**
```swift
// OLD:
print("🔍 Processing \(emailsResponse.items.count) emails...")
// NEW:
print("🔍 Processing \(emailsResponse.emails.count) emails...")
```

**Line 104:**
```swift
// OLD:
for (index, emailPayload) in emailsResponse.items.enumerated() {
// NEW:
for (index, emailPayload) in emailsResponse.emails.enumerated() {
```

## Apply Fix Script

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/ios/InboxIQ/InboxIQ/Services

# Backup
cp SyncService.swift SyncService.swift.backup-$(date +%Y%m%d-%H%M%S)

# Apply fixes
sed -i '' 's/let items: \[EmailPayload\]/let emails: [EmailPayload]/' SyncService.swift
sed -i '' 's/let total: Int/let totalFetched: Int/' SyncService.swift
sed -i '' 's/emailsResponse\.items/emailsResponse.emails/g' SyncService.swift

echo "✅ SyncService.swift fixed"
```

## Test Steps
1. Apply fix to SyncService.swift
2. Clean build (Cmd+Shift+K)
3. Build and run (Cmd+R)
4. Login
5. Watch console for successful email decoding

---

**Status:** Ready to apply
