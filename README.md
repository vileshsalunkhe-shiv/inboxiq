# InboxIQ

**AI-Powered iPhone Email Organizer**

InboxIQ is an enterprise-grade iPhone email application that uses AI to automatically categorize and manage Gmail emails. Built with Swift/SwiftUI for iOS and FastAPI for the backend, InboxIQ saves users 30+ minutes daily through intelligent email organization.

---

## 🎯 What is InboxIQ?

InboxIQ transforms email management from overwhelming to effortless by:
- **AI Categorization**: Claude AI automatically organizes emails into 6 smart categories
- **Intelligent Inbox**: Priority-first email management
- **Native iOS**: Fluid SwiftUI experience optimized for iPhone
- **Privacy-First**: Your data stays private - no selling to advertisers

**Target Users:** Knowledge workers, executives, freelancers managing 50-200+ emails daily

---

## ✨ Features

### Core Features (MVP)
- ✅ **Gmail Integration** - OAuth 2.0 secure authentication
- ✅ **Google Calendar Integration** - OAuth 2.0 calendar access
- ✅ **AI Categorization** - Automatic email sorting with Claude AI
  - Work, Personal, Finance, Shopping, Travel, Newsletters
- ✅ **Smart Inbox** - Priority-first email management
- ✅ **Search** - Fast, intelligent email search
- ✅ **Compose & Reply** - Full email composition with rich text
- ✅ **Push Notifications** - Real-time email alerts
- ✅ **Background Sync** - Seamless email synchronization

### Calendar Features (New!)
- 📅 **Calendar Connection** - Connect your Google Calendar
- 📅 **View Events** - See upcoming calendar events
- 📅 **Create Events** - Schedule meetings directly from the app
- 📅 **Email-to-Calendar** - Context-aware event creation from emails

### Coming Soon
- 🚧 Smart Digest (daily email summary)
- 🚧 Snooze & Schedule
- 🚧 Email templates
- 🚧 Multi-account support

---

## 🏗️ Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│ iPhone App (SwiftUI)                                         │
│ ├─ Authentication & User Management                          │
│ ├─ Email List & Detail Views                                 │
│ ├─ Calendar Integration UI                                   │
│ ├─ Core Data Local Cache                                     │
│ └─ Background Sync                                            │
└────────────────┬────────────────────────────────────────────┘
                 │
                 │ REST API (HTTPS)
                 │
┌────────────────┴────────────────────────────────────────────┐
│ FastAPI Backend (Python)                                     │
│ ├─ Authentication Service (JWT + OAuth)                      │
│ ├─ Gmail Service (Google OAuth 2.0)                          │
│ ├─ Calendar Service (Google OAuth 2.0) ✨ NEW               │
│ ├─ AI Categorization Engine (Claude)                         │
│ ├─ Sync Engine                                                │
│ └─ Push Notification Service (APNs)                          │
└────────────────┬────────────────────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
┌───────┴──────┐  ┌──────┴───────┐
│ PostgreSQL   │  │ Redis Cache  │
│ - Users      │  │ - Sessions   │
│ - Emails     │  │ - Job Queue  │
│ - Categories │  │ - Rate Limit │
└──────────────┘  └──────────────┘
```

### Tech Stack

**iOS App:**
- Swift 5.9+
- SwiftUI
- Core Data (local caching)
- Keychain (secure storage)

**Backend:**
- Python 3.11+
- FastAPI (async web framework)
- SQLAlchemy (ORM)
- PostgreSQL (primary database)
- Redis (caching & queues)

**External APIs:**
- Gmail API (email access)
- Google Calendar API (calendar integration) ✨ NEW
- Anthropic Claude API (AI categorization)
- Apple Push Notification Service (push notifications)

**Infrastructure:**
- Railway (hosting)
- GitHub Actions (CI/CD)

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 🚀 Quick Start

### Prerequisites

- **Backend:**
  - Python 3.11+
  - PostgreSQL 14+
  - Redis 7+
  - Google Cloud account
  - Anthropic API key

- **iOS:**
  - macOS 13+
  - Xcode 15+
  - iOS 17+ device or simulator

### Backend Setup

```bash
# Clone repository
cd /Users/openclaw-service/.openclaw/workspace/projects/inboxiq/backend

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-calendar.txt  # Calendar integration

# Configure environment
cp .env.example .env
# Edit .env with your credentials

# Run migrations
alembic upgrade head

# Start server
uvicorn app.main:app --reload --port 8000
```

### iOS Setup

```bash
# Open in Xcode
open ios/InboxIQ.xcodeproj

# Update Configuration
# 1. Set your Development Team
# 2. Update Bundle Identifier
# 3. Configure API endpoint

