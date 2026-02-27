#!/bin/bash

# InboxIQ Backend Smoke Tests
# Quick verification that all critical endpoints are working

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKEND_URL="${BACKEND_URL:-http://localhost:8000}"
VERBOSE=false
TESTS_PASSED=0
TESTS_FAILED=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --url)
            BACKEND_URL="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --url URL       Backend URL (default: http://localhost:8000)"
            echo "  -v, --verbose   Show detailed output"
            echo "  -h, --help      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

debug() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[DEBUG]${NC} $1"
    fi
}

# Test function wrapper
test_endpoint() {
    local name="$1"
    local method="$2"
    local path="$3"
    local expected_status="$4"
    local data="$5"
    
    debug "Testing: $method $BACKEND_URL$path"
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$BACKEND_URL$path" 2>&1)
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$BACKEND_URL$path" \
            -H "Content-Type: application/json" \
            -d "$data" 2>&1)
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    debug "Status: $status_code"
    debug "Response: $body"
    
    if [ "$status_code" = "$expected_status" ]; then
        pass "$name"
        return 0
    else
        fail "$name (expected $expected_status, got $status_code)"
        if [ "$VERBOSE" = true ]; then
            echo "    Response: $body"
        fi
        return 1
    fi
}

# Print header
echo "=========================================="
echo "  InboxIQ Backend Smoke Tests"
echo "=========================================="
echo ""
info "Testing backend at: $BACKEND_URL"
echo ""

# Test 1: Health Check
echo "📊 Infrastructure Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "Health check endpoint" "GET" "/health" "200"

# Verify health response structure
health_response=$(curl -s "$BACKEND_URL/health")
if echo "$health_response" | grep -q '"status"'; then
    pass "Health response has status field"
else
    fail "Health response missing status field"
fi

if echo "$health_response" | grep -q '"checks"'; then
    pass "Health response has checks field"
else
    fail "Health response missing checks field"
fi
echo ""

# Test 2: API Documentation
echo "📚 Documentation Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "OpenAPI docs available" "GET" "/docs" "200"
test_endpoint "OpenAPI JSON schema" "GET" "/openapi.json" "200"
echo ""

# Test 3: Authentication Endpoints
echo "🔐 Authentication Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "Login endpoint exists" "POST" "/auth/login" "422"  # 422 = validation error (no data)
test_endpoint "Refresh endpoint exists" "POST" "/auth/refresh" "401"  # 401 = unauthorized
test_endpoint "Logout endpoint exists" "POST" "/auth/logout" "401"  # 401 = unauthorized
echo ""

# Test 4: Email Endpoints (Protected)
echo "📧 Email Endpoint Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "List emails (protected)" "GET" "/emails" "401"  # Should require auth
test_endpoint "Sync emails (protected)" "POST" "/emails/sync" "401"  # Should require auth
echo ""

# Test 5: Category Endpoints
echo "🏷️  Category Endpoint Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "List categories (protected)" "GET" "/categories" "401"  # Should require auth
echo ""

# Test 6: Database Connectivity
echo "🗄️  Database Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
health=$(curl -s "$BACKEND_URL/health")
db_status=$(echo "$health" | grep -o '"database":"[^"]*"' | cut -d'"' -f4)

if [ "$db_status" = "ok" ]; then
    pass "Database connection healthy"
else
    fail "Database connection failed (status: $db_status)"
fi
echo ""

# Test 7: Redis Connectivity
echo "📦 Redis Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
redis_status=$(echo "$health" | grep -o '"redis":"[^"]*"' | cut -d'"' -f4)

if [ "$redis_status" = "ok" ]; then
    pass "Redis connection healthy"
else
    fail "Redis connection failed (status: $redis_status)"
fi
echo ""

# Test 8: CORS Headers
echo "🌐 CORS Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cors_response=$(curl -s -I -X OPTIONS "$BACKEND_URL/health" \
    -H "Origin: http://localhost:3000" \
    -H "Access-Control-Request-Method: GET")

if echo "$cors_response" | grep -qi "Access-Control-Allow-Origin"; then
    pass "CORS headers present"
else
    fail "CORS headers missing"
fi
echo ""

# Test 9: Rate Limiting
echo "🚦 Rate Limiting Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
rate_limit_headers=$(curl -s -I "$BACKEND_URL/health" | grep -i "X-RateLimit")

if [ -n "$rate_limit_headers" ]; then
    pass "Rate limit headers present"
    if [ "$VERBOSE" = true ]; then
        echo "$rate_limit_headers"
    fi
else
    warn "Rate limit headers not found (may not be enabled)"
fi
echo ""

# Test 10: Security Headers
echo "🔒 Security Headers Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
security_headers=$(curl -s -I "$BACKEND_URL/health")

# Check for security headers
if echo "$security_headers" | grep -qi "X-Content-Type-Options"; then
    pass "X-Content-Type-Options header present"
else
    warn "X-Content-Type-Options header missing"
fi

if echo "$security_headers" | grep -qi "X-Frame-Options"; then
    pass "X-Frame-Options header present"
else
    warn "X-Frame-Options header missing"
fi

if echo "$security_headers" | grep -qi "Strict-Transport-Security"; then
    pass "HSTS header present"
else
    warn "HSTS header missing (OK for local development)"
fi
echo ""

# Test 11: Response Time
echo "⚡ Performance Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
start_time=$(date +%s%N)
curl -s "$BACKEND_URL/health" > /dev/null
end_time=$(date +%s%N)
response_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds

if [ $response_time -lt 100 ]; then
    pass "Health check response time: ${response_time}ms (excellent)"
elif [ $response_time -lt 500 ]; then
    pass "Health check response time: ${response_time}ms (good)"
else
    warn "Health check response time: ${response_time}ms (slow)"
fi
echo ""

# Print summary
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo ""
echo "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo "Total tests:  $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  • Check if all services are running: docker-compose ps"
    echo "  • View logs: docker-compose logs backend"
    echo "  • Restart services: docker-compose restart"
    echo ""
    exit 1
fi
