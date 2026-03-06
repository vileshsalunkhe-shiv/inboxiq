#!/bin/bash
# Run Alembic migration on Railway

cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Use Railway environment variables
export DATABASE_URL="${DATABASE_URL}"

# Run migration
alembic upgrade head

echo "✅ Migration complete"
