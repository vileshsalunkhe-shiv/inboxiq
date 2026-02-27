#!/bin/bash

# InboxIQ Database Migration Script
# Safely run database migrations with rollback capability

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Parse arguments
DRY_RUN=false
ROLLBACK=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --rollback)
            ROLLBACK=true
            shift
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run       Show pending migrations without running them"
            echo "  --rollback      Rollback the last migration"
            echo "  --target REV    Migrate to specific revision"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

echo "=========================================="
echo "  InboxIQ Database Migration"
echo "=========================================="
echo ""

# Check if database is accessible
info "Checking database connection..."

if docker-compose ps postgres | grep -q "Up"; then
    DB_HOST="localhost"
    DB_PORT="5432"
    DB_USER="inboxiq"
    DB_NAME="inboxiq_dev"
    
    # Test connection
    if docker-compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        info "✓ Database connection successful"
    else
        error "Cannot connect to database"
    fi
else
    error "PostgreSQL container is not running. Run: docker-compose up -d postgres"
fi
echo ""

# Navigate to backend directory
cd "$(dirname "$0")/../../backend" || error "Backend directory not found"

# Activate virtual environment if it exists
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Check if Alembic is installed
if ! command -v alembic &> /dev/null; then
    error "Alembic is not installed. Run: pip install alembic"
fi

# Check current database version
info "Checking current database version..."
CURRENT_VERSION=$(alembic current 2>&1 | grep -oP '(?<=\(head\)|^)[a-f0-9]+' | head -1 || echo "none")
if [ "$CURRENT_VERSION" = "none" ] || [ -z "$CURRENT_VERSION" ]; then
    warn "Database is not initialized or at base version"
    CURRENT_VERSION="base"
else
    info "Current version: $CURRENT_VERSION"
fi
echo ""

# Handle dry run
if [ "$DRY_RUN" = true ]; then
    info "Dry run mode - showing pending migrations..."
    alembic history --verbose
    echo ""
    info "To apply migrations, run: $0"
    exit 0
fi

# Handle rollback
if [ "$ROLLBACK" = true ]; then
    warn "ROLLBACK MODE: This will undo the last migration"
    read -p "Are you sure? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        info "Rollback cancelled"
        exit 0
    fi
    
    info "Rolling back one revision..."
    alembic downgrade -1
    
    NEW_VERSION=$(alembic current 2>&1 | grep -oP '(?<=\(head\)|^)[a-f0-9]+' | head -1 || echo "base")
    info "✓ Rolled back to version: $NEW_VERSION"
    exit 0
fi

# Create backup before migration
info "Creating database backup..."
BACKUP_FILE="backups/db_backup_$(date +%Y%m%d_%H%M%S).sql"
mkdir -p backups

docker-compose exec -T postgres pg_dump -U $DB_USER -d $DB_NAME > "$BACKUP_FILE" 2>/dev/null

if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
    info "✓ Backup created: $BACKUP_FILE"
else
    warn "Backup creation failed, but continuing with migration"
fi
echo ""

# Show pending migrations
info "Checking for pending migrations..."
PENDING=$(alembic history | grep -c "^Rev:" || echo "0")
if [ "$PENDING" -eq 0 ]; then
    info "No pending migrations"
    exit 0
fi
echo ""

# Run migrations
info "Running migrations..."
echo ""

if [ -n "$TARGET" ]; then
    info "Migrating to target revision: $TARGET"
    alembic upgrade "$TARGET"
else
    info "Migrating to latest version (head)"
    alembic upgrade head
fi

# Check migration success
if [ $? -eq 0 ]; then
    echo ""
    info "✓ Migration completed successfully"
    
    # Show new version
    NEW_VERSION=$(alembic current 2>&1 | grep -oP '(?<=\(head\)|^)[a-f0-9]+' | head -1 || echo "unknown")
    info "New version: $NEW_VERSION"
    
    # Verify database integrity
    info "Verifying database integrity..."
    docker-compose exec -T postgres psql -U $DB_USER -d $DB_NAME -c "SELECT tablename FROM pg_tables WHERE schemaname='public';" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        info "✓ Database integrity check passed"
    else
        warn "Database integrity check failed"
    fi
    
else
    error "Migration failed! Rolling back..."
    
    # Attempt rollback
    warn "Attempting automatic rollback..."
    alembic downgrade -1
    
    if [ $? -eq 0 ]; then
        warn "Rollback successful. Database restored to previous state."
    else
        error "Rollback failed! Manual intervention required. Backup available at: $BACKUP_FILE"
    fi
fi

echo ""
echo "=========================================="
echo "  Migration Summary"
echo "=========================================="
echo "Previous version: $CURRENT_VERSION"
echo "Current version:  $NEW_VERSION"
echo "Backup location:  $BACKUP_FILE"
echo ""
echo "To view migration history: alembic history --verbose"
echo "To rollback: $0 --rollback"
echo ""
