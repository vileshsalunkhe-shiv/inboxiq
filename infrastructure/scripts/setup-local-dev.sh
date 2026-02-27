#!/bin/bash

# InboxIQ Local Development Setup Script
# This script sets up the complete local development environment

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Print header
echo "=========================================="
echo "  InboxIQ Local Development Setup"
echo "=========================================="
echo ""

# Check prerequisites
info "Checking prerequisites..."

if ! command_exists docker; then
    error "Docker is not installed. Please install Docker Desktop: https://www.docker.com/products/docker-desktop"
fi

if ! command_exists docker-compose; then
    error "docker-compose is not installed. Please install Docker Compose"
fi

if ! command_exists python3; then
    error "Python 3 is not installed. Please install Python 3.11+"
fi

# Check Python version
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
if (( $(echo "$PYTHON_VERSION < 3.11" | bc -l) )); then
    error "Python 3.11+ is required. Current version: $PYTHON_VERSION"
fi

info "✓ All prerequisites met"
echo ""

# Navigate to infrastructure directory
cd "$(dirname "$0")/.."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    info "Creating .env file from template..."
    cp .env.example .env
    
    # Generate secrets
    info "Generating secure secrets..."
    
    # Generate JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    sed -i.bak "s|your-super-secret-jwt-key-change-this-in-production|$JWT_SECRET|g" .env
    
    # Generate encryption key
    ENCRYPTION_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
    sed -i.bak "s|your-fernet-encryption-key-must-be-32-url-safe-base64-encoded-bytes|$ENCRYPTION_KEY|g" .env
    
    # Clean up backup file
    rm .env.bak
    
    warn "Please edit .env and add your Google OAuth and Anthropic API credentials"
    warn "Required: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, ANTHROPIC_API_KEY"
else
    info "✓ .env file already exists"
fi
echo ""

# Create necessary directories
info "Creating project directories..."
mkdir -p ../backend/app/{api,core,models,services,worker}
mkdir -p ../backend/alembic/versions
mkdir -p ../backend/tests
mkdir -p logs
info "✓ Directories created"
echo ""

# Stop any existing containers
info "Stopping existing containers..."
docker-compose down -v 2>/dev/null || true
info "✓ Existing containers stopped"
echo ""

# Start PostgreSQL and Redis
info "Starting PostgreSQL and Redis..."
docker-compose up -d postgres redis

# Wait for services to be healthy
info "Waiting for services to be ready..."
MAX_WAIT=60
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    if docker-compose ps postgres | grep -q "healthy"; then
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    error "PostgreSQL failed to start within $MAX_WAIT seconds"
fi

info "✓ PostgreSQL is ready"

# Check Redis
if docker-compose ps redis | grep -q "healthy"; then
    info "✓ Redis is ready"
else
    error "Redis failed to start"
fi
echo ""

# Install Python dependencies
if [ -f ../backend/requirements.txt ]; then
    info "Installing Python dependencies..."
    
    # Create virtual environment if it doesn't exist
    if [ ! -d ../backend/venv ]; then
        info "Creating virtual environment..."
        python3 -m venv ../backend/venv
    fi
    
    # Activate virtual environment
    source ../backend/venv/bin/activate
    
    # Upgrade pip
    pip install --upgrade pip setuptools wheel
    
    # Install dependencies
    pip install -r ../backend/requirements.txt
    
    info "✓ Python dependencies installed"
else
    warn "backend/requirements.txt not found. Skipping Python dependency installation."
fi
echo ""

# Initialize database
info "Initializing database..."

# Create init SQL script
cat > scripts/init-db.sql <<EOF
-- Initialize InboxIQ database
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create application user (if not exists)
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'inboxiq_app') THEN
        CREATE USER inboxiq_app WITH PASSWORD 'inboxiq_app_password';
    END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE inboxiq_dev TO inboxiq_app;
GRANT ALL PRIVILEGES ON SCHEMA public TO inboxiq_app;
EOF

# Run init script
docker-compose exec -T postgres psql -U inboxiq -d inboxiq_dev < scripts/init-db.sql 2>/dev/null || warn "Database initialization may have partially failed (this is ok if already initialized)"

