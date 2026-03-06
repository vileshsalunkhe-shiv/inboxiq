# Email Sync Issue - Comprehensive Fix

## Problem Identified
iOS app shows **old emails** (from 12:00-13:00) at top, not the **latest ones** (from 15:00-16:00).

**Root Cause:**
Backend uses delta sync after initial sync. Your last sync was hours ago, so delta sync only fetches emails since then. But Gmail's history API has timing issues and may miss recent emails.

## Two Issues to Fix

### Issue #1: Delta Sync Missing Recent Emails
**Current behavior:**
- Initial sync: Fetches 20 most recent emails from last 7 days
- Delta sync: Fetches only changes since `last_history_id`
- Problem: Delta sync can miss emails due to timing/caching

**Fix:**
Increase initial sync limit from 20 → 100 emails AND improve delta sync fallback.

### Issue #2: Initial Sync Too Limited
**Current:** `max_results=20, newer_than:7d`  
**Better:** `max_results=100` for richer initial state

---

## Backend Fixes to Apply

**File:** `/backend/app/services/sync_service.py`

### Fix #1: Increase Initial Sync Limit
```python
async def _fetch_initial_message_ids(self, access_token: str) -> list[str]:
    # Increased from 20 to 100 for better initial state
    data = await self.gmail.list_messages(access_token, query="newer_than:7d", max_results=100)
    return [msg["id"] for msg in data.get("messages", [])]
```

### Fix #2: Add Fallback to Delta Sync
```python
async def sync(self, user_id: str) -> int:
    # ... existing code ...
    
    if history_id and has_emails:
        logger.info("sync_delta_mode", user_id=user_id, history_id=history_id)
        message_ids = await self._fetch_delta_message_ids(access_token, history_id)
        
        # NEW: If delta returns few/no results, fall back to recent initial sync
        if len(message_ids) < 5:
            logger.info("sync_delta_fallback", user_id=user_id, delta_count=len(message_ids))
            recent_ids = await self._fetch_initial_message_ids(access_token)
            # Merge unique IDs
            message_ids = list(set(message_ids + recent_ids))
            logger.info("sync_after_fallback", user_id=user_id, total_count=len(message_ids))
    else:
        logger.info("sync_initial_mode", user_id=user_id, has_emails=has_emails, history_id=history_id)
        message_ids = await self._fetch_initial_message_ids(access_token)
```

---

## Immediate Workaround (For Testing)

**Option A: Delete all emails in iOS app**
1. In iOS CoreData, clear all emails
2. Next sync will do initial sync (fetch latest 100)

**Option B: Call sync API multiple times**
Sync endpoint is idempotent, so calling it 2-3 times in a row may eventually fetch the missing emails.

**Option C: Wait for backend fix, then force re-sync**
Apply fixes above, deploy, then trigger sync.

---

## Which Do You Want?

1. **Quick test:** Just tap Sync button 2-3 times in iOS app (may fetch missing emails)
2. **Proper fix:** I apply the backend fixes above, deploy to Railway, you test again
3. **Nuclear option:** Delete iOS app data and re-login (forces initial sync)

**Recommendation:** Go with #2 (proper fix). Takes 5 minutes to apply and deploy.

Want me to apply the backend fixes now?
