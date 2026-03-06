# InboxIQ - Deployment Test Plan
**Created:** 2026-03-05 07:31 CST  
**Status:** Feature Freeze - Testing Phase  
**Goal:** Test all existing features, deploy to TestFlight

---

## ✅ MVP Feature Scope (Must Complete Before Testing)

**Completed Features:**
- ✅ OAuth login (Google)
- ✅ Email sync (Gmail API)
- ✅ Email list view (inbox)
- ✅ AI categorization (7 categories)
- ✅ Calendar integration (OAuth + events)
- ✅ Calendar view
- ✅ Settings screen
- ✅ Design system (Colors, Typography, Spacing)
- ✅ Dark mode support
- ✅ App icon & launch screen (VS Labs branding)

**Must Complete (Before Testing Phase):**
- 🔨 Email compose UI (new email)
- 🔨 Email reply UI (single reply + reply all)
- 🔨 Email forward UI
- 🔨 Email actions (archive, delete, star, mark read/unread)
- 🔨 Calendar event creation UI
- 🔨 Calendar event editing UI
- 🔨 Daily digest configuration (Settings)
- 🔨 Daily digest delivery testing
- 🔨 Search UI (email + calendar)

**Optional (If Time Permits):**
- ⏳ Push notifications (requires Apple Developer setup)
- ⏳ Email swipe gestures (archive, delete)
- ⏳ Bulk email actions
- ⏳ Email filters/rules

---

## 🧪 Testing Phase (3-5 Days)

### Phase 1: Local Testing (Day 1-2)

**Backend Tests:**
1. **OAuth Flow**
   - Sign in with Google (new user)
   - Token refresh after expiry
   - Sign out and back in
   - Error handling (invalid tokens)

2. **Email Sync**
   - Initial sync (last 7 days)
   - Delta sync (new emails)
   - Large mailbox (1000+ emails)
   - Email with attachments
   - Thread handling

3. **AI Categorization**
   - All 7 categories tested
   - Confidence scores reasonable
   - Performance (time per email)
   - Batch processing

4. **Calendar Integration**
   - OAuth flow
   - Fetch events (next 7 days)
   - Event details (attendees, location, description)
   - All-day events
   - Recurring events

**iOS Tests:**
1. **Authentication**
   - Sign in flow (Safari → app redirect)
   - Token storage (Keychain)
   - App restart (token persistence)
   - Sign out

2. **Email Inbox**
   - List view renders
   - Category badges display
   - Category filtering works
   - Pull to refresh
   - Email detail view
   - Mark read/unread (if implemented)

3. **Calendar View**
   - List view renders
   - Event cards display
   - Date formatting
   - Attendees list
   - All-day event indicators

4. **Settings**
   - Settings screen loads
   - Version info displays
   - Sign out button works
   - VS Labs branding visible

5. **Design System**
   - Light mode colors correct
   - Dark mode colors correct
   - Typography consistent
   - Spacing uniform
   - Components render properly

6. **UI/UX**
   - Navigation smooth
   - Tab switching works
   - No UI glitches
   - Error states display properly
   - Loading indicators appropriate

---

### Phase 2: Integration Testing (Day 2-3)

**End-to-End Scenarios:**
1. **New User Onboarding**
   - Download app
   - Sign in with Google
   - First email sync completes
   - Calendar authorized
   - All tabs functional

2. **Daily Use Case**
   - Open app (should show cached emails)
   - Pull to refresh (delta sync)
   - Browse emails by category
   - View email details
   - Check calendar events
   - Switch between tabs

3. **Error Recovery**
   - Network offline (graceful degradation)
   - Backend API down (error message)
   - Token expired (refresh or re-auth)
   - Empty inbox/calendar (empty states)

4. **Performance**
   - App startup time (<3 seconds)
   - Email sync time (baseline)
   - UI responsiveness (no lag)
   - Memory usage (no leaks)

---