# Run on device or simulator
# Product → Run (⌘R)
```

### Google Calendar Setup

Follow the detailed setup guide in [GOOGLE-CALENDAR-SETUP.md](GOOGLE-CALENDAR-SETUP.md).

**Quick steps:**
1. Create Google Cloud project
2. Enable Google Calendar API
3. Configure OAuth consent screen
4. Create OAuth 2.0 credentials
5. Add credentials to `.env` file

See [INTEGRATIONS.md](INTEGRATIONS.md) for complete integration documentation.

---

## 📚 Documentation

### Core Documentation
- **[PRD.md](PRD.md)** - Product Requirements Document
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture and design
- **[QUICKSTART.md](QUICKSTART.md)** - Day 1 setup guide
- **[API-DOCUMENTATION.md](API-DOCUMENTATION.md)** - Complete API reference

### Integration Guides
- **[INTEGRATIONS.md](INTEGRATIONS.md)** - Third-party integrations (Gmail, Calendar)
- **[GOOGLE-CALENDAR-SETUP.md](GOOGLE-CALENDAR-SETUP.md)** - Calendar setup guide
- **[CALENDAR-INTEGRATION-SUMMARY.md](CALENDAR-INTEGRATION-SUMMARY.md)** - Calendar integration overview

### Development
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[SYSTEM-WALKTHROUGH.md](SYSTEM-WALKTHROUGH.md)** - System walkthrough
- **[QUICK-LOCAL-TEST.md](QUICK-LOCAL-TEST.md)** - Local testing guide

### Strategy & Planning
- **[ROADMAP.md](ROADMAP.md)** - Product roadmap
- **[LEAN-LAUNCH-STRATEGY.md](LEAN-LAUNCH-STRATEGY.md)** - Launch strategy
- **[RISK-ASSESSMENT.md](RISK-ASSESSMENT.md)** - Risk analysis

---

## 🔧 API Overview

### Authentication
```http
POST /auth/login        # User login (JWT)
POST /auth/register     # User registration
POST /auth/refresh      # Refresh access token
```

### Gmail Integration
```http
GET  /gmail/auth/initiate    # Start Gmail OAuth
GET  /gmail/auth/callback    # OAuth callback
GET  /gmail/emails           # Fetch emails
POST /gmail/emails/send      # Send email
```

### Calendar Integration ✨ NEW
```http
GET  /api/calendar/auth/initiate  # Start Calendar OAuth
GET  /api/calendar/auth/callback  # OAuth callback
GET  /api/calendar/events         # List events
POST /api/calendar/events         # Create event
GET  /api/calendar/status         # Connection status
```

### Email Management
```http
GET    /emails              # List categorized emails
GET    /emails/{id}         # Get email details
PUT    /emails/{id}/category # Update category
DELETE /emails/{id}         # Delete email
```

See [API-DOCUMENTATION.md](API-DOCUMENTATION.md) for complete API documentation.

---

## 🧪 Testing

### Backend Tests
```bash
cd backend

# Run all tests
pytest

# Run with coverage
pytest --cov=app tests/

# Run specific test file
pytest tests/test_calendar.py
```

### iOS Tests
```bash
# In Xcode
# Product → Test (⌘U)

# Or via command line
xcodebuild test \
  -project ios/InboxIQ.xcodeproj \
  -scheme InboxIQ \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 🔐 Security

InboxIQ takes security seriously:

- **OAuth 2.0**: Industry-standard authentication for Gmail and Calendar
- **Token Encryption**: Sensitive tokens encrypted at rest
- **JWT Authentication**: Stateless API authentication
- **HTTPS Only**: All API communication over TLS
- **Token Refresh**: Automatic token rotation
- **Rate Limiting**: API abuse prevention
- **Input Validation**: Comprehensive request validation
- **CSRF Protection**: State tokens for OAuth flows

For complete security documentation, see [DATA-SECURITY.md](DATA-SECURITY.md).

---

## 🚢 Deployment

### Backend Deployment (Railway)

```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Link project
railway link

# Deploy
railway up
```

### iOS Deployment (TestFlight/App Store)

1. **Archive build**: Product → Archive
2. **Upload to App Store Connect**: Distribute App
3. **TestFlight**: Submit for beta review
4. **App Store**: Submit for review

See deployment guides:
- Backend: [infrastructure/README.md](infrastructure/README.md)
- iOS: [ios-complete/DEPLOYMENT-GUIDE.md](ios-complete/DEPLOYMENT-GUIDE.md)

---

## 📊 Project Status

### Current Version: 0.3.0

**Recently Completed:**
- ✅ Google Calendar Integration (Backend)
- ✅ Calendar OAuth 2.0 flow
- ✅ Event listing and creation APIs
- ✅ Comprehensive calendar documentation

**In Progress:**
- 🔄 Calendar token database storage
- 🔄 Token encryption implementation
- 🔄 iOS calendar UI integration

**Next Up:**
- 📋 Database migration for calendar tokens
- 📋 Calendar event-email linking
- 📋 Smart scheduling features
- 📋 Calendar event reminders

See [CHANGELOG.md](CHANGELOG.md) for full version history.

---

## 🤝 Contributing

This is currently a private project. For inquiries, please contact the project maintainer.

### Development Workflow

1. Create feature branch: `git checkout -b feature/calendar-sync`
2. Make changes and test thoroughly
3. Update documentation
4. Submit pull request
5. Code review and merge

---

## 📄 License

Proprietary - All rights reserved

---

## 📞 Support & Contact

**Project Owner:** Vilesh  
**Workspace:** vs-work-with-shiv

**Issue Tracking:** Linear (Team: INB)

**Documentation Issues:** Please update relevant `.md` files and submit PR.

---

## 🎯 Vision

InboxIQ aims to make email intelligent, delightful, and stress-free by combining the best of AI-powered automation with beautiful, native iOS design.

**Mission:** Save users 30+ minutes daily through intelligent email organization while respecting privacy and delivering a premium native experience.

---

**Made with ❤️ using Swift, Python, and AI**

*Last Updated: March 2, 2026*
