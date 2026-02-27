#!/bin/bash

# InboxIQ Railway Deployment Script
# Automated deployment with health checks and rollback capability

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_NAME="inboxiq"
GIT_REQUIRED=true
HEALTH_CHECK_TIMEOUT=300  # 5 minutes
HEALTH_CHECK_INTERVAL=10  # 10 seconds

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

debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Parse arguments
ENVIRONMENT="production"
SERVICE="all"
SKIP_TESTS=false
SKIP_MIGRATIONS=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --service)
            SERVICE="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-migrations)
            SKIP_MIGRATIONS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --env ENV           Environment (staging|production) [default: production]"
            echo "  --service SERVICE   Deploy specific service (backend|worker|all) [default: all]"
            echo "  --skip-tests        Skip pre-deployment tests"
            echo "  --skip-migrations   Skip database migrations"
            echo "  --dry-run           Show what would be deployed without deploying"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Print header
echo "=========================================="
echo "  InboxIQ Deployment to Railway"
echo "=========================================="
echo ""
info "Environment: $ENVIRONMENT"
info "Service: $SERVICE"
echo ""

# Pre-flight checks
info "Running pre-flight checks..."

# Check Railway CLI
if ! command_exists railway; then
    error "Railway CLI not installed. Install with: npm install -g @railway/cli"
fi

# Check if logged in
if ! railway whoami &> /dev/null; then
    error "Not logged into Railway. Run: railway login"
fi

# Check git status
if [ "$GIT_REQUIRED" = true ]; then
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository"
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        warn "You have uncommitted changes"
        read -p "Continue anyway? (yes/no): " CONTINUE
        if [ "$CONTINUE" != "yes" ]; then
            error "Deployment cancelled"
        fi
    fi
    
    # Get current commit
    GIT_COMMIT=$(git rev-parse --short HEAD)
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    
    info "Git commit: $GIT_COMMIT"
    info "Git branch: $GIT_BRANCH"
fi

info "✓ Pre-flight checks passed"
echo ""

# Run tests
if [ "$SKIP_TESTS" = false ]; then
    info "Running pre-deployment tests..."
    
    # Check if backend tests exist
    if [ -f "../backend/tests/test_main.py" ]; then
        cd ../backend
        python -m pytest tests/ -v || error "Tests failed. Fix issues or use --skip-tests"
        cd ../infrastructure
        info "✓ Tests passed"
    else
        warn "No tests found, skipping"
    fi
    echo ""
fi

# Dry run check
if [ "$DRY_RUN" = true ]; then
    info "DRY RUN MODE - No actual deployment will occur"
    echo ""
fi

# Tag deployment
DEPLOY_TAG="deploy-${ENVIRONMENT}-$(date +%Y%m%d-%H%M%S)"
if [ "$GIT_REQUIRED" = true ]; then
    DEPLOY_TAG="${DEPLOY_TAG}-${GIT_COMMIT}"
fi

info "Deployment tag: $DEPLOY_TAG"

if [ "$DRY_RUN" = false ]; then
    git tag -a "$DEPLOY_TAG" -m "Deployment to $ENVIRONMENT on $(date)" 2>/dev/null || warn "Failed to create git tag"
fi
echo ""

# Build Docker images locally (optional verification)
info "Building Docker images for verification..."

if [ "$SERVICE" = "all" ] || [ "$SERVICE" = "backend" ]; then
    info "Building backend image..."
    if [ "$DRY_RUN" = false ]; then
        docker build -f railway/backend.Dockerfile -t inboxiq-backend:$DEPLOY_TAG ../ || error "Backend build failed"
        info "✓ Backend image built"
    else
        info "[DRY RUN] Would build backend image"
    fi
fi

if [ "$SERVICE" = "all" ] || [ "$SERVICE" = "worker" ]; then
    info "Building worker image..."
    if [ "$DRY_RUN" = false ]; then
        docker build -f railway/worker.Dockerfile -t inboxiq-worker:$DEPLOY_TAG ../ || error "Worker build failed"
        info "✓ Worker image built"
    else
        info "[DRY RUN] Would build worker image"
    fi
fi
echo ""

# Deploy to Railway
info "Deploying to Railway..."

if [ "$DRY_RUN" = true ]; then
    info "[DRY RUN] Would deploy $SERVICE to Railway"
    exit 0
fi

# Record current deployment for rollback
PREVIOUS_DEPLOYMENT=$(railway status --json 2>/dev/null | grep -o '"deploymentId":"[^"]*"' | head -1 || echo "")
info "Recording current deployment for potential rollback: $PREVIOUS_DEPLOYMENT"

