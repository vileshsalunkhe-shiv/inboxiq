# Fix: Decoding Error - Missing Data

**Error:** "The data couldn't be read because it is missing."  
**Impact:** Only 1 of 17 emails synced to iOS  
**Root Cause:** Backend response format doesn't match iOS struct

---

## Console Evidence

```
✅ Backend sync completed: 1 emails synced
❌ Decoding error: The data couldn't be read because it is missing.
```

**Translation:** iOS successfully parsed 1 email, failed on the other 16.

---

## Problem: Field Mismatch

**Backend sends field that iOS doesn't expect, OR**  
**iOS expects field that backend doesn't send**

---

## Step 1: Get Backend Response

**Run this to see exact format:**

```bash
# Get token from Xcode console (you already have it)
TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxYWUwZWU1OC1hMDRmLTQ3YjItYmE3OS01Nzc5YmZmNDhiNjUiLCJleHAiOjE3NzI3MjIxODF9.Lzu8ABuJqd82xQE2J-mEnl6wA7jcSdtr-XPpXc5gmjU"

# Call API
curl -H "Authorization: Bearer $TOKEN" \
  https://inboxiq-production-5368.up.railway.app/emails \
  | jq '.' > /tmp/backend-response.json

# Check first email structure
cat /tmp/backend-response.json | jq '.emails[0]'
```

**This will show exactly what backend sends.**

---

## Step 2: Compare with iOS Struct

**iOS expects this (from EmailEntity or Email struct):**

```swift
struct Email: Codable {
    let id: UUID
    let gmail_id: String
    let subject: String
    let sender: String
    let body_preview: String?
    let received_date: String  // or Date
    let is_unread: Bool
    let is_starred: Bool
    let category: String?
    // ... any other fields
}
```

**Common mismatches:**
- Field name differences (camelCase vs snake_case)
- Missing optional fields
- Date format issues
- Type mismatches (String vs Int, etc.)

---

## Step 3: Find the Missing Field

**Look for:**

1. **Field name mismatch:**
   - Backend: `received_date`
   - iOS expects: `receivedDate`

2. **Missing required field:**
   - iOS requires `body_preview`
   - Backend doesn't send it (or sends null)

3. **Wrong type:**
   - Backend sends `"2024-03-05"` (String)
   - iOS expects Date object

---

## Quick Fix Options

### Option A: Update iOS Struct (If Backend is Correct)

**Add CodingKeys to handle snake_case:**

```swift
struct Email: Codable {
    let id: UUID
    let gmailId: String
    let subject: String
    let sender: String
    let bodyPreview: String?
    let receivedDate: Date
    let isUnread: Bool
    let isStarred: Bool
    let category: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case gmailId = "gmail_id"
        case subject
        case sender
        case bodyPreview = "body_preview"
        case receivedDate = "received_date"
        case isUnread = "is_unread"
        case isStarred = "is_starred"
        case category
    }
}
```

---

### Option B: Update Backend Response (If iOS is Correct)

**Modify backend serialization to match iOS:**

```python
# In backend schema
class EmailResponse(BaseModel):
    id: UUID
    gmailId: str  # Change from gmail_id
    subject: str
    sender: str
    bodyPreview: Optional[str]  # Change from body_preview
    receivedDate: datetime  # Change from received_date
    isUnread: bool  # Change from is_unread
    isStarred: bool  # Change from is_starred
    category: Optional[str]
    
    class Config:
        alias_generator = lambda x: x  # Use field names as-is
```

---

### Option C: Make All Fields Optional (Temporary Workaround)

**In iOS, make everything optional except ID:**

```swift
struct Email: Codable {
    let id: UUID?
    let gmailId: String?
    let subject: String?
    let sender: String?
    let bodyPreview: String?
    let receivedDate: String?  // Use String, parse later
    let isUnread: Bool?
    let isStarred: Bool?
    let category: String?
}
```

This will at least let you see which fields are present.

---

## Recommended Action

**1. Run Option B curl command** to get backend response  
**2. Share the output** with me  
**3. I'll identify the exact mismatch**  
**4. We'll fix either iOS or backend** (whichever is easier)

---

## Timeline

**5 minutes** to identify issue  
**10-20 minutes** to fix  
**5 minutes** to test

**Total:** 20-30 minutes to resolve

---

**Next:** Run the curl command and paste the first email structure.
