# Backend ↔ iOS Field Mismatch

**Problem Identified:** Backend response doesn't match iOS expectations

---

## Backend Sends (Actual)

```json
{
  "id": "157",                    ← STRING (should be UUID)
  "gmail_id": "19cbe621b926853b",
  "subject": "...",
  "sender": "...",
  "category": null,
  "ai_summary": null,
  "ai_confidence": null,
  "snippet": "...",               ← Should be "body_preview"
  "received_at": "2026-03-05..."  ← Should be "received_date"
}
```

---

## iOS Expects

```swift
struct Email {
    let id: UUID                   ← UUID (backend sends String!)
    let gmail_id: String
    let subject: String
    let sender: String
    let body_preview: String?      ← Backend sends "snippet"
    let received_date: Date        ← Backend sends "received_at"
    let is_unread: Bool            ← MISSING from backend!
    let is_starred: Bool           ← MISSING from backend!
    let category: String?
}
```

---

## Mismatches Found

### 1. ❌ CRITICAL: ID Type Mismatch
- Backend: `"id": "157"` (String)
- iOS: `id: UUID`
- **Result:** Parsing fails completely

### 2. ❌ Field Name: snippet vs body_preview
- Backend: `"snippet": "..."`
- iOS: `body_preview`

### 3. ❌ Field Name: received_at vs received_date
- Backend: `"received_at": "..."`
- iOS: `received_date`

### 4. ❌ Missing: is_unread
- Backend: Not sent
- iOS: Required field

### 5. ❌ Missing: is_starred
- Backend: Not sent
- iOS: Required field

---

## Fix Options

### Option A: Fix Backend Response (RECOMMENDED)

**Modify `/backend/app/schemas/email.py`:**

```python
class EmailResponse(BaseModel):
    id: UUID                        # Change from int to UUID
    gmail_id: str
    subject: str
    sender: str
    body_preview: str | None        # Rename from snippet
    received_date: datetime         # Rename from received_at
    is_unread: bool = True          # Add missing field
    is_starred: bool = False        # Add missing field
    category: str | None
    ai_summary: str | None
    ai_confidence: float | None
    
    class Config:
        from_attributes = True
        
    @classmethod
    def from_orm(cls, email):
        return cls(
            id=email.id,                    # This should already be UUID
            gmail_id=email.gmail_id,
            subject=email.subject,
            sender=email.sender,
            body_preview=email.snippet,     # Map snippet → body_preview
            received_date=email.received_at, # Map received_at → received_date
            is_unread=email.is_unread if hasattr(email, 'is_unread') else True,
            is_starred=email.is_starred if hasattr(email, 'is_starred') else False,
            category=email.category,
            ai_summary=email.ai_summary,
            ai_confidence=email.ai_confidence
        )
```

**Also check Email model in `/backend/app/models/email.py`:**
- Ensure `id` column is UUID type (not Integer)
- Ensure `is_unread` and `is_starred` columns exist

---

### Option B: Fix iOS Parsing (TEMPORARY)

**Update iOS Email struct:**

```swift
struct Email: Codable {
    let id: String              // Change from UUID to String temporarily
    let gmailId: String
    let subject: String
    let sender: String
    let snippet: String?        // Change from body_preview
    let receivedAt: String      // Change from received_date, use String
    let isUnread: Bool?         // Make optional
    let isStarred: Bool?        // Make optional
    let category: String?
    let aiSummary: String?
    let aiConfidence: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case gmailId = "gmail_id"
        case subject
        case sender
        case snippet
        case receivedAt = "received_at"
        case isUnread = "is_unread"
        case isStarred = "is_starred"
        case category
        case aiSummary = "ai_summary"
        case aiConfidence = "ai_confidence"
    }
}
```

---

## Recommended Fix: Backend

**Why backend fix is better:**
1. iOS struct was correct initially
2. Backend schema is inconsistent (id as String is wrong)
3. Missing fields (is_unread, is_starred) are actually in database
4. Field names should match iOS expectations (we documented this in architecture)

---

## Implementation Steps

### 1. Check Database Schema
```bash
railway run bash
psql $DATABASE_URL

\d emails

# Should show:
# - id: UUID
# - is_unread: BOOLEAN
# - is_starred: BOOLEAN
```

### 2. Fix Backend Schema
- Update `app/schemas/email.py`
- Map field names correctly
- Test response

### 3. Deploy to Railway
```bash
git add .
git commit -m "Fix email response schema to match iOS"
git push
railway up
```

### 4. Test iOS Again
- Kill app
- Restart
- Login
- Emails should appear

---

## Quick Test

**After fix, backend should return:**
```json
{
  "id": "1ae0ee58-a04f-47b2-ba79-5779bff48b65",  ← UUID string
  "gmail_id": "...",
  "subject": "...",
  "sender": "...",
  "body_preview": "...",                          ← Not "snippet"
  "received_date": "2026-03-05T14:23:35Z",       ← Not "received_at"
  "is_unread": true,                              ← Added
  "is_starred": false,                            ← Added
  "category": null
}
```

---

**Next:** Fix backend response schema (15-20 minutes)
