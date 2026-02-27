# InboxIQ Phase 1 Infrastructure - Deployment Summary

**Status:** ✅ Complete  
**Last Updated:** February 26, 2025  
**Version:** 1.0.0

---

## 📋 Quick Overview

This document provides a high-level summary of the InboxIQ infrastructure setup, deployment configuration, and operational procedures.

### What's Included

InboxIQ Phase 1 Infrastructure includes:

- ✅ **Railway Deployment Configuration** - Production-ready cloud deployment
- ✅ **Docker Containers** - Backend API and AI Worker services
- ✅ **Database Setup** - PostgreSQL with migrations
- ✅ **Caching Layer** - Redis for sessions and queue management
- ✅ **Monitoring & Observability** - Sentry error tracking, structured logging
- ✅ **Deployment Scripts** - Automated deployment, testing, and setup
- ✅ **Comprehensive Documentation** - Complete guides for all operations

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     InboxIQ Production                      │
│                      Railway.app Cloud                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────┐         ┌──────────────┐               │
│   │   Backend    │◄────────┤   Frontend   │               │
│   │   (FastAPI)  │         │   (React)    │               │
│   │  Port 8000   │         │              │               │
│   └──────┬───────┘         └──────────────┘               │
│          │                                                 │
│          ├─────────────┐                                   │
│          ▼             ▼                                   │
│   ┌──────────┐  ┌──────────┐                              │
│   │PostgreSQL│  │  Redis   │                              │
│   │ Database │  │  Cache   │                              │
│   └──────────┘  └──────────┘                              │
│          │                                                 │
│          ▼                                                 │
│   ┌──────────────┐                                         │
│   │  AI Worker   │─────────► Claude API (Anthropic)       │
│   │  (Python)    │                                         │
│   └──────────────┘                                         │
│          │                                                 │
│          └─────────────────► Gmail API (Google)            │
│                     └───────► APNs (Apple)                 │
│                                                             │
│   ┌──────────────────────────────────────┐                │
│   │    Monitoring & Observability        │                │
│   │  • Sentry (Error Tracking)          │                │
│   │  • Structured Logs (JSON)            │                │
│   │  • Railway Metrics                   │                │
│   └──────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Directory Structure

```
infrastructure/
├── docs/
│   ├── DEPLOYMENT.md           # Complete deployment guide
│   ├── ENVIRONMENT.md          # Environment variables reference
│   ├── MONITORING.md           # Monitoring and alerting setup
│   └── TROUBLESHOOTING.md      # Common issues and solutions
│
├── railway/
│   ├── backend.Dockerfile      # Backend API container
│   ├── worker.Dockerfile       # AI Worker container
│   ├── railway.json           # Railway configuration
│   └── README.md              # Railway-specific docs
│
├── scripts/
│   ├── deploy.sh              # Automated deployment script
│   ├── run-migrations.sh      # Database migration script
│   ├── setup-local-dev.sh     # Local development setup
│   └── test-backend.sh        # Backend smoke tests
│
├── monitoring/
│   ├── logging-config.yaml    # Structured logging config
│   └── sentry-config.py       # Sentry integration
│
├── docker-compose.yml         # Local development environment
├── .env.example              # Environment variables template
└── DEPLOYMENT-SUMMARY.md     # This file
```

---

## 🚀 Quick Start Guide

### Prerequisites

