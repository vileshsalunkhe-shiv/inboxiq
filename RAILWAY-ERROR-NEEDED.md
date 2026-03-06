# Railway Error Logs Needed

**To debug the health check failure, I need:**

## 1. Railway Deployment Logs

```bash
# Run this command and paste the output
railway logs --tail 100
```

**Look for:**
- Python tracebacks
- `ImportError`
- `ValidationError`
- `AttributeError`
- `ModuleNotFoundError`
- Health check errors

---

## 2. Health Check Response

```bash
# Test health check directly
curl https://inboxiq-production-5368.up.railway.app/health
```

**What does it return?**
- 200 OK with JSON?
- 500 Internal Server Error?
- Connection refused?
- Timeout?

---

## 3. Last Successful Deploy

**What was the last commit that deployed successfully?**

```bash
git log --oneline -10
```

**Which commit failed?**

---

## Quick Rollback (If Needed)

**If we need to rollback to working version:**

```bash
# Find last working commit
git log --oneline

# Rollback (replace COMMIT_HASH with actual hash)
git revert COMMIT_HASH

# Or hard reset (destructive)
git reset --hard COMMIT_HASH
git push --force

# Redeploy
railway up
```

---

## Meanwhile: Test Locally

```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Start backend
uvicorn app.main:app --reload --port 8000

# In another terminal
curl localhost:8000/health
curl -H "Authorization: Bearer $TOKEN" localhost:8000/emails | jq '.'
```

**If local works:** Railway deployment issue  
**If local fails:** Code issue

---

**Please paste Railway logs so I can identify the exact error.**
