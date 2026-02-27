# InboxIQ Infrastructure

**Production-ready deployment infrastructure for InboxIQ email management platform.**

[![Railway](https://img.shields.io/badge/Deploy-Railway-blueviolet?logo=railway)](https://railway.app)
[![Docker](https://img.shields.io/badge/Container-Docker-2496ED?logo=docker)](https://www.docker.com/)
[![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-336791?logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Cache-Redis-DC382D?logo=redis)](https://redis.io/)

---

## 📁 Project Structure

```
infrastructure/
├── 📚 docs/                    # Complete documentation
│   ├── DEPLOYMENT.md          # Step-by-step deployment guide
│   ├── ENVIRONMENT.md         # Environment variables reference
│   ├── MONITORING.md          # Monitoring & observability
│   ├── TROUBLESHOOTING.md     # Common issues & solutions
│   └── COST-OPTIMIZATION.md   # Cost reduction strategies
│
├── 🚂 railway/                # Railway.app deployment
│   ├── backend.Dockerfile     # Backend API container
│   ├── worker.Dockerfile      # AI worker container
│   ├── railway.json          # Railway configuration
│   └── README.md             # Railway-specific docs
│
├── 🛠️ scripts/                # Automation scripts
│   ├── deploy.sh             # Automated deployment
│   ├── run-migrations.sh     # Database migrations
│   ├── setup-local-dev.sh    # Local dev environment
│   └── test-backend.sh       # Smoke tests
│
├── 📊 monitoring/             # Monitoring configuration
│   ├── logging-config.yaml   # Structured logging setup
│   └── sentry-config.py      # Sentry integration
│
├── 🐳 docker-compose.yml      # Local development
├── 📄 .env.example           # Environment template
├── 📝 DEPLOYMENT-SUMMARY.md  # Quick reference guide
└── 📖 README.md              # This file
```

---

## 🚀 Quick Start

### Prerequisites

- **Accounts:**
  - [Railway.app](https://railway.app) (cloud hosting)
  - [Google Cloud Console](https://console.cloud.google.com) (Gmail OAuth)
  - [Anthropic](https://console.anthropic.com) (Claude AI)
  - [Sentry.io](https://sentry.io) (error tracking - optional)
  - [Apple Developer](https://developer.apple.com) (APNs - for iOS)

- **Tools:**
  ```bash
  npm install -g @railway/cli
  # Docker Desktop, Git, Python 3.11+
  ```

### Local Development (5 minutes)

```bash
# 1. Clone and navigate
git clone <repo-url>
cd inboxiq/infrastructure

# 2. Run automated setup
./scripts/setup-local-dev.sh

# 3. Configure credentials
nano .env  # Add your API keys

# 4. Start services
docker-compose up -d

# 5. Verify
curl http://localhost:8000/health
open http://localhost:8000/docs
```

**That's it!** 🎉 Local environment is ready.

### Production Deployment (10 minutes)

```bash
# 1. Login to Railway
railway login

# 2. Create project
railway init
railway add postgresql
railway add redis

# 3. Set environment variables
# See docs/ENVIRONMENT.md for complete list
railway variables set JWT_SECRET_KEY=$(openssl rand -base64 32)
railway variables set GOOGLE_CLIENT_ID=<your-id>
railway variables set ANTHROPIC_API_KEY=<your-key>
# ... (see DEPLOYMENT.md)

# 4. Deploy
./scripts/deploy.sh --env production

# 5. Verify
curl https://api.inboxiq.app/health
```

**Done!** 🚀 Your API is live.

---

## 📚 Documentation

### Getting Started

- **[DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md)** - Start here! High-level overview
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Complete deployment guide
- **[docs/ENVIRONMENT.md](docs/ENVIRONMENT.md)** - All environment variables explained

### Operations

- **[docs/MONITORING.md](docs/MONITORING.md)** - Monitoring, logging, and alerts
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[docs/COST-OPTIMIZATION.md](docs/COST-OPTIMIZATION.md)** - Reduce infrastructure costs

### Platform-Specific

- **[railway/README.md](railway/README.md)** - Railway.app deployment details

---

## 🏗️ Architecture

```
┌────────────────────────────────────────────────────┐
│              InboxIQ Production Stack              │
│                   Railway.app                      │
└────────────────────────────────────────────────────┘

    👤 Users
     ↓
┌──────────────┐
│   Frontend   │  React/Next.js (separate repo)
│ inboxiq.app  │
└──────┬───────┘
       │ HTTPS
       ↓
┌──────────────────────────────────────────────────┐
│              Backend API (FastAPI)               │
│          api.inboxiq.app (Port 8000)            │
│                                                  │
│  Endpoints:                                      │
│  • /auth/* - OAuth & JWT                        │
│  • /emails/* - Email CRUD                       │
│  • /categories/* - Categorization                │
│  • /sync - Gmail synchronization                 │
└──────┬────────────────────┬──────────────────────┘
       │                    │
       ↓                    ↓
┌──────────────┐    ┌──────────────┐
│  PostgreSQL  │    │    Redis     │
│   Database   │    │    Cache     │
│   (Hobby)    │    │   (Shared)   │
└──────┬───────┘    └──────────────┘
       │
       ↓
┌──────────────────────────────────────────────────┐
│           AI Worker (Background)                 │
│                                                  │
│  Tasks:                                          │
│  • Email categorization (Claude AI)             │
│  • Daily digest generation                       │
│  • Push notifications (APNs)                     │
└──────────────────────────────────────────────────┘
       │
       ├─────────► Claude API (Anthropic)
       ├─────────► Gmail API (Google)
       └─────────► APNs (Apple)

┌──────────────────────────────────────────────────┐
│         Monitoring & Observability               │
│  • Sentry (errors & performance)                │
│  • Structured logs (JSON)                        │
│  • Railway metrics (CPU, memory, etc.)          │
└──────────────────────────────────────────────────┘
```

---

## 💰 Cost Breakdown

### Monthly Infrastructure Costs

| Service | Plan | Cost |
|---------|------|------|
| Railway Backend | Starter | $5-10 |
| Railway Worker | Hobby | $5 |
| PostgreSQL | Hobby (10GB) | $5 |
| Redis | Shared (1GB) | $5 |
| **Infrastructure Total** | | **$20-25** |

### Variable API Costs

| Service | Pricing | Est. Monthly |
|---------|---------|--------------|
| Claude AI (Haiku) | $0.25/MTok in, $1.25/MTok out | $10-30 |
| Gmail API | Free (1B units/day) | $0 |
| APNs | Free | $0 |
| Sentry | Free tier (5K events) | $0 |
| **API Total** | | **$10-30** |

### **Total: $30-55/month** (< 1000 users)

**📉 Cost per user decreases with scale:**
- 100 users: $0.35/user/month
- 1,000 users: $0.085/user/month
- 10,000 users: $0.045/user/month

See [docs/COST-OPTIMIZATION.md](docs/COST-OPTIMIZATION.md) for detailed strategies.

---

## 🔐 Security

### Secrets Management

**Required secrets:**
- `JWT_SECRET_KEY` - Auth token signing
- `ENCRYPTION_KEY` - Gmail token encryption
- `GOOGLE_CLIENT_SECRET` - OAuth
- `ANTHROPIC_API_KEY` - Claude AI
- `APNS_KEY` - iOS push notifications

**Generate secrets:**
```bash
# JWT Secret
openssl rand -base64 32

# Encryption Key (Fernet)
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

**Store secrets:**
```bash
# Railway (production)
railway variables set JWT_SECRET_KEY=<generated-key>

# Local development
echo "JWT_SECRET_KEY=<generated-key>" >> .env
```

**Security checklist:**
- ✅ All secrets stored in Railway/1Password (never in git)
- ✅ HTTPS enforced (automatic with Railway)
- ✅ CORS configured for frontend domain only
- ✅ Rate limiting enabled
- ✅ SQL injection protection (SQLAlchemy ORM)
- ✅ JWT token expiration (30 minutes)
- ✅ Encrypted Gmail tokens (Fernet)
- ✅ Non-root Docker containers
- ✅ Security headers (HSTS, X-Frame-Options, etc.)

---

## 📊 Monitoring

### Health Check

```bash
curl https://api.inboxiq.app/health
```

Expected response:
```json
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

### View Logs

```bash
# Real-time logs
railway logs --service backend --follow

# Last 100 lines
railway logs --service backend --tail 100

# Filter errors
railway logs --service backend | grep ERROR
```

### Metrics Dashboard

- **Railway:** CPU, Memory, Network (built-in)
- **Sentry:** Error rates, performance traces
- **Custom:** `/admin/metrics` endpoint (if implemented)

See [docs/MONITORING.md](docs/MONITORING.md) for complete setup.

---

## 🔄 CI/CD

### Automatic Deployment

When linked to GitHub, Railway automatically deploys on push to `main`:

```bash
git add .
git commit -m "feat: add new feature"
git push origin main
# 🎉 Railway auto-deploys
```

### Manual Deployment

```bash
# Deploy all services
./scripts/deploy.sh --env production

# Deploy specific service
./scripts/deploy.sh --env production --service backend

# Dry run (test without deploying)
./scripts/deploy.sh --env production --dry-run
```

### Rollback

```bash
# List deployments
railway deployments

# Rollback to previous
railway rollback <deployment-id>
```

---

## 🧪 Testing

### Run Tests Locally

```bash
# Backend unit tests
cd ../backend
pytest tests/ -v

# Integration tests
pytest tests/integration/ -v

# Coverage report
pytest --cov=app tests/
```

### Smoke Tests

```bash
# Test production API
./scripts/test-backend.sh --url https://api.inboxiq.app

# Test local development
./scripts/test-backend.sh --url http://localhost:8000

# Verbose output
./scripts/test-backend.sh --url https://api.inboxiq.app --verbose
```

---

## 🛠️ Common Operations

### Restart Service

```bash
railway restart --service backend
```

### Run Database Migration

```bash
./scripts/run-migrations.sh
```

### Access Database

```bash
# PostgreSQL shell
railway run psql

# Run specific query
railway run psql -c "SELECT COUNT(*) FROM users;"
```

### Check Environment Variables

```bash
# List all
railway variables

# Get specific
railway variables get ANTHROPIC_API_KEY

# Set new
railway variables set NEW_VAR=value
```

### Scale Services

```bash
# Scale backend replicas
railway service update backend --num-replicas 2

# Update resource limits
railway service update backend --memory 512 --cpu 0.5
```

---

## 🐛 Troubleshooting

### Common Issues

**Deployment fails:**
```bash
# Check logs
railway logs --service backend --deployment latest

# Verify environment variables
railway variables

# Re-deploy
./scripts/deploy.sh --env production
```

**Database connection error:**
```bash
# Test connection
railway run psql -c "SELECT 1;"

# Check connection pool
railway variables get DATABASE_POOL_SIZE
```

**Worker not processing:**
```bash
# Check worker logs
railway logs --service worker

# Restart worker
railway restart --service worker

# Check queue
railway run psql -c "SELECT status, COUNT(*) FROM ai_queue GROUP BY status;"
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for comprehensive guide.

---

## 📈 Scaling

### Current Capacity

- **Users:** 0-1,000 (current config)
- **Requests/day:** ~100,000
- **Database:** 10GB storage
- **API calls:** ~10,000/day

### Scale Up Strategy

**500-2,000 users:**
- Scale backend to 2 replicas
- Increase database pool
- Add Redis caching

**2,000-10,000 users:**
- Scale to 3 replicas
- Upgrade PostgreSQL to Pro
- Implement CDN
- Add read replicas

**10,000+ users:**
- Multiple workers
- Database sharding
- Multi-region deployment
- Custom AI model

---

## 📞 Support

### Documentation

- Start: [DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md)
- Deployment: [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)
- Troubleshooting: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

### External Support

- **Railway:** [Discord](https://discord.gg/railway) | [Docs](https://docs.railway.app)
- **Anthropic:** support@anthropic.com
- **Google Cloud:** [Support](https://support.google.com/cloud)

### Getting Help

When requesting support, include:
```bash
# Environment
railway status > status.txt

# Logs
railway logs --service backend --tail 100 > logs.txt

# Health check
curl https://api.inboxiq.app/health > health.json

# Attach files in support request
```

---

## 🗺️ Roadmap

### Phase 1: MVP Infrastructure ✅ Complete

- [x] Railway deployment configuration
- [x] Docker containers
- [x] Database setup
- [x] Monitoring integration
- [x] Deployment scripts
- [x] Complete documentation

### Phase 2: Optimization (Current)

- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Database optimization
- [ ] Advanced caching
- [ ] Cost monitoring dashboard
- [ ] Automated backups to S3

### Phase 3: Scale (Future)

- [ ] Multi-region deployment
- [ ] CDN integration
- [ ] Read replicas
- [ ] Custom AI model
- [ ] Advanced analytics

---

## 📋 Maintenance Checklist

### Daily

- [ ] Check error rate (Sentry)
- [ ] Monitor API costs (Claude)
- [ ] Verify queue depth (< 100)

### Weekly

- [ ] Review performance metrics
- [ ] Check database size
- [ ] Review logs for issues
- [ ] Test rollback procedure

### Monthly

- [ ] Review total costs
- [ ] Update dependencies
- [ ] Optimize slow queries
- [ ] Test disaster recovery
- [ ] Rotate secrets (if scheduled)

---

## 🤝 Contributing

### Making Infrastructure Changes

1. **Test locally first:**
   ```bash
   docker-compose down -v
   docker-compose up -d
   ./scripts/test-backend.sh
   ```

2. **Update documentation:**
   - Update relevant .md files
   - Update .env.example if needed

3. **Test deployment:**
   ```bash
   ./scripts/deploy.sh --env staging --dry-run
   ```

4. **Deploy to staging:**
   ```bash
   ./scripts/deploy.sh --env staging
   ```

5. **Deploy to production:**
   ```bash
   ./scripts/deploy.sh --env production
   ```

---

## 📄 License

[Your License Here]

---

## 🎉 Infrastructure Complete!

InboxIQ Phase 1 Infrastructure is production-ready. All necessary components, scripts, and documentation are in place.

**Next steps:**
1. Review [DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md)
2. Follow [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for first deployment
3. Set up monitoring as per [docs/MONITORING.md](docs/MONITORING.md)

**Questions?** See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) or contact the team.

---

*Last Updated: February 26, 2025 | Version: 1.0.0*
