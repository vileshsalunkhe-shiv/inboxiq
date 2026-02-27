# InboxIQ Backend – Implementation Notes (Phase 1)

## Overview
This FastAPI backend provides Google OAuth login, JWT auth, Gmail sync, AI categorization, and digest generation. It uses async SQLAlchemy with PostgreSQL, Redis-based rate limiting, and a lightweight worker for AI processing.

## Key Components
- **FastAPI app**: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/main.py`
  - CORS enabled (wide-open for Phase 1).
  - Redis + `fastapi-limiter` initialized on startup.
  - Health check at `/health` verifies DB connectivity.
  - Structured JSON logging via `structlog`.
- **Database**: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/database.py`
  - Async SQLAlchemy engine/session.
  - Models in `/app/models`.
- **Auth**: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/services/auth_service.py`
  - Google OAuth URL generation and token exchange.
  - JWT access + refresh tokens.
  - Refresh token rotation and revocation.
  - Encrypted storage of Google refresh tokens (Fernet).
- **Gmail integration**: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/services/gmail_service.py`
  - Uses Gmail API for list, get, history, send.
  - `asyncio.to_thread` wraps Google API (blocking) calls.
- **Sync service**: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/services/sync_service.py`
  - Initial sync: last 7 days.
  - Delta sync: Gmail `historyId`.
  - Inserts emails and queues AI processing.
- **AI service**: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/services/ai_service.py`
  - Uses `anthropic.AsyncAnthropic` with Claude Haiku.
  - Robust JSON parsing with `_safe_json`.
  - Graceful fallback if API key missing or model response invalid.
- **Worker**: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/worker.py`
  - Polls `ai_queue` for pending items.
  - Updates email category + queue status.
- **Digest**: `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/services/digest_service.py`
  - Builds summary payload from recent emails.
  - Requests AI summary and emails digest via Gmail API.

## Data Model Summary
- **User**: email, Google token blob, last history ID.
- **Email**: user_id, gmail_id, subject, sender, snippet, category, received_at.
- **AIQueue**: email_id, status, attempts, error.
- **RefreshToken**: user_id, token_hash, revoked, expires_at.
- **DigestSettings**: frequency hours.

## Security & Error Handling
- JWTs signed with `JWT_SECRET`.
- Refresh tokens are **hashed** in DB for safety.
- Google OAuth refresh tokens are **encrypted** with Fernet (`ENCRYPTION_KEY`).
- `AuthService` raises `ValueError` for invalid tokens; API routes convert to HTTP 401/400.
- AI service always returns a fallback category/summary on failures.
- Sync worker logs processing failures and captures errors in `ai_queue`.

## Environment Variables
See `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/.env.example` for the full list.

## Running Locally
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload
python worker.py
```

## Tests
- Located in `/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend/app/tests/`.
- Coverage includes:
  - Auth URL generation
  - Token hashing determinism
  - AI response JSON parsing

Run:
```bash
pytest
```

## Notable Phase 1 Tradeoffs
- Wide-open CORS for rapid iteration.
- Minimal rate limiting defaults (Redis-based, can be tuned).
- Basic email filtering uses string dates; can be extended to strict datetime parsing as needed.
- AI prompt responses assume JSON output; `_safe_json` provides resilience if format deviates.

## Next Steps (Phase 2+)
- Add background job system (e.g., Celery/RQ) instead of polling worker.
- Expand test coverage for API routes and DB interactions.
- Tighten CORS + introduce per-user rate limits.
- Improve digest templates and delivery status tracking.