# Deploy based on service selection
if [ "$SERVICE" = "all" ]; then
    info "Deploying all services..."
    railway up || error "Deployment failed"
elif [ "$SERVICE" = "backend" ]; then
    info "Deploying backend service..."
    railway up --service backend || error "Backend deployment failed"
elif [ "$SERVICE" = "worker" ]; then
    info "Deploying worker service..."
    railway up --service worker || error "Worker deployment failed"
else
    error "Invalid service: $SERVICE"
fi

info "✓ Deployment initiated"
echo ""

# Run migrations
if [ "$SKIP_MIGRATIONS" = false ] && ([ "$SERVICE" = "all" ] || [ "$SERVICE" = "backend" ]); then
    info "Running database migrations..."
    
    railway run --service backend alembic upgrade head || {
        error "Migration failed! Rolling back deployment..."
        # Attempt rollback
        if [ -n "$PREVIOUS_DEPLOYMENT" ]; then
            railway rollback "$PREVIOUS_DEPLOYMENT" || warn "Rollback failed"
        fi
        exit 1
    }
    
    info "✓ Migrations completed"
    echo ""
fi

# Wait for deployment to complete
info "Waiting for deployment to complete..."
sleep 10

# Get deployment URL
BACKEND_URL=$(railway url --service backend 2>/dev/null || echo "")
if [ -z "$BACKEND_URL" ]; then
    warn "Could not retrieve backend URL"
    BACKEND_URL="https://inboxiq-backend.railway.app"  # Fallback
fi

info "Backend URL: $BACKEND_URL"
echo ""

# Health check
info "Running health checks..."
HEALTH_ELAPSED=0
HEALTH_PASSED=false

while [ $HEALTH_ELAPSED -lt $HEALTH_CHECK_TIMEOUT ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND_URL/health" 2>/dev/null || echo "000")
    
    if [ "$HTTP_CODE" = "200" ]; then
        # Check health status
        HEALTH_RESPONSE=$(curl -s "$BACKEND_URL/health" 2>/dev/null || echo "{}")
        HEALTH_STATUS=$(echo "$HEALTH_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        
        if [ "$HEALTH_STATUS" = "healthy" ]; then
            HEALTH_PASSED=true
            break
        fi
    fi
    
    echo -n "."
    sleep $HEALTH_CHECK_INTERVAL
    HEALTH_ELAPSED=$((HEALTH_ELAPSED + HEALTH_CHECK_INTERVAL))
done
echo ""

if [ "$HEALTH_PASSED" = true ]; then
    info "✓ Health check passed after ${HEALTH_ELAPSED}s"
else
    error "Health check failed after ${HEALTH_CHECK_TIMEOUT}s. Check logs: railway logs --service backend"
fi
echo ""

# Verify all services
info "Verifying deployment..."

# Check database
DB_CHECK=$(curl -s "$BACKEND_URL/health" | grep -o '"database":"[^"]*"' | cut -d'"' -f4)
if [ "$DB_CHECK" = "ok" ]; then
    info "✓ Database connection healthy"
else
    warn "Database check failed: $DB_CHECK"
fi

# Check Redis
REDIS_CHECK=$(curl -s "$BACKEND_URL/health" | grep -o '"redis":"[^"]*"' | cut -d'"' -f4)
if [ "$REDIS_CHECK" = "ok" ]; then
    info "✓ Redis connection healthy"
else
    warn "Redis check failed: $REDIS_CHECK"
fi

echo ""

# Smoke tests
info "Running smoke tests..."
../infrastructure/scripts/test-backend.sh --url "$BACKEND_URL" || warn "Some smoke tests failed"
echo ""

# Print deployment summary
echo "=========================================="
echo "  Deployment Summary"
echo "=========================================="
echo ""
echo "Environment:     $ENVIRONMENT"
echo "Service:         $SERVICE"
echo "Deployment tag:  $DEPLOY_TAG"
if [ -n "$GIT_COMMIT" ]; then
    echo "Git commit:      $GIT_COMMIT"
    echo "Git branch:      $GIT_BRANCH"
fi
echo ""
echo "URLs:"
echo "  Backend:       $BACKEND_URL"
echo "  API Docs:      $BACKEND_URL/docs"
echo "  Health:        $BACKEND_URL/health"
echo ""
echo "Railway commands:"
echo "  View logs:     railway logs --service backend"
echo "  View status:   railway status"
echo "  Rollback:      railway rollback"
echo ""
echo -e "${GREEN}✓ Deployment complete!${NC}"
echo ""
