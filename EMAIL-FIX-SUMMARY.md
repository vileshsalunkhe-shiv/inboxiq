# Email Schema Fix - Ready to Deploy

**Problem:** iOS decoding error - "The data couldn't be read because it is missing."  
**Cause:** Backend response format didn't match iOS expectations  
**Status:** ✅ FIXED (ready to deploy)

---

## Changes Made

### 1. Schema Update (`app/schemas/email.py`)
```python
class EmailOut(BaseModel):
    id: str
    gmail_id: str
    subject: str | None
    sender: str | None
    body_preview: str | None      # ← Renamed from "snippet"
    received_date: datetime | None # ← Renamed from "received_at"
    is_unread: bool = True         # ← Added
    is_starred: bool = False       # ← Added
    category: str | None
    ai_summary: str | None
    ai_confidence: float | None
```

### 2. API Updates (4 locations)
Fixed EmailOut serialization in:
- `app/api/emails.py` (3 places)
- `app/api/categorization.py` (1 place)

All now correctly map:
- `snippet` → `body_preview`
- `received_at` → `received_date`
- Add `is_unread` from database
- Add `is_starred` (default False)

---

## Deploy Steps

### Option A: Automated (Recommended)
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend
./DEPLOY-EMAIL-FIX.sh
```

### Option B: Manual
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq

# Commit
git add backend/app/schemas/email.py
git add backend/app/api/emails.py
git add backend/app/api/categorization.py
git commit -m "Fix: Email response schema to match iOS expectations"

# Deploy
git push origin main
railway up
```

---

## After Deploy

### 1. Wait for Railway Deployment (1-2 min)
```bash
railway logs --tail 50
```

Look for: "Build successful" or "Deployment complete"

### 2. Test Backend Response
```bash
TOKEN="your-jwt-token"  # From iOS console
curl -H "Authorization: Bearer $TOKEN" \
  https://inboxiq-production-5368.up.railway.app/emails | jq '.emails[0]'
```

**Should now show:**
```json
{
  "id": "157",
  "gmail_id": "...",
  "subject": "...",
  "sender": "...",
  "body_preview": "...",   ← NOT "snippet"
  "received_date": "...",  ← NOT "received_at"
  "is_unread": true,       ← NEW
  "is_starred": false,     ← NEW
  "category": null
}
```

### 3. Test iOS App
1. Kill app in simulator (⌘.)
2. Clean build folder (⌘⇧K)
3. Build (⌘B)
4. Run (⌘R)
5. Login
6. **Emails should now display!** 🎉

---

## Expected Result

**Before fix:**
- Backend synced 17 emails
- iOS showed 0 emails
- Console: "Decoding error: The data couldn't be read because it is missing."

**After fix:**
- Backend syncs 17 emails
- iOS shows all 17 emails
- Console: "✅ Backend sync completed: 17 emails synced"

---

## If Still Broken

**Check iOS console for NEW error message.**

Possible remaining issues:
- Date format mismatch
- UUID parsing (id is string, should be fine)
- Other field type mismatches

---

**Time to deploy:** 5 minutes  
**Time to test:** 2 minutes  
**Total:** ~7 minutes

---

**Ready to deploy!** Run `./DEPLOY-EMAIL-FIX.sh` when ready.