### Phase 3: Railway Deployment Testing (Day 3)

**Pre-Deployment Checklist:**
1. ✅ Environment variables set
2. ✅ Database migrations run
3. ✅ Redis cache operational
4. ✅ Health check endpoint responding
5. ✅ CORS configured correctly
6. ✅ SSL certificate valid
7. ✅ Error logging enabled

**Deployment Tests:**
1. Deploy latest backend to Railway
2. Run health check: `https://inboxiq-production-5368.up.railway.app/health`
3. Test OAuth from iOS app (production)
4. Test email sync from iOS app (production)
5. Monitor Railway logs for errors
6. Check database for new users/emails
7. Verify Redis cache hits

**Rollback Plan:**
- Keep previous Railway deployment available
- Document current commit hash
- Test rollback procedure

---

### Phase 4: TestFlight Beta (Day 4-5)

**Pre-TestFlight Checklist:**
1. ✅ Apple Developer account active
2. ✅ App Store Connect configured
3. ✅ Bundle ID registered: `com.vss.InboxIQ`
4. ✅ Provisioning profiles created
5. ✅ App icon (1024x1024) uploaded
6. ✅ Privacy policy URL (if required)
7. ✅ App description written
8. ✅ Screenshots prepared (if needed)

**TestFlight Setup:**
1. Archive iOS app in Xcode
2. Upload to App Store Connect
3. Set beta testing info:
   - App name: InboxIQ
   - Description: AI-powered email organizer
   - Beta testers: Internal (founders)
4. Submit for review (1-2 days)
5. Invite beta testers

**Beta Testing Focus:**
- Install from TestFlight
- Complete onboarding flow
- Use app for 2-3 days
- Report bugs/issues
- Provide UX feedback
- Test on multiple devices (if available)

---

## 🐛 Bug Tracking

**Use Linear for all bugs:**
- Priority: Critical (blocks deployment) / High (bad UX) / Medium (polish) / Low (nice-to-have)
- Tag: `bug`, `deployment`, `testflight`

**Critical Bugs = Deployment Blockers:**
- App crashes on startup
- OAuth completely broken
- Email sync fails for all users
- Data loss or corruption

**High Priority = Fix Before TestFlight:**
- UI glitches (broken layouts)
- Performance issues (>5 second sync)
- Incorrect data display
- Missing error handling

**Medium/Low = Post-TestFlight:**
- UI polish
- Minor performance improvements
- Edge case handling

---

## 📋 Testing Checklist

### Backend (Railway Production)
- [ ] Health check responds 200 OK
- [ ] OAuth callback URL correct
- [ ] Database migrations applied
- [ ] Redis cache operational
- [ ] Environment variables set
- [ ] Error logging enabled
- [ ] CORS configured
- [ ] API rate limiting (if needed)

### iOS (Local Build)
- [ ] Build compiles (no errors)
- [ ] App launches successfully
- [ ] Sign in with Google works
- [ ] Email inbox loads
- [ ] Email details display
- [ ] Category filtering works
- [ ] Calendar tab loads
- [ ] Calendar events display
- [ ] Settings tab loads
- [ ] Sign out works
- [ ] Light mode renders correctly
- [ ] Dark mode renders correctly
- [ ] App icon displays
- [ ] Launch screen displays
- [ ] No console errors

### End-to-End
- [ ] New user can sign in
- [ ] Email sync completes
- [ ] AI categorization applies
- [ ] Calendar OAuth completes
- [ ] Calendar events sync
- [ ] App persists state on restart
- [ ] Network offline handled gracefully
- [ ] Token refresh works
- [ ] Sign out clears data

---

## 🚀 Updated Timeline

### Week 1: Feature Completion (March 5-9)

**Day 1-2 (March 5-6): Email Actions**
- Backend: Email action APIs already complete ✅
- iOS: Build compose/reply/forward/archive/delete/star UI
- iOS: Integrate with backend APIs
- Test locally

