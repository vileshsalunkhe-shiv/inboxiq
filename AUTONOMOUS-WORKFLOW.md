# Autonomous Testing & Fixing Workflow

## Goal
Minimize back-and-forth by giving Shiv tools to test, debug, and fix independently.

---

## Setup (One-Time, ~5 minutes)

### 1. Railway CLI Access
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend
brew install railway  # If not installed
railway login         # Opens browser, authenticate once
railway link          # Select inboxiq-production project
```

**Result:** Shiv can now pull Railway logs directly without asking you.

---

### 2. iOS Automated Testing
```bash
chmod +x /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/TEST-IOS-AUTO.sh
```

**Result:** One-command iOS testing that captures all logs to files Shiv can read.

---

## New Workflow

### When Shiv needs to test iOS changes:

**Old way (manual):**
1. Shiv: "Please clean build and test"
2. V: Opens Xcode, cleans, builds, runs, copies console output
3. Shiv: Analyzes logs, fixes
4. Repeat 5-10 times ❌

**New way (autonomous):**
1. Shiv: Makes fixes to files
2. V: Runs ONE command: `bash TEST-IOS-AUTO.sh`
3. Shiv: Reads log files directly, identifies issues, batches fixes
4. V: Runs test script again after all fixes applied ✅

**Time saved:** 80% reduction in back-and-forth

---

## Test Script Features

**What it does:**
- ✅ Clean build
- ✅ Compile project
- ✅ Launch simulator
- ✅ Install app
- ✅ Capture console logs to file
- ✅ Run for 30 seconds (captures login + sync)
- ✅ Saves everything to timestamped log files

**Output files:**
- `ios-test-YYYYMMDD-HHMMSS.log` - Build output
- `ios-console-YYYYMMDD-HHMMSS.log` - Runtime console logs

**Shiv can read both files directly** - no need to paste.

---

## Backend Testing (Already Autonomous)

Shiv can already:
- ✅ Pull Railway logs: `railway logs`
- ✅ Test APIs with curl
- ✅ Deploy fixes (auto-deploy on git push)
- ✅ Monitor health: `curl https://inboxiq-production-5368.up.railway.app/health`

---

## Enhanced Workflow

### Phase 1: Discovery (No interruption)
1. Shiv detects issue from conversation
2. Shiv pulls Railway logs, reads iOS logs
3. Shiv identifies root causes
4. Shiv creates comprehensive fix document

### Phase 2: Batch Fix (One interaction)
5. Shiv applies all fixes to files
6. Shiv creates test plan
7. Shiv notifies: "Applied 5 fixes, ready to test"

### Phase 3: Validation (One command)
8. V runs: `bash TEST-IOS-AUTO.sh`
9. Shiv reads logs automatically
10. Either ✅ passes or 🔄 repeats with new batch of fixes

---

## What V Runs

**For iOS testing:**
```bash
bash /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/TEST-IOS-AUTO.sh
```

**For backend testing:**
```bash
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend
railway logs --tail 100
```

**That's it.** No Xcode interaction needed.

---

## Fallback: When Automation Doesn't Work

If test script fails or doesn't capture the issue:
1. Shiv asks for **specific** information (not "test again")
2. V provides one comprehensive log dump
3. Shiv batches multiple fixes based on that
4. Test once with all fixes applied

---

## Estimated Time Savings

**Current session today:**
- ~2 hours of back-and-forth testing
- ~15 "test and paste logs" cycles

**With automation:**
- ~20 minutes total
- ~2-3 test cycles (batch fixes between each)

**80-90% time savings** ⚡

---

## Next Steps

1. **Right now:** V runs Railway CLI setup (2 min)
2. **Right now:** V runs test script once to verify it works
3. **Going forward:** Shiv uses autonomous workflow

Ready to set up?
