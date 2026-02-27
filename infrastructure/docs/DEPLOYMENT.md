# InboxIQ Deployment Guide

Complete guide for deploying InboxIQ to Railway.app and managing production infrastructure.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Environment Configuration](#environment-configuration)
4. [First Deployment](#first-deployment)
5. [Continuous Deployment](#continuous-deployment)
6. [Domain Configuration](#domain-configuration)
7. [Monitoring Setup](#monitoring-setup)
8. [Rollback Procedures](#rollback-procedures)
9. [CI/CD Pipeline](#cicd-pipeline-future)

---

## Prerequisites

### Required Accounts

- ✅ **Railway.app** - Cloud hosting platform
  - Sign up: https://railway.app
  - Credit card required for paid plans
  - Estimated cost: $20-40/month

- ✅ **Google Cloud Console** - For Gmail OAuth
  - Console: https://console.cloud.google.com
  - Enable Gmail API
  - Create OAuth 2.0 credentials

- ✅ **Anthropic** - For Claude AI
  - Console: https://console.anthropic.com
  - API key required
  - Pay-as-you-go pricing

- ✅ **Sentry.io** - Error tracking (optional but recommended)
  - Sign up: https://sentry.io
  - Free tier available
  - Create new project for InboxIQ

- ✅ **Apple Developer** - For APNs push notifications
  - Account: https://developer.apple.com
  - $99/year membership
  - APNs key + Team ID required

### Required Tools

```bash
# Install Railway CLI
npm install -g @railway/cli

# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# Install Git
# macOS: brew install git
# Linux: apt-get install git
```

---

## Initial Setup

### 1. Railway Project Creation

```bash
# Login to Railway
railway login

# Create new project
railway init

# Name your project
Project name: inboxiq-production
```

### 2. Link Git Repository (Recommended)

Linking to GitHub enables automatic deployments on push.

```bash
# From your project directory
railway link

# Or connect via Railway dashboard:
# Dashboard → Project → Settings → Connect Repo
```

### 3. Add Required Services

```bash
# Add PostgreSQL database
railway add postgresql

# Add Redis cache
railway add redis

# Verify services
railway services
```

Expected output:
```
Services:
  - postgresql (PostgreSQL 15)
  - redis (Redis 7)
```

---

## Environment Configuration

### 1. Generate Secrets

**JWT Secret:**
```bash
openssl rand -base64 32
```

**Encryption Key (Fernet):**
```bash
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### 2. Set Environment Variables

```bash
# Backend service variables
railway variables set \
  ENVIRONMENT=production \
  LOG_LEVEL=INFO \
  JWT_SECRET_KEY=<your-jwt-secret> \
  ENCRYPTION_KEY=<your-fernet-key> \
  GOOGLE_CLIENT_ID=<your-google-client-id> \
  GOOGLE_CLIENT_SECRET=<your-google-client-secret> \
  GOOGLE_REDIRECT_URI=https://api.inboxiq.app/auth/callback \
  ANTHROPIC_API_KEY=<your-anthropic-key> \
  CLAUDE_MODEL=claude-3-haiku-20240307 \
  SENTRY_DSN=<your-sentry-dsn> \
  CORS_ORIGINS=https://inboxiq.app,https://api.inboxiq.app \
  APNS_KEY_ID=<your-apns-key-id> \
  APNS_TEAM_ID=<your-apple-team-id> \
  APNS_BUNDLE_ID=com.yourcompany.inboxiq
```

**Note:** Database and Redis URLs are automatically provided by Railway as `${{PostgreSQL.DATABASE_URL}}` and `${{Redis.REDIS_URL}}`.

### 3. Upload APNs Key

```bash
# Create secrets directory in Railway project
railway run mkdir -p /app/secrets

# Upload APNs .p8 key file
railway run --service backend \
  bash -c 'echo "$APNS_KEY_CONTENT" > /app/secrets/AuthKey_KEYID.p8'
```

Or store key content as environment variable:
```bash
railway variables set APNS_KEY_PATH=/app/secrets/AuthKey_<KEYID>.p8
railway variables set APNS_KEY_CONTENT="$(cat AuthKey_KEYID.p8)"
```

---

## First Deployment

### 1. Deploy Backend Service

```bash
# From infrastructure/ directory
cd infrastructure

# Deploy using our deployment script
./scripts/deploy.sh --env production --service backend
```

Or manually:
```bash
# Build and deploy
railway up --service backend

# Monitor deployment
railway logs --service backend --follow
```

### 2. Run Database Migrations

```bash
# After backend is deployed
railway run --service backend alembic upgrade head

# Verify migrations
railway run --service backend alembic current
```

Expected output:
```
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
<revision-hash> (head)
```

### 3. Seed Default Categories

```bash
# SSH into backend container
railway run --service backend bash

# Run seed script
psql $DATABASE_URL << EOF
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
```

### 4. Deploy Worker Service

```bash
# Create worker service
railway service create worker

# Configure worker service
railway service update worker \
  --dockerfile infrastructure/railway/worker.Dockerfile

# Set worker environment variables
railway variables set \
  --service worker \
  ENVIRONMENT=production \
  WORKER_CONCURRENCY=5 \
  WORKER_BATCH_SIZE=10 \
  ANTHROPIC_API_KEY=<your-key> \
  SENTRY_DSN=<your-dsn>

# Deploy worker
railway up --service worker
```

### 5. Verify Deployment

```bash
# Get backend URL
BACKEND_URL=$(railway url --service backend)

# Test health endpoint
curl $BACKEND_URL/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "checks": {
    "database": "ok",
    "redis": "ok",
    "queue_depth": 0
  }
}

# Run comprehensive tests
./scripts/test-backend.sh --url $BACKEND_URL
```

---

## Continuous Deployment

### Auto-Deploy on Git Push

Railway automatically deploys when you push to the linked branch (usually `main`).

**Workflow:**
```bash
# Make changes
git add .
git commit -m "feat: add new feature"

# Push to GitHub
git push origin main

# Railway automatically:
# 1. Detects push
# 2. Builds Docker images
# 3. Runs health checks
# 4. Deploys new version
# 5. Keeps old version running until new one is healthy
```

### Manual Deployment

```bash
# Deploy specific service
railway up --service backend

# Deploy all services
railway up

# Deploy specific commit
git checkout <commit-hash>
railway up
```

### Deployment Hooks

Create `railway.toml` for custom deployment behavior:

```toml
[build]
builder = "DOCKERFILE"
dockerfilePath = "infrastructure/railway/backend.Dockerfile"

[deploy]
startCommand = "sh -c 'alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT'"
healthcheckPath = "/health"
healthcheckTimeout = 300
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3

[environments.production.build]
watchPatterns = ["backend/**", "infrastructure/**"]
```

---

## Domain Configuration

### 1. Add Custom Domain

**In Railway Dashboard:**
```
Project → Settings → Domains → Add Domain
```

Enter your domain:
```
api.inboxiq.app
```

### 2. Configure DNS

Add CNAME record in your DNS provider:

```
Type: CNAME
Name: api
Value: <railway-provided-domain>.railway.app
TTL: 300
```

### 3. SSL Certificate

Railway automatically provisions SSL certificates via Let's Encrypt. Wait 2-5 minutes for certificate issuance.

Verify:
```bash
curl -I https://api.inboxiq.app/health
# Should show: HTTP/2 200
```

### 4. Force HTTPS

In backend code (FastAPI middleware):
```python
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware

if os.getenv("ENVIRONMENT") == "production":
    app.add_middleware(HTTPSRedirectMiddleware)
```

---

## Monitoring Setup

### 1. Sentry Integration

Already configured via environment variables. Verify:

```bash
# Check Sentry DSN is set
railway variables get SENTRY_DSN --service backend

# Trigger test error
railway run --service backend \
  python -c "import sentry_sdk; sentry_sdk.init(dsn='<dsn>'); sentry_sdk.capture_message('Test from Railway')"

# Check Sentry dashboard for test event
```

### 2. Railway Metrics

**Built-in metrics available:**
- CPU usage
- Memory usage
- Network I/O
- Request latency
- Error rates

Access: Railway Dashboard → Project → Observability

### 3. Custom Metrics

Set up Prometheus metrics endpoint (future):

```python
# app/metrics.py
from prometheus_client import Counter, Histogram

email_sync_total = Counter('email_sync_total', 'Total email syncs')
ai_categorization_duration = Histogram('ai_categorization_duration_seconds', 'AI categorization time')
```

### 4. Log Aggregation

**View logs:**
```bash
# Real-time logs
railway logs --service backend --follow

# Last 100 lines
railway logs --service backend --tail 100

# Filter by level
railway logs --service backend | grep ERROR
```

**Export logs** (for external analysis):
```bash
# Export to file
railway logs --service backend --tail 10000 > logs-export.json

# Send to log aggregation service (future)
# Consider: Datadog, New Relic, Logtail
```

---

## Rollback Procedures

### Quick Rollback

```bash
# List recent deployments
railway deployments

# Rollback to specific deployment
railway rollback <deployment-id>

# Or rollback to previous
railway rollback --confirm
```

### Database Rollback

```bash
# List migration history
railway run --service backend alembic history

# Rollback one migration
railway run --service backend alembic downgrade -1

# Rollback to specific version
railway run --service backend alembic downgrade <revision>
```

### Full System Rollback

```bash
# 1. Rollback application
railway rollback <deployment-id>

# 2. Rollback database (if migration applied)
railway run --service backend alembic downgrade -1

# 3. Verify health
curl https://api.inboxiq.app/health

# 4. Check logs
railway logs --service backend --tail 50
```

---

## CI/CD Pipeline (Future)

### GitHub Actions Example

`.github/workflows/deploy.yml`:

```yaml
name: Deploy to Railway

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          cd backend
          pip install -r requirements.txt
          pytest tests/
  
  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Railway CLI
        run: npm i -g @railway/cli
      - name: Deploy to Railway
        run: railway up --service backend
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

### Pre-Deployment Checks

Create pre-deployment script:

```bash
#!/bin/bash
# pre-deploy.sh

# Run tests
pytest backend/tests/ || exit 1

# Check code quality
pylint backend/app/ || exit 1

# Check security
bandit -r backend/app/ || exit 1

# Build Docker image locally
docker build -f infrastructure/railway/backend.Dockerfile . || exit 1

echo "✓ Pre-deployment checks passed"
```

---

## Deployment Checklist

### Before Every Deployment

- [ ] All tests passing locally
- [ ] Code reviewed and merged to main
- [ ] Environment variables verified
- [ ] Database migrations tested locally
- [ ] Changelog updated
- [ ] Sentry release created (optional)

### First Production Deployment

- [ ] All environment variables set
- [ ] Database initialized and migrated
- [ ] Default categories seeded
- [ ] Domain configured and SSL active
- [ ] Sentry integration verified
- [ ] Health checks passing
- [ ] APNs credentials configured
- [ ] Backup strategy implemented
- [ ] Monitoring dashboards set up
- [ ] Team notified

### After Deployment

- [ ] Health check verified
- [ ] Smoke tests run
- [ ] Logs monitored for errors
- [ ] Sentry checked for new issues
- [ ] Database queries performing well
- [ ] Worker processing queue
- [ ] Push notifications working
- [ ] Email sync functional

---

## Emergency Contacts

**On-Call Rotation:**
- Primary: [Name] - [Phone/Slack]
- Secondary: [Name] - [Phone/Slack]

**Service Status:**
- Railway: https://status.railway.app
- Anthropic: https://status.anthropic.com
- Google Workspace: https://www.google.com/appsstatus

**Escalation:**
1. Check Railway status page
2. Check Sentry for errors
3. Review recent deployments
4. Contact Railway support (if platform issue)
5. Rollback if necessary

---

## Additional Resources

- [ENVIRONMENT.md](./ENVIRONMENT.md) - Environment variables reference
- [MONITORING.md](./MONITORING.md) - Monitoring and alerting setup
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Common issues and solutions
- [Railway Documentation](https://docs.railway.app)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)

---

*Last updated: 2024-01-15*
