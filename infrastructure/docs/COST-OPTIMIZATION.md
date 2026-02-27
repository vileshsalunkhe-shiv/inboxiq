# InboxIQ Cost Optimization Guide

Comprehensive strategies for minimizing infrastructure and API costs while maintaining performance and user experience.

## Table of Contents

1. [Cost Overview](#cost-overview)
2. [Railway Infrastructure Optimization](#railway-infrastructure-optimization)
3. [Claude AI Cost Reduction](#claude-ai-cost-reduction)
4. [Database Optimization](#database-optimization)
5. [Redis Optimization](#redis-optimization)
6. [Network & Bandwidth](#network--bandwidth)
7. [Monitoring Cost](#monitoring-cost)
8. [Cost Tracking & Alerts](#cost-tracking--alerts)
9. [Scaling Strategy](#scaling-strategy)
10. [Cost Projections](#cost-projections)

---

## Cost Overview

### Current Cost Structure (Monthly)

#### Fixed Costs

| Service | Plan | Monthly Cost | Optimization Potential |
|---------|------|--------------|----------------------|
| Backend (Railway) | Starter | $5-10 | ⭐⭐ Medium |
| Worker (Railway) | Hobby | $5 | ⭐ Low |
| PostgreSQL | Hobby | $5 | ⭐⭐⭐ High |
| Redis | Shared | $5 | ⭐⭐ Medium |
| **Infrastructure Total** | | **$20-25** | |

#### Variable Costs

| Service | Pricing Model | Est. Monthly | Optimization Potential |
|---------|--------------|--------------|----------------------|
| Claude AI (Haiku) | $0.25/MTok input, $1.25/MTok output | $10-50 | ⭐⭐⭐⭐⭐ Very High |
| Gmail API | Free (1B units/day) | $0 | N/A |
| APNs | Free | $0 | N/A |
| Sentry | Free tier (5K events) | $0 | ⭐⭐ Medium |
| **Variable Total** | | **$10-50** | |

### **Total: $30-75/month** (MVP, <1000 users)

### Cost Breakdown by User Activity

- **Inactive user:** $0.01-0.05/month (database storage only)
- **Light user:** $0.20-0.50/month (100 emails/day)
- **Heavy user:** $1-3/month (500+ emails/day, frequent AI categorization)

**Target:** Keep average cost per active user under $0.50/month

---

## Railway Infrastructure Optimization

### Right-Size Services

#### Backend Service

**Current:** 512MB RAM, 0.5 vCPU

**Optimization:**

```bash
# Start small, scale up only when needed
railway service update backend --memory 256 --cpu 0.25

# Monitor for 1-2 weeks
railway logs --service backend | grep -i "memory\|cpu"

# Scale up if needed
railway service update backend --memory 512 --cpu 0.5
```

**Savings:** $2-3/month

#### Worker Service

**Current:** 256MB RAM, 0.25 vCPU

**Optimization:**

```bash
# Worker can run on minimal resources
railway service update worker --memory 128 --cpu 0.1

# Increase concurrency instead of resources
railway variables set WORKER_CONCURRENCY=3  # From 5
```

**Savings:** $1-2/month

### Auto-Scaling Configuration

```json
// railway.json
{
  "deploy": {
    "numReplicas": 1,
    "autoscaling": {
      "enabled": true,
      "minReplicas": 1,
      "maxReplicas": 3,
      "targetCPU": 80,
      "targetMemory": 85
    }
  }
}
```

**Strategy:**
- Start with 1 replica
- Auto-scale only during peak hours
- Scale down aggressively during low traffic

**Savings:** $5-10/month (vs. always running 2+ replicas)

### Sleep Mode for Development

```bash
# Enable sleep mode for staging/dev environments
railway service update staging-backend --sleep-after 3600

# Staging environment sleeps after 1 hour of inactivity
# Wakes automatically on request (adds ~10s delay)
```

**Savings:** $5-10/month on staging environments

---

## Claude AI Cost Reduction

### Model Selection

**Current:** Claude 3 Haiku - $0.25/MTok input, $1.25/MTok output

**Cost Comparison:**

| Model | Input Cost | Output Cost | Use Case | Relative Cost |
|-------|-----------|-------------|----------|---------------|
| Haiku | $0.25/MTok | $1.25/MTok | ✅ Email categorization | 1x (baseline) |
| Sonnet | $3/MTok | $15/MTok | ❌ Too expensive | 12x |
| Opus | $15/MTok | $75/MTok | ❌ Way too expensive | 60x |

**Recommendation:** Stick with Haiku for categorization tasks.

**Savings:** Using Haiku vs Sonnet = **90% cost reduction**

### Prompt Optimization

#### Before Optimization (Expensive)

```python
# Full email content + verbose prompt
prompt = f"""
You are an AI assistant that categorizes emails. Please analyze the following email and determine which category it belongs to. Consider the sender, subject, and content carefully. Provide reasoning for your categorization.

Email Details:
From: {email.sender}
To: {email.recipient}
Subject: {email.subject}
Date: {email.date}

Full Content:
{email.full_body}  # Could be 1000+ tokens

Categories:
{json.dumps(categories, indent=2)}  # Verbose JSON

Please respond with your analysis.
"""
# Average tokens: 800-1200 input, 150 output
# Cost per email: $0.0003 (input) + $0.00019 (output) = $0.00049
```

**Cost for 10,000 emails/day:** $4.90/day = **$147/month**

#### After Optimization (Cheap)

```python
# Minimal prompt with only essential data
prompt = f"""Categorize this email:
From: {email.sender}
Subject: {email.subject}
Snippet: {email.body[:200]}

Categories: {','.join([c.name for c in categories])}

Reply with category name only."""

# Average tokens: 100-150 input, 5-10 output
# Cost per email: $0.00004 (input) + $0.00001 (output) = $0.00005
```

**Cost for 10,000 emails/day:** $0.50/day = **$15/month**

**Savings:** **90% reduction ($132/month saved!)**

### Batch Processing

```python
# Instead of 1 API call per email (expensive)
async def categorize_email(email):
    response = await claude.messages.create(
        model="claude-3-haiku-20240307",
        messages=[{"role": "user", "content": prompt}]
    )
    # Cost: 1x per email

# Batch multiple emails in one call (cheaper)
async def categorize_batch(emails):
    batch_prompt = "Categorize these emails (respond with JSON array):\n\n"
    for i, email in enumerate(emails):
        batch_prompt += f"{i}. From: {email.sender}, Subject: {email.subject}\n"
    
    response = await claude.messages.create(
        model="claude-3-haiku-20240307",
        messages=[{"role": "user", "content": batch_prompt}]
    )
    # Cost: 1x for 10 emails
```

**Savings:** 50-70% reduction in API calls

**Configuration:**

```bash
# Increase batch size
railway variables set WORKER_BATCH_SIZE=20  # From 10

# Process more efficiently
railway variables set WORKER_POLL_INTERVAL=30  # From 5 (wait for more emails to batch)
```

### Caching Predictions

```python
# Cache common sender→category mappings
import redis

cache = redis.from_url(os.getenv("REDIS_URL"))

async def categorize_with_cache(email):
    # Create cache key from sender + subject pattern
    cache_key = f"cat:{email.sender}:{hash(email.subject[:20])}"
    
    # Check cache first
    cached = await cache.get(cache_key)
    if cached:
        return json.loads(cached)
    
    # Call API only if cache miss
    category = await categorize_email(email)
    
    # Cache for 30 days
    await cache.setex(cache_key, 2592000, json.dumps(category))
    
    return category
```

**Expected cache hit rate:** 60-80% (newsletters, automated emails)

**Savings:** 60-80% reduction in API calls

**Cost impact:**
- Before: 10,000 emails/day × $0.00005 = $0.50/day
- After (70% cache hit): 3,000 API calls/day × $0.00005 = $0.15/day
- **Savings: $0.35/day = $10.50/month**

### Daily Budget Limits

```python
# Implement hard budget cap
async def check_daily_budget():
    today = datetime.now().date()
    today_cost = await get_ai_cost_for_date(today)
    daily_budget = float(os.getenv("CLAUDE_DAILY_BUDGET_USD", "5.00"))
    
    if today_cost >= daily_budget:
        logger.warning(f"Daily budget ${daily_budget} exceeded (${today_cost})")
        # Pause worker or use fallback categorization
        return False
    
    return True

# In worker loop
if await check_daily_budget():
    await process_batch()
else:
    # Use rule-based fallback categorization
    await fallback_categorize(emails)
```

**Configuration:**

```bash
# Set conservative daily budget
railway variables set CLAUDE_DAILY_BUDGET_USD=5.00
railway variables set CLAUDE_COST_ALERT_THRESHOLD_USD=4.00  # Alert at 80%
```

### Smart Categorization Strategy

```python
# Only use AI for ambiguous emails
async def smart_categorize(email):
    # 1. Try rule-based first (free!)
    if email.sender in known_senders:
        return known_senders[email.sender].category
    
    # 2. Check cache
    cached = await get_cached_category(email)
    if cached:
        return cached
    
    # 3. Pattern matching (free!)
    if 'newsletter' in email.subject.lower():
        return 'Newsletters'
    if 'receipt' in email.subject.lower():
        return 'Shopping'
    
    # 4. Only use AI for truly ambiguous emails
    return await ai_categorize(email)
```

**Expected AI usage:** 20-40% of emails (vs. 100%)

**Savings:** 60-80% reduction = **$2-4/day**

---

## Database Optimization

### Query Optimization

#### Slow Query (Before)

```sql
-- Fetching user's emails without index
SELECT * FROM emails 
WHERE user_id = 'abc-123' 
ORDER BY received_at DESC 
LIMIT 50;

-- Execution time: 800ms
-- Database CPU: High
```

#### Fast Query (After)

```sql
-- Create composite index
CREATE INDEX CONCURRENTLY idx_emails_user_received 
ON emails(user_id, received_at DESC);

-- Same query now
-- Execution time: 15ms
-- Database CPU: Low
```

**Savings:** Reduced database CPU usage = can run on smaller plan

#### Essential Indexes

```sql
-- User lookup
CREATE INDEX idx_emails_user_id ON emails(user_id);
CREATE INDEX idx_users_email ON users(email);

-- Category filtering
CREATE INDEX idx_emails_category ON emails(category_id);
CREATE INDEX idx_emails_user_category ON emails(user_id, category_id);

-- Time-based queries
CREATE INDEX idx_emails_received_at ON emails(received_at DESC);

-- Search (if implemented)
CREATE INDEX idx_emails_subject ON emails USING gin(to_tsvector('english', subject));
```

### Connection Pooling

```python
# Inefficient: Each request creates new connection
engine = create_engine(DATABASE_URL)

# Efficient: Reuse connection pool
engine = create_engine(
    DATABASE_URL,
    pool_size=10,           # Base connections
    max_overflow=20,        # Extra during peak
    pool_recycle=3600,      # Recycle connections every hour
    pool_pre_ping=True      # Verify connection health
)
```

**Configuration:**

```bash
# Optimize connection pool for Railway Hobby plan (50 connections max)
railway variables set DATABASE_POOL_SIZE=10
railway variables set DATABASE_MAX_OVERFLOW=15
# Total max: 25 connections (leaves room for other services)
```

**Savings:** Can serve more users without upgrading database plan

### Data Archival Strategy

```sql
-- Move old emails to archive table
-- Keep main table fast and small

-- 1. Create archive table
CREATE TABLE emails_archive (LIKE emails INCLUDING ALL);

-- 2. Move emails older than 6 months
INSERT INTO emails_archive
SELECT * FROM emails
WHERE received_at < NOW() - INTERVAL '6 months';

DELETE FROM emails
WHERE received_at < NOW() - INTERVAL '6 months';

-- 3. Vacuum to reclaim space
VACUUM FULL emails;
```

**Schedule:** Run monthly via cron

**Savings:** Reduced database size = lower storage costs, faster queries

### Database Plan Optimization

**Current:** Hobby ($5/month) - 10GB storage, 50 connections

**Monitor usage:**

```sql
-- Check database size
SELECT pg_size_pretty(pg_database_size('inboxiq'));

-- Check connection usage
SELECT count(*) FROM pg_stat_activity;
```

**Thresholds:**
- < 2GB usage → Stay on Hobby
- 2-8GB usage → Hobby is fine
- > 8GB → Consider archival strategy before upgrading

**Savings:** Avoid upgrading to Pro ($15/month) = **$10/month saved**

---

## Redis Optimization

### Memory Usage Optimization

```python
# Store only essential data in Redis
# Avoid storing full objects

# ❌ Bad: Store entire user object (100+ bytes)
redis.set(f"user:{user_id}", json.dumps(user_dict))

# ✅ Good: Store only user ID (36 bytes)
redis.set(f"session:{token}", user_id)

# ❌ Bad: Store full email content in queue (1KB+)
redis.lpush("ai_queue", json.dumps(email_full))

# ✅ Good: Store only email ID (reference)
redis.lpush("ai_queue", email_id)
```

**Savings:** 90% reduction in Redis memory usage

### TTL Management

```python
# Set aggressive TTLs for cached data

# Session tokens: 30 minutes
redis.setex(f"session:{token}", 1800, user_id)

# Category cache: 7 days
redis.setex(f"cat:{sender}", 604800, category)

# Temporary data: 1 hour
redis.setex(f"temp:{key}", 3600, value)
```

**Savings:** Reduced memory usage = can stay on Shared plan longer

### Eviction Policy

```bash
# Configure LRU eviction in Redis
redis-cli CONFIG SET maxmemory-policy allkeys-lru

# Or in docker-compose.yml
command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
```

**Recommendation:** Use LRU (Least Recently Used) eviction

### Redis Plan Optimization

**Current:** Shared ($5/month) - 1GB memory

**Monitor:**

```bash
# Check Redis memory usage
redis-cli INFO memory | grep used_memory_human

# Check eviction stats
redis-cli INFO stats | grep evicted_keys
```

**Thresholds:**
- < 500MB → Shared is perfect
- 500-900MB → Optimize TTLs, reduce stored data
- > 900MB → Consider eviction policy before upgrading

**Savings:** Stay on Shared plan = **$10/month saved** (vs. Dedicated)

---

## Network & Bandwidth

### API Response Compression

```python
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)
```

**Savings:** 70-80% reduction in response size

### Pagination

```python
# ❌ Bad: Return all emails
@app.get("/emails")
async def get_emails(user_id: str):
    return await db.query(Email).filter(user_id=user_id).all()
    # Could be 10,000+ emails = 10MB+ response

# ✅ Good: Paginate
@app.get("/emails")
async def get_emails(user_id: str, limit: int = 50, offset: int = 0):
    return await db.query(Email)\
        .filter(user_id=user_id)\
        .limit(limit)\
        .offset(offset)\
        .all()
    # 50 emails = 50KB response
```

**Savings:** 99% reduction in bandwidth per request

### GraphQL/Partial Responses

```python
# Allow clients to request only needed fields
@app.get("/emails")
async def get_emails(
    user_id: str,
    fields: str = "id,subject,sender,received_at"
):
    # Only query and return requested fields
    pass
```

**Savings:** 50-80% reduction in response size

---

## Monitoring Cost

### Sentry Optimization

**Current:** Free tier (5,000 events/month)

**Optimization:**

```python
# 1. Filter low-value events
def before_send(event, hint):
    # Don't send validation errors
    if event.get('exception', {}).get('type') == 'ValidationError':
        return None
    
    # Don't send 404s
    if event.get('request', {}).get('status_code') == 404:
        return None
    
    return event

sentry_sdk.init(
    dsn=SENTRY_DSN,
    before_send=before_send,
    # Sample performance traces
    traces_sample_rate=0.05  # Only 5% of transactions
)
```

**Savings:** Stay under free tier limit = **$0/month** (vs. $26/month paid plan)

### Log Management

```python
# Reduce log volume in production

# ❌ Bad: Log everything
logger.debug(f"Processing email {email.id} for user {user.id}")  # Every email!

# ✅ Good: Log only important events
logger.info(f"Batch categorized {len(emails)} emails")  # Once per batch
logger.error(f"Failed to categorize email {email.id}: {error}")  # Only errors
```

**Configuration:**

```bash
# Production: Only warnings and errors
railway variables set LOG_LEVEL=WARNING

# Staging: Info level
railway variables set LOG_LEVEL=INFO --service staging-backend
```

**Savings:** Reduced log storage and processing

---

## Cost Tracking & Alerts

### Implement Cost Tracking

```sql
-- Create cost tracking table
CREATE TABLE cost_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    service VARCHAR(50) NOT NULL,  -- 'claude_api', 'railway', etc.
    cost_usd DECIMAL(10, 4) NOT NULL,
    units_used INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Daily cost summary
SELECT 
    date,
    service,
    SUM(cost_usd) as daily_cost,
    SUM(units_used) as total_units
FROM cost_tracking
WHERE date >= NOW() - INTERVAL '30 days'
GROUP BY date, service
ORDER BY date DESC;
```

### Cost Alerts

```python
async def check_costs_and_alert():
    # Daily Claude cost
    today_claude = await get_claude_cost_today()
    if today_claude > 5.00:
        await send_slack_alert(f"⚠️ Claude cost today: ${today_claude:.2f}")
    
    # Monthly total projection
    monthly_projection = await project_monthly_cost()
    if monthly_projection > 75.00:
        await send_email_alert(f"⚠️ Projected monthly cost: ${monthly_projection:.2f}")
    
    # Per-user cost outliers
    expensive_users = await get_expensive_users(threshold=2.00)
    if expensive_users:
        await log_warning(f"High-cost users: {expensive_users}")
```

**Configure alerts:**

```bash
railway variables set DAILY_BUDGET_USD=5.00
railway variables set MONTHLY_BUDGET_USD=75.00
railway variables set COST_ALERT_SLACK_WEBHOOK=https://hooks.slack.com/...
```

### Cost Dashboard

```python
# Simple cost dashboard endpoint
@app.get("/admin/costs")
async def get_costs(days: int = 30):
    return {
        "daily_costs": await get_daily_costs(days),
        "monthly_total": await get_monthly_total(),
        "cost_by_service": await get_cost_breakdown(),
        "cost_per_active_user": await get_cost_per_user(),
        "projected_monthly": await project_monthly_cost()
    }
```

---

## Scaling Strategy

### User Growth → Cost Scaling

| Users | Daily Emails | Monthly Cost | Cost/User |
|-------|-------------|--------------|-----------|
| 100 | 10,000 | $35 | $0.35 |
| 500 | 50,000 | $55 | $0.11 |
| 1,000 | 100,000 | $85 | $0.085 |
| 5,000 | 500,000 | $250 | $0.05 |
| 10,000 | 1M | $450 | $0.045 |

**Key insight:** Cost per user DECREASES as you scale (economies of scale)

### Optimization Roadmap

**0-500 users (MVP):**
- Focus on functionality, not optimization
- Use simple caching
- Monitor costs weekly
- **Target:** < $75/month

**500-2,000 users:**
- Implement aggressive caching
- Optimize Claude prompts
- Add database indexes
- **Target:** < $150/month

**2,000-10,000 users:**
- Batch processing optimization
- Consider reserved instances
- Implement CDN for static assets
- **Target:** < $500/month

**10,000+ users:**
- Custom AI model (fine-tuned, cheaper)
- Dedicated infrastructure
- Multi-region deployment
- **Target:** < $0.05/user/month

---

## Cost Projections

### Conservative Scenario (High Cost)

**Assumptions:**
- 1,000 active users
- 200 emails/user/day
- 80% use AI categorization
- No caching
- Haiku model

**Calculation:**
- Emails/day: 200,000
- AI calls/day: 160,000
- Cost/email: $0.0001
- Daily AI cost: $16
- Monthly AI cost: $480
- Infrastructure: $25
- **Total: $505/month**
- **Cost per user: $0.505**

### Optimized Scenario (Low Cost)

**Assumptions:**
- 1,000 active users
- 200 emails/user/day
- 30% use AI (rest cached/rule-based)
- Optimized prompts (50% token reduction)
- Haiku model

**Calculation:**
- Emails/day: 200,000
- AI calls/day: 60,000 (70% cache hit)
- Cost/email: $0.00005 (50% token reduction)
- Daily AI cost: $3
- Monthly AI cost: $90
- Infrastructure: $25
- **Total: $115/month**
- **Cost per user: $0.115**

### **Savings: $390/month (77% reduction!)**

---

## Cost Optimization Checklist

### Immediate Actions (Do Now)

- [ ] Switch to Claude Haiku model
- [ ] Optimize AI prompts (reduce tokens by 50%+)
- [ ] Implement category prediction caching
- [ ] Add database indexes
- [ ] Set daily AI budget limits
- [ ] Configure connection pooling
- [ ] Enable response compression
- [ ] Implement pagination
- [ ] Right-size Railway services
- [ ] Set up cost tracking

### Short-Term (This Month)

- [ ] Implement batch AI processing
- [ ] Add rule-based categorization fallback
- [ ] Optimize database queries
- [ ] Set up cost alerts
- [ ] Review and reduce log volume
- [ ] Implement data archival strategy
- [ ] Monitor and optimize Redis usage
- [ ] Add performance monitoring

### Long-Term (3-6 Months)

- [ ] Consider custom fine-tuned model
- [ ] Implement advanced caching strategies
- [ ] Evaluate dedicated hosting (if cost-effective at scale)
- [ ] Build internal categorization model
- [ ] Implement smart pre-processing
- [ ] Consider CDN for static assets
- [ ] Evaluate multi-region deployment

---

## Conclusion

By implementing these optimizations, you can:

- **Reduce Claude AI costs by 80-90%** ($40-50/month → $5-10/month)
- **Avoid infrastructure upgrades** (stay on $20-25/month plans)
- **Maintain fast performance** (< 500ms API response times)
- **Scale efficiently** (cost per user decreases with growth)

**Target:** Keep total monthly costs under $50 for MVP (0-1000 users)

**Key Priorities:**
1. Optimize AI prompts (biggest impact)
2. Implement caching (70-80% hit rate)
3. Batch processing (reduce API calls)
4. Right-size infrastructure (don't over-provision)
5. Monitor and alert (stay within budget)

---

*Last updated: 2024-02-26*
