# InboxIQ Troubleshooting Guide

Comprehensive troubleshooting guide for common InboxIQ deployment and runtime issues.

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Deployment Issues](#deployment-issues)
3. [Database Problems](#database-problems)
4. [Authentication Errors](#authentication-errors)
5. [Gmail API Issues](#gmail-api-issues)
6. [AI/Claude API Problems](#aiclaude-api-problems)
7. [Worker Issues](#worker-issues)
8. [Performance Problems](#performance-problems)
9. [Network & Connectivity](#network--connectivity)
10. [APNs Push Notification Issues](#apns-push-notification-issues)
11. [Common Error Messages](#common-error-messages)
12. [Emergency Procedures](#emergency-procedures)

---

## Quick Diagnostics

### Health Check Command

```bash
# Check overall system health
curl https://api.inboxiq.app/health | jq

# Expected healthy response:
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

### Quick Status Check

```bash
# Railway services status
railway status

# View recent logs
railway logs --service backend --tail 50
railway logs --service worker --tail 50

# Check database connection
railway run --service backend python -c "
from sqlalchemy import create_engine
import os
engine = create_engine(os.getenv('DATABASE_URL'))
with engine.connect() as conn:
    result = conn.execute('SELECT 1')
    print('Database: OK')
"

# Check Redis connection
railway run --service backend python -c "
import redis
import os
r = redis.from_url(os.getenv('REDIS_URL'))
r.ping()
print('Redis: OK')
"
```

---

## Deployment Issues

### Issue: Deployment Fails During Build

**Symptoms:**
```
Error: Docker build failed
Error: No space left on device
```

**Solutions:**

1. **Clean Docker cache:**
```bash
docker system prune -a --volumes
```

2. **Check Dockerfile syntax:**
```bash
# Validate Dockerfile
docker build --no-cache -f infrastructure/railway/backend.Dockerfile . --dry-run
```

3. **Verify all files are committed:**
```bash
git status
git add .
git commit -m "Add missing files"
git push
```

4. **Check Railway build logs:**
```bash
railway logs --service backend --deployment latest
```

### Issue: Health Check Timeout

**Symptoms:**
```
Error: Health check failed after 300s
Deployment rolled back
```

**Solutions:**

1. **Check application startup:**
```bash
# View startup logs
railway logs --service backend --tail 100 | grep -i "error\|exception"
```

2. **Verify health endpoint responds:**
```bash
# Test locally first
docker-compose up -d
curl http://localhost:8000/health
```

3. **Increase health check timeout:**

Edit `railway/railway.json`:
```json
{
  "deploy": {
    "healthcheckTimeout": 600  // Increase to 10 minutes
  }
}
```

4. **Check database migrations:**
```bash
railway run --service backend alembic current
railway run --service backend alembic upgrade head
```

### Issue: Migration Fails During Deployment

**Symptoms:**
```
Error: Migration failed
alembic.util.exc.CommandError
```

**Solutions:**

1. **Check migration history:**
```bash
railway run --service backend alembic history --verbose
railway run --service backend alembic current
```

2. **Manually run migrations:**
```bash
# Skip auto-migration in Dockerfile, run manually
railway run --service backend alembic upgrade head
```

3. **Rollback problematic migration:**
```bash
railway run --service backend alembic downgrade -1
```

4. **Fix migration script:**
- Review `backend/alembic/versions/*.py`
- Test locally before redeploying

### Issue: Environment Variables Not Set

**Symptoms:**
```
Error: ANTHROPIC_API_KEY is not set
KeyError: 'DATABASE_URL'
```

**Solutions:**

1. **List all variables:**
```bash
railway variables --service backend
```

2. **Set missing variables:**
```bash
railway variables set ANTHROPIC_API_KEY=sk-ant-...
railway variables set JWT_SECRET_KEY=$(openssl rand -base64 32)
```

3. **Check Railway auto-provided variables:**
```bash
# These should exist automatically:
railway variables get DATABASE_URL
railway variables get REDIS_URL
```

4. **Restart service after setting variables:**
```bash
railway restart --service backend
```

---

## Database Problems

### Issue: Connection Refused

**Symptoms:**
```
psycopg2.OperationalError: could not connect to server
Connection refused
```

**Solutions:**

1. **Verify DATABASE_URL:**
```bash
railway variables get DATABASE_URL
# Should be: postgresql://user:pass@host:port/dbname
```

2. **Check PostgreSQL service status:**
```bash
railway status
# PostgreSQL should show "Active"
```

3. **Test connection:**
```bash
railway run psql $DATABASE_URL -c "SELECT 1;"
```

4. **Check connection pool settings:**
```bash
# Reduce pool size if too many connections
railway variables set DATABASE_POOL_SIZE=10
railway variables set DATABASE_MAX_OVERFLOW=10
```

### Issue: Too Many Connections

**Symptoms:**
```
FATAL: too many connections for role "user"
remaining connection slots are reserved
```

**Solutions:**

1. **Check current connections:**
```bash
railway run psql -c "
SELECT count(*) as connections, state 
FROM pg_stat_activity 
WHERE datname = 'inboxiq' 
GROUP BY state;
"
```

2. **Kill idle connections:**
```bash
railway run psql -c "
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE datname = 'inboxiq' 
  AND state = 'idle' 
  AND state_change < now() - interval '10 minutes';
"
```

3. **Reduce connection pool:**
```bash
railway variables set DATABASE_POOL_SIZE=5
railway variables set DATABASE_MAX_OVERFLOW=5
railway restart
```

4. **Upgrade PostgreSQL plan** for more connections

### Issue: Slow Queries

**Symptoms:**
- API responses taking > 5 seconds
- Database CPU at 100%

**Solutions:**

1. **Identify slow queries:**
```bash
railway run psql -c "
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;
"
```

2. **Add missing indexes:**
```sql
-- Common indexes for InboxIQ
CREATE INDEX idx_emails_user_id ON emails(user_id);
CREATE INDEX idx_emails_received_at ON emails(received_at DESC);
CREATE INDEX idx_emails_category_id ON emails(category_id);
CREATE INDEX idx_emails_user_category ON emails(user_id, category_id);
```

3. **Analyze query plans:**
```sql
EXPLAIN ANALYZE SELECT * FROM emails WHERE user_id = 'abc-123' ORDER BY received_at DESC LIMIT 50;
```

4. **Update table statistics:**
```bash
railway run psql -c "VACUUM ANALYZE;"
```

---

## Authentication Errors

### Issue: JWT Token Invalid

**Symptoms:**
```
401 Unauthorized
Could not validate credentials
Token signature verification failed
```

**Solutions:**

1. **Verify JWT_SECRET_KEY is set:**
```bash
railway variables get JWT_SECRET_KEY
```

2. **Check token expiration:**
```bash
# Decode JWT (paste token)
echo "YOUR_JWT_TOKEN" | cut -d. -f2 | base64 -d | jq
# Check 'exp' field
```

3. **Re-generate secret if changed:**
```bash
# Generate new secret
NEW_SECRET=$(openssl rand -base64 32)
railway variables set JWT_SECRET_KEY="$NEW_SECRET"
railway restart

# All users will need to re-login
```

4. **Check clock sync:**
- Token validation depends on accurate time
- Verify server time is correct

### Issue: OAuth Callback Fails

**Symptoms:**
```
Error: redirect_uri_mismatch
OAuth2 callback failed
```

**Solutions:**

1. **Verify GOOGLE_REDIRECT_URI:**
```bash
railway variables get GOOGLE_REDIRECT_URI
# Should match EXACTLY what's in Google Console
```

2. **Check Google Console configuration:**
- Go to: https://console.cloud.google.com/apis/credentials
- Edit OAuth 2.0 Client ID
- Ensure redirect URI matches exactly (including https://)

3. **Common mismatches:**
```
❌ http://api.inboxiq.app/auth/callback  (wrong protocol)
✅ https://api.inboxiq.app/auth/callback

❌ https://api.inboxiq.app/auth/callback/  (trailing slash)
✅ https://api.inboxiq.app/auth/callback

❌ https://inboxiq-backend.railway.app/auth/callback  (wrong domain)
✅ https://api.inboxiq.app/auth/callback
```

4. **Update environment variable:**
```bash
railway variables set GOOGLE_REDIRECT_URI=https://api.inboxiq.app/auth/callback
railway restart
```

---

## Gmail API Issues

### Issue: Gmail API Quota Exceeded

**Symptoms:**
```
Error: Quota exceeded for quota metric 'Queries' and limit 'Queries per day'
429 Too Many Requests
```

**Solutions:**

1. **Check quota in Google Console:**
- https://console.cloud.google.com/apis/api/gmail.googleapis.com/quotas
- Default: 1 billion quota units/day
- Each request costs ~5-10 units

2. **Implement rate limiting:**
```python
# Add exponential backoff in sync code
import time
from googleapiclient.errors import HttpError

def sync_with_backoff(service, user_id):
    for retry in range(5):
        try:
            return service.users().messages().list(userId='me').execute()
        except HttpError as e:
            if e.resp.status == 429:
                wait = (2 ** retry) + random.random()
                time.sleep(wait)
            else:
                raise
```

3. **Request quota increase:**
- Go to Google Cloud Console
- Navigate to Quotas
- Request increase (up to 10x free)

4. **Optimize API calls:**
```python
# Fetch multiple messages in batch
from googleapiclient.http import BatchHttpRequest

batch = service.new_batch_http_request()
for msg_id in message_ids:
    batch.add(service.users().messages().get(userId='me', id=msg_id))
batch.execute()
```

### Issue: Gmail Token Expired/Invalid

**Symptoms:**
```
Error: Invalid Credentials
Token has been expired or revoked
401 Unauthorized from Gmail API
```

**Solutions:**

1. **Check refresh token storage:**
```bash
railway run psql -c "
SELECT user_id, email, 
       CASE WHEN refresh_token IS NULL THEN 'MISSING' ELSE 'EXISTS' END as token_status
FROM users 
WHERE email = 'user@example.com';
"
```

2. **Re-authenticate user:**
```bash
# User needs to go through OAuth flow again
# Generate new auth URL
curl https://api.inboxiq.app/auth/google
```

3. **Verify ENCRYPTION_KEY hasn't changed:**
```bash
# If encryption key changed, all stored tokens are invalid
railway variables get ENCRYPTION_KEY
```

4. **Check Gmail API is enabled:**
- https://console.cloud.google.com/apis/library/gmail.googleapis.com
- Ensure "Gmail API" is enabled

---

## AI/Claude API Problems

### Issue: Anthropic API Key Invalid

**Symptoms:**
```
Error: Invalid API key
401 Unauthorized from Anthropic
```

**Solutions:**

1. **Verify API key:**
```bash
railway variables get ANTHROPIC_API_KEY
# Should start with: sk-ant-api03-
```

2. **Test API key directly:**
```bash
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{
    "model": "claude-3-haiku-20240307",
    "max_tokens": 10,
    "messages": [{"role": "user", "content": "Hi"}]
  }'
```

3. **Generate new key:**
- Go to: https://console.anthropic.com/settings/keys
- Create new key
- Update in Railway

4. **Set and restart:**
```bash
railway variables set ANTHROPIC_API_KEY=sk-ant-api03-new-key
railway restart --service backend
railway restart --service worker
```

### Issue: Claude API Rate Limited

**Symptoms:**
```
Error: rate_limit_error
429 Too Many Requests
```

**Solutions:**

1. **Check current usage:**
- https://console.anthropic.com/settings/usage
- View current rate limits and usage

2. **Implement request throttling:**
```python
# Add delay between categorization requests
import asyncio

async def categorize_batch(emails):
    results = []
    for email in emails:
        result = await categorize_email(email)
        results.append(result)
        await asyncio.sleep(0.5)  # 500ms delay
    return results
```

3. **Reduce worker concurrency:**
```bash
railway variables set WORKER_CONCURRENCY=2  # From 5
railway variables set WORKER_BATCH_SIZE=5    # From 10
railway restart --service worker
```

4. **Request rate limit increase:**
- Contact Anthropic support
- Explain use case and user count

### Issue: High Claude API Costs

**Symptoms:**
- Daily costs exceeding budget
- Unexpected bill

**Solutions:**

1. **Check usage logs:**
```bash
railway run psql -c "
SELECT DATE(created_at) as date,
       COUNT(*) as requests,
       SUM(input_tokens) as input_tokens,
       SUM(output_tokens) as output_tokens,
       SUM(cost_usd) as daily_cost
FROM ai_api_logs
WHERE created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
"
```

2. **Optimize prompts:**
```python
# Use shorter, more efficient prompts
# Before: Full email content + long system prompt (1000 tokens)
# After: Email subject + sender + first 200 chars (200 tokens)
```

3. **Use Haiku model:**
```bash
railway variables set CLAUDE_MODEL=claude-3-haiku-20240307
# Haiku is 5x cheaper than Sonnet, 20x cheaper than Opus
```

4. **Implement daily budget limits:**
```python
async def check_daily_budget():
    today_cost = await get_today_cost()
    if today_cost > float(os.getenv("CLAUDE_DAILY_BUDGET_USD", "10")):
        # Pause worker or queue jobs
        logger.warning("Daily budget exceeded, pausing AI categorization")
        return False
    return True
```

---

## Worker Issues

### Issue: Worker Not Processing Queue

**Symptoms:**
- Emails not getting categorized
- Queue depth increasing
- Worker logs showing no activity

**Solutions:**

1. **Check worker is running:**
```bash
railway status
railway logs --service worker --tail 50
```

2. **Verify queue has items:**
```bash
railway run psql -c "
SELECT status, COUNT(*) 
FROM ai_queue 
GROUP BY status;
"
```

3. **Check worker configuration:**
```bash
railway variables --service worker | grep WORKER
```

4. **Restart worker:**
```bash
railway restart --service worker
```

5. **Check for crashed jobs:**
```bash
railway run psql -c "
SELECT id, user_id, status, error_message, retry_count
FROM ai_queue
WHERE status = 'failed'
ORDER BY updated_at DESC
LIMIT 10;
"
```

6. **Reset stuck jobs:**
```bash
railway run psql -c "
UPDATE ai_queue 
SET status = 'pending', retry_count = 0 
WHERE status = 'processing' 
  AND updated_at < NOW() - INTERVAL '1 hour';
"
```

### Issue: Worker Memory Leak

**Symptoms:**
- Worker memory usage growing over time
- Worker crashes with OOM errors
- Railway shows increasing memory usage

**Solutions:**

1. **Monitor memory usage:**
```bash
# Check Railway dashboard metrics
# Or query in worker
import psutil
process = psutil.Process()
print(f"Memory: {process.memory_info().rss / 1024 / 1024:.2f} MB")
```

2. **Implement batch processing with cleanup:**
```python
async def process_batch():
    emails = await fetch_batch()
    results = await categorize_batch(emails)
    await save_results(results)
    
    # Force garbage collection
    import gc
    gc.collect()
```

3. **Restart worker periodically:**
```bash
# Add to cron or Railway auto-restart
# Restart every 6 hours
railway service update worker --restart-policy-type ALWAYS
```

4. **Reduce batch size:**
```bash
railway variables set WORKER_BATCH_SIZE=5
railway restart --service worker
```

---

## Performance Problems

### Issue: Slow API Response Times

**Symptoms:**
- API requests taking > 2 seconds
- Timeout errors
- Poor user experience

**Solutions:**

1. **Identify slow endpoints:**
```bash
# Check Sentry performance
# Or parse logs
railway logs --service backend --tail 1000 | grep "duration_ms" | \
  jq -r 'select(.duration_ms > 2000) | "\(.path) \(.duration_ms)ms"'
```

2. **Add database indexes:**
```sql
-- Analyze query plan
EXPLAIN ANALYZE SELECT * FROM emails WHERE user_id = '...' LIMIT 50;

-- Add index if needed
CREATE INDEX CONCURRENTLY idx_emails_user_received 
ON emails(user_id, received_at DESC);
```

3. **Implement caching:**
```python
import redis
from functools import wraps

def cache_result(ttl=300):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            cache_key = f"{func.__name__}:{args}:{kwargs}"
            cached = await redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
            
            result = await func(*args, **kwargs)
            await redis_client.setex(cache_key, ttl, json.dumps(result))
            return result
        return wrapper
    return decorator
```

4. **Use connection pooling:**
```python
# Already configured in DATABASE_POOL_SIZE
# Increase if needed
railway variables set DATABASE_POOL_SIZE=20
```

5. **Enable query caching:**
```sql
-- PostgreSQL shared_buffers (requires restart)
ALTER SYSTEM SET shared_buffers = '256MB';
```

### Issue: High CPU Usage

**Symptoms:**
- CPU at 100% sustained
- Slow response times
- Railway throttling service

**Solutions:**

1. **Identify CPU-intensive operations:**
```bash
# Check Railway metrics dashboard
# Or profile in code
import cProfile
cProfile.run('your_function()')
```

2. **Optimize email parsing:**
```python
# Use lazy parsing
from email import policy
from email.parser import BytesParser

parser = BytesParser(policy=policy.default)
msg = parser.parsebytes(raw_email)
# Don't parse full body if not needed
```

3. **Reduce worker concurrency:**
```bash
railway variables set WORKER_CONCURRENCY=3
railway restart --service worker
```

4. **Scale horizontally:**
```bash
# Add more replicas
railway service update backend --num-replicas 2
```

---

## Network & Connectivity

### Issue: CORS Errors

**Symptoms:**
```
Access to XMLHttpRequest blocked by CORS policy
No 'Access-Control-Allow-Origin' header
```

**Solutions:**

1. **Check CORS_ORIGINS:**
```bash
railway variables get CORS_ORIGINS
# Should include your frontend domain
```

2. **Add frontend origin:**
```bash
railway variables set CORS_ORIGINS="https://inboxiq.app,https://www.inboxiq.app,http://localhost:3000"
railway restart
```

3. **Verify CORS middleware:**
```python
# In FastAPI app
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

4. **Test CORS:**
```bash
curl -H "Origin: https://inboxiq.app" \
     -H "Access-Control-Request-Method: POST" \
     -X OPTIONS \
     https://api.inboxiq.app/emails/sync
```

### Issue: SSL/TLS Certificate Errors

**Symptoms:**
```
SSL certificate verification failed
ERR_CERT_AUTHORITY_INVALID
```

**Solutions:**

1. **Check Railway domain SSL:**
- Railway auto-provisions SSL
- Wait 2-5 minutes after adding domain

2. **Verify DNS propagation:**
```bash
dig api.inboxiq.app
# Should point to Railway domain
```

3. **Test SSL certificate:**
```bash
openssl s_client -connect api.inboxiq.app:443 -servername api.inboxiq.app
# Check certificate chain
```

4. **Force HTTPS redirect:**
```python
from fastapi.middleware.httpsredirect import HTTPSRedirectMiddleware

if os.getenv("ENVIRONMENT") == "production":
    app.add_middleware(HTTPSRedirectMiddleware)
```

---

## APNs Push Notification Issues

### Issue: Push Notifications Not Delivering

**Symptoms:**
- Notifications not appearing on devices
- No errors in logs

**Solutions:**

1. **Verify APNs credentials:**
```bash
railway variables get APNS_KEY_ID
railway variables get APNS_TEAM_ID
railway variables get APNS_BUNDLE_ID
```

2. **Check APNs environment:**
```bash
# Development/TestFlight
railway variables get APNS_USE_SANDBOX  # Should be "true"

# Production
railway variables set APNS_USE_SANDBOX=false
```

3. **Verify device token:**
```bash
railway run psql -c "
SELECT user_id, device_token, LENGTH(device_token) as token_length
FROM push_tokens
WHERE user_id = 'USER_ID';
"
# Token should be 64 hex characters
```

4. **Test APNs connection:**
```python
# In Railway console
import jwt
import time
import httpx

# Generate JWT
token = jwt.encode(
    {"iss": APNS_TEAM_ID, "iat": time.time()},
    open(APNS_KEY_PATH).read(),
    algorithm="ES256",
    headers={"kid": APNS_KEY_ID}
)

# Test connection
async with httpx.AsyncClient() as client:
    response = await client.post(
        f"https://api{'development' if SANDBOX else ''}.push.apple.com/3/device/{DEVICE_TOKEN}",
        headers={"authorization": f"bearer {token}"},
        json={"aps": {"alert": "Test"}}
    )
    print(response.status_code, response.text)
```

5. **Common issues:**
- Wrong bundle ID
- Expired APNs key
- Invalid device token
- App not in foreground (check notification settings)

---

## Common Error Messages

### Error: "Connection pool exhausted"

**Cause:** Too many database connections
**Solution:**
```bash
railway variables set DATABASE_POOL_SIZE=20
railway variables set DATABASE_MAX_OVERFLOW=30
railway restart
```

### Error: "Redis connection refused"

**Cause:** Redis service down or wrong URL
**Solution:**
```bash
railway variables get REDIS_URL
railway restart --service redis
```

### Error: "Encryption key invalid"

**Cause:** ENCRYPTION_KEY changed or wrong format
**Solution:**
```bash
# Generate new key
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
# Set in Railway
railway variables set ENCRYPTION_KEY="generated-key"
# Note: All users need to re-authenticate
```

### Error: "Failed to fetch Gmail messages"

**Cause:** Invalid token or API disabled
**Solution:**
1. Check Gmail API is enabled in Google Console
2. Verify user's refresh token exists
3. Re-authenticate user

### Error: "Worker timeout"

**Cause:** AI categorization taking too long
**Solution:**
```bash
railway variables set CLAUDE_TIMEOUT=60
railway variables set WORKER_BATCH_SIZE=5
railway restart --service worker
```

---

## Emergency Procedures

### Emergency Rollback

```bash
# 1. List recent deployments
railway deployments --service backend

# 2. Rollback to previous deployment
railway rollback <deployment-id>

# 3. Rollback database if needed
railway run --service backend alembic downgrade -1

# 4. Verify health
curl https://api.inboxiq.app/health
```

### Put System in Maintenance Mode

```bash
# 1. Enable maintenance mode
railway variables set MAINTENANCE_MODE=true
railway restart

# 2. Notify users (if you have a status page)
# Update status.inboxiq.app

# 3. Perform maintenance
# ... fix issues ...

# 4. Disable maintenance mode
railway variables set MAINTENANCE_MODE=false
railway restart
```

### Database Emergency Backup

```bash
# 1. Create immediate backup
railway run pg_dump $DATABASE_URL > emergency-backup-$(date +%Y%m%d-%H%M%S).sql

# 2. Compress backup
gzip emergency-backup-*.sql

# 3. Upload to safe location
aws s3 cp emergency-backup-*.sql.gz s3://inboxiq-backups/emergency/
```

### Kill All Connections

```bash
# If database is locked or stuck
railway run psql -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'inboxiq'
  AND pid <> pg_backend_pid();
"
```

---

## Getting Help

### Before Requesting Support

1. Check this troubleshooting guide
2. Search GitHub issues
3. Check Railway status page
4. Review recent deployments
5. Gather relevant logs

### Support Channels

**Railway Issues:**
- Railway Status: https://status.railway.app
- Railway Discord: https://discord.gg/railway
- Railway Docs: https://docs.railway.app

**Claude/Anthropic:**
- Status: https://status.anthropic.com
- Support: support@anthropic.com
- Docs: https://docs.anthropic.com

**Google API:**
- Status: https://www.google.com/appsstatus
- Support: https://support.google.com/cloud
- Stack Overflow: `google-api` tag

### Information to Include

When requesting support, provide:

```bash
# Environment
railway variables get ENVIRONMENT

# Recent logs
railway logs --service backend --tail 100 > logs.txt

# Current status
railway status > status.txt

# Health check
curl https://api.inboxiq.app/health > health.json

# Recent deployments
railway deployments --service backend > deployments.txt

# Include all files in support request
```

---

## Preventive Maintenance

### Weekly Checklist

- [ ] Review error logs in Sentry
- [ ] Check API response times
- [ ] Monitor Claude API costs
- [ ] Review database performance
- [ ] Check queue depth
- [ ] Verify backups are running

### Monthly Checklist

- [ ] Update dependencies
- [ ] Review and optimize slow queries
- [ ] Analyze user growth trends
- [ ] Review infrastructure costs
- [ ] Test disaster recovery procedures
- [ ] Rotate secrets (if scheduled)

---

*Last updated: 2024-01-15*
