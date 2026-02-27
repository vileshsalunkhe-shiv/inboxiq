# InboxIQ Environment Variables Reference

Complete reference for all environment variables used in InboxIQ backend and worker services.

## Table of Contents

1. [Server Configuration](#server-configuration)
2. [Database Configuration](#database-configuration)
3. [Redis Configuration](#redis-configuration)
4. [Authentication & Security](#authentication--security)
5. [Google OAuth & Gmail](#google-oauth--gmail)
6. [Claude AI Configuration](#claude-ai-configuration)
7. [Apple Push Notifications](#apple-push-notifications)
8. [Monitoring & Logging](#monitoring--logging)
9. [Worker Configuration](#worker-configuration)
10. [Feature Flags](#feature-flags)
11. [Environment-Specific Settings](#environment-specific-settings)

---

## Server Configuration

### PORT
- **Type:** Integer
- **Default:** `8000`
- **Required:** No
- **Description:** Port number for the FastAPI server
- **Example:** `PORT=8000`
- **Notes:** Railway sets this automatically

### ENVIRONMENT
- **Type:** String (enum)
- **Default:** `development`
- **Required:** Yes
- **Values:** `development`, `staging`, `production`
- **Description:** Deployment environment name
- **Example:** `ENVIRONMENT=production`
- **Notes:** Controls logging, error handling, and feature flags

### LOG_LEVEL
- **Type:** String (enum)
- **Default:** `INFO`
- **Required:** No
- **Values:** `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`
- **Description:** Minimum log level to output
- **Example:** `LOG_LEVEL=INFO`
- **Notes:** Use `DEBUG` in development, `INFO` or `WARNING` in production

---

## Database Configuration

### DATABASE_URL
- **Type:** String (Connection URI)
- **Default:** None
- **Required:** Yes
- **Format:** `postgresql://user:password@host:port/database`
- **Example:** `postgresql://inboxiq:pass@localhost:5432/inboxiq_dev`
- **Railway:** `${{PostgreSQL.DATABASE_URL}}`
- **Security:** ⚠️ Never commit to git

### DATABASE_POOL_SIZE
- **Type:** Integer
- **Default:** `10`
- **Required:** No
- **Description:** Maximum number of database connections in pool
- **Example:** `DATABASE_POOL_SIZE=20`
- **Recommendations:**
  - Development: 5-10
  - Staging: 10-20
  - Production: 20-50

### DATABASE_MAX_OVERFLOW
- **Type:** Integer
- **Default:** `20`
- **Required:** No
- **Description:** Maximum overflow connections beyond pool size
- **Example:** `DATABASE_MAX_OVERFLOW=30`

### DATABASE_ECHO
- **Type:** Boolean
- **Default:** `false`
- **Required:** No
- **Description:** Log all SQL queries (debug only)
- **Example:** `DATABASE_ECHO=true`
- **Notes:** ⚠️ Never enable in production (performance impact)

---

## Redis Configuration

### REDIS_URL
- **Type:** String (Connection URI)
- **Default:** None
- **Required:** Yes
- **Format:** `redis://[:password]@host:port/database`
- **Example:** `redis://:mypassword@localhost:6379/0`
- **Railway:** `${{Redis.REDIS_URL}}`
- **Security:** ⚠️ Never commit to git

### REDIS_MAX_CONNECTIONS
- **Type:** Integer
- **Default:** `50`
- **Required:** No
- **Description:** Maximum Redis connection pool size
- **Example:** `REDIS_MAX_CONNECTIONS=100`

### REDIS_SOCKET_TIMEOUT
- **Type:** Integer (seconds)
- **Default:** `5`
- **Required:** No
- **Description:** Socket timeout for Redis operations
- **Example:** `REDIS_SOCKET_TIMEOUT=10`

---

## Authentication & Security

### JWT_SECRET_KEY
- **Type:** String (base64)
- **Default:** None
- **Required:** Yes
- **Generate:** `openssl rand -base64 32`
- **Example:** `JWT_SECRET_KEY=abc123def456...`
- **Security:** 🔒 Critical secret - rotate quarterly
- **Notes:** Used to sign JWT access tokens

### JWT_ALGORITHM
- **Type:** String
- **Default:** `HS256`
- **Required:** No
- **Values:** `HS256`, `HS384`, `HS512`
- **Example:** `JWT_ALGORITHM=HS256`

### ACCESS_TOKEN_EXPIRE_MINUTES
- **Type:** Integer
- **Default:** `30`
- **Required:** No
- **Description:** JWT access token lifetime in minutes
- **Example:** `ACCESS_TOKEN_EXPIRE_MINUTES=60`
- **Recommendations:**
  - Development: 60 minutes
  - Production: 15-30 minutes

### REFRESH_TOKEN_EXPIRE_DAYS
- **Type:** Integer
- **Default:** `30`
- **Required:** No
- **Description:** Refresh token lifetime in days
- **Example:** `REFRESH_TOKEN_EXPIRE_DAYS=7`

### ENCRYPTION_KEY
- **Type:** String (Fernet key)
- **Default:** None
- **Required:** Yes
- **Generate:** `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`
- **Example:** `ENCRYPTION_KEY=gAAAAABh...`
- **Security:** 🔒 Critical secret - used for Gmail token encryption
- **Notes:** Must be 32 url-safe base64-encoded bytes

### CORS_ORIGINS
- **Type:** String (comma-separated)
- **Default:** `http://localhost:3000`
- **Required:** Yes
- **Description:** Allowed CORS origins
- **Example:** `CORS_ORIGINS=https://inboxiq.app,https://api.inboxiq.app`
- **Notes:** Include all frontend domains

### HSTS_MAX_AGE
- **Type:** Integer (seconds)
- **Default:** `31536000` (1 year)
- **Required:** No
- **Description:** HSTS header max-age value
- **Example:** `HSTS_MAX_AGE=31536000`

---

## Google OAuth & Gmail

### GOOGLE_CLIENT_ID
- **Type:** String
- **Default:** None
- **Required:** Yes
- **Source:** Google Cloud Console → APIs & Services → Credentials
- **Example:** `GOOGLE_CLIENT_ID=123456789-abc.apps.googleusercontent.com`
- **Security:** ⚠️ Sensitive - do not expose publicly

### GOOGLE_CLIENT_SECRET
- **Type:** String
- **Default:** None
- **Required:** Yes
- **Source:** Google Cloud Console → APIs & Services → Credentials
- **Example:** `GOOGLE_CLIENT_SECRET=GOCSPX-...`
- **Security:** 🔒 Critical secret

### GOOGLE_REDIRECT_URI
- **Type:** String (URL)
- **Default:** None
- **Required:** Yes
- **Description:** OAuth callback URL
- **Example:** `https://api.inboxiq.app/auth/callback`
- **Notes:** Must match exactly what's configured in Google Console

### GOOGLE_SCOPES
- **Type:** String (space-separated)
- **Default:** (see below)
- **Required:** No
- **Example:** `https://www.googleapis.com/auth/gmail.readonly https://www.googleapis.com/auth/gmail.modify https://www.googleapis.com/auth/gmail.send`
- **Notes:** Default scopes are sufficient for InboxIQ

---

## Claude AI Configuration

### ANTHROPIC_API_KEY
- **Type:** String
- **Default:** None
- **Required:** Yes
- **Source:** https://console.anthropic.com
- **Format:** `sk-ant-api03-...`
- **Example:** `ANTHROPIC_API_KEY=sk-ant-api03-...`
- **Security:** 🔒 Critical secret - track usage and costs

### CLAUDE_MODEL
- **Type:** String
- **Default:** `claude-3-haiku-20240307`
- **Required:** No
- **Values:**
  - `claude-3-haiku-20240307` - Fastest, cheapest (recommended)
  - `claude-3-sonnet-20240229` - Better quality, more expensive
  - `claude-3-opus-20240229` - Best quality, most expensive
- **Example:** `CLAUDE_MODEL=claude-3-haiku-20240307`
- **Cost:** Haiku: $0.25/MTok input, $1.25/MTok output

### CLAUDE_MAX_TOKENS
- **Type:** Integer
- **Default:** `1024`
- **Required:** No
- **Description:** Maximum tokens for Claude responses
- **Example:** `CLAUDE_MAX_TOKENS=2048`
- **Recommendations:**
  - Email categorization: 100-200
  - Digest generation: 1000-2000

### CLAUDE_TEMPERATURE
- **Type:** Float (0.0-1.0)
- **Default:** `0.3`
- **Required:** No
- **Description:** Response randomness (0 = deterministic, 1 = creative)
- **Example:** `CLAUDE_TEMPERATURE=0.3`
- **Recommendations:**
  - Categorization: 0.1-0.3 (consistent)
  - Digest summaries: 0.3-0.5 (natural)

### CLAUDE_TIMEOUT
- **Type:** Integer (seconds)
- **Default:** `30`
- **Required:** No
- **Description:** API request timeout
- **Example:** `CLAUDE_TIMEOUT=60`

### CLAUDE_DAILY_BUDGET_USD
- **Type:** Float
- **Default:** `10.00`
- **Required:** No
- **Description:** Daily spending limit (monitoring)
- **Example:** `CLAUDE_DAILY_BUDGET_USD=20.00`

---

## Apple Push Notifications

### APNS_KEY_ID
- **Type:** String
- **Default:** None
- **Required:** Yes (for iOS push)
- **Source:** Apple Developer Portal → Certificates, IDs & Profiles → Keys
- **Example:** `APNS_KEY_ID=ABC123XYZ9`
- **Format:** 10-character key ID

### APNS_TEAM_ID
- **Type:** String
- **Default:** None
- **Required:** Yes (for iOS push)
- **Source:** Apple Developer Portal → Membership
- **Example:** `APNS_TEAM_ID=TEAMID1234`
- **Format:** 10-character team ID

### APNS_BUNDLE_ID
- **Type:** String
- **Default:** None
- **Required:** Yes (for iOS push)
- **Description:** iOS app bundle identifier
- **Example:** `APNS_BUNDLE_ID=com.yourcompany.inboxiq`
- **Notes:** Must match Xcode project bundle ID

### APNS_KEY_PATH
- **Type:** String (file path)
- **Default:** None
- **Required:** Yes (for iOS push)
- **Description:** Path to .p8 key file
- **Example:** `APNS_KEY_PATH=/app/secrets/AuthKey_ABC123XYZ9.p8`

### APNS_USE_SANDBOX
- **Type:** Boolean
- **Default:** `true`
- **Required:** No
- **Description:** Use APNs sandbox environment
- **Example:** `APNS_USE_SANDBOX=false`
- **Notes:** `false` for production, `true` for development/TestFlight

---

## Monitoring & Logging

### SENTRY_DSN
- **Type:** String (URL)
- **Default:** None
- **Required:** No (recommended)
- **Source:** https://sentry.io → Project Settings → Client Keys (DSN)
- **Example:** `SENTRY_DSN=https://abc123@o123456.ingest.sentry.io/789`
- **Notes:** Omit in development to disable Sentry

### SENTRY_ENVIRONMENT
- **Type:** String
- **Default:** Value of `ENVIRONMENT`
- **Required:** No
- **Description:** Environment tag in Sentry
- **Example:** `SENTRY_ENVIRONMENT=production`

### SENTRY_TRACES_SAMPLE_RATE
- **Type:** Float (0.0-1.0)
- **Default:** `0.1` (10%)
- **Required:** No
- **Description:** Percentage of transactions to trace
- **Example:** `SENTRY_TRACES_SAMPLE_RATE=0.05`
- **Recommendations:**
  - Development: 1.0 (100%)
  - Production: 0.05-0.1 (5-10%)

### LOG_FORMAT
- **Type:** String (enum)
- **Default:** `json`
- **Required:** No
- **Values:** `json`, `text`
- **Example:** `LOG_FORMAT=json`
- **Notes:** Use `json` for production, `text` for development

---

## Worker Configuration

### WORKER_CONCURRENCY
- **Type:** Integer
- **Default:** `5`
- **Required:** No
- **Description:** Number of concurrent worker jobs
- **Example:** `WORKER_CONCURRENCY=10`
- **Recommendations:**
  - Development: 3-5
  - Production: 5-10

### WORKER_BATCH_SIZE
- **Type:** Integer
- **Default:** `10`
- **Required:** No
- **Description:** Emails processed per batch
- **Example:** `WORKER_BATCH_SIZE=20`

### WORKER_POLL_INTERVAL
- **Type:** Integer (seconds)
- **Default:** `5`
- **Required:** No
- **Description:** Seconds between queue checks
- **Example:** `WORKER_POLL_INTERVAL=10`

### WORKER_MAX_RETRIES
- **Type:** Integer
- **Default:** `3`
- **Required:** No
- **Description:** Maximum retry attempts for failed jobs
- **Example:** `WORKER_MAX_RETRIES=5`

### DIGEST_ENABLED
- **Type:** Boolean
- **Default:** `true`
- **Required:** No
- **Description:** Enable daily digest feature
- **Example:** `DIGEST_ENABLED=true`

### DIGEST_CHECK_INTERVAL
- **Type:** Integer (seconds)
- **Default:** `3600` (1 hour)
- **Required:** No
- **Description:** Frequency to check for due digests
- **Example:** `DIGEST_CHECK_INTERVAL=7200`

---

## Feature Flags

### FEATURE_DAILY_DIGEST
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enable daily email digest
- **Example:** `FEATURE_DAILY_DIGEST=true`

### FEATURE_CUSTOM_CATEGORIES
- **Type:** Boolean
- **Default:** `true`
- **Description:** Allow users to create custom categories
- **Example:** `FEATURE_CUSTOM_CATEGORIES=false`

### FEATURE_EMAIL_SEARCH
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enable email search functionality
- **Example:** `FEATURE_EMAIL_SEARCH=true`

---

## Environment-Specific Settings

### Development
```bash
ENVIRONMENT=development
LOG_LEVEL=DEBUG
DEBUG=true
ENABLE_API_DOCS=true
RELOAD_ON_CHANGE=true
SENTRY_DSN=  # Empty (disabled)
DATABASE_ECHO=true
```

### Staging
```bash
ENVIRONMENT=staging
LOG_LEVEL=INFO
DEBUG=false
ENABLE_API_DOCS=true
SENTRY_DSN=<staging-sentry-dsn>
SENTRY_TRACES_SAMPLE_RATE=0.5
```

### Production
```bash
ENVIRONMENT=production
LOG_LEVEL=WARNING
DEBUG=false
ENABLE_API_DOCS=false
SENTRY_DSN=<production-sentry-dsn>
SENTRY_TRACES_SAMPLE_RATE=0.1
DATABASE_ECHO=false
HSTS_MAX_AGE=31536000
```

---

## Security Best Practices

### Secret Rotation Schedule

| Secret | Rotation Frequency | Priority |
|--------|-------------------|----------|
| JWT_SECRET_KEY | Quarterly | High |
| ENCRYPTION_KEY | Bi-annually | Critical |
| GOOGLE_CLIENT_SECRET | Annually | High |
| ANTHROPIC_API_KEY | Annually | Medium |
| APNs Keys | Annually | Medium |

### Secret Storage

- ✅ Store in Railway environment variables
- ✅ Use 1Password/Vault for backup
- ✅ Restrict access to production secrets
- ❌ Never commit secrets to git
- ❌ Never log secret values
- ❌ Never expose in error messages

### Verification Checklist

Before deployment:
- [ ] All required variables set
- [ ] All secrets are strong and unique
- [ ] No default/example values in production
- [ ] CORS origins restricted to actual domains
- [ ] Debug mode disabled in production
- [ ] Database echo disabled
- [ ] Appropriate log level set
- [ ] Sentry DSN configured
- [ ] SSL/TLS enabled

---

## Troubleshooting

### Missing Variable Error

```
Error: ANTHROPIC_API_KEY is not set
```

**Solution:**
```bash
railway variables set ANTHROPIC_API_KEY=<your-key>
railway restart
```

### Invalid Secret Format

```
Error: Invalid ENCRYPTION_KEY format
```

**Solution:**
```bash
# Regenerate key
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Set new key
railway variables set ENCRYPTION_KEY=<new-key>
```

### Database Connection Failed

```
Error: could not connect to server: Connection refused
```

**Solution:**
1. Verify `DATABASE_URL` is set correctly
2. Check PostgreSQL service is running
3. Verify network connectivity

---

## Additional Resources

- [.env.example](../env.example) - Template with all variables
- [DEPLOYMENT.md](./DEPLOYMENT.md) - Deployment guide
- [Railway Environment Variables](https://docs.railway.app/develop/variables)

---

*Last updated: 2024-01-15*
