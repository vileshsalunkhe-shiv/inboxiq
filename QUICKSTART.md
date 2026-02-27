# InboxIQ Quick Start Guide

## 🚀 Day 1: Get Everything Running

### 1. Set Up Your Development Environment

```bash
# Backend setup (30 minutes)
mkdir inboxiq && cd inboxiq
git init

# Create backend structure
mkdir -p backend/{app,tests,alembic}
cd backend

# Initialize Python project with Poetry
curl -sSL https://install.python-poetry.org | python3 -
poetry new . --name inboxiq-backend
poetry add fastapi uvicorn[standard] sqlalchemy asyncpg
poetry add python-jose[cryptography] python-multipart
poetry add google-auth google-auth-oauthlib google-auth-httplib2
poetry add anthropic redis httpx pytest-asyncio

# Create main app file
cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="InboxIQ API", version="0.1.0")

# Configure CORS for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "inboxiq-api"}

@app.get("/")
async def root():
    return {"message": "Welcome to InboxIQ API"}
EOF

# Test it works
poetry run uvicorn app.main:app --reload
```

### 2. Google Cloud Setup (20 minutes)

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create new project: "InboxIQ"
3. Enable Gmail API:
   ```
   APIs & Services → Library → Search "Gmail API" → Enable
   ```
4. Create OAuth 2.0 credentials:
   ```
   APIs & Services → Credentials → Create Credentials → OAuth client ID
   - Application type: Web application
   - Name: InboxIQ Backend
   - Authorized redirect URIs: 
     - http://localhost:8000/auth/callback (dev)
     - https://your-app.railway.app/auth/callback (prod)
   ```
5. Download credentials JSON

### 3. Get Your API Keys

