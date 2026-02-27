# InboxIQ Monitoring & Observability Guide

Comprehensive guide for monitoring InboxIQ infrastructure, tracking performance, and setting up alerts.

## Table of Contents

1. [Monitoring Overview](#monitoring-overview)
2. [Sentry Setup](#sentry-setup)
3. [Railway Metrics](#railway-metrics)
4. [Logging Strategy](#logging-strategy)
5. [Performance Monitoring](#performance-monitoring)
6. [Cost Monitoring](#cost-monitoring)
7. [Alert Configuration](#alert-configuration)
8. [Dashboard Setup](#dashboard-setup)
9. [Incident Response](#incident-response)

---

## Monitoring Overview

### Monitoring Stack

```
┌─────────────────────────────────────────────┐
│           InboxIQ Monitoring                │
├─────────────────────────────────────────────┤
│                                             │
│  📊 Sentry (Errors & Performance)          │
│  ├─ Error tracking                          │
│  ├─ Performance monitoring                  │
│  ├─ Release tracking                        │
│  └─ User feedback                           │
│                                             │
│  📈 Railway (Infrastructure)                │
│  ├─ CPU & Memory usage                     │
│  ├─ Network metrics                         │
│  ├─ Database performance                    │
│  └─ Deployment history                      │
│                                             │
│  📝 Structured Logging                      │
│  ├─ JSON format logs                        │
│  ├─ Request tracing                         │
│  ├─ Business metrics                        │
│  └─ Audit trail                             │
│                                             │
│  💰 Cost Tracking                           │
│  ├─ Claude API usage                        │
│  ├─ Railway infrastructure                  │
│  ├─ Database storage                        │
│  └─ Total monthly spend                     │
│                                             │
└─────────────────────────────────────────────┘
```

### Key Metrics to Track

**Availability:**
- Uptime percentage (target: 99.9%)
- Health check response time
- Failed health checks

**Performance:**
- API response time (p50, p95, p99)
- Email sync duration
- AI categorization time
- Database query performance

**Business Metrics:**
- Active users
- Emails synced per day
- AI categorizations per day
- Daily digest sends
- Error rate

**Costs:**
- Claude API daily spend
- Railway monthly costs
- Total infrastructure costs

---

## Sentry Setup

### 1. Create Sentry Project

```bash
# Sign up at https://sentry.io
# Create organization: "inboxiq"
# Create project: "inboxiq-backend"
# Select platform: "Python - FastAPI"
```

### 2. Configure Sentry in Backend

Sentry is pre-configured in `infrastructure/monitoring/sentry-config.py`.

**Initialize in your app:**

```python
# backend/app/main.py
from infrastructure.monitoring.sentry_config import init_sentry

# Initialize Sentry before creating FastAPI app
init_sentry("inboxiq-backend")

app = FastAPI(title="InboxIQ API")
```

**Set environment variable:**
```bash
railway variables set SENTRY_DSN=https://abc123@o123456.ingest.sentry.io/789
```

### 3. Verify Integration

**Test error capture:**
```bash
railway run --service backend python -c "
from infrastructure.monitoring.sentry_config import init_sentry, capture_message
init_sentry('inboxiq-backend')
capture_message('Test from Railway', level='info')
print('✓ Test message sent to Sentry')
"
```

Check Sentry dashboard for the test event.

### 4. Sentry Performance Monitoring

**Track custom operations:**

```python
from infrastructure.monitoring.sentry_config import SentryPerformance

async def sync_user_emails(user_id: str):
    with SentryPerformance("gmail_sync", op="sync"):
        # Your sync logic
        emails = await fetch_gmail_emails(user_id)
        return emails
```

**Track function performance:**

```python
from infrastructure.monitoring.sentry_config import track_performance

@track_performance("ai.categorize")
async def categorize_email(email_id: str):
    # AI categorization logic
    result = await claude_api.categorize(email_id)
    return result
```

### 5. Sentry Alerts

**Configure in Sentry Dashboard:**

```
Settings → Alerts → Create Alert Rule
```

**Recommended alerts:**

1. **High Error Rate**
   - Condition: Error count > 50 in 1 hour
   - Action: Email + Slack notification

2. **Performance Degradation**
   - Condition: P95 response time > 2 seconds
   - Action: Email notification

3. **Critical Errors**
   - Condition: Any ERROR level log
   - Action: Immediate Slack notification

4. **Daily Digest Failures**
   - Condition: "digest_failed" event
   - Action: Email notification

### 6. Sentry Releases

Track deployments:

```bash
# Install Sentry CLI
npm install -g @sentry/cli

# Create release
export SENTRY_ORG=inboxiq
export SENTRY_PROJECT=inboxiq-backend
export VERSION=$(git rev-parse --short HEAD)

sentry-cli releases new $VERSION
sentry-cli releases set-commits $VERSION --auto
sentry-cli releases finalize $VERSION

# Deploy
railway up

# Mark deployed
sentry-cli releases deploys $VERSION new -e production
```

---

## Railway Metrics

### Built-in Metrics

Railway provides these metrics out-of-the-box:

**1. CPU Usage**
- View: Railway Dashboard → Service → Metrics
- Alert threshold: > 80% sustained
- Actions: Scale up or optimize code

**2. Memory Usage**
- View: Railway Dashboard → Service → Metrics
- Alert threshold: > 90% of limit
- Actions: Increase memory limit or fix leaks

**3. Network I/O**
- Incoming/outgoing traffic
- Request count
- Bandwidth usage

**4. Deployment History**
- Deployment timeline
- Build duration
- Deploy success/failure

### Custom Metrics Endpoint

Add Prometheus metrics (future enhancement):

```python
# backend/app/metrics.py
from prometheus_client import Counter, Histogram, Gauge, generate_latest

# Define metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

email_sync_duration = Histogram(
    'email_sync_duration_seconds',
    'Time spent syncing emails',
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0]
)

active_users = Gauge(
    'active_users',
    'Number of active users'
)

# Expose metrics endpoint
@app.get("/metrics")
async def metrics():
    return Response(
        generate_latest(),
        media_type="text/plain"
    )
```

---

## Logging Strategy

### Structured Logging with Structlog

**Configuration:** `infrastructure/monitoring/logging-config.yaml`

**Log Levels:**
- `DEBUG`: Development troubleshooting
- `INFO`: Normal operations, business events
- `WARNING`: Degraded performance, retries
- `ERROR`: Errors that need attention
- `CRITICAL`: System-wide failures

### Application Logging

```python
import structlog

logger = structlog.get_logger()

# Info logging
logger.info("email_synced",
    user_id=user_id,
    email_count=10,
    duration_ms=1234
)

# Error logging
logger.error("sync_failed",
    user_id=user_id,
    error=str(e),
    retry_attempt=2
)

# Performance logging
logger.info("ai_categorization",
    email_id=email_id,
    category="Work",
    confidence=0.95,
    processing_time_ms=456,
    tokens_used=123,
    cost_usd=0.0012
)
```

### Log Retention

**Railway:**
- Default: 7 days
- Paid plans: Up to 30 days

**Export for long-term retention:**

```bash
# Export logs to file
railway logs --service backend --tail 100000 > logs-$(date +%Y%m%d).json

# Upload to S3 (future)
aws s3 cp logs-$(date +%Y%m%d).json s3://inboxiq-logs/
```

### Log Analysis

**Search logs:**

```bash
# Search for errors
railway logs --service backend | grep ERROR

# Filter by user
railway logs --service backend | grep "user_id=abc-123"

# Track specific operation
railway logs --service backend | grep "email_sync"
```

**JSON log parsing:**

```bash
# Extract sync durations
railway logs --service backend --tail 1000 \
  | jq 'select(.event=="email_synced") | .duration_ms'

# Calculate average
railway logs --service backend --tail 1000 \
  | jq 'select(.event=="email_synced") | .duration_ms' \
  | jq -s 'add/length'
```

---

## Performance Monitoring

### API Response Times

**Track in code:**

```python
import time
from fastapi import Request

@app.middleware("http")
async def track_response_time(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    logger.info("api_request",
        method=request.method,
        path=request.url.path,
        status_code=response.status_code,
        duration_ms=int(duration * 1000)
    )
    
    response.headers["X-Response-Time"] = f"{duration:.3f}s"
    return response
```

**Performance targets:**

| Endpoint | P50 | P95 | P99 |
|----------|-----|-----|-----|
| /health | 10ms | 50ms | 100ms |
| /auth/login | 200ms | 500ms | 1s |
| /emails/sync | 1s | 3s | 5s |
| /emails (list) | 100ms | 300ms | 500ms |
| AI categorization | 500ms | 2s | 5s |

### Database Performance

**Monitor slow queries:**

```sql
-- Enable pg_stat_statements
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View slow queries
SELECT 
  query,
  calls,
  mean_exec_time,
  max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- Queries averaging > 100ms
ORDER BY mean_exec_time DESC
LIMIT 20;
```

**Connection pool monitoring:**

```python
from sqlalchemy import event

@event.listens_for(engine, "connect")
def receive_connect(dbapi_conn, connection_record):
    logger.debug("database_connection_created")

@event.listens_for(engine, "close")
def receive_close(dbapi_conn, connection_record):
    logger.debug("database_connection_closed")
```

### AI Performance Tracking

```python
logger.info("ai_metrics",
    model="claude-3-haiku-20240307",
    operation="categorization",
    input_tokens=456,
    output_tokens=23,
    total_tokens=479,
    latency_ms=1234,
    cost_usd=0.00056,
    success=True
)
```

---

## Cost Monitoring

### Claude API Costs

**Track per-request:**

```python
class ClaudeAPIClient:
    def calculate_cost(self, usage):
        # Claude 3 Haiku pricing (as of 2024)
        input_cost = (usage.input_tokens / 1_000_000) * 0.25
        output_cost = (usage.output_tokens / 1_000_000) * 1.25
        return input_cost + output_cost
    
    async def categorize(self, email):
        response = await self.client.messages.create(...)
        
        cost = self.calculate_cost(response.usage)
        
        # Log cost
        logger.info("ai_cost",
            operation="categorize",
            tokens=response.usage.total_tokens,
            cost_usd=cost
        )
        
        # Track in database
        await self.record_api_cost(cost)
        
        return result
```

**Daily cost report:**

```sql
SELECT 
  DATE(created_at) as date,
  COUNT(*) as api_calls,
  SUM(input_tokens) as total_input_tokens,
  SUM(output_tokens) as total_output_tokens,
  SUM(cost_usd) as total_cost
FROM ai_api_logs
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

**Cost alerts:**

```python
async def check_daily_budget():
    today_cost = await get_today_ai_cost()
    budget = float(os.getenv("CLAUDE_DAILY_BUDGET_USD", "10.00"))
    
    if today_cost > budget * 0.8:
        logger.warning("daily_budget_warning",
            current_cost=today_cost,
            budget=budget,
            percentage=(today_cost / budget) * 100
        )
        
        # Send alert
        await send_slack_alert(
            f"⚠️ AI cost at ${today_cost:.2f} (80% of ${budget} budget)"
        )
```

### Railway Costs

**Monitor in Dashboard:**
- Railway Dashboard → Usage & Billing
- View: Current month spend
- Export: Monthly invoices

**Estimated monthly costs:**

| Service | Plan | Cost |
|---------|------|------|
| Backend | Starter | $5-10 |
| Worker | Hobby | $5 |
| PostgreSQL | Hobby | $5 |
| Redis | Shared | $5 |
| **Total** | | **$20-25** |

---

## Alert Configuration

### Critical Alerts (Immediate Response)

1. **Service Down**
   ```
   Condition: Health check failing for > 5 minutes
   Channel: PagerDuty + SMS
   Response: Immediate
   ```

2. **Database Connection Lost**
   ```
   Condition: Database status != "ok"
   Channel: Slack + Email
   Response: Within 15 minutes
   ```

3. **High Error Rate**
   ```
   Condition: Error rate > 5% for 10 minutes
   Channel: Slack
   Response: Within 30 minutes
   ```

### Warning Alerts (Monitor & Investigate)

4. **High CPU Usage**
   ```
   Condition: CPU > 80% for 15 minutes
   Channel: Slack
   Response: Next business day
   ```

5. **Slow API Responses**
   ```
   Condition: P95 latency > 3s
   Channel: Email
   Response: Next business day
   ```

6. **Budget Warning**
   ```
   Condition: Daily AI cost > 80% of budget
   Channel: Email
   Response: Review next day
   ```

### Slack Webhook Setup

```python
# backend/app/alerts.py
import httpx

async def send_slack_alert(message: str, severity: str = "warning"):
    webhook_url = os.getenv("SLACK_WEBHOOK_URL")
    if not webhook_url:
        return
    
    color = {
        "info": "#36a64f",
        "warning": "#ff9800",
        "error": "#f44336",
        "critical": "#9c27b0"
    }[severity]
    
    payload = {
        "attachments": [{
            "color": color,
            "title": f"InboxIQ Alert - {severity.upper()}",
            "text": message,
            "footer": "InboxIQ Monitoring",
            "ts": int(time.time())
        }]
    }
    
    async with httpx.AsyncClient() as client:
        await client.post(webhook_url, json=payload)
```

---

## Dashboard Setup

### Grafana Dashboard (Future)

**Metrics to visualize:**

1. **System Health**
   - Uptime percentage
   - Health check latency
   - Error rate

2. **Performance**
   - API response time (P50, P95, P99)
   - Requests per minute
   - Active connections

3. **Business Metrics**
   - Daily active users
   - Emails synced per hour
   - AI categorizations per hour
   - Daily digests sent

4. **Costs**
   - Hourly AI API cost
   - Daily total spend
   - Monthly projection

### Simple Monitoring Script

```python
# scripts/health-monitor.py
import httpx
import asyncio

async def monitor_health():
    url = "https://api.inboxiq.app/health"
    
    while True:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, timeout=10)
                
                if response.status_code != 200:
                    await send_slack_alert(
                        f"❌ Health check failed: {response.status_code}",
                        severity="error"
                    )
                else:
                    health = response.json()
                    if health["status"] != "healthy":
                        await send_slack_alert(
                            f"⚠️ Service degraded: {health}",
                            severity="warning"
                        )
        except Exception as e:
            await send_slack_alert(
                f"💥 Health check error: {str(e)}",
                severity="critical"
            )
        
        await asyncio.sleep(60)  # Check every minute

if __name__ == "__main__":
    asyncio.run(monitor_health())
```

---

## Incident Response

### Incident Response Workflow

```
Incident Detected
    ↓
Assess Severity
    ↓
├─ Critical → Immediate response
├─ High → Response within 1 hour
└─ Low → Response next business day
    ↓
Investigate
    ↓
├─ Check Sentry for errors
├─ Review logs
├─ Check Railway metrics
└─ Test API endpoints
    ↓
Resolve
    ↓
├─ Fix issue
├─ Deploy fix
└─ Verify resolution
    ↓
Post-Mortem
    ↓
Document incident and preventive measures
```

### Incident Checklist

**During Incident:**
- [ ] Acknowledge alert
- [ ] Assess severity
- [ ] Notify team if critical
- [ ] Check Sentry for stack traces
- [ ] Review recent deployments
- [ ] Check Railway service status
- [ ] Verify database connectivity
- [ ] Test API manually
- [ ] Implement fix or rollback
- [ ] Verify resolution
- [ ] Update status page (if applicable)

**After Resolution:**
- [ ] Write post-mortem
- [ ] Identify root cause
- [ ] Document prevention steps
- [ ] Update runbooks
- [ ] Schedule follow-up improvements

---

## Monitoring Checklist

### Daily
- [ ] Check Sentry for new errors
- [ ] Review error rate trend
- [ ] Check AI cost vs budget
- [ ] Verify all services healthy

### Weekly
- [ ] Review performance metrics
- [ ] Analyze slow queries
- [ ] Check storage usage
- [ ] Review alert history
- [ ] Export and archive logs

### Monthly
- [ ] Review total infrastructure costs
- [ ] Analyze user growth trends
- [ ] Update capacity plan
- [ ] Review and update alerts
- [ ] Test incident response procedures

---

## Additional Resources

- [Sentry Documentation](https://docs.sentry.io)
- [Railway Observability](https://docs.railway.app/reference/observability)
- [Structlog Documentation](https://www.structlog.org)
- [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

*Last updated: 2024-01-15*
