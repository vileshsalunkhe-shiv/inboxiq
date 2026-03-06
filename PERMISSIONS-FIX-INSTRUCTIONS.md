# Fix Xcode CLI & Homebrew Permissions

## Run This Command (requires sudo password)

**As your admin user (vileshsalunkhe_mc):**

```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/FIX-XCODE-ACCESS.sh
```

**What it does:**
1. ✅ Verifies Xcode command line tools installed
2. ✅ Sets Xcode developer directory
3. ✅ Accepts Xcode license
4. ✅ Adds openclaw-service to _developer group
5. ✅ Fixes Homebrew permissions
6. ✅ Tests that simctl works

**Time:** ~1 minute

**Requires:** Your sudo password

---

## After Running

Once permissions are fixed, you can run the automated test:

```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/SIMPLE-TEST.sh
```

This will:
- Start capturing logs
- Tell you to test in Xcode
- Save logs to file when you press Ctrl+C
- I read the file and batch fix all issues

---

## Run It Now

Copy/paste this:

```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/FIX-XCODE-ACCESS.sh
```

It will prompt for your password. Then we're fully autonomous!