**Day 3 (March 7): Calendar CRUD**
- Backend: Build calendar create/edit/delete APIs
- iOS: Build event creation/editing UI
- iOS: Integrate with backend APIs
- Test locally

**Day 4 (March 8): Digest + Search**
- Backend: Verify digest delivery (cron job)
- iOS: Build digest settings UI
- iOS: Build search UI (email + calendar)
- Test locally

**Day 5 (March 9): Integration Testing**
- End-to-end testing (all features)
- Bug fixes
- Performance testing

### Week 2: Deployment (March 10-14)

**Day 6 (March 10): Railway Production**
- Deploy backend to Railway
- Test iOS against production
- Fix production issues

**Day 7 (March 11): TestFlight Prep**
- Archive iOS app
- Upload to App Store Connect
- Submit for beta review

**Day 8-9 (March 12-13): TestFlight Beta**
- Internal beta testing (founders)
- Bug fixes
- Iteration

**Day 10 (March 14): App Store Prep**
- Screenshots, description, metadata
- Final polish
- Prepare for App Store submission

### Week 3: Launch (March 17-21)
- App Store submission (March 17)
- Review period (3-7 days)
- Public launch (March 21-25)

---

## 📊 Success Metrics

**For TestFlight Approval:**
- ✅ App launches without crashes
- ✅ Core features functional (login, email, calendar)
- ✅ No critical bugs
- ✅ Acceptable performance

**For Beta Testers:**
- ✅ Onboarding completes successfully
- ✅ App usable for daily email management
- ✅ Positive feedback on UI/UX
- ✅ No major bugs reported

**For App Store Submission:**
- ✅ All beta bugs fixed
- ✅ App Store guidelines compliance
- ✅ Screenshots and marketing materials ready
- ✅ Privacy policy/terms (if required)

---

## 🔧 Known Issues to Test

**From Security Review (2026-03-04):**
1. ✅ OAuth MissingGreenlet - Fixed
2. ✅ Keychain accessibility - Fixed
3. ✅ SSL certificate pinning - Implemented
4. ✅ Logging privacy - Fixed
5. ✅ CoreData background saves - Fixed

**From Yesterday's Work:**
1. ⏳ OAuth token refresh - Needs testing
2. ⏳ Design system dark mode - Needs visual verification
3. ⏳ Email action APIs - Backend ready, iOS UI not implemented
4. ⏳ Launch screen timing - Verify 1-2 second display

---

## 📝 Testing Notes Template

**Use this format for reporting test results:**

```markdown
### Test: [Feature Name]
**Date:** YYYY-MM-DD HH:MM CST
**Tester:** [Name]
**Environment:** Local / Railway / TestFlight
**Device:** iPhone [Model] iOS [Version]

**Steps:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Status:** ✅ Pass / ❌ Fail / ⚠️ Issues
**Issues:** [List any bugs found]
**Linear Issue:** [INB-XX if created]
```

---

## 🎯 Next Actions (Today)

1. **Morning Testing (2-3 hours):**
   - Test OAuth flow locally
   - Test email sync with your Gmail account
   - Test calendar integration
   - Document any bugs found

2. **Bug Fixes (2-4 hours):**
   - Fix critical bugs (deployment blockers)
   - Fix high priority bugs (bad UX)
   - Create Linear issues for medium/low bugs

3. **Railway Deployment (1 hour):**
   - Deploy latest backend
   - Test production OAuth
   - Monitor logs for errors

4. **End-of-Day Status:**
   - Document test results
   - Update Linear with bugs found
   - Plan tomorrow's testing

---

**Owner:** V (Vilesh Salunkhe)  
**Support:** Shiv (for bug fixes and deployment)  
**Timeline:** 3-5 days to TestFlight  
**Status:** Ready to begin testing

---

_This is your deployment roadmap. Feature freeze is in effect - no new features until after TestFlight launch._
