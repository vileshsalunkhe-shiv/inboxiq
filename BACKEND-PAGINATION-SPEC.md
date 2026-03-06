# Backend Pagination Task Specification

## Goal
Add pagination support for emails and calendar events to allow users to load older/newer data beyond the initial 7-day windows.

## Context
- **Current behavior:**
  - Emails: Initial sync fetches last 7 days only
  - Calendar: Fetches next 7 days (upcoming events)
- **Linear issue:** INB-21
- **User need:** Access older emails and past/future calendar events

---

## Task 1: Email Pagination

### Current Endpoint
```
GET /emails?user_id={uuid}
```

### Required Changes

**1. Add pagination parameters:**
```python
GET /emails?user_id={uuid}&page_token={token}&max_results={int}
```

**Parameters:**
- `page_token` (optional, string): Token for next page (Gmail pageToken)
- `max_results` (optional, int): Results per page (default: 50, max: 100)

**2. Update response to include pagination metadata:**
```json
{
  "emails": [...],
  "next_page_token": "string or null",
  "has_more": boolean,
  "total_fetched": int
}
```

**3. Implementation notes:**
- Use Gmail API's `pageToken` parameter for pagination
- Store current page state (don't need to persist, stateless pagination)
- Return `next_page_token` from Gmail API response
- `has_more = true` if `next_page_token` exists

**Files to modify:**
- `app/api/emails.py` - Update list endpoint
- `app/services/gmail_service.py` - Add pageToken support to list_messages()

---

## Task 2: Calendar Pagination

### Current Endpoint
```
GET /calendar/events?user_id={uuid}&max_results={int}
```

### Required Changes

**1. Add time range parameters:**
```python
GET /calendar/events?user_id={uuid}&time_min={iso8601}&time_max={iso8601}&max_results={int}
```

**Parameters:**
- `time_min` (optional, ISO8601 datetime): Start of time range
- `time_max` (optional, ISO8601 datetime): End of time range
- `max_results` (optional, int): Results per page (default: 10, max: 50)

**2. Default behavior (if not specified):**
```python
time_min = datetime.utcnow()  # Now
time_max = time_min + timedelta(days=7)  # Next 7 days
```

**3. Support past events:**
```python
# Example: Load past events
time_min = datetime.utcnow() - timedelta(days=30)
time_max = datetime.utcnow()
```

**4. Update response (no change needed, already returns list):**
```json
[
  {
    "id": "string",
    "summary": "string",
    "start": "iso8601",
    "end": "iso8601",
    ...
  }
]
```

**Files to modify:**
- `app/api/calendar.py` - Update list_calendar_events endpoint
- `app/services/calendar_service.py` - Already supports time_min/time_max (just expose in API)

---

## API Contract (for iOS team)

### Email Pagination Response
```typescript
{
  "emails": Array<{
    id: string,
    gmail_id: string,
    subject: string,
    sender: string,
    category: string | null,
    ai_summary: string | null,
    ai_confidence: number | null,
    snippet: string,
    received_at: string  // ISO8601
  }>,
  "next_page_token": string | null,
  "has_more": boolean,
  "total_fetched": number
}
```

### Calendar Events Response (unchanged)
```typescript
Array<{
  id: string,
  summary: string,
  description: string | null,
  start: string,  // ISO8601
  end: string,    // ISO8601
  location: string | null,
  attendees: Array<{
    email: string | null,
    display_name: string | null
  }>,
  html_link: string
}>
```

---

## Testing

### Email Pagination
1. First request: `GET /emails?user_id={uuid}` → Returns 50 recent emails + page token
2. Next page: `GET /emails?user_id={uuid}&page_token={token}` → Returns next 50 emails
3. Last page: Returns emails with `next_page_token: null`, `has_more: false`

### Calendar Past Events
1. Request: `GET /calendar/events?user_id={uuid}&time_min=2026-02-01T00:00:00Z&time_max=2026-03-01T00:00:00Z`
2. Returns: Events from February 2026

### Calendar Future Events
1. Request: `GET /calendar/events?user_id={uuid}&time_min=2026-03-10T00:00:00Z&time_max=2026-03-31T00:00:00Z`
2. Returns: Events beyond the initial 7-day window

---

## Deliverables

1. **Modified files:**
   - `app/api/emails.py`
   - `app/services/gmail_service.py`
   - `app/api/calendar.py`
   - `app/services/calendar_service.py` (if needed)

2. **Testing commands:**
   ```bash
   # Test email pagination
   curl "http://localhost:8000/emails?user_id={uuid}"
   curl "http://localhost:8000/emails?user_id={uuid}&page_token={token}"
   
   # Test calendar past events
   curl "http://localhost:8000/calendar/events?user_id={uuid}&time_min=2026-02-01T00:00:00Z&time_max=2026-03-01T00:00:00Z"
   ```

3. **Documentation:**
   - API changes documented
   - Response format examples

---

## Notes
- Keep existing default behavior (7-day windows) when parameters not provided
- Use Gmail API's built-in pagination (don't reinvent)
- Calendar already supports time ranges, just expose in API
- No database changes needed (stateless pagination)

---

**Estimated time:** 2-3 hours
**Agent:** DEV-BE-premium (GPT-5.2-Codex)
