# InboxIQ - Development Roadmap & Timeline
**Ship MVP to App Store in 8 Weeks**

---

## 📋 Table of Contents
1. [Executive Summary](#executive-summary)
2. [MVP Sprint Planning (8 Weeks)](#mvp-sprint-planning-8-weeks)
3. [Resource Allocation](#resource-allocation)
4. [Milestone Definitions](#milestone-definitions)
5. [Critical Path & Dependencies](#critical-path--dependencies)
6. [Risk Mitigation](#risk-mitigation)
7. [Testing Strategy](#testing-strategy)
8. [App Store Submission Checklist](#app-store-submission-checklist)
9. [Post-Launch Roadmap (Phase 2-5)](#post-launch-roadmap-phase-2-5)
10. [Success Criteria](#success-criteria)

---

## 🎯 Executive Summary

**Target:** Ship functional MVP to App Store in **8 weeks** (56 days)
**Core Value Prop:** AI-powered email management with Gmail integration
**Launch Date:** Week of April 19, 2026
**Team Structure:** Premium + Budget AI agents, coordinated deployment
**MVP Scope:** iPhone app only, Gmail OAuth, AI categorization, core inbox features

### What We're Building (MVP)
✅ Gmail OAuth integration
✅ AI categorization (Primary/Social/Promotions/Updates)
✅ Basic inbox (archive, delete, mark read/unread)
✅ Compose, reply, forward
✅ Search functionality
✅ Push notifications
✅ Native iOS app (iPhone)

### What We're NOT Building (MVP)
❌ Multiple accounts (Phase 2)
❌ Snooze/send later (Phase 2)
❌ Calendar integration (Phase 2)
❌ Templates (Phase 2)
❌ iPad/Mac apps (Phase 3/4)
❌ Team features (Phase 3)

---

## 📅 MVP Sprint Planning (8 Weeks)

### Sprint Structure
- **Sprint Duration:** 1 week (Monday-Sunday)
- **Daily Standups:** Async via memory logs
- **Sprint Review:** End of each week
- **Sprint Retrospective:** Lessons captured in docs
- **Buffer:** Week 8 is dedicated buffer/polish

---

## Week 1: Foundation & Architecture
**Dates:** Feb 24 - Mar 2, 2026
**Goal:** Technical foundation, architecture decisions, dev environment setup

### Deliverables
- [ ] Technical architecture document
  - Backend stack (FastAPI + PostgreSQL)
  - iOS app architecture (SwiftUI + Combine)
  - AI integration strategy (Claude API)
  - Data models & database schema
  - API contract definitions
- [ ] Dev environment setup
  - GitHub repo created
  - CI/CD pipeline (GitHub Actions)
  - Development/staging/production environments
  - Local development setup docs
- [ ] Gmail OAuth integration (backend)
  - Google Cloud project setup
  - OAuth 2.0 flow implementation
  - Token storage & refresh logic
  - Gmail API connection testing
- [ ] iOS project scaffolding
  - Xcode project created
  - SwiftUI app structure
  - Navigation architecture
  - Network layer setup
- [ ] Database schema v1
  - Users, accounts, emails tables
  - Indexes for performance
  - Migration strategy

### Owners
- **Backend:** DEV-PREMIUM (lead), DEV-BUDGET (support)
- **iOS:** DEV-PREMIUM (lead), DEV-BUDGET (support)
- **Architecture:** DOC-PREMIUM
- **Coordination:** PROJECT-MANAGER

### Success Criteria
✓ Can authenticate with Gmail via OAuth
✓ Can fetch email list from Gmail API
✓ Database can store email metadata
✓ iOS app compiles and runs on simulator
✓ All docs committed to repo

### Risks
⚠️ **Gmail API quota limits** - Mitigate: Request quota increase early
⚠️ **OAuth complexity** - Mitigate: Use proven library (google-auth-library)

---

## Week 2: Core Backend APIs
**Dates:** Mar 3 - Mar 9, 2026
**Goal:** Build backend APIs for email operations

### Deliverables
- [ ] User authentication API
  - Sign up/login endpoints
  - JWT token management
  - Password reset flow
- [ ] Email sync engine
  - Background job to sync Gmail → DB
  - Incremental sync (only new emails)
  - Attachment metadata extraction
  - Error handling & retry logic
- [ ] Email CRUD APIs
  - GET /emails (list, pagination, filters)
  - GET /emails/:id (single email)
  - PATCH /emails/:id (mark read/unread, archive, delete)
  - POST /emails/send (send new email)
  - POST /emails/:id/reply (reply to email)
- [ ] Search API (basic)
  - Full-text search on subject/body
  - Filter by sender, date range
  - Pagination support
- [ ] AI categorization (Phase 1 - simple)
  - Claude API integration
  - Prompt engineering for categories
  - Batch processing for new emails
  - Category storage in DB

### Owners
- **Backend Lead:** DEV-PREMIUM
- **API Development:** DEV-BUDGET (2 agents in parallel)
- **AI Integration:** DEV-PREMIUM
- **Testing:** QA-BUDGET

### Success Criteria
✓ All API endpoints functional & tested
✓ Postman collection with examples
✓ Email sync works end-to-end
✓ AI categorization achieves >80% accuracy on test set
✓ API response times <500ms

### Dependencies
- Week 1: Gmail OAuth must be complete

### Risks
⚠️ **AI accuracy** - Mitigate: Start with rule-based fallback
⚠️ **Gmail sync performance** - Mitigate: Batch processing, queue system

---

## Week 3: iOS Inbox UI (Core Experience)
**Dates:** Mar 10 - Mar 16, 2026
**Goal:** Build the main inbox interface

### Deliverables
- [ ] Inbox list view
  - Email cell design (sender, subject, preview, timestamp)
  - Category badges (AI-powered)
  - Unread indicators
  - Pull-to-refresh
  - Infinite scroll/pagination
- [ ] Email detail view
  - Full email content rendering
  - HTML email support (WKWebView)
  - Attachment display (icons, sizes)
  - Action buttons (reply, forward, archive, delete)
- [ ] Swipe gestures
  - Swipe left → Archive
  - Swipe right → Delete
  - Customizable actions (settings)
- [ ] Navigation
  - Tab bar (Inbox, Search, Compose, Settings)
  - Category filters (All, Primary, Social, etc.)
  - Smooth transitions & animations
- [ ] State management
  - Combine publishers for data flow
  - Offline support (read cached emails)
  - Optimistic UI updates

### Owners
- **iOS Lead:** DEV-PREMIUM
- **UI Development:** DEV-BUDGET (2 agents)
- **Design Review:** DOC-PREMIUM
- **UX Testing:** QA-BUDGET

### Success Criteria
✓ Inbox displays emails correctly
✓ Swipe gestures feel native & responsive
✓ Email detail view renders HTML properly
✓ Navigation is intuitive (no user confusion)
✓ Performance: 60fps scrolling

### Dependencies
- Week 2: Backend APIs must be functional

### Risks
⚠️ **HTML rendering issues** - Mitigate: Test with diverse email samples
⚠️ **Performance on old devices** - Mitigate: Test on iPhone 11/12

---

## Week 4: Compose & Reply
**Dates:** Mar 17 - Mar 23, 2026
**Goal:** Enable users to send emails

### Deliverables
- [ ] Compose UI
  - To/Cc/Bcc fields with autocomplete
  - Subject line
  - Rich text editor (bold, italic, links)
  - Attachment picker (photos, files)
  - Send button + keyboard shortcut (Cmd+Enter)
- [ ] Reply/Forward UI
  - Quote original email
  - Reply vs Reply All logic
  - Forward with attachments
  - Inline reply composer
- [ ] Draft management
  - Auto-save drafts (every 5 seconds)
  - Resume draft from inbox
  - Discard draft confirmation
- [ ] Contact autocomplete
  - Search device contacts
  - Recent recipients
  - Gmail contacts sync
- [ ] Send functionality
  - Gmail API send implementation
  - Attachment upload to Gmail
  - Error handling (network failures)
  - Sent confirmation

### Owners
- **iOS Lead:** DEV-PREMIUM
- **Compose Features:** DEV-BUDGET (2 agents)
- **Backend Support:** DEV-PREMIUM (Gmail send API)
- **Testing:** QA-BUDGET

### Success Criteria
✓ Can compose and send email successfully
✓ Can reply/forward with quoted text
✓ Drafts auto-save reliably
✓ Contacts autocomplete works
✓ Attachments upload correctly

### Dependencies
- Week 3: Navigation must be complete

### Risks
⚠️ **Attachment upload failures** - Mitigate: Chunked uploads, retry logic
⚠️ **Draft sync conflicts** - Mitigate: Last-write-wins strategy

---

## Week 5: Search, Notifications & Polish
**Dates:** Mar 24 - Mar 30, 2026
**Goal:** Core features refinement + critical polish

### Deliverables
- [ ] Search functionality
  - Search UI (prominent in tab bar)
  - Real-time search (as you type)
  - Search history
  - Filter options (date, sender, has attachment)
  - Search results view (same as inbox)
- [ ] Push notifications
  - APNs setup (Apple Push Notification service)
  - Backend: Send push for new emails
  - Notification payload (title, body, badge count)
  - Notification actions (Reply, Archive, Mark Read)
  - Rich notifications (show email preview)
- [ ] Settings screen
  - Account info & logout
  - Notification preferences
  - Swipe gesture customization
  - About/version info
  - Privacy policy & terms links
- [ ] UI/UX polish
  - Loading states (spinners, skeletons)
  - Error states (network failures, empty states)
  - Haptic feedback
  - Animations & transitions
  - Dark mode support
  - Accessibility (VoiceOver, Dynamic Type)

### Owners
- **Search:** DEV-BUDGET
- **Notifications:** DEV-PREMIUM (backend + iOS)
- **Settings:** DEV-BUDGET
- **Polish:** DOC-PREMIUM (review) + DEV-PREMIUM (implementation)
- **Accessibility:** QA-BUDGET (testing)

### Success Criteria
✓ Search returns relevant results quickly (<1s)
✓ Push notifications work reliably
✓ Settings are discoverable & functional
✓ App feels polished (no rough edges)
✓ Dark mode works throughout
✓ VoiceOver navigable

### Dependencies
- Week 4: All core features must be functional

### Risks
⚠️ **APNs certificate issues** - Mitigate: Set up early, test thoroughly
⚠️ **Search performance** - Mitigate: Index optimization, debouncing

---

## Week 6: Beta Testing & Bug Fixes
**Dates:** Mar 31 - Apr 6, 2026
**Goal:** Internal beta, identify critical bugs, fix blockers

### Deliverables
- [ ] TestFlight setup
  - Upload first beta build
  - Invite internal testers (V + key stakeholders)
  - Feedback collection system (in-app or external)
- [ ] Bug bash
  - Dedicated testing session (all agents)
  - Create issue tracker (GitHub Issues or Linear)
  - Prioritize bugs (P0 = blocker, P1 = critical, P2 = nice-to-fix)
- [ ] Critical bug fixes
  - **Target:** Fix all P0 bugs, 80% of P1 bugs
  - Focus on crash fixes, data loss prevention
  - Network error handling
  - Edge case handling
- [ ] Performance optimization
  - Profile app (Instruments)
  - Optimize slow screens
  - Reduce memory usage
  - Improve battery efficiency
- [ ] First-run experience
  - Onboarding flow (optional for MVP)
  - OAuth permission explanations
  - Helpful tooltips for key features

### Owners
- **Beta Coordination:** PROJECT-MANAGER
- **Bug Fixes:** ALL DEV agents (priority queue)
- **Performance:** DEV-PREMIUM
- **Testing:** QA-BUDGET (lead testing effort)

### Success Criteria
✓ Beta build deployed to TestFlight
✓ 5+ testers actively using app
✓ All P0 bugs fixed
✓ 80%+ P1 bugs fixed
✓ No known crash bugs
✓ App passes manual test suite

### Dependencies
- Week 5: All features must be implemented

### Risks
⚠️ **Too many bugs found** - Mitigate: Strict scope control, triage ruthlessly
⚠️ **TestFlight delays** - Mitigate: Submit build early in week

---

## Week 7: App Store Preparation
**Dates:** Apr 7 - Apr 13, 2026
**Goal:** Finalize App Store assets, submit for review

### Deliverables
- [ ] App Store assets
  - App icon (1024x1024)
  - Screenshots (iPhone 15 Pro, iPhone SE)
  - Preview video (optional but recommended)
  - App Store description (compelling copy)
  - Keywords for ASO (App Store Optimization)
  - Privacy policy URL
  - Terms of service URL
- [ ] Final polish
  - Fix remaining P1 bugs
  - Final design review
  - Proofread all copy
  - Test on multiple devices
- [ ] App Store Connect setup
  - Create app listing
  - Upload screenshots & metadata
  - Set pricing (free)
  - Select categories (Productivity, Utilities)
  - Age rating (4+)
  - App privacy details
- [ ] Submit for review
  - Upload final build to App Store Connect
  - Fill out review notes
  - Submit for Apple review
- [ ] Documentation
  - User guide / Help center (basic)
  - FAQ page
  - Support email/form

### Owners
- **App Store Assets:** DOC-PREMIUM
- **Final Polish:** DEV-PREMIUM
- **Copy/Marketing:** DOC-PREMIUM
- **Submission:** PROJECT-MANAGER + DEV-PREMIUM
- **Documentation:** DOC-BUDGET

### Success Criteria
✓ App submitted to App Store
✓ All assets uploaded & approved
✓ Privacy policy & ToS live
✓ Help documentation available
✓ Marketing site live (optional MVP)

### Dependencies
- Week 6: All critical bugs fixed

### Risks
⚠️ **App Store rejection** - Mitigate: Follow guidelines strictly, test thoroughly
⚠️ **Asset creation delays** - Mitigate: Start early, use templates

---

## Week 8: Buffer & Launch Prep
**Dates:** Apr 14 - Apr 20, 2026
**Goal:** Respond to Apple feedback, prepare for launch

### Deliverables
- [ ] Apple review response
  - Address any rejection reasons
  - Fix compliance issues
  - Resubmit if needed
- [ ] Backend scaling prep
  - Load testing
  - Database optimization
  - CDN setup for attachments
  - Monitoring & alerting (Sentry, DataDog)
- [ ] Launch checklist
  - Final smoke test on production
  - Social media announcements prepared
  - Press kit (optional)
  - Launch email drafted
  - Support inbox ready
- [ ] Contingency work
  - Fix any last-minute issues
  - Final polish pass
  - Backup plans for launch day issues

### Owners
- **Apple Review:** DEV-PREMIUM + PROJECT-MANAGER
- **Backend Scaling:** DEV-PREMIUM
- **Launch Prep:** DOC-PREMIUM + PROJECT-MANAGER
- **Final QA:** QA-BUDGET

### Success Criteria
✓ App approved by Apple
✓ Backend ready for production traffic
✓ Monitoring & alerts configured
✓ Launch materials ready
✓ Team confident in launch

### Dependencies
- Week 7: App must be submitted

### Risks
⚠️ **Extended Apple review** - Mitigate: Submit early, be responsive
⚠️ **Launch day outage** - Mitigate: Load testing, rollback plan

---

## 🎯 Gantt-Style Timeline

```
Week 1: [████████] Foundation & Architecture
         ├─ Backend OAuth (DEV-PREMIUM)
         ├─ iOS Scaffolding (DEV-PREMIUM)
         ├─ Database Schema (DEV-BUDGET)
         └─ Architecture Docs (DOC-PREMIUM)

Week 2: [████████] Core Backend APIs
         ├─ Email Sync Engine (DEV-PREMIUM) ━━━━━━━┓
         ├─ CRUD APIs (DEV-BUDGET x2)               ┃
         └─ AI Categorization (DEV-PREMIUM) ━━━━━━━┛
                                                     ┃
Week 3: [████████] iOS Inbox UI          ━━━━━━━━━━┛
         ├─ Inbox List (DEV-PREMIUM)
         ├─ Email Detail (DEV-BUDGET)
         └─ Swipe Gestures (DEV-BUDGET)

Week 4: [████████] Compose & Reply
         ├─ Compose UI (DEV-PREMIUM) ━━━━━┓
         ├─ Reply/Forward (DEV-BUDGET)     ┃
         └─ Draft Management (DEV-BUDGET)  ┃
                                           ┃
Week 5: [████████] Search, Notifications & Polish ━┛
         ├─ Search (DEV-BUDGET)
         ├─ Push Notifications (DEV-PREMIUM)
         ├─ Settings (DEV-BUDGET)
         └─ UI Polish (ALL)

Week 6: [████████] Beta Testing & Bug Fixes
         └─ ALL AGENTS: Bug bash & fixes

Week 7: [████████] App Store Preparation
         ├─ Assets (DOC-PREMIUM)
         └─ Submission (PROJECT-MANAGER)

Week 8: [████████] Buffer & Launch Prep
         └─ Contingency & Launch (ALL)

LAUNCH: 🚀 Week of Apr 19, 2026
```

---

## 👥 Resource Allocation

### Agent Roles & Responsibilities

#### DEV-PREMIUM (1 agent) - **Lead Developer**
**Weekly Hours:** 40 hours/week
**Cost:** ~$2,000/week (premium tier)
**Responsibilities:**
- Technical architecture decisions
- Complex features (OAuth, AI integration, push notifications)
- Code review & quality assurance
- Performance optimization
- Critical bug fixes
- Backend infrastructure

**Week-by-Week:**
- Week 1: OAuth + Architecture
- Week 2: Email sync + AI categorization
- Week 3: Inbox UI lead
- Week 4: Compose UI lead
- Week 5: Push notifications
- Week 6: Critical bug fixes
- Week 7: Final polish
- Week 8: Launch readiness

#### DEV-BUDGET (3 agents) - **Feature Development**
**Weekly Hours:** 40 hours/week each
**Cost:** ~$500/week each (~$1,500/week total)
**Responsibilities:**
- Implement well-defined features
- Write tests
- Bug fixes (P1/P2)
- API endpoint development
- UI component development

**Parallel Work Assignments:**
- **Agent A:** Backend API development (Weeks 2-5)
- **Agent B:** iOS UI components (Weeks 3-5)
- **Agent C:** Search, settings, polish (Weeks 5-6)

#### DOC-PREMIUM (1 agent) - **Documentation & Design Review**
**Weekly Hours:** 20 hours/week
**Cost:** ~$1,000/week
**Responsibilities:**
- Architecture documentation
- API documentation
- Design review & UX feedback
- App Store copy & assets
- User guides & help docs
- Marketing materials

#### PROJECT-MANAGER (1 agent) - **Coordination**
**Weekly Hours:** 20 hours/week
**Cost:** ~$800/week
**Responsibilities:**
- Sprint planning
- Daily progress tracking
- Blocker resolution
- Stakeholder communication
- Timeline management
- Risk tracking

#### QA-BUDGET (1 agent) - **Testing**
**Weekly Hours:** 30 hours/week (ramps up Week 5+)
**Cost:** ~$400/week
**Responsibilities:**
- Test case creation
- Manual testing
- Bug reporting
- Regression testing
- Accessibility testing
- Beta coordination

### Total Weekly Cost
- DEV-PREMIUM: $2,000
- DEV-BUDGET (x3): $1,500
- DOC-PREMIUM: $1,000
- PROJECT-MANAGER: $800
- QA-BUDGET: $400
**Total: ~$5,700/week**

### 8-Week MVP Cost
**$5,700 × 8 = $45,600**

*(Plus infrastructure: ~$500-1,000 for dev/staging environments)*

---

## ✅ Milestone Definitions

### What Does "Done" Mean?

#### M1: Foundation Complete (End of Week 1)
**Date:** Mar 2, 2026
**Definition of Done:**
- [ ] Gmail OAuth flow works (can fetch access token)
- [ ] Database schema created & documented
- [ ] iOS app compiles and runs
- [ ] Network layer can call backend APIs
- [ ] All docs committed to repo
- [ ] Dev environment reproducible (README instructions)

**Validation:**
- Demo: Authenticate with Gmail from iOS app
- Code review: Architecture approved by V
- Test: Database migration runs successfully

---

#### M2: Backend APIs Live (End of Week 2)
**Date:** Mar 9, 2026
**Definition of Done:**
- [ ] All CRUD endpoints functional
- [ ] Email sync works (can fetch emails from Gmail)
- [ ] AI categorization working (>80% accuracy)
- [ ] API documentation complete (Swagger/OpenAPI)
- [ ] Postman collection with examples
- [ ] Error handling implemented
- [ ] Unit tests written (>70% coverage)

**Validation:**
- Demo: Postman request to fetch emails
- Test: Sync 1,000 emails successfully
- Metric: API response time <500ms (p95)

---

#### M3: Inbox UI Complete (End of Week 3)
**Date:** Mar 16, 2026
**Definition of Done:**
- [ ] Inbox displays emails correctly
- [ ] Email detail view renders HTML
- [ ] Swipe gestures work
- [ ] Category filters work
- [ ] Pull-to-refresh works
- [ ] Navigation smooth & intuitive
- [ ] No UI bugs on iPhone 12/13/14/15

**Validation:**
- Demo: Navigate inbox, read emails, swipe to archive
- Test: Performance test (60fps scrolling)
- UX test: 3 users can complete tasks without confusion

---

#### M4: Compose & Send Works (End of Week 4)
**Date:** Mar 23, 2026
**Definition of Done:**
- [ ] Can compose new email
- [ ] Can reply/forward
- [ ] Drafts auto-save
- [ ] Can attach files
- [ ] Email sends successfully
- [ ] Sent email appears in Gmail
- [ ] Contact autocomplete works

**Validation:**
- Demo: Compose and send email end-to-end
- Test: Send 100 test emails successfully
- Test: Draft recovery after app kill

---

#### M5: Feature Complete (End of Week 5)
**Date:** Mar 30, 2026
**Definition of Done:**
- [ ] Search works
- [ ] Push notifications work
- [ ] Settings functional
- [ ] Dark mode complete
- [ ] Accessibility: VoiceOver works
- [ ] All MVP features implemented
- [ ] No P0 bugs
- [ ] App passes internal review

**Validation:**
- Demo: Full app walkthrough (15 min)
- Test: Complete test suite passes
- Review: V approves feature set

---

#### M6: Beta Ready (End of Week 6)
**Date:** Apr 6, 2026
**Definition of Done:**
- [ ] Beta build on TestFlight
- [ ] 5+ testers have used app
- [ ] All P0 bugs fixed
- [ ] 80%+ P1 bugs fixed
- [ ] Known issues documented
- [ ] Crash-free rate >99%
- [ ] Beta feedback incorporated

**Validation:**
- Metric: Crash-free rate >99% (Firebase Crashlytics)
- Feedback: Positive sentiment from testers
- Test: Full regression suite passes

---

#### M7: App Store Submitted (End of Week 7)
**Date:** Apr 13, 2026
**Definition of Done:**
- [ ] App submitted to Apple
- [ ] All App Store assets uploaded
- [ ] Privacy policy & ToS live
- [ ] Help documentation available
- [ ] No P0 or P1 bugs remaining
- [ ] Final build tested on 5+ devices

**Validation:**
- Confirmation: App Store Connect shows "In Review"
- Checklist: All App Store requirements met
- Test: Final build passes smoke tests

---

#### M8: Launch Ready (End of Week 8)
**Date:** Apr 20, 2026
**Definition of Done:**
- [ ] App approved by Apple
- [ ] Backend scaled for production
- [ ] Monitoring & alerts live
- [ ] Support email ready
- [ ] Launch materials ready
- [ ] Rollback plan documented

**Validation:**
- Status: App shows "Ready for Sale"
- Test: Production smoke test passes
- Confidence: Team gives "go" for launch

---

## 🔗 Critical Path & Dependencies

### Critical Path (Cannot Be Parallelized)
These tasks MUST happen in sequence. Delays here delay entire launch.

```
Week 1: Gmail OAuth → Week 2: Email Sync → Week 3: Inbox UI → Week 4: Compose → Week 5: Polish → Week 6: Beta → Week 7: Submit → Week 8: Approval
```

**Critical Path Duration:** 8 weeks (no slack)

### Dependency Map

```
┌─────────────────┐
│ Gmail OAuth     │ ← MUST BE FIRST
│ (Week 1)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Email Sync      │ ← BLOCKS iOS INBOX
│ + APIs (Week 2) │
└────────┬────────┘
         │
         ├──────────┐
         ▼          ▼
┌─────────────────┐ ┌──────────────────┐
│ Inbox UI        │ │ AI Categorization│ ← CAN BE PARALLEL
│ (Week 3)        │ │ (Week 2)         │
└────────┬────────┘ └──────────────────┘
         │
         ▼
┌─────────────────┐
│ Compose & Reply │
│ (Week 4)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Search + Notifs │
│ (Week 5)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Beta Testing    │ ← CANNOT BE RUSHED
│ (Week 6)        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ App Store Submit│ ← APPLE CONTROLS TIMELINE
│ (Week 7-8)      │
└─────────────────┘
```

### Parallelizable Work
- **Backend APIs + iOS UI** (Weeks 3-4): Once APIs are defined, iOS can mock responses
- **Search + Notifications** (Week 5): Independent features
- **Documentation + Development** (All weeks): Docs can lag by 1 week

### Buffer Zones
- **Week 8:** Entire week is buffer for Apple review delays or critical bugs
- **Mid-sprint buffer:** Each sprint has 1 day buffer (5 days work, 2 days buffer)

---

## ⚠️ Risk Mitigation

### High-Probability Risks

#### R1: Gmail API Quota Limits
**Probability:** Medium | **Impact:** High
**Risk:** Gmail API has rate limits that could block development/testing
**Mitigation:**
- Request quota increase from Google immediately (Week 1)
- Implement rate limit handling & backoff
- Use test accounts with separate quotas
- Cache emails locally to reduce API calls
**Owner:** DEV-PREMIUM
**Contingency:** If quota blocked, use IMAP fallback for testing

---

#### R2: AI Categorization Accuracy
**Probability:** High | **Impact:** Medium
**Risk:** AI categorization might not be accurate enough (<80%)
**Mitigation:**
- Start with rule-based heuristics as fallback
- Use Claude with strong prompt engineering
- Test on diverse email corpus (1,000+ emails)
- Allow manual correction (AI learns)
**Owner:** DEV-PREMIUM
**Contingency:** Ship with rule-based categorization, improve AI post-launch

---

#### R3: App Store Rejection
**Probability:** Medium | **Impact:** High
**Risk:** Apple rejects app for guideline violations
**Mitigation:**
- Study App Store Review Guidelines thoroughly
- Test privacy disclosures carefully
- Avoid restricted APIs
- Submit early (Week 7) to allow resubmit time
- Have Week 8 as buffer
**Owner:** PROJECT-MANAGER + DEV-PREMIUM
**Contingency:** Address rejection reasons immediately, resubmit within 48 hours

---

#### R4: Feature Creep
**Probability:** Very High | **Impact:** High
**Risk:** Adding "just one more feature" delays launch
**Mitigation:**
- Strict scope document (this roadmap)
- V approval required for any scope change
- Maintain "Phase 2" backlog for post-launch
- Weekly scope review
**Owner:** PROJECT-MANAGER
**Contingency:** Cut features ruthlessly if timeline slips

---

#### R5: Critical Bugs in Week 6
**Probability:** High | **Impact:** Medium
**Risk:** Beta testing reveals too many P0/P1 bugs to fix in time
**Mitigation:**
- Continuous testing from Week 3 onwards
- Daily smoke tests
- Automated test suite (70%+ coverage)
- Bug triage daily during Week 6
**Owner:** QA-BUDGET + DEV-PREMIUM
**Contingency:** Extend to Week 9 if necessary, delay launch

---

#### R6: Performance Issues (Old Devices)
**Probability:** Medium | **Impact:** Medium
**Risk:** App sluggish on iPhone 11/12
**Mitigation:**
- Test on old devices weekly
- Profile with Instruments early (Week 4)
- Optimize list rendering (LazyVStack)
- Image caching strategy
**Owner:** DEV-PREMIUM
**Contingency:** Drop support for iPhone 11 (iPhone 12+ only)

---

#### R7: Backend Scaling for Launch
**Probability:** Low | **Impact:** High
**Risk:** Backend can't handle Day 1 traffic
**Mitigation:**
- Load testing in Week 8
- Auto-scaling configured (Railway/Fly.io)
- CDN for attachments (CloudFront)
- Database connection pooling
- Monitoring & alerts (Sentry, DataDog)
**Owner:** DEV-PREMIUM
**Contingency:** Throttle new user signups, scale manually

---

#### R8: Key Agent Unavailability
**Probability:** Low | **Impact:** High
**Risk:** DEV-PREMIUM becomes unavailable mid-sprint
**Mitigation:**
- Document everything (architecture, decisions)
- Knowledge sharing sessions
- Cross-train DEV-BUDGET agents
- Keep tasks modular & well-defined
**Owner:** PROJECT-MANAGER
**Contingency:** Reassign to DEV-BUDGET, extend timeline by 1 week

---

### Risk Dashboard
Track weekly:

| Risk | Status | Week 1 | Week 2 | Week 3 | Week 4 | Week 5 | Week 6 | Week 7 | Week 8 |
|------|--------|--------|--------|--------|--------|--------|--------|--------|--------|
| R1: API Quota | 🟡 | | | | | | | | |
| R2: AI Accuracy | 🟡 | | | | | | | | |
| R3: App Store | 🟢 | | | | | | | | |
| R4: Feature Creep | 🟡 | | | | | | | | |
| R5: Critical Bugs | 🟢 | | | | | | | | |
| R6: Performance | 🟢 | | | | | | | | |
| R7: Scaling | 🟢 | | | | | | | | |
| R8: Agent Unavail. | 🟢 | | | | | | | | |

🟢 = Low risk | 🟡 = Monitor | 🔴 = High risk / Needs action

---

## 🧪 Testing Strategy

### Testing Pyramid

```
           ┌─────────────┐
           │   Manual    │ ← 10% (Week 6-7)
           │  E2E Tests  │
           └─────────────┘
          ┌───────────────┐
          │  Integration  │ ← 30% (Week 3-8)
          │     Tests     │
          └───────────────┘
        ┌───────────────────┐
        │   Unit Tests      │ ← 60% (Week 2-8)
        │ (>70% coverage)   │
        └───────────────────┘
```

### Testing Schedule

#### Week 2-5: Continuous Testing
- **Daily:** Unit tests on every PR
- **Weekly:** Integration test suite (API endpoints)
- **Bi-weekly:** Manual smoke test on device

#### Week 6: Beta Testing
- **Day 1:** Deploy to TestFlight
- **Day 2-3:** Internal testing (5 testers)
- **Day 4-5:** Bug bash (all agents)
- **Day 6-7:** Fix critical bugs

#### Week 7-8: Pre-Launch Testing
- **Regression testing:** Full test suite 2x
- **Device testing:** iPhone 12/13/14/15, SE
- **Network testing:** Airplane mode, slow 3G
- **Edge cases:** Empty inbox, 10,000 emails, no internet

### Test Coverage Goals

#### Backend
- **Unit tests:** 80% coverage
- **Integration tests:** All API endpoints
- **Key scenarios:**
  - OAuth flow (happy path + errors)
  - Email sync (success, failures, rate limits)
  - AI categorization (various email types)
  - Send email (success, network failure)

#### iOS
- **Unit tests:** 70% coverage (ViewModels, business logic)
- **UI tests:** Critical user flows
- **Key scenarios:**
  - Login → View inbox → Read email → Archive
  - Compose → Send → Verify sent
  - Search → Find email → Open
  - Push notification → Tap → Open email

### Test Environments
- **Dev:** Local development (mock data)
- **Staging:** Pre-production (real Gmail test accounts)
- **Production:** Live (real users)

### Test Data
- **Test Gmail accounts:** Create 5 test accounts with diverse email types
  - Account 1: Heavy inbox (10,000+ emails)
  - Account 2: Newsletter-heavy
  - Account 3: Work emails (threads, attachments)
  - Account 4: Empty inbox
  - Account 5: Edge cases (huge attachments, weird HTML)

### Beta Testing Plan

#### Internal Beta (Week 6)
- **Testers:** V + 4 key stakeholders
- **Duration:** 5 days
- **Focus:** Critical bugs, usability issues
- **Feedback method:** Slack channel + in-app feedback
- **Success criteria:** All testers can complete core tasks without help

#### External Beta (Post-Launch)
- **Phase 2:** Expand to 50-100 beta testers
- **Channels:** TestFlight public link, ProductHunt
- **Feedback:** In-app form + email

### Automated Testing
- **CI/CD:** GitHub Actions
  - Run tests on every PR
  - Lint code (SwiftLint, flake8)
  - Build iOS app
  - Deploy backend to staging
- **Smoke tests:** Automated tests run hourly on staging
- **Performance tests:** Weekly (measure API response times)

---

## 📱 App Store Submission Checklist

### Pre-Submission (Week 7, Day 1-3)

#### Technical Requirements
- [ ] App builds without errors (Release configuration)
- [ ] App bundle ID created (com.inboxiq.app)
- [ ] Provisioning profile & certificates valid
- [ ] Push notification entitlement configured
- [ ] App icon set (all sizes)
- [ ] Launch screen configured
- [ ] Version number set (1.0.0)
- [ ] Build number incremented
- [ ] Minimum iOS version set (iOS 16.0+)
- [ ] Device support: iPhone only (iPad later)

#### App Store Connect Setup
- [ ] App created in App Store Connect
- [ ] Bundle ID associated
- [ ] App name: "InboxIQ" (check availability)
- [ ] Subtitle: "AI-Powered Email Management"
- [ ] Primary category: Productivity
- [ ] Secondary category: Business
- [ ] Age rating: 4+ (no objectionable content)
- [ ] Pricing: Free

#### App Privacy Details
- [ ] Data collection disclosure:
  - Email address (for account creation)
  - Email content (for AI categorization)
  - Usage data (analytics)
- [ ] Data usage policy explained
- [ ] Third-party data sharing: None
- [ ] Privacy policy URL: https://inboxiq.app/privacy
- [ ] Terms of service URL: https://inboxiq.app/terms

#### Screenshots & Media
- [ ] iPhone 15 Pro Max screenshots (6.7")
  - Screenshot 1: Inbox view (AI categories visible)
  - Screenshot 2: Email detail (beautiful HTML rendering)
  - Screenshot 3: Compose (clean, simple)
  - Screenshot 4: Search (powerful, fast)
  - Screenshot 5: Settings (privacy-focused)
- [ ] iPhone SE screenshots (5.5")
- [ ] App Preview video (optional, 15-30 seconds)
  - Show: Open app → View inbox → Read email → Reply

#### App Description (Optimized for ASO)
```
InboxIQ - Your AI-Powered Email Assistant

Tired of email overload? InboxIQ uses artificial intelligence to automatically organize your inbox, so you can focus on what matters.

✨ KEY FEATURES:
• AI-Powered Categorization - Automatically sorts emails into Primary, Social, Promotions, and more
• Lightning Fast - Instant app launch, blazing-fast search
• Beautiful Design - Native iOS experience with Dark Mode support
• Privacy-Focused - Your data stays yours. No ads, no tracking.
• Smart Compose - AI-assisted email writing
• Push Notifications - Stay informed without being overwhelmed

🚀 PRODUCTIVITY BOOSTERS:
• Swipe Gestures - Archive, delete, snooze with a swipe
• Powerful Search - Find any email in seconds
• Quick Reply - Respond without leaving your inbox
• Attachment Management - Easy file handling

🔒 PRIVACY & SECURITY:
• End-to-end encryption support
• Phishing detection
• Tracking blocker - Block sender tracking pixels
• No data selling - Your email is yours

InboxIQ is perfect for:
• Professionals drowning in email
• Anyone who wants a cleaner inbox
• People who value privacy
• Power users who demand speed

Download InboxIQ today and take control of your inbox!

---
Currently supports Gmail. More providers coming soon.
```

#### Keywords (100 characters max)
```
email,gmail,inbox,ai,productivity,mail,organizer,smart,fast,privacy
```

#### Support Information
- [ ] Support URL: https://inboxiq.app/support
- [ ] Support email: support@inboxiq.app
- [ ] Marketing URL: https://inboxiq.app

#### Review Notes (For Apple Reviewers)
```
Test Account Credentials:
Email: applereview@inboxiq.app
Password: AppleReview2026!

Instructions:
1. Launch app
2. Tap "Sign in with Gmail"
3. Use test account credentials above
4. Browse inbox, read emails, compose new email
5. Test search functionality
6. Try archiving/deleting emails

The app requires a Gmail account to function. AI categorization may take a few seconds on first launch as emails are processed.

For questions, contact: dev@inboxiq.app
```

### Submission Day (Week 7, Day 4)

#### Final Checks
- [ ] Fresh install on clean device (no bugs)
- [ ] Test all core features (15-min walkthrough)
- [ ] Check for crashes (Firebase Crashlytics)
- [ ] Verify push notifications work
- [ ] Test on iPhone 12, 14, 15
- [ ] Test on slow network (3G simulation)

#### Upload Build
- [ ] Archive app in Xcode (Release configuration)
- [ ] Upload to App Store Connect via Organizer
- [ ] Wait for processing (15-30 minutes)
- [ ] Select build for submission

#### Submit for Review
- [ ] Review all metadata one last time
- [ ] Click "Submit for Review"
- [ ] Confirm submission email received

### Post-Submission (Week 7-8)

#### Monitor Status
- [ ] Check App Store Connect daily
- [ ] Respond to Apple within 24 hours (if contacted)
- [ ] Fix any rejection issues immediately

#### Apple Review Timeline
- **Typical:** 1-3 days
- **Worst case:** 5-7 days
- **Our buffer:** Week 8 covers delays

#### Rejection Response Plan
1. **Read rejection carefully:** Understand exact reason
2. **Fix issue:** Make minimal changes
3. **Document fix:** Note what changed in review notes
4. **Resubmit within 48 hours:** Fast turnaround
5. **Escalate if needed:** Use expedited review (only if critical)

### Launch Day Checklist

#### Pre-Launch (Morning of Launch)
- [ ] App shows "Ready for Sale" in App Store Connect
- [ ] Final smoke test on production
- [ ] Backend monitoring enabled
- [ ] Support email monitored
- [ ] Social media posts scheduled

#### Launch (12pm CT)
- [ ] App live on App Store (verify by searching)
- [ ] Post to social media (Twitter, LinkedIn)
- [ ] Email announcement (if list exists)
- [ ] Monitor for issues (Sentry, DataDog)
- [ ] Respond to early user feedback

#### Post-Launch (Week 8+)
- [ ] Track downloads & installs
- [ ] Monitor crash-free rate (target: >99%)
- [ ] Respond to App Store reviews
- [ ] Collect user feedback
- [ ] Plan hotfix if critical bugs found

---

## 🚀 Post-Launch Roadmap (Phase 2-5)

### Phase 2: Power Features (Weeks 9-16)
**Duration:** 8 weeks
**Goal:** Expand feature set, improve retention

#### Features
- Multiple email accounts (Gmail, Outlook, iCloud)
- Snooze emails (until time/date)
- Send later (schedule emails)
- Smart compose & reply (AI-powered)
- Email templates
- Calendar integration (show events in sidebar)
- VIP inbox (filter by important senders)
- iPad support (optimized layout)

#### Success Criteria
- User retention: 40%+ (Week 4 retention)
- Free → Pro conversion: 3-5%
- App Store rating: 4.5+ stars
- NPS: 40+

#### Milestones
- **M9 (Week 12):** Multiple accounts working
- **M10 (Week 14):** Smart compose live
- **M11 (Week 16):** iPad app launched

---

### Phase 3: Team Features (Weeks 17-24)
**Duration:** 8 weeks
**Goal:** Enable team collaboration, unlock Team tier revenue

#### Features
- Shared inbox (team email management)
- Email assignment (delegate to teammates)
- Internal notes (comment without sending)
- Team templates
- Analytics dashboard
- SLA tracking (response time goals)
- Mac app (native macOS)

#### Success Criteria
- Team signups: 10+ teams (10-50 users each)
- Team MRR: $5,000+
- User retention (teams): 70%+ (Week 4)
- NPS (teams): 60+

#### Milestones
- **M12 (Week 20):** Shared inbox working
- **M13 (Week 22):** Team analytics live
- **M14 (Week 24):** Mac app launched

---

### Phase 4: Advanced AI (Weeks 25-32)
**Duration:** 8 weeks
**Goal:** AI becomes truly intelligent, proactive

#### Features
- Smart scheduling assistant (find meeting times)
- Email bundles (auto-group related emails)
- Sender insights (response time patterns)
- Response time optimization (when to send)
- Meeting prep assistant (show relevant emails)
- Advanced search (natural language)
- Web app (browser access)

#### Success Criteria
- AI engagement: 80%+ users use AI features weekly
- Time saved: 30+ minutes/week (user survey)
- Pro conversion: 7-10%
- Churn: <5%/month

#### Milestones
- **M15 (Week 28):** Smart scheduling live
- **M16 (Week 30):** Sender insights working
- **M17 (Week 32):** Web app launched

---

### Phase 5: Ecosystem (Weeks 33-40)
**Duration:** 8 weeks
**Goal:** Build platform, enable integrations

#### Features
- Zapier integration
- Public API (with docs)
- CRM integrations (Salesforce, HubSpot)
- Task integrations (Todoist, Asana)
- Advanced custom workflows
- Apple Watch app
- Email tracking (open rates, clicks)

#### Success Criteria
- API users: 100+ developers
- Integrations used: 40%+ Pro users
- MRR: $50,000+
- Total users: 50,000+

#### Milestones
- **M18 (Week 36):** API launched
- **M19 (Week 38):** Zapier integration live
- **M20 (Week 40):** Apple Watch app launched

---

### Phase 6+: Future Vision (Months 12-24)

#### AI Agent Features (Months 12-18)
- Personal email assistant ("Schedule lunch with John")
- Auto-draft responses (AI writes, you approve)
- Auto-triage (AI handles routine emails)
- Smart forwarding (AI delegates to teammates)
- Meeting prep automation

#### Ecosystem Expansion (Months 18-24)
- InboxIQ for Slack (manage Slack like email)
- InboxIQ for SMS (unified messaging)
- Voice assistant (Siri Shortcuts)
- AR features (Vision Pro support)
- Decentralized email

---

## 📊 Success Criteria

### MVP Launch (Week 8)
**Must-Haves:**
- ✅ App approved & live on App Store
- ✅ Crash-free rate: >99%
- ✅ Core features work reliably
- ✅ 0 P0 bugs, <5 P1 bugs

**Nice-to-Haves:**
- 🎯 100+ downloads in Week 1
- 🎯 App Store rating: 4.0+ (with 10+ reviews)
- 🎯 User retention: 30%+ (Day 7)

---

### Week 4 Post-Launch
**User Metrics:**
- Downloads: 500+
- Active users: 200+ (40% retention)
- Daily active users (DAU): 100+
- Sessions per user: 5+/day

**Quality Metrics:**
- Crash-free rate: >99.5%
- App Store rating: 4.5+
- NPS score: 40+

**Business Metrics:**
- Free → Pro conversion: 3-5% (10-15 paid users)
- MRR: $100-200 (assuming $10/month Pro tier)

---

### Month 3 Post-Launch (End of Phase 2)
**User Metrics:**
- Total users: 2,000+
- Active users: 800+ (40% retention)
- DAU: 400+
- Sessions per user: 8+/day

**Quality Metrics:**
- Crash-free rate: >99.7%
- App Store rating: 4.5+
- NPS score: 50+

**Business Metrics:**
- Free → Pro conversion: 5-8% (100-150 paid users)
- MRR: $1,000-1,500
- Churn: <5%/month

---

### Month 6 Post-Launch (End of Phase 3)
**User Metrics:**
- Total users: 10,000+
- Active users: 4,000+ (40% retention)
- DAU: 2,000+
- Team users: 500+ (across 10-20 teams)

**Quality Metrics:**
- Crash-free rate: >99.8%
- App Store rating: 4.6+
- NPS score: 55+

**Business Metrics:**
- Pro users: 500-800 (5-8% conversion)
- Team users: 500 (10 teams @ $25/user)
- MRR: $15,000-20,000
  - Pro tier: $5,000-8,000
  - Team tier: $10,000-12,000
- Churn: <4%/month

---

### Year 1 Goal (End of Phase 5)
**User Metrics:**
- Total users: 50,000+
- Active users: 20,000+ (40% retention)
- DAU: 10,000+
- Team users: 2,000+ (across 50-100 teams)

**Quality Metrics:**
- Crash-free rate: >99.9%
- App Store rating: 4.7+
- NPS score: 60+

**Business Metrics:**
- Pro users: 3,000-4,000 (6-8% conversion)
- Team users: 2,000
- MRR: $70,000-100,000
  - Pro tier: $30,000-40,000
  - Team tier: $40,000-60,000
- ARR: $840,000-1,200,000
- Churn: <3%/month

---

### Leading Indicators to Track (Weekly)

#### Engagement
- **DAU/MAU ratio:** >40% (healthy engagement)
- **Sessions per user:** >5/day (sticky)
- **Emails processed:** >50/user/week (valuable)
- **AI features used:** >3/week/user (AI value)

#### Retention
- **Day 1 retention:** >80%
- **Day 7 retention:** >30%
- **Day 30 retention:** >20%

#### Quality
- **Crash-free rate:** >99%
- **App Store rating:** >4.5
- **Support tickets:** <5% of users
- **Bug reports:** <10/week

#### Business
- **Free → Pro conversion:** 5-8%
- **Trial → Paid conversion:** 60%+
- **Churn rate:** <5%/month
- **LTV/CAC ratio:** >3:1

---

## 🎯 Launch Success Formula

### Week 1-2: Foundations
**Focus:** Get technical foundations right
**Metric:** OAuth works, emails sync

### Week 3-5: Core Features
**Focus:** Build MVP feature set
**Metric:** Can read, compose, send email

### Week 6-7: Polish & Ship
**Focus:** Make it great, not just functional
**Metric:** Beta testers love it, App Store approved

### Week 8+: Iterate & Grow
**Focus:** Learn from users, improve relentlessly
**Metric:** Retention, conversion, happiness

---

## 🔥 Ruthless Prioritization

### What We're Shipping (MVP)
✅ Read email
✅ Compose email
✅ AI categorization
✅ Search
✅ Push notifications
✅ Archive/delete

### What We're NOT Shipping (Yet)
❌ Snooze (Phase 2)
❌ Multiple accounts (Phase 2)
❌ Calendar integration (Phase 2)
❌ Templates (Phase 2)
❌ Team features (Phase 3)
❌ Advanced AI (Phase 4)

### Decision Framework
For any feature request, ask:
1. **Is this essential for MVP?** (Can users accomplish core tasks without it?)
2. **Can users work around it?** (Is there a manual alternative?)
3. **What's the cost?** (How many dev-weeks?)
4. **What's the impact?** (Does it improve conversion/retention?)

If the answer is "not essential, workaround exists, high cost, low impact" → **Phase 2+**

---

## 📝 Summary & Next Steps

### What Success Looks Like (Week 8)
- ✅ InboxIQ is live on the App Store
- ✅ Users can manage their Gmail inbox beautifully
- ✅ AI categorization is working
- ✅ App is fast, reliable, polished
- ✅ We have real user feedback
- ✅ We're ready to iterate toward Phase 2

### Immediate Actions (This Week)
1. **V Reviews & Approves Roadmap** (1 hour)
2. **Create GitHub Repo** (DEV-PREMIUM, 1 hour)
3. **Request Gmail API Quota Increase** (DEV-PREMIUM, 30 min)
4. **Set Up Dev Environments** (DEV-PREMIUM, 4 hours)
5. **Start Week 1 Sprint** (ALL, Monday Feb 24)

### Weekly Cadence
- **Monday:** Sprint planning (30 min)
- **Daily:** Async standups via memory logs
- **Friday:** Sprint review (1 hour)
- **Sunday:** Sprint retrospective (30 min)

### Communication
- **Daily updates:** Memory logs (each agent)
- **Blockers:** Slack immediately
- **Decisions:** Doc in `/decisions` folder
- **Progress:** Update ROADMAP.md weekly

---

## 🚀 Let's Ship This!

**Target:** Week of April 19, 2026
**Team:** Ready
**Plan:** Detailed
**Mindset:** Ruthlessly focused on MVP

We're not building the perfect email app. We're building **Version 1.0** — a great foundation we can iterate on.

Ship fast. Learn fast. Improve fast.

Let's make InboxIQ happen. 🔥

---

**Document Version:** 1.0
**Created:** Feb 23, 2026
**Author:** Shiv 🔥 (Doc-Premium Subagent)
**Next Review:** End of Week 2 (Mar 9, 2026)
**Status:** Ready for V approval & Sprint 1 kickoff