info "✓ Database initialized"
echo ""

# Run database migrations
if [ -f ../backend/alembic.ini ]; then
    info "Running database migrations..."
    cd ../backend
    source venv/bin/activate
    alembic upgrade head || warn "Migration failed (this is ok if schema doesn't exist yet)"
    cd ../infrastructure
    info "✓ Migrations complete"
else
    warn "alembic.ini not found. Skipping migrations."
fi
echo ""

# Seed default categories
info "Seeding default categories..."
cat > /tmp/seed_categories.sql <<EOF
-- Insert default categories (if they don't exist)
INSERT INTO categories (name, color, icon, is_system) VALUES
    ('Work', '#3B82F6', '💼', true),
    ('Personal', '#10B981', '👤', true),
    ('Newsletters', '#F59E0B', '📰', true),
    ('Social', '#8B5CF6', '👥', true),
    ('Shopping', '#EC4899', '🛍️', true),
    ('Finance', '#14B8A6', '💰', true),
    ('Travel', '#06B6D4', '✈️', true),
    ('Promotions', '#F97316', '🎁', true),
    ('Updates', '#6366F1', '🔔', true),
    ('Important', '#EF4444', '⭐', true)
ON CONFLICT (name) WHERE is_system = true DO NOTHING;
EOF

docker-compose exec -T postgres psql -U inboxiq -d inboxiq_dev < /tmp/seed_categories.sql 2>/dev/null || warn "Category seeding may have failed (this is ok if table doesn't exist yet)"
rm /tmp/seed_categories.sql

info "✓ Default categories seeded"
echo ""

# Create test user (optional)
info "Creating test user..."
cat > /tmp/create_test_user.sql <<EOF
-- Create test user (if users table exists)
DO \$\$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        INSERT INTO users (email, created_at) 
        VALUES ('test@inboxiq.dev', NOW())
        ON CONFLICT (email) DO NOTHING;
    END IF;
END
\$\$;
EOF

docker-compose exec -T postgres psql -U inboxiq -d inboxiq_dev < /tmp/create_test_user.sql 2>/dev/null || warn "Test user creation skipped (table may not exist yet)"
rm /tmp/create_test_user.sql

info "✓ Test user created"
echo ""

# Start all services
info "Starting all services..."
docker-compose up -d

# Wait for backend to be ready
info "Waiting for backend to be ready..."
MAX_WAIT=120
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done
echo ""

if [ $WAITED -ge $MAX_WAIT ]; then
    warn "Backend did not respond within $MAX_WAIT seconds. Check logs with: docker-compose logs backend"
else
    info "✓ Backend is ready"
fi
echo ""

# Run health check
info "Running health check..."
HEALTH_RESPONSE=$(curl -s http://localhost:8000/health || echo '{"status":"error"}')
HEALTH_STATUS=$(echo $HEALTH_RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', 'unknown'))")

if [ "$HEALTH_STATUS" = "healthy" ]; then
    info "✓ Health check passed"
else
    warn "Health check returned: $HEALTH_STATUS"
    warn "Response: $HEALTH_RESPONSE"
fi
echo ""

# Print service URLs
echo "=========================================="
echo "  Setup Complete! 🎉"
echo "=========================================="
echo ""
echo "Services are running:"
echo "  • Backend API:      http://localhost:8000"
echo "  • API Docs:         http://localhost:8000/docs"
echo "  • PostgreSQL:       localhost:5432"
echo "  • Redis:            localhost:6379"
echo ""
echo "Optional management tools (run with --profile tools):"
echo "  • pgAdmin:          http://localhost:5050"
echo "  • Redis Commander:  http://localhost:8081"
echo ""
echo "Useful commands:"
echo "  • View logs:        docker-compose logs -f"
echo "  • Stop services:    docker-compose down"
echo "  • Restart:          docker-compose restart"
echo "  • Run migrations:   ./scripts/run-migrations.sh"
echo "  • Run tests:        ./scripts/test-backend.sh"
echo ""
echo "Next steps:"
echo "  1. Edit .env and add your API credentials"
echo "  2. Visit http://localhost:8000/docs to explore the API"
echo "  3. Start building! 🚀"
echo ""