1. **Anthropic (Claude)**:
   - Sign up at [claude.ai](https://claude.ai)
   - Go to API section
   - Generate API key
   - You get $5 free credit (enough for testing)

2. **Railway**:
   - Sign up at [railway.app](https://railway.app)
   - Verify account for $5 free credit
   - Install CLI: `npm install -g @railway/cli`

### 4. Create Basic Backend Structure

```python
# app/config.py
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # App
    app_name: str = "InboxIQ"
    debug: bool = True
    
    # Security
    secret_key: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    
    # Database
    database_url: str
    
    # External APIs
    google_client_id: str
    google_client_secret: str
    anthropic_api_key: str
    
    # Redis
    redis_url: str = "redis://localhost:6379"
    
    class Config:
        env_file = ".env"

@lru_cache()
def get_settings():
    return Settings()
```

```bash
# Create .env file
cat > .env << 'EOF'
SECRET_KEY=your-super-secret-key-here
DATABASE_URL=postgresql://user:password@localhost/inboxiq
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
ANTHROPIC_API_KEY=your-anthropic-key
EOF
```

### 5. iOS App Setup (30 minutes)

```bash
# In project root
mkdir ios && cd ios

# Create new Xcode project
# 1. Open Xcode
# 2. Create New Project → iOS → App
# 3. Product Name: InboxIQ
# 4. Interface: SwiftUI
# 5. Language: Swift
# 6. Use Core Data: Yes

# Add dependencies (in Xcode)
# File → Add Package Dependencies
# Add: https://github.com/Alamofire/Alamofire
# Add: https://github.com/kishikawakatsumi/KeychainAccess
```

## 📋 Week 1 Checklist

### Monday: Project Setup ✓
- [ ] Create GitHub repository
- [ ] Set up backend project structure
- [ ] Configure development environment
- [ ] Create Railway account
- [ ] Initialize iOS project

### Tuesday: Authentication
- [ ] Implement Google OAuth flow
- [ ] Create JWT token generation
- [ ] Set up user model
- [ ] Test authentication end-to-end

### Wednesday: Database
- [ ] Design database schema
- [ ] Set up PostgreSQL locally
- [ ] Create SQLAlchemy models
- [ ] Write migration scripts
- [ ] Implement user CRUD operations

### Thursday: Gmail Integration
- [ ] Implement Gmail API client
- [ ] Create email fetching service
- [ ] Handle pagination
- [ ] Store emails in database
- [ ] Test with real Gmail account

### Friday: iOS Foundation
- [ ] Create login screen
- [ ] Implement keychain storage
- [ ] Build API client
- [ ] Create email list view
- [ ] Test on real device

## 🔧 Essential Code Snippets

### FastAPI Gmail Service
```python
# app/services/gmail.py
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

class GmailService:
    def __init__(self, user_id: str):
        self.user_id = user_id
        self.service = None
        
    async def initialize(self, credentials: dict):
        creds = Credentials.from_authorized_user_info(credentials)
        self.service = build('gmail', 'v1', credentials=creds)
    
    async def fetch_messages(self, query: str = "is:unread", max_results: int = 50):
        results = self.service.users().messages().list(
            userId='me',
            q=query,
            maxResults=max_results
        ).execute()
        
        messages = results.get('messages', [])
        return [self.get_message(msg['id']) for msg in messages]
    
    def get_message(self, message_id: str):
        message = self.service.users().messages().get(
            userId='me',
            id=message_id
        ).execute()
        
        return self.parse_message(message)
```

### iOS API Client
```swift
// APIClient.swift
import Foundation
import Alamofire

class APIClient {
    static let shared = APIClient()
    private let baseURL = "http://localhost:8000"
    
    private var headers: HTTPHeaders {
        guard let token = KeychainService.shared.getToken() else {
            return []
        }
        return ["Authorization": "Bearer \(token)"]
    }
    
    func fetchEmails(completion: @escaping (Result<[Email], Error>) -> Void) {
        AF.request("\(baseURL)/emails", headers: headers)
            .responseDecodable(of: EmailResponse.self) { response in
                switch response.result {
                case .success(let emailResponse):
                    completion(.success(emailResponse.emails))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
```

### Database Models
```python
# app/models/user.py
from sqlalchemy import Column, String, DateTime
from sqlalchemy.dialects.postgresql import UUID
import uuid

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    google_refresh_token = Column(String, nullable=True)  # Encrypted
    created_at = Column(DateTime, server_default=func.now())
    last_sync = Column(DateTime, nullable=True)
    
    # Relationships
    emails = relationship("Email", back_populates="user")
    categories = relationship("Category", back_populates="user")
```

## 🎯 Success Metrics for Week 1

By end of Week 1, you should have:

1. **Working Authentication**: User can log in with Gmail
2. **Email Fetching**: Backend can retrieve emails from Gmail
3. **Data Storage**: Emails saved to PostgreSQL
4. **Basic iOS App**: Shows list of emails
5. **Local Development**: Everything runs on your machine

## 🚨 Common Pitfalls to Avoid

1. **Don't over-engineer early**: Start simple, iterate
2. **Test with real data**: Use your actual Gmail from day 1
3. **Security shortcuts**: Never commit API keys to Git
4. **Skipping error handling**: Add try-catch blocks everywhere
5. **Not testing on device**: iOS Simulator ≠ real iPhone

## 💡 Pro Tips

1. **Use ngrok for iOS testing**:
   ```bash
   ngrok http 8000  # Exposes local backend to internet
   ```

2. **Set up pre-commit hooks**:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

3. **Log everything during development**:
   ```python
   import structlog
   logger = structlog.get_logger()
   logger.info("gmail_fetch", user_id=user.id, email_count=len(emails))
   ```

4. **Create seed data script**:
   ```python
   # scripts/seed_data.py
   async def create_test_data():
       # Create test user
       # Add sample categories
       # Generate mock emails
   ```

## 📞 When You Get Stuck

1. **FastAPI issues**: Check the [FastAPI docs](https://fastapi.tiangolo.com/)
2. **Gmail API**: Use [Google's API Explorer](https://developers.google.com/gmail/api/reference/rest)
3. **iOS problems**: [Swift Forums](https://forums.swift.org/) are helpful
4. **Database**: [PostgreSQL Discord](https://discord.gg/postgresql) is active

## 🎉 Your First Milestone

When you can:
1. Open the iOS app
2. Log in with Gmail
3. See your real emails in a list
4. Pull to refresh and get new emails

**You've completed Phase 1!** 🎊

Take a screenshot and celebrate - you've built the foundation of a real product!

---

Remember: This is a marathon, not a sprint. Focus on getting one thing working at a time.