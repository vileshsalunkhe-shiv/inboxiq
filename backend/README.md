# InboxIQ Backend

FastAPI backend for InboxIQ with Gmail sync, AI categorization worker, and daily digest support.

## Features
- Google OAuth 2.0 login + token refresh
- JWT access/refresh tokens with rotation
- Gmail delta sync via historyId
- AI categorization worker (Claude Haiku)
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

## Testing

```bash
pytest
```

## Health Check

`GET /health`
