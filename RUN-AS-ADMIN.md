# Run This As Your Admin Account

## The Issue
`openclaw-service` user doesn't have sudo privileges. You need to run the permission fix as **your admin account** (vileshsalunkhe_mc).

---

## Steps

### 1. Open a NEW Terminal Window
- Press Cmd+N in Terminal
- Or: File → New Window

### 2. Verify You're Logged in as Admin
Run this:
```bash
whoami
```

**Should show:** `vileshsalunkhe_mc` (or your admin username)  
**NOT:** `openclaw-service`

### 3. Run the Permission Fix Script
```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/GRANT-XCODE-ACCESS.sh
```

**It will:**
- Prompt for YOUR password (your admin password)
- Fix Xcode CLI permissions
- Fix Homebrew permissions
- Test that it works

**Takes:** ~30 seconds

### 4. Go Back to openclaw-service Terminal
After the script succeeds, switch back to your openclaw-service terminal and run:

```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SIMPLE-TEST.sh
```

**This time it should work!**

---

## Summary

**Wrong terminal:** openclaw-service (no sudo) ❌  
**Right terminal:** vileshsalunkhe_mc (admin) ✅

Once permissions are fixed, openclaw-service can run the test script automatically.

---

## Do This Now

1. **Open NEW Terminal window** (Cmd+N)
2. **Check:** `whoami` → should show your admin username
3. **Run:** `bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/GRANT-XCODE-ACCESS.sh`
4. **Enter password when prompted**
5. **Done!**

Then autonomous testing will work! 🚀
