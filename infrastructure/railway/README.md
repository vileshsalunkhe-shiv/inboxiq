# Railway Deployment Configuration

This directory contains Railway.app deployment configuration for InboxIQ.

## Files

- **railway.json** - Railway project configuration
- **backend.Dockerfile** - Backend API container (FastAPI)
- **worker.Dockerfile** - AI worker container (Python)

## Services Architecture

```
┌─────────────┐
│   Backend   │ ─── HTTP ───▶ FastAPI (Port 8000)
│  (FastAPI)  │ ─── DB ─────▶ PostgreSQL
└─────────────┘ ─── Cache ──▶ Redis
       │
       ▼
┌─────────────┐
│   Worker    │ ─── Queue ──▶ PostgreSQL (ai_queue)
│  (Python)   │ ─── AI ─────▶ Claude API
└─────────────┘ ─── Push ───▶ APNs
```

## Required Railway Services

### 1. PostgreSQL Database
```bash
railway add postgresql
```

### 2. Redis Cache
```bash
railway add redis
```

### 3. Backend Service
- Build: `backend.Dockerfile`
- Port: 8000
- Health check: `/health`
- Auto-scaling: Yes
- Replicas: 1-3 (based on load)

### 4. Worker Service
- Build: `worker.Dockerfile`
- No exposed ports
- Auto-restart: Always
- Replicas: 1

## Environment Variables

See `infrastructure/.env.example` for complete list.

### Required Secrets

Generate secrets:
```bash
# JWT Secret
openssl rand -base64 32

# Encryption Key (Fernet)
python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Set in Railway:
```bash
railway variables set JWT_SECRET_KEY=<generated-jwt-secret>
railway variables set ENCRYPTION_KEY=<generated-fernet-key>
railway variables set GOOGLE_CLIENT_ID=<google-oauth-id>
railway variables set GOOGLE_CLIENT_SECRET=<google-oauth-secret>
railway variables set ANTHROPIC_API_KEY=<claude-api-key>
railway variables set SENTRY_DSN=<sentry-dsn>
```

## Deployment

### First Deployment

```bash
# 1. Login to Railway
railway login

# 2. Create new project
railway init

# 3. Link to GitHub repo (recommended)
railway link

# 4. Add PostgreSQL
railway add postgresql

# 5. Add Redis
railway add redis

# 6. Set environment variables
railway variables set JWT_SECRET_KEY=...
railway variables set ENCRYPTION_KEY=...
# ... (see above)

# 7. Deploy backend
railway up

# 8. Create worker service
railway service create worker
railway service update worker --dockerfile infrastructure/railway/worker.Dockerfile

# 9. Deploy worker
railway up --service worker
```

### Subsequent Deployments

Railway auto-deploys on git push when linked to GitHub.

Manual deployment:
```bash
# Deploy all services
railway up

# Deploy specific service
railway up --service backend
railway up --service worker
```

## Monitoring

### Health Checks

Backend health endpoint: `https://your-backend.railway.app/health`

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

### Logs

```bash
# View backend logs
railway logs --service backend

# View worker logs
railway logs --service worker

# Follow logs
railway logs --service backend --follow
```

### Metrics

- Railway Dashboard: CPU, Memory, Network
- Sentry: Error tracking, Performance
- Database: Connection pool, Query performance

## Cost Optimization

### Resource Limits

**Backend Service:**
- Memory: 512 MB - 1 GB
- CPU: 0.5 - 1 vCPU
- Storage: Minimal (stateless)

**Worker Service:**
- Memory: 256 MB - 512 MB
- CPU: 0.25 - 0.5 vCPU
- Storage: Minimal

**PostgreSQL:**
- Plan: Hobby ($5/month)
- Storage: 10 GB
- Connections: 50

**Redis:**
- Plan: Shared ($5/month)
- Memory: 1 GB
- Eviction: LRU

### Estimated Monthly Cost

| Service | Cost |
|---------|------|
| Backend | $5-10 |
| Worker | $5 |
| PostgreSQL | $5 |
| Redis | $5 |
| **Total** | **$20-25/month** |

(Plus variable costs: Claude API, APNs, etc.)

## Scaling Strategy

### Horizontal Scaling

**Backend:**
- Scale to 2-3 replicas under heavy load
- Railway auto-scales based on CPU/Memory

**Worker:**
- Single replica sufficient for MVP
- Scale to 2-3 for >10K active users

### Database Optimization

- Connection pooling (max 20 connections)
- Read replicas for reporting (future)
- Partition old emails by month

## Troubleshooting

### Deployment Fails

```bash
# Check build logs
railway logs --service backend

# Common issues:
# - Missing environment variables
# - Database migration failure
# - Health check timeout
```

### Worker Not Processing

```bash
# Check worker logs
railway logs --service worker

# Verify queue has items
railway run psql -c "SELECT COUNT(*) FROM ai_queue WHERE status='pending';"

# Restart worker
railway service restart worker
```

### Database Connection Issues

```bash
# Check connection string
railway variables get DATABASE_URL

# Test connection
railway run psql -c "SELECT 1;"

# Check connection pool
railway run psql -c "SELECT * FROM pg_stat_activity;"
```

## Security

### SSL/TLS

- Railway automatically provisions SSL certificates
- All traffic encrypted with TLS 1.3
- HSTS headers enforced

### Secrets Management

- Never commit secrets to git
- Use Railway environment variables
- Rotate secrets quarterly
- Store backup secrets in 1Password/Vault

### Network Security

- Backend: Public (HTTPS only)
- Worker: Internal only
- Database: Internal only (Railway private network)
- Redis: Internal only

## Rollback

### Automatic Rollback

Railway automatically rolls back failed deployments.

### Manual Rollback

```bash
# List deployments
railway deployments

# Rollback to specific deployment
railway rollback <deployment-id>
```

## Support

- Railway Docs: https://docs.railway.app
- Railway Discord: https://discord.gg/railway
- Project Issues: GitHub Issues