1. **Create Required Accounts:**
   - [Railway.app](https://railway.app) - Cloud hosting
   - [Google Cloud Console](https://console.cloud.google.com) - Gmail OAuth
   - [Anthropic](https://console.anthropic.com) - Claude AI API
   - [Sentry.io](https://sentry.io) - Error tracking (optional)
   - [Apple Developer](https://developer.apple.com) - APNs push notifications

2. **Install Required Tools:**
   ```bash
   npm install -g @railway/cli
   # Docker Desktop, Git, Python 3.11+
   ```

### Local Development Setup

```bash
# 1. Clone repository
git clone https://github.com/your-org/inboxiq.git
cd inboxiq/infrastructure

# 2. Run setup script
./scripts/setup-local-dev.sh

# 3. Edit .env with your API credentials
nano .env

# 4. Start services
docker-compose up -d

# 5. Verify health
curl http://localhost:8000/health
```

### Production Deployment

```bash
# 1. Login to Railway
railway login

# 2. Create project and add services
railway init
railway add postgresql
railway add redis

# 3. Set environment variables
./scripts/configure-env.sh production

# 4. Deploy
./scripts/deploy.sh --env production

# 5. Verify deployment
curl https://api.inboxiq.app/health
```

---

## 🔐 Required Secrets

### Critical Secrets (Must Generate)

```bash
# JWT Secret (for auth tokens)
openssl rand -base64 32

# Encryption Key (for Gmail tokens)
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

### Third-Party API Keys

| Service | Key Name | Get From | Required |
|---------|----------|----------|----------|
| Google OAuth | `GOOGLE_CLIENT_ID` | [Google Console](https://console.cloud.google.com/apis/credentials) | ✅ Yes |
| Google OAuth | `GOOGLE_CLIENT_SECRET` | Google Console | ✅ Yes |
| Claude AI | `ANTHROPIC_API_KEY` | [Anthropic Console](https://console.anthropic.com/settings/keys) | ✅ Yes |
| Sentry | `SENTRY_DSN` | [Sentry Project](https://sentry.io) | ⚠️ Recommended |
| APNs | `APNS_KEY_ID` | [Apple Developer](https://developer.apple.com) | ✅ Yes (iOS) |
| APNs | `APNS_TEAM_ID` | Apple Developer | ✅ Yes (iOS) |

### Set in Railway

```bash
railway variables set JWT_SECRET_KEY=<generated-jwt-secret>
railway variables set ENCRYPTION_KEY=<generated-encryption-key>
railway variables set GOOGLE_CLIENT_ID=<your-google-client-id>
railway variables set GOOGLE_CLIENT_SECRET=<your-google-client-secret>
railway variables set ANTHROPIC_API_KEY=<your-anthropic-key>
railway variables set SENTRY_DSN=<your-sentry-dsn>
railway variables set APNS_KEY_ID=<your-apns-key-id>
railway variables set APNS_TEAM_ID=<your-apple-team-id>
railway variables set APNS_BUNDLE_ID=com.yourcompany.inboxiq
railway variables set CORS_ORIGINS=https://inboxiq.app,https://api.inboxiq.app
```

---

## 📊 Services Configuration

### Backend Service

- **Type:** FastAPI Python application
- **Port:** 8000
- **Dockerfile:** `railway/backend.Dockerfile`
- **Health Check:** `/health`
- **Replicas:** 1-3 (auto-scaling)
- **Resources:** 512MB RAM, 0.5 vCPU
- **Auto-deploy:** Yes (on git push)

### Worker Service

- **Type:** Python background worker
- **Dockerfile:** `railway/worker.Dockerfile`
- **Replicas:** 1
- **Resources:** 256MB RAM, 0.25 vCPU
- **Tasks:**
  - Email categorization (Claude AI)
  - Daily digest generation
  - Push notification delivery

### PostgreSQL Database

- **Plan:** Railway Hobby ($5/month)
- **Storage:** 10GB
- **Connections:** 50 max
- **Backup:** Daily automatic backups
- **Auto-provided:** `${{PostgreSQL.DATABASE_URL}}`

### Redis Cache

- **Plan:** Railway Shared ($5/month)
- **Memory:** 1GB
- **Eviction:** LRU (least recently used)
- **Auto-provided:** `${{Redis.REDIS_URL}}`

---

## 💰 Cost Breakdown

### Fixed Monthly Costs

| Service | Plan | Cost |
|---------|------|------|
| Railway Backend | Starter | $5-10 |
| Railway Worker | Hobby | $5 |
| PostgreSQL | Hobby | $5 |
| Redis | Shared | $5 |
| **Subtotal (Infrastructure)** | | **$20-25** |

### Variable Costs (Usage-Based)

| Service | Pricing | Estimated Monthly |
|---------|---------|-------------------|
| Claude API (Haiku) | $0.25/MTok input, $1.25/MTok output | $10-30 |
| APNs | Free | $0 |
| Gmail API | Free (1B units/day) | $0 |
| Sentry | Free tier (5K events) | $0 |
| **Subtotal (API Usage)** | | **$10-30** |

### **Total Estimated: $30-55/month** (for MVP with <1000 users)

### Cost Optimization Tips

1. **Use Claude Haiku model** - 5x cheaper than Sonnet
2. **Batch AI requests** - Reduce API calls
3. **Implement caching** - Cache category predictions
4. **Optimize prompts** - Shorter prompts = lower costs
5. **Monitor daily budgets** - Set alerts for spending
6. **Scale gradually** - Start with minimum resources

---

## 📈 Monitoring & Alerts

### Health Checks

```bash
# Overall health
curl https://api.inboxiq.app/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "checks": {
    "database": "ok",
    "redis": "ok",
    "queue_depth": 42
  }
}
```

### Key Metrics to Watch

1. **Uptime** (target: 99.9%)
2. **API Response Time** (P95 < 1s)
3. **Error Rate** (< 1%)
4. **Queue Depth** (< 100 pending)
5. **Daily AI Cost** (< budget)
6. **Database Connections** (< 40/50)

### Sentry Integration

- **Error Tracking:** Automatic capture of all exceptions
- **Performance Monitoring:** API endpoint performance
- **Release Tracking:** Track deployments
- **Alerts:** Email/Slack on errors

### Viewing Logs

```bash
# Real-time backend logs
railway logs --service backend --follow

# Worker logs
railway logs --service worker --follow

# Filter errors only
railway logs --service backend | grep ERROR

# Export logs
railway logs --service backend --tail 10000 > logs.json
```

---

## 🔄 Deployment Workflow

### Automated Deployment (Recommended)

1. **Push to GitHub:**
   ```bash
   git add .
   git commit -m "feat: add feature"
   git push origin main
   ```

2. **Railway Auto-Deploys:**
   - Detects git push
   - Builds Docker images
   - Runs health checks
   - Deploys new version (zero-downtime)

### Manual Deployment

```bash
# Deploy all services
./scripts/deploy.sh --env production

# Deploy specific service
./scripts/deploy.sh --env production --service backend

# Dry run (test without deploying)
./scripts/deploy.sh --env production --dry-run
```

### Rollback Procedure

```bash
# List recent deployments
railway deployments --service backend

# Rollback to previous
railway rollback <deployment-id>

# Rollback database if needed
railway run --service backend alembic downgrade -1
```

---

## 🧪 Testing

### Local Testing

```bash
# Run backend tests
cd backend
pytest tests/ -v

# Run integration tests
pytest tests/integration/ -v

# Test coverage
pytest --cov=app tests/
```

### Smoke Tests

```bash
# Run comprehensive smoke tests
./scripts/test-backend.sh --url https://api.inboxiq.app

# Test specific endpoint
curl -X POST https://api.inboxiq.app/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "test"}'
```

### Load Testing

```bash
# Install k6
brew install k6

# Run load test
k6 run tests/load/basic.js
```

---

## 🛠️ Common Operations

### View Service Status

```bash
railway status
```

### Restart Service

```bash
railway restart --service backend
railway restart --service worker
```

### Run Database Migrations

```bash
./scripts/run-migrations.sh
# Or manually:
railway run --service backend alembic upgrade head
```

### Access Database

```bash
# Connect to PostgreSQL
railway run psql

# Run query
railway run psql -c "SELECT COUNT(*) FROM users;"
```

### Check Environment Variables

```bash
# List all variables
railway variables --service backend

# Get specific variable
railway variables get ANTHROPIC_API_KEY

# Set new variable
railway variables set NEW_VAR=value
```

### Scale Services

```bash
# Scale backend to 2 replicas
railway service update backend --num-replicas 2

# Scale worker to 3 replicas
railway service update worker --num-replicas 3
```

---

## 📚 Documentation Reference

| Document | Purpose | Audience |
|----------|---------|----------|
| **DEPLOYMENT.md** | Complete deployment guide | DevOps, Developers |
| **ENVIRONMENT.md** | Environment variables reference | Developers |
| **MONITORING.md** | Monitoring and alerting setup | DevOps, SRE |
| **TROUBLESHOOTING.md** | Common issues and solutions | Everyone |
| **railway/README.md** | Railway-specific configuration | DevOps |
| **.env.example** | Environment template | Developers |

---

## ✅ Pre-Deployment Checklist

### Before First Deployment

- [ ] All required accounts created
- [ ] Railway CLI installed
- [ ] Railway project created
- [ ] PostgreSQL service added
- [ ] Redis service added
- [ ] All environment variables set (see `.env.example`)
- [ ] Secrets generated (JWT, Encryption Key)
- [ ] Google OAuth configured
- [ ] Anthropic API key obtained
- [ ] Sentry project created
- [ ] APNs credentials configured (for iOS)
- [ ] Domain configured and DNS updated
- [ ] SSL certificate issued (automatic by Railway)
- [ ] Tested locally with `docker-compose`
- [ ] Reviewed DEPLOYMENT.md

### Before Every Deployment

- [ ] All tests passing (`pytest`)
- [ ] Code reviewed and approved
- [ ] Changelog updated
- [ ] Database migrations tested locally
- [ ] No uncommitted changes
- [ ] Environment variables verified
- [ ] Backup recent data
- [ ] Team notified of deployment

### After Deployment

- [ ] Health check passing
- [ ] Smoke tests successful
- [ ] Check Sentry for new errors
- [ ] Monitor logs for 10-15 minutes
- [ ] Verify database queries performing well
- [ ] Test critical user flows
- [ ] Notify team of successful deployment

---

## 🆘 Getting Help

### Quick Troubleshooting

1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review Railway logs: `railway logs --service backend`
3. Check health endpoint: `curl https://api.inboxiq.app/health`
4. Verify Sentry for errors
5. Check Railway status: https://status.railway.app

### Support Channels

- **Railway:** [Discord](https://discord.gg/railway), [Docs](https://docs.railway.app)
- **Anthropic:** support@anthropic.com
- **Internal:** See team communication channels

---

## 🎯 Next Steps

### Post-Phase 1 Improvements

1. **CI/CD Pipeline**
   - GitHub Actions for automated testing
   - Automated security scanning
   - Preview deployments for PRs

2. **Advanced Monitoring**
   - Grafana dashboards
   - Custom metrics with Prometheus
   - Uptime monitoring (e.g., UptimeRobot)

3. **Performance Optimization**
   - Database query optimization
   - API response caching
   - CDN for static assets
   - Database read replicas

4. **Security Enhancements**
   - WAF (Web Application Firewall)
   - Rate limiting per user
   - API key rotation
   - Security scanning (Snyk, Dependabot)

5. **Scalability**
   - Horizontal scaling strategy
   - Database sharding for large users
   - Message queue (e.g., RabbitMQ)
   - Microservices architecture

6. **Disaster Recovery**
   - Automated daily backups to S3
   - Backup restoration testing
   - Multi-region deployment
   - Incident response playbook

---

## 📝 Change Log

### Version 1.0.0 (2025-02-26)

**Initial Release - Phase 1 Complete**

- ✅ Railway deployment configuration
- ✅ Docker containers (backend + worker)
- ✅ PostgreSQL database setup
- ✅ Redis caching layer
- ✅ Sentry monitoring integration
- ✅ Structured logging
- ✅ Deployment scripts
- ✅ Comprehensive documentation
- ✅ Local development environment
- ✅ Smoke tests
- ✅ Environment variable templates

---

## 📞 Contact

**Project:** InboxIQ  
**Infrastructure Version:** 1.0.0  
**Maintained By:** [Your Team Name]  
**Last Updated:** February 26, 2025

For infrastructure issues or questions, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) or contact the DevOps team.

---

**🎉 Infrastructure Phase 1 Complete!**

All deployment infrastructure is ready for production. Follow DEPLOYMENT.md for detailed deployment instructions.
