#!/bin/bash
# Test OAuth locally to isolate Railway-specific issues
# Part of INB-2: Test OAuth flow locally (bypass Railway)

set -e  # Exit on error

echo "🔍 InboxIQ OAuth Local Testing"
echo "================================"
echo ""

# Navigate to backend directory
BACKEND_DIR="/Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend"
cd "$BACKEND_DIR"

echo "📁 Working directory: $BACKEND_DIR"
echo ""

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚠️  No .env file found. Creating from .env.example..."
    cp .env.example .env
    echo "✅ Created .env file"
    echo ""
    echo "🛠️  NEXT STEPS:"
    echo "   1. Edit .env and add your Google OAuth credentials:"
    echo "      • GOOGLE_CLIENT_ID"
    echo "      • GOOGLE_CLIENT_SECRET"
    echo "      • GOOGLE_REDIRECT_URI=http://localhost:8000/auth/google/callback"
    echo ""
    echo "   2. Generate an encryption key:"
    echo "      poetry run python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'"
    echo ""
    echo "   3. Add encryption key to .env:"
    echo "      ENCRYPTION_KEY=<generated-key>"
    echo ""
    echo "   4. Re-run this script"
    echo ""
    exit 1
fi

echo "✅ .env file exists"
echo ""

# Check if PostgreSQL is running
echo "🔍 Checking PostgreSQL..."
if ! pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    echo "⚠️  PostgreSQL is not running on localhost:5432"
    echo ""
    echo "🛠️  Start PostgreSQL:"
    echo "   brew services start postgresql@14"
    echo ""
    exit 1
fi

echo "✅ PostgreSQL is running"
echo ""

# Check if Redis is running
echo "🔍 Checking Redis..."
if ! redis-cli ping > /dev/null 2>&1; then
    echo "⚠️  Redis is not running on localhost:6379"
    echo ""
    echo "🛠️  Start Redis:"
    echo "   brew services start redis"
    echo ""
    exit 1
fi

echo "✅ Redis is running"
echo ""

# Check if database exists
echo "🔍 Checking database..."
if ! psql -h localhost -U postgres -lqt | cut -d \| -f 1 | grep -qw inboxiq; then
    echo "⚠️  Database 'inboxiq' does not exist"
    echo ""
    echo "🛠️  Create database:"
    echo "   createdb -h localhost -U postgres inboxiq"
    echo ""
    echo "Creating database now..."
    createdb -h localhost -U postgres inboxiq
    echo "✅ Database created"
else
    echo "✅ Database 'inboxiq' exists"
fi

echo ""

# Run migrations
echo "🔄 Running database migrations..."
poetry run alembic upgrade head
echo "✅ Migrations complete"
echo ""

# Start backend server
echo "🚀 Starting backend server on http://localhost:8000"
echo ""
echo "📝 Test OAuth flow:"
echo "   1. Update iOS app to point to http://localhost:8000"
echo "   2. Launch iOS app in simulator"
echo "   3. Tap 'Sign in with Google'"
echo "   4. Complete Google authentication"
echo "   5. Watch logs below for OAuth exchange"
echo ""
echo "🔍 Look for these log entries:"
echo "   • google_oauth_token_exchange_attempt"
echo "   • google_oauth_token_exchange_response"
echo "   • google_oauth_token_exchange_failed (if error)"
echo ""
echo "Press Ctrl+C to stop server"
echo ""
echo "================================"
echo ""

# Start server with auto-reload
poetry run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
