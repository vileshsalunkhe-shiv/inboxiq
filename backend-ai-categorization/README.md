# InboxIQ Backend

FastAPI backend for InboxIQ with Gmail sync, AI categorization worker, and daily digest support.

## Features
- Google OAuth 2.0 login + token refresh
- JWT access/refresh tokens with rotation
- Gmail delta sync via historyId
- AI categorization worker (Claude Sonnet 4)
- Digest settings + manual digest send
- Structured logging + Sentry
- Rate limiting via Redis

## Quick Start

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
```

Run the API:
```bash
uvicorn app.main:app --reload
```

Run the worker:
```bash
python worker.py
```

## Database Migrations

Alembic is scaffolded in `/alembic`.

```bash
alembic init alembic
alembic revision --autogenerate -m "init"
alembic upgrade head
```

## Environment Variables
See `.env.example` for full list.

## API Docs
FastAPI docs available at:
- http://localhost:8000/docs
- http://localhost:8000/redoc

## AI Categorization

Categories:
- Urgent
- Action Required
- Finance
- FYI
- Newsletter
- Receipt
- Spam

Example cURL:

```bash
# Categorize a single email
curl -X POST "http://localhost:8000/emails/123/categorize" \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# Categorize uncategorized emails (batch)
curl -X POST "http://localhost:8000/emails/categorize-all?limit=200" \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# Filter emails by category
curl "http://localhost:8000/emails?category=Urgent" \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# Category stats
curl "http://localhost:8000/categories/stats" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

## Testing

```bash
pytest
```

## Health Check

`GET /health`
