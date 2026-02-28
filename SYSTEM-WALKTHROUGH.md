# InboxIQ System Walkthrough - Complete User Journey

**Document Version:** 1.0  
**Date:** February 27, 2026  
**Author:** Shiv (AI Assistant)  
**Purpose:** Comprehensive walkthrough of InboxIQ architecture and file interactions

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Summary](#architecture-summary)
3. [Part 1: App Launch & Initial Setup](#part-1-app-launch--initial-setup)
4. [Part 2: User Login (First Time)](#part-2-user-login-first-time)
5. [Part 3: First Email Sync](#part-3-first-email-sync)
6. [Part 4: AI Email Categorization](#part-4-ai-email-categorization-background)
7. [Part 5: User Interactions](#part-5-user-interactions)
8. [Part 6: Daily Digest Feature](#part-6-daily-digest-feature)
9. [Part 7: Token Refresh](#part-7-token-refresh-automatic)
10. [Part 8: Background Sync](#part-8-background-sync-ios)
11. [Part 9: Deployment](#part-9-deployment-railway)
12. [Key Files Summary](#key-files-summary)
13. [Data Flow Diagram](#data-flow-diagram)

---

## Overview

InboxIQ is a privacy-focused, AI-powered email management app for iPhone. This document walks through the complete user journey from app launch to email categorization, explaining which files are involved at each step.

### Technology Stack

**Backend:**
- FastAPI (Python)
- PostgreSQL (database)
- Redis (rate limiting)
- Claude AI (Anthropic Haiku)
- Gmail API (Google)

**iOS:**
- Swift/SwiftUI
- Core Data (local storage)
- Keychain (secure token storage)
- ASWebAuthenticationSession (OAuth)

**Infrastructure:**
- Railway.app (hosting)
- Docker (containers)
- Sentry (monitoring)

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                         iPhone App                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Views   │→ │ViewModels│→ │ Services │→ │APIClient │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│       ↓              ↓              ↓              ↓        │
│  ┌──────────────────────────────────────────────────┐      │
│  │              Core Data (SQLite)                  │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                           ↕ HTTPS
┌─────────────────────────────────────────────────────────────┐
│                      Backend (Railway)                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   API    │→ │ Services │→ │  Models  │→ │PostgreSQL│   │
│  │ Routes   │  │(Auth,Sync│  │(SQLAlch) │  │          │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│       ↓              ↓              ↓                       │
│  Gmail API    Claude AI       AI Queue                     │
└─────────────────────────────────────────────────────────────┘
                           ↕
┌─────────────────────────────────────────────────────────────┐
│                    Background Worker                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Polls AI Queue → Calls Claude → Updates Categories  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 1: App Launch & Initial Setup

### Step 1: User Opens App

**User Action:** Taps InboxIQ icon on iPhone

**What Happens:**
- App checks if user has saved authentication tokens
- If tokens exist → Navigate to inbox
- If no tokens → Show login screen

**Files Involved:**

#### iOS Files

**1. `ios/InboxIQ/InboxIQApp.swift`** - App Entry Point
```swift
@main
struct InboxIQApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var syncViewModel = SyncViewModel()
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                HomeView()
            } else {
                LoginView()
            }
        }
    }
}
```
**Purpose:**
- Creates app-wide environment objects
- Initializes Core Data stack
- Decides which view to show (Login vs Home)

**2. `ios/InboxIQ/CoreData/PersistenceController.swift`** - Local Database
```swift
class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "InboxIQ")
        container.loadPersistentStores { description, error in
            // Loads emails/categories from local SQLite
        }
    }
}
```
**Purpose:**
- Creates Core Data stack (local SQLite database)
- Loads previously synced emails from device storage
- Provides persistent storage between app launches

**3. `ios/InboxIQ/Services/KeychainService.swift`** - Secure Token Storage
```swift
class KeychainService {
    func getAccessToken() -> String? {
        // Reads JWT from iOS Keychain (encrypted)
    }
    
    func saveTokens(accessToken: String, refreshToken: String) {
        // Saves JWTs to Keychain (secure)
    }
}
```
**Purpose:**
- Checks if user has saved authentication tokens
- Provides secure storage for JWT tokens
- Uses iOS Keychain (encrypted, survives app uninstall)

**Decision Flow:**
```
App Launch
    ↓
KeychainService.getAccessToken()
    ↓
[Token exists?]
    ├─ Yes → authViewModel.isAuthenticated = true → Show HomeView
    └─ No → authViewModel.isAuthenticated = false → Show LoginView
```

---

## Part 2: User Login (First Time)

### Step 2: User Taps "Sign in with Google"

**User Action:** Taps "Sign in with Google" button on LoginView

**What Happens:**
- App requests OAuth URL from backend
- Opens Safari in-app browser with Google login
- User authenticates with Google
- Google redirects back to app with authorization code
- App exchanges code for JWT tokens
- Tokens saved to Keychain

---

#### Phase 2.1: Request OAuth URL

**iOS Files:**

**1. `ios/InboxIQ/Views/Auth/LoginView.swift`** - Login Screen
```swift
struct LoginView: View {
    @StateObject var viewModel = AuthViewModel()
    
    var body: some View {
        Button("Sign in with Google") {
            viewModel.signInWithGoogle()
        }
    }
}
```
**Purpose:** Displays login UI and triggers OAuth flow

**2. `ios/InboxIQ/ViewModels/AuthViewModel.swift`** - Auth Logic
```swift
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    private let authService = AuthService.shared
    
    func signInWithGoogle() {
        Task {
            await authService.startOAuthFlow()
        }
    }
}
```
**Purpose:** Coordinates authentication flow

**3. `ios/InboxIQ/Services/AuthService.swift`** - OAuth Implementation
```swift
class AuthService {
    func startOAuthFlow() async throws {
        // Step 1: Get OAuth URL from backend
        let url = try await apiClient.get("/auth/google/authorize")
        
        // Step 2: Open Safari with Google login
        presentOAuthWebView(url: url)
    }
}
```
**Purpose:** Manages OAuth flow with backend

**4. `ios/InboxIQ/Services/APIClient.swift`** - Network Layer
```swift
class APIClient {
    private let baseURL = Constants.apiBaseURL
    
    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        let url = URL(string: baseURL + endpoint)!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```
**Purpose:** Handles HTTP communication with backend

**5. `ios/InboxIQ/Utils/Constants.swift`** - Configuration
```swift
struct Constants {
    static let apiBaseURL = "https://inboxiq-production.railway.app"
    static let oauthClientId = "YOUR_GOOGLE_CLIENT_ID"
    static let oauthCallbackScheme = "inboxiq"
}
```
**Purpose:** Stores app configuration (API URLs, OAuth settings)

---

**Backend Files:**

**1. `backend/app/main.py`** - FastAPI Application
```python
from fastapi import FastAPI
from app.api import auth, sync, emails

app = FastAPI(title="InboxIQ API")

# Include API routers
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(sync.router, prefix="/sync", tags=["sync"])
app.include_router(emails.router, prefix="/emails", tags=["emails"])

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
```
**Purpose:** 
- Main FastAPI application
- Routes requests to appropriate handlers
- Provides health check endpoint

**2. `backend/app/api/auth.py`** - Authentication Endpoints
```python
from fastapi import APIRouter, Depends
from app.services.auth_service import AuthService

router = APIRouter()

@router.get("/google/authorize")
async def get_google_authorize_url():
    """Returns OAuth URL for Google login"""
    auth_service = AuthService()
    oauth_url = auth_service.get_google_oauth_url()
    return {"url": oauth_url}
```
**Purpose:** Handles authentication API endpoints

**3. `backend/app/services/auth_service.py`** - Auth Business Logic
```python
from google_auth_oauthlib.flow import Flow

class AuthService:
    def get_google_oauth_url(self) -> str:
        """Generate Google OAuth authorization URL"""
        flow = Flow.from_client_config(
            client_config={
                "web": {
                    "client_id": settings.GOOGLE_CLIENT_ID,
                    "client_secret": settings.GOOGLE_CLIENT_SECRET,
                    "redirect_uris": [settings.OAUTH_REDIRECT_URI]
                }
            },
            scopes=[
                "https://www.googleapis.com/auth/gmail.readonly",
                "https://www.googleapis.com/auth/gmail.send"
            ]
        )
        
        authorization_url, _ = flow.authorization_url(
            access_type="offline",
            include_granted_scopes="true"
        )
        
        return authorization_url
```
**Purpose:**
- Generates Google OAuth URL
- Defines required Gmail scopes (read + send)
- Returns URL like: `https://accounts.google.com/o/oauth2/auth?client_id=...`

**4. `backend/app/config.py`** - Configuration Management
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Google OAuth
    GOOGLE_CLIENT_ID: str
    GOOGLE_CLIENT_SECRET: str
    OAUTH_REDIRECT_URI: str
    
    # JWT
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    
    # Database
    DATABASE_URL: str
    
    class Config:
        env_file = ".env"

settings = Settings()
```
**Purpose:**
- Loads configuration from environment variables
- Provides type-safe access to settings
- Reads from `.env` file in development

---

#### Phase 2.2: User Authenticates with Google

**User Action:** Enters Google credentials and approves permissions

**iOS Files:**

**1. `ios/InboxIQ/Views/Auth/OAuthWebView.swift`** - Safari Browser
```swift
import AuthenticationServices

class OAuthWebView {
    func present(url: URL, callbackScheme: String) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackScheme
        ) { callbackURL, error in
            // Handle callback
            if let callbackURL = callbackURL {
                let code = extractAuthCode(from: callbackURL)
                exchangeCodeForTokens(code)
            }
        }
        
        session.presentationContextProvider = self
        session.start()
    }
}
```
**Purpose:**
- Opens Safari in-app browser
- Shows Google login page
- Handles redirect callback
- Extracts authorization code

**Flow:**
```
iOS opens Safari → Google login page
    ↓
User enters email/password
    ↓
Google shows permission screen:
    "InboxIQ wants to:
     - Read your emails
     - Send emails on your behalf"
    ↓
User clicks "Allow"
    ↓
Google redirects to: inboxiq://auth/callback?code=AUTHORIZATION_CODE
    ↓
iOS intercepts URL (registered URL scheme)
```

---

#### Phase 2.3: Exchange Authorization Code for Tokens

**iOS Files:**

**1. `ios/InboxIQ/Services/AuthService.swift`** - Token Exchange
```swift
func exchangeCodeForTokens(_ code: String) async throws {
    let request = TokenRequest(code: code)
    let response: TokenResponse = try await apiClient.post(
        "/auth/google/callback",
        body: request
    )
    
    // Save tokens to Keychain
    KeychainService.shared.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken
    )
    
    // Update auth state
    DispatchQueue.main.async {
        authViewModel.isAuthenticated = true
    }
}
```
**Purpose:** Exchanges code for JWT tokens and saves them

---

**Backend Files:**

**1. `backend/app/api/auth.py`** - Callback Endpoint
```python
@router.post("/google/callback")
async def google_callback(
    request: TokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """Exchange authorization code for JWT tokens"""
    auth_service = AuthService(db)
    
    # Exchange code with Google
    user_info = await auth_service.exchange_google_code(request.code)
    
    # Create or update user
    user = await auth_service.create_or_update_user(user_info)
    
    # Generate JWT tokens
    tokens = auth_service.create_tokens(user.id)
    
    return tokens
```
**Purpose:** Handles OAuth callback and returns JWT tokens

**2. `backend/app/services/auth_service.py`** - Token Generation
```python
class AuthService:
    async def exchange_google_code(self, code: str):
        """Exchange authorization code with Google"""
        flow = Flow.from_client_config(...)
        flow.fetch_token(code=code)
        
        credentials = flow.credentials
        
        # Get user info from Google
        user_info = {
            "email": credentials.id_token["email"],
            "google_access_token": credentials.token,
            "google_refresh_token": credentials.refresh_token
        }
        
        return user_info
    
    async def create_or_update_user(self, user_info: dict):
        """Create or update user in database"""
        user = await db.query(User).filter(
            User.email == user_info["email"]
        ).first()
        
        if not user:
            user = User(email=user_info["email"])
            db.add(user)
        
        # Encrypt Google refresh token
        encrypted_token = security.encrypt(
            user_info["google_refresh_token"]
        )
        user.google_refresh_token = encrypted_token
        
        await db.commit()
        return user
    
    def create_tokens(self, user_id: int):
        """Generate JWT access and refresh tokens"""
        # Access token (15 minutes)
        access_token = jwt.encode(
            {
                "user_id": user_id,
                "exp": datetime.utcnow() + timedelta(minutes=15)
            },
            settings.JWT_SECRET,
            algorithm=settings.JWT_ALGORITHM
        )
        
        # Refresh token (7 days)
        refresh_token = jwt.encode(
            {
                "user_id": user_id,
                "exp": datetime.utcnow() + timedelta(days=7)
            },
            settings.JWT_SECRET,
            algorithm=settings.JWT_ALGORITHM
        )
        
        # Save refresh token to database
        token_hash = security.hash_token(refresh_token)
        db_token = RefreshToken(
            user_id=user_id,
            token_hash=token_hash,
            expires_at=datetime.utcnow() + timedelta(days=7)
        )
        db.add(db_token)
        db.commit()
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer"
        }
```
**Purpose:**
- Exchanges code with Google
- Creates/updates user in database
- Encrypts Google refresh token (Fernet)
- Generates JWT access + refresh tokens
- Saves refresh token hash to database

**3. `backend/app/models/user.py`** - User Database Model
```python
from sqlalchemy import Column, String, DateTime, Text
from sqlalchemy.dialects.postgresql import UUID
import uuid

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), unique=True, nullable=False, index=True)
    google_refresh_token = Column(Text, nullable=True)  # Encrypted
    created_at = Column(DateTime, server_default=func.now())
    last_sync = Column(DateTime, nullable=True)
    
    # Relationships
    emails = relationship("Email", back_populates="user")
    refresh_tokens = relationship("RefreshToken", back_populates="user")
```
**Purpose:** SQLAlchemy model for users table in PostgreSQL

**4. `backend/app/models/refresh_token.py`** - Refresh Token Model
```python
class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    token_hash = Column(String(255), unique=True, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    revoked = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())
    
    user = relationship("User", back_populates="refresh_tokens")
```
**Purpose:** Stores hashed refresh tokens (for revocation)

**5. `backend/app/utils/security.py`** - Security Utilities
```python
from cryptography.fernet import Fernet
import hashlib
import jwt

# Fernet encryption for Google tokens
fernet = Fernet(settings.ENCRYPTION_KEY)

def encrypt(plaintext: str) -> str:
    """Encrypt sensitive data (Google refresh tokens)"""
    return fernet.encrypt(plaintext.encode()).decode()

def decrypt(ciphertext: str) -> str:
    """Decrypt sensitive data"""
    return fernet.decrypt(ciphertext.encode()).decode()

def hash_token(token: str) -> str:
    """Hash JWT refresh tokens for database storage"""
    return hashlib.sha256(token.encode()).hexdigest()

def verify_jwt(token: str) -> dict:
    """Verify and decode JWT token"""
    return jwt.decode(
        token,
        settings.JWT_SECRET,
        algorithms=[settings.JWT_ALGORITHM]
    )
```
**Purpose:**
- Encrypts/decrypts Google tokens (Fernet symmetric encryption)
- Hashes JWT refresh tokens (SHA-256)
- Verifies JWT signatures

**6. `backend/app/database.py`** - Database Connection
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

engine = create_async_engine(settings.DATABASE_URL)
AsyncSessionLocal = sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False
)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
```
**Purpose:** Provides async SQLAlchemy database sessions

---

#### Phase 2.4: iOS Saves Tokens

**iOS Files:**

**1. `ios/InboxIQ/Services/KeychainService.swift`** - Save Tokens
```swift
class KeychainService {
    func saveTokens(accessToken: String, refreshToken: String) {
        let accessQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "inboxiq.access_token",
            kSecValueData as String: accessToken.data(using: .utf8)!,
            kSecAttrAccessGroup as String: "com.inboxiq.shared"
        ]
        
        SecItemDelete(accessQuery as CFDictionary)
        SecItemAdd(accessQuery as CFDictionary, nil)
        
        // Same for refresh token
    }
}
```
**Purpose:**
- Saves tokens to iOS Keychain (encrypted by iOS)
- Survives app deletion
- Shared across app extensions

**2. `ios/InboxIQ/ViewModels/AuthViewModel.swift`** - Update State
```swift
@Published var isAuthenticated = false

func handleAuthSuccess() {
    DispatchQueue.main.async {
        self.isAuthenticated = true
    }
}
```
**Purpose:** Triggers navigation from LoginView to HomeView

---

**Summary - Login Flow:**
```
User taps "Sign in with Google"
    ↓
iOS → Backend: GET /auth/google/authorize
    ↓
Backend → Returns OAuth URL
    ↓
iOS opens Safari with Google login
    ↓
User authenticates with Google
    ↓
Google redirects: inboxiq://auth/callback?code=AUTH_CODE
    ↓
iOS → Backend: POST /auth/google/callback {code}
    ↓
Backend:
    - Exchanges code with Google
    - Creates/updates User in database
    - Encrypts Google refresh token
    - Generates JWT access + refresh tokens
    - Returns JWT tokens to iOS
    ↓
iOS saves tokens to Keychain
    ↓
iOS navigates to HomeView (inbox)
```

---

## Part 3: First Email Sync

### Step 6: App Fetches Emails from Gmail

**User Action:** App automatically syncs on HomeView appearance

**What Happens:**
- App sends sync request to backend (with JWT)
- Backend verifies JWT
- Backend decrypts user's Google token
- Backend fetches emails from Gmail API
- Backend saves emails to PostgreSQL
- Backend queues emails for AI categorization
- Backend returns email list to app
- App saves emails to Core Data
- UI updates with email list

---

#### Phase 3.1: Trigger Sync

**iOS Files:**

**1. `ios/InboxIQ/Views/Home/HomeView.swift`** - Main Inbox View
```swift
struct HomeView: View {
    @StateObject var viewModel = EmailListViewModel()
    @StateObject var syncViewModel = SyncViewModel()
    
    var body: some View {
        NavigationView {
            EmailListView(emails: viewModel.emails)
                .onAppear {
                    syncViewModel.syncEmails()
                }
                .refreshable {
                    await syncViewModel.syncEmails()
                }
        }
    }
}
```
**Purpose:**
- Main inbox screen
- Triggers sync on appear
- Supports pull-to-refresh

**2. `ios/InboxIQ/ViewModels/SyncViewModel.swift`** - Sync Coordinator
```swift
class SyncViewModel: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    private let syncService = SyncService.shared
    
    func syncEmails() async {
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            try await syncService.performSync()
            lastSyncDate = Date()
        } catch {
            // Handle error
        }
    }
}
```
**Purpose:** Manages sync state and coordinates with SyncService

**3. `ios/InboxIQ/Services/SyncService.swift`** - Sync Implementation
```swift
class SyncService {
    private let apiClient = APIClient.shared
    private let persistenceController = PersistenceController.shared
    
    func performSync() async throws {
        // Step 1: Trigger backend sync
        let syncResponse: SyncResponse = try await apiClient.post("/sync")
        
        // Step 2: Fetch email list
        let emails: [Email] = try await apiClient.get("/emails")
        
        // Step 3: Save to Core Data
        await saveToCoreData(emails)
    }
    
    private func saveToCoreData(_ emails: [Email]) async {
        let context = persistenceController.container.viewContext
        
        for email in emails {
            let emailEntity = EmailEntity(context: context)
            emailEntity.id = email.id
            emailEntity.gmailId = email.gmailId
            emailEntity.subject = email.subject
            emailEntity.sender = email.sender
            emailEntity.snippet = email.snippet
            emailEntity.receivedAt = email.receivedAt
            emailEntity.category = email.category
            emailEntity.isUnread = email.isUnread
        }
        
        try? context.save()
    }
}
```
**Purpose:**
- Triggers backend sync
- Fetches updated email list
- Saves to Core Data for offline access

**4. `ios/InboxIQ/Services/APIClient.swift`** - Authenticated Requests
```swift
class APIClient {
    func post<T: Decodable>(_ endpoint: String, body: Encodable? = nil) async throws -> T {
        var request = URLRequest(url: URL(string: baseURL + endpoint)!)
        request.httpMethod = "POST"
        
        // Add JWT token to header
        if let accessToken = KeychainService.shared.getAccessToken() {
            request.setValue(
                "Bearer \(accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        }
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle 401 (token expired) - auto-refresh
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            try await refreshAccessToken()
            return try await post(endpoint, body: body)  // Retry
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```
**Purpose:**
- Adds JWT token to all requests
- Handles 401 errors (auto-refresh token)
- Retries failed requests after refresh

---

#### Phase 3.2: Backend Processes Sync Request

**Backend Files:**

**1. `backend/app/api/sync.py`** - Sync Endpoint
```python
from fastapi import APIRouter, Depends
from app.api.deps import get_current_user
from app.services.sync_service import SyncService

router = APIRouter()

@router.post("/sync")
async def sync_emails(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Sync user's emails from Gmail"""
    sync_service = SyncService(db)
    result = await sync_service.sync_emails(user)
    
    return {
        "synced": result["synced_count"],
        "queued_for_ai": result["queued_count"]
    }
```
**Purpose:** Endpoint for syncing emails (requires authentication)

**2. `backend/app/api/deps.py`** - Authentication Dependency
```python
from fastapi import Depends, HTTPException, Header
from app.utils.security import verify_jwt

async def get_current_user(
    authorization: str = Header(None),
    db: AsyncSession = Depends(get_db)
) -> User:
    """Extract and verify JWT token, return User"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing token")
    
    token = authorization.replace("Bearer ", "")
    
    try:
        payload = verify_jwt(token)
        user_id = payload["user_id"]
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user = await db.query(User).filter(User.id == user_id).first()
    
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    return user
```
**Purpose:**
- Extracts JWT from Authorization header
- Verifies JWT signature
- Returns authenticated User object
- Raises 401 if invalid/expired

**3. `backend/app/services/sync_service.py`** - Sync Logic
```python
from app.services.gmail_service import GmailService
from app.models.email import Email
from app.models.ai_queue import AIQueue

class SyncService:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def sync_emails(self, user: User) -> dict:
        """Sync emails from Gmail"""
        gmail_service = GmailService(user)
        
        # Determine sync type
        if user.last_sync:
            # Delta sync (only new emails since last sync)
            messages = await gmail_service.get_history_since(
                user.last_history_id
            )
        else:
            # Initial sync (last 7 days)
            messages = await gmail_service.list_messages(
                query="after:7d",
                max_results=100
            )
        
        synced_count = 0
        queued_count = 0
        
        for message_id in messages:
            # Fetch full message
            message = await gmail_service.get_message(message_id)
            
            # Save to database
            email = Email(
                user_id=user.id,
                gmail_id=message["id"],
                subject=message["subject"],
                sender=message["from"],
                snippet=message["snippet"],
                body=message["body"],
                received_at=message["date"],
                is_unread=message["is_unread"]
            )
            
            self.db.add(email)
            synced_count += 1
            
            # Queue for AI categorization
            ai_queue_item = AIQueue(
                email_id=email.id,
                status="pending"
            )
            self.db.add(ai_queue_item)
            queued_count += 1
        
        # Update user's last sync
        user.last_sync = datetime.utcnow()
        user.last_history_id = messages[-1]["historyId"]
        
        await self.db.commit()
        
        return {
            "synced_count": synced_count,
            "queued_count": queued_count
        }
```
**Purpose:**
- Determines sync type (initial vs delta)
- Fetches emails from Gmail
- Saves emails to database
- Queues emails for AI processing

**4. `backend/app/services/gmail_service.py`** - Gmail API Wrapper
```python
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials
from app.utils.security import decrypt
import asyncio

class GmailService:
    def __init__(self, user: User):
        self.user = user
        self.service = self._build_service()
    
    def _build_service(self):
        """Create Gmail API client"""
        # Decrypt user's Google refresh token
        refresh_token = decrypt(self.user.google_refresh_token)
        
        credentials = Credentials(
            token=None,
            refresh_token=refresh_token,
            token_uri="https://oauth2.googleapis.com/token",
            client_id=settings.GOOGLE_CLIENT_ID,
            client_secret=settings.GOOGLE_CLIENT_SECRET
        )
        
        return build("gmail", "v1", credentials=credentials)
    
    async def list_messages(self, query: str, max_results: int = 100):
        """List Gmail messages matching query"""
        # Gmail API is blocking, run in thread pool
        def _list():
            result = self.service.users().messages().list(
                userId="me",
                q=query,
                maxResults=max_results
            ).execute()
            return result.get("messages", [])
        
        return await asyncio.to_thread(_list)
    
    async def get_message(self, message_id: str):
        """Get full message details"""
        def _get():
            message = self.service.users().messages().get(
                userId="me",
                id=message_id,
                format="full"
            ).execute()
            
            # Parse message
            headers = {h["name"]: h["value"] for h in message["payload"]["headers"]}
            
            return {
                "id": message["id"],
                "subject": headers.get("Subject", ""),
                "from": headers.get("From", ""),
                "date": headers.get("Date", ""),
                "snippet": message.get("snippet", ""),
                "body": self._extract_body(message),
                "is_unread": "UNREAD" in message.get("labelIds", []),
                "historyId": message.get("historyId")
            }
        
        return await asyncio.to_thread(_get)
    
    def _extract_body(self, message: dict) -> str:
        """Extract email body from Gmail message"""
        # Handle multipart messages, HTML/plain text, etc.
        # (Simplified for this example)
        payload = message.get("payload", {})
        parts = payload.get("parts", [])
        
        for part in parts:
            if part["mimeType"] == "text/plain":
                data = part["body"]["data"]
                return base64.urlsafe_b64decode(data).decode()
        
        return message.get("snippet", "")
```
**Purpose:**
- Wraps Gmail API
- Decrypts user's Google token
- Fetches messages (list, get, history)
- Parses email content
- Runs blocking Gmail API calls in thread pool (async compatibility)

**5. `backend/app/models/email.py`** - Email Database Model
```python
class Email(Base):
    __tablename__ = "emails"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    gmail_id = Column(String(255), unique=True, nullable=False)
    subject = Column(String(500), nullable=True)
    sender = Column(String(255), nullable=True)
    snippet = Column(Text, nullable=True)
    body = Column(Text, nullable=True)
    received_at = Column(DateTime, nullable=False)
    category = Column(String(50), nullable=True)  # Primary, Social, etc.
    is_unread = Column(Boolean, default=True)
    is_archived = Column(Boolean, default=False)
    synced_at = Column(DateTime, server_default=func.now())
    
    user = relationship("User", back_populates="emails")
    ai_queue = relationship("AIQueue", back_populates="email", uselist=False)
```
**Purpose:** SQLAlchemy model for emails table

**6. `backend/app/models/ai_queue.py`** - AI Processing Queue
```python
class AIQueue(Base):
    __tablename__ = "ai_queue"
    
    id = Column(Integer, primary_key=True)
    email_id = Column(Integer, ForeignKey("emails.id"))
    status = Column(String(20), default="pending")  # pending, processing, completed, failed
    attempts = Column(Integer, default=0)
    error_message = Column(Text, nullable=True)
    created_at = Column(DateTime, server_default=func.now())
    processed_at = Column(DateTime, nullable=True)
    
    email = relationship("Email", back_populates="ai_queue")
```
**Purpose:** Tracks emails waiting for AI categorization

---

#### Phase 3.3: Return Email List to iOS

**Backend Files:**

**1. `backend/app/api/emails.py`** - Email List Endpoint
```python
@router.get("/emails")
async def get_emails(
    skip: int = 0,
    limit: int = 50,
    category: str = None,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user's emails (paginated)"""
    query = db.query(Email).filter(
        Email.user_id == user.id,
        Email.is_archived == False
    )
    
    if category:
        query = query.filter(Email.category == category)
    
    emails = await query.order_by(
        Email.received_at.desc()
    ).offset(skip).limit(limit).all()
    
    return [EmailSchema.from_orm(e) for e in emails]
```
**Purpose:** Returns paginated email list (with optional category filter)

**2. `backend/app/schemas/email.py`** - Email Response Schema
```python
from pydantic import BaseModel
from datetime import datetime

class EmailSchema(BaseModel):
    id: int
    gmail_id: str
    subject: str
    sender: str
    snippet: str
    received_at: datetime
    category: str | None
    is_unread: bool
    
    class Config:
        from_attributes = True
```
**Purpose:** Defines email JSON structure for API responses

---

#### Phase 3.4: iOS Saves to Core Data and Displays

**iOS Files:**

**1. `ios/InboxIQ/CoreData/InboxIQ.xcdatamodeld`** - Core Data Model
```xml
<entity name="EmailEntity">
    <attribute name="id" attributeType="Integer 64"/>
    <attribute name="gmailId" attributeType="String"/>
    <attribute name="subject" attributeType="String"/>
    <attribute name="sender" attributeType="String"/>
    <attribute name="snippet" attributeType="String"/>
    <attribute name="receivedAt" attributeType="Date"/>
    <attribute name="category" attributeType="String" optional="YES"/>
    <attribute name="isUnread" attributeType="Boolean" defaultValue="YES"/>
    <relationship name="category" toMany="NO" deletionRule="Nullify" destinationEntity="CategoryEntity"/>
</entity>
```
**Purpose:** Defines Core Data schema (local SQLite)

**2. `ios/InboxIQ/ViewModels/EmailListViewModel.swift`** - Email List State
```swift
class EmailListViewModel: ObservableObject {
    @Published var emails: [Email] = []
    @Published var selectedCategory: String? = nil
    
    private let context = PersistenceController.shared.container.viewContext
    
    init() {
        fetchEmails()
    }
    
    func fetchEmails() {
        let request: NSFetchRequest<EmailEntity> = EmailEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "receivedAt", ascending: false)
        ]
        
        if let category = selectedCategory {
            request.predicate = NSPredicate(
                format: "category == %@",
                category
            )
        }
        
        do {
            let entities = try context.fetch(request)
            emails = entities.map { Email(from: $0) }
        } catch {
            print("Failed to fetch emails: \(error)")
        }
    }
}
```
**Purpose:**
- Fetches emails from Core Data
- Observes changes (SwiftUI auto-updates)
- Supports category filtering

**3. `ios/InboxIQ/Views/Home/EmailListView.swift`** - Email List UI
```swift
struct EmailListView: View {
    @ObservedObject var viewModel: EmailListViewModel
    
    var body: some View {
        List(viewModel.emails) { email in
            NavigationLink(destination: EmailDetailView(email: email)) {
                EmailRowView(email: email)
            }
        }
    }
}
```
**Purpose:** Displays list of emails

**4. `ios/InboxIQ/Views/Home/EmailRowView.swift`** - Email Row
```swift
struct EmailRowView: View {
    let email: Email
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(email.sender)
                    .font(.subheadline)
                    .fontWeight(email.isUnread ? .semibold : .regular)
                
                Text(email.subject)
                    .font(.body)
                    .lineLimit(1)
                
                Text(email.snippet)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(email.receivedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if let category = email.category {
                    CategoryBadge(category: category)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
```
**Purpose:** Displays individual email in list (sender, subject, snippet, time, category)

---

**Summary - Email Sync Flow:**
```
HomeView appears
    ↓
iOS → Backend: POST /sync (with JWT)
    ↓
Backend verifies JWT
    ↓
Backend decrypts Google token
    ↓
Backend → Gmail API: Fetch emails
    ↓
Backend saves emails to PostgreSQL
    ↓
Backend queues emails for AI (ai_queue table)
    ↓
Backend → iOS: {synced: 42, queued_for_ai: 42}
    ↓
iOS → Backend: GET /emails
    ↓
Backend → iOS: [email list with categories]
    ↓
iOS saves to Core Data
    ↓
UI updates (SwiftUI observes Core Data)
    ↓
User sees inbox with emails
```

---

## Part 4: AI Email Categorization (Background)

### Step 8: Worker Processes AI Queue

**What Happens:**
- Separate worker process runs continuously
- Polls `ai_queue` table every 5 seconds
- Finds emails with `status = "pending"`
- Sends email content to Claude AI
- Claude returns category (Primary, Social, Promotions, etc.)
- Worker updates email category in database
- Next sync: iOS sees updated categories

---

**Backend Files:**

**1. `backend/worker.py`** - Background Worker Process
```python
import asyncio
import time
from app.database import AsyncSessionLocal
from app.models.ai_queue import AIQueue
from app.models.email import Email
from app.services.ai_service import AIService
from app.utils.logger import get_logger

logger = get_logger(__name__)

async def process_ai_queue():
    """Main worker loop"""
    logger.info("AI worker started")
    
    while True:
        try:
            async with AsyncSessionLocal() as db:
                # Find pending items (batch of 10)
                queue_items = await db.query(AIQueue).filter(
                    AIQueue.status == "pending"
                ).limit(10).all()
                
                if not queue_items:
                    await asyncio.sleep(5)  # Wait 5 seconds
                    continue
                
                logger.info(f"Processing {len(queue_items)} emails")
                
                ai_service = AIService()
                
                for item in queue_items:
                    try:
                        # Update status
                        item.status = "processing"
                        item.attempts += 1
                        await db.commit()
                        
                        # Get email
                        email = await db.query(Email).filter(
                            Email.id == item.email_id
                        ).first()
                        
                        # Categorize with AI
                        result = await ai_service.categorize_email(email)
                        
                        # Update email
                        email.category = result["category"]
                        
                        # Update queue
                        item.status = "completed"
                        item.processed_at = datetime.utcnow()
                        
                        await db.commit()
                        
                        logger.info(
                            f"Categorized email {email.id}: {result['category']}"
                        )
                        
                    except Exception as e:
                        logger.error(f"Failed to process email: {e}")
                        
                        # Update queue with error
                        item.status = "failed"
                        item.error_message = str(e)
                        
                        # Retry limit
                        if item.attempts >= 3:
                            item.status = "failed_max_attempts"
                        
                        await db.commit()
                
        except Exception as e:
            logger.error(f"Worker error: {e}")
            await asyncio.sleep(10)

if __name__ == "__main__":
    asyncio.run(process_ai_queue())
```
**Purpose:**
- Runs as separate process (alongside backend)
- Polls database for pending emails
- Processes in batches (10 at a time)
- Retries failures (max 3 attempts)
- Logs all activity

**2. `backend/app/services/ai_service.py`** - Claude AI Integration
```python
from anthropic import AsyncAnthropic
import json

class AIService:
    def __init__(self):
        self.client = AsyncAnthropic(api_key=settings.ANTHROPIC_API_KEY)
    
    async def categorize_email(self, email: Email) -> dict:
        """Categorize email using Claude AI"""
        
        prompt = f"""Categorize this email into one of these categories:
- Primary: Important personal emails, work, urgent
- Social: Social networks, friend updates, event invitations
- Promotions: Marketing, ads, deals, newsletters
- Updates: Automated notifications, receipts, confirmations
- Forums: Discussion groups, mailing lists

Email details:
From: {email.sender}
Subject: {email.subject}
Content: {email.snippet}

Respond with JSON only:
{{"category": "Primary", "confidence": 0.95}}
"""
        
        try:
            message = await self.client.messages.create(
                model="claude-3-haiku-20240307",  # Cheapest Claude model
                max_tokens=100,
                temperature=0,
                messages=[{
                    "role": "user",
                    "content": prompt
                }]
            )
            
            response_text = message.content[0].text
            result = self._safe_json_parse(response_text)
            
            return result
            
        except Exception as e:
            logger.error(f"AI categorization failed: {e}")
            # Fallback category
            return {
                "category": "Primary",
                "confidence": 0.0
            }
    
    def _safe_json_parse(self, text: str) -> dict:
        """Parse JSON with error handling"""
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            # Try to extract JSON from markdown code blocks
            if "```json" in text:
                text = text.split("```json")[1].split("```")[0]
                return json.loads(text)
            
            # Fallback
            return {"category": "Primary", "confidence": 0.0}
```
**Purpose:**
- Sends email content to Claude AI (Haiku model)
- Parses JSON response
- Handles errors gracefully (fallback category)
- Uses cheapest Claude model (cost optimization)

---

**Summary - AI Categorization Flow:**
```
Worker polls ai_queue table (every 5 seconds)
    ↓
Find emails with status = "pending"
    ↓
For each email:
    ↓
Update status = "processing"
    ↓
Send to Claude AI:
    - Email sender, subject, snippet
    - Request category
    ↓
Claude returns: {"category": "Primary", "confidence": 0.92}
    ↓
Update email.category = "Primary"
    ↓
Update ai_queue.status = "completed"
    ↓
Next iOS sync: User sees category badge
```

---

## Part 5: User Interactions

### Step 10: User Taps an Email

**iOS Files:**

**1. `ios/InboxIQ/Views/Detail/EmailDetailView.swift`** - Email Detail Screen
```swift
struct EmailDetailView: View {
    let email: Email
    @State private var showActions = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(email.sender)
                            .font(.headline)
                        Text(email.receivedAt.formatted())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let category = email.category {
                        CategoryBadge(category: category)
                    }
                }
                
                // Subject
                Text(email.subject)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Divider()
                
                // Body
                Text(email.body)
                    .font(.body)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: archiveEmail) {
                        Label("Archive", systemImage: "archivebox")
                    }
                    Button(action: deleteEmail) {
                        Label("Delete", systemImage: "trash")
                    }
                    Button(action: reply) {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    func archiveEmail() {
        Task {
            try? await APIClient.shared.post("/emails/\(email.id)/archive")
        }
    }
}
```
**Purpose:**
- Displays full email content
- Provides action menu (archive, delete, reply)
- Calls backend API for actions

---

### Step 11: User Archives Email

**Backend Files:**

**1. `backend/app/api/emails.py`** - Email Actions
```python
@router.post("/emails/{email_id}/archive")
async def archive_email(
    email_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Archive an email"""
    email = await db.query(Email).filter(
        Email.id == email_id,
        Email.user_id == user.id
    ).first()
    
    if not email:
        raise HTTPException(status_code=404, detail="Email not found")
    
    # Archive in Gmail
    gmail_service = GmailService(user)
    await gmail_service.archive_message(email.gmail_id)
    
    # Update local database
    email.is_archived = True
    await db.commit()
    
    return {"status": "archived"}

@router.delete("/emails/{email_id}")
async def delete_email(
    email_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete an email"""
    email = await db.query(Email).filter(
        Email.id == email_id,
        Email.user_id == user.id
    ).first()
    
    if not email:
        raise HTTPException(status_code=404, detail="Email not found")
    
    # Delete from Gmail
    gmail_service = GmailService(user)
    await gmail_service.trash_message(email.gmail_id)
    
    # Delete from database
    await db.delete(email)
    await db.commit()
    
    return {"status": "deleted"}
```
**Purpose:** Handles email actions (archive, delete, mark read, etc.)

**2. `backend/app/services/gmail_service.py`** - Gmail Actions
```python
async def archive_message(self, message_id: str):
    """Archive email in Gmail (remove INBOX label)"""
    def _archive():
        self.service.users().messages().modify(
            userId="me",
            id=message_id,
            body={"removeLabelIds": ["INBOX"]}
        ).execute()
    
    return await asyncio.to_thread(_archive)

async def trash_message(self, message_id: str):
    """Move email to trash in Gmail"""
    def _trash():
        self.service.users().messages().trash(
            userId="me",
            id=message_id
        ).execute()
    
    return await asyncio.to_thread(_trash)
```
**Purpose:** Performs actions in Gmail via API

---

## Part 6: Daily Digest Feature

### Step 12: User Enables Daily Digest

**iOS Files:**

**1. `ios/InboxIQ/Views/Settings/SettingsView.swift`** - Settings Screen
```swift
struct SettingsView: View {
    @State private var digestEnabled = false
    @State private var digestFrequency = 12 // hours
    
    var body: some View {
        Form {
            Section(header: Text("Daily Digest")) {
                Toggle("Enable Daily Digest", isOn: $digestEnabled)
                
                if digestEnabled {
                    Picker("Frequency", selection: $digestFrequency) {
                        Text("Every 12 hours").tag(12)
                        Text("Every 24 hours").tag(24)
                    }
                }
            }
        }
        .onChange(of: digestEnabled) { _ in
            updateDigestSettings()
        }
        .onChange(of: digestFrequency) { _ in
            updateDigestSettings()
        }
    }
    
    func updateDigestSettings() {
        Task {
            try? await APIClient.shared.post("/digest/settings", body: [
                "enabled": digestEnabled,
                "frequency_hours": digestFrequency
            ])
        }
    }
}
```
**Purpose:** Allows user to configure digest preferences

---

**Backend Files:**

**1. `backend/app/api/digest.py`** - Digest Endpoints
```python
@router.post("/digest/settings")
async def update_digest_settings(
    settings: DigestSettingsUpdate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update user's digest preferences"""
    user_settings = await db.query(DigestSettings).filter(
        DigestSettings.user_id == user.id
    ).first()
    
    if not user_settings:
        user_settings = DigestSettings(user_id=user.id)
        db.add(user_settings)
    
    user_settings.enabled = settings.enabled
    user_settings.frequency_hours = settings.frequency_hours
    
    await db.commit()
    
    return {"status": "updated"}
```
**Purpose:** Saves user's digest preferences

**2. `backend/app/models/digest_settings.py`** - Digest Settings Model
```python
class DigestSettings(Base):
    __tablename__ = "digest_settings"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True)
    enabled = Column(Boolean, default=False)
    frequency_hours = Column(Integer, default=12)
    last_sent_at = Column(DateTime, nullable=True)
    
    user = relationship("User")
```
**Purpose:** Stores digest preferences per user

**3. `backend/app/services/digest_service.py`** - Digest Generation
```python
class DigestService:
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def should_send_digest(self, user: User) -> bool:
        """Check if digest should be sent"""
        settings = await self.db.query(DigestSettings).filter(
            DigestSettings.user_id == user.id
        ).first()
        
        if not settings or not settings.enabled:
            return False
        
        if not settings.last_sent_at:
            return True
        
        hours_since_last = (
            datetime.utcnow() - settings.last_sent_at
        ).total_seconds() / 3600
        
        return hours_since_last >= settings.frequency_hours
    
    async def generate_digest(self, user: User) -> dict:
        """Generate email digest"""
        settings = await self.db.query(DigestSettings).filter(
            DigestSettings.user_id == user.id
        ).first()
        
        # Get emails from last X hours
        since = datetime.utcnow() - timedelta(
            hours=settings.frequency_hours
        )
        
        emails = await self.db.query(Email).filter(
            Email.user_id == user.id,
            Email.received_at >= since
        ).all()
        
        if not emails:
            return None
        
        # Group by category
        by_category = {}
        for email in emails:
            category = email.category or "Uncategorized"
            if category not in by_category:
                by_category[category] = []
            by_category[category].append(email)
        
        # Summarize with AI
        ai_service = AIService()
        summary = await ai_service.summarize_emails(emails)
        
        return {
            "email_count": len(emails),
            "by_category": by_category,
            "summary": summary,
            "action_items": summary.get("action_items", [])
        }
    
    async def send_digest(self, user: User, digest: dict):
        """Send digest email to user"""
        # Format HTML email
        html = self._format_digest_html(digest)
        
        # Send via Gmail API
        gmail_service = GmailService(user)
        await gmail_service.send_message(
            to=user.email,
            subject=f"InboxIQ Digest: {digest['email_count']} new emails",
            html=html
        )
        
        # Update last_sent_at
        settings = await self.db.query(DigestSettings).filter(
            DigestSettings.user_id == user.id
        ).first()
        settings.last_sent_at = datetime.utcnow()
        await self.db.commit()
```
**Purpose:** Generates and sends email digest

**4. Worker Integration** - Add to `backend/worker.py`
```python
async def process_digests():
    """Check and send digests"""
    async with AsyncSessionLocal() as db:
        digest_service = DigestService(db)
        
        # Get all users with digest enabled
        users = await db.query(User).join(DigestSettings).filter(
            DigestSettings.enabled == True
        ).all()
        
        for user in users:
            if await digest_service.should_send_digest(user):
                digest = await digest_service.generate_digest(user)
                if digest:
                    await digest_service.send_digest(user, digest)

# Add to main worker loop
asyncio.create_task(process_digests())
```
**Purpose:** Worker periodically checks and sends digests

---

## Part 7: Token Refresh (Automatic)

### Step 13: Access Token Expires

**iOS Files:**

**1. `ios/InboxIQ/Services/APIClient.swift`** - Auto-Refresh Logic
```swift
class APIClient {
    private var isRefreshing = false
    private var refreshTask: Task<String, Error>?
    
    func request<T: Decodable>(_ endpoint: String) async throws -> T {
        // Add auth header
        var request = URLRequest(url: URL(string: baseURL + endpoint)!)
        if let token = KeychainService.shared.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Handle 401 - token expired
        if (response as? HTTPURLResponse)?.statusCode == 401 {
            // Prevent refresh loop on /auth/refresh endpoint
            guard !endpoint.contains("/auth/refresh") else {
                throw APIError.authenticationFailed
            }
            
            // Refresh token
            let newAccessToken = try await refreshAccessToken()
            
            // Retry request with new token
            request.setValue(
                "Bearer \(newAccessToken)",
                forHTTPHeaderField: "Authorization"
            )
            
            let (retryData, _) = try await URLSession.shared.data(for: request)
            return try JSONDecoder().decode(T.self, from: retryData)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    private func refreshAccessToken() async throws -> String {
        // Prevent multiple simultaneous refresh requests
        if let existingTask = refreshTask {
            return try await existingTask.value
        }
        
        let task = Task<String, Error> {
            guard let refreshToken = KeychainService.shared.getRefreshToken() else {
                throw APIError.noRefreshToken
            }
            
            let response: TokenResponse = try await post(
                "/auth/refresh",
                body: ["refresh_token": refreshToken]
            )
            
            // Save new access token
            KeychainService.shared.saveAccessToken(response.accessToken)
            
            // Optionally save new refresh token (if rotated)
            if let newRefreshToken = response.refreshToken {
                KeychainService.shared.saveRefreshToken(newRefreshToken)
            }
            
            return response.accessToken
        }
        
        refreshTask = task
        defer { refreshTask = nil }
        
        return try await task.value
    }
}
```
**Purpose:**
- Detects 401 errors (expired token)
- Automatically refreshes access token
- Retries original request
- Prevents refresh loops
- Handles concurrent refresh requests

---

**Backend Files:**

**1. `backend/app/api/auth.py`** - Refresh Endpoint
```python
@router.post("/auth/refresh")
async def refresh_access_token(
    request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """Refresh access token using refresh token"""
    auth_service = AuthService(db)
    
    try:
        tokens = await auth_service.refresh_access_token(
            request.refresh_token
        )
        return tokens
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
```
**Purpose:** Endpoint for refreshing tokens

**2. `backend/app/services/auth_service.py`** - Refresh Logic
```python
async def refresh_access_token(self, refresh_token_str: str) -> dict:
    """Generate new access token from refresh token"""
    
    # Verify refresh token
    try:
        payload = verify_jwt(refresh_token_str)
        user_id = payload["user_id"]
    except Exception:
        raise ValueError("Invalid refresh token")
    
    # Check if token exists in database (not revoked)
    token_hash = hash_token(refresh_token_str)
    db_token = await self.db.query(RefreshToken).filter(
        RefreshToken.token_hash == token_hash,
        RefreshToken.revoked == False
    ).first()
    
    if not db_token or db_token.expires_at < datetime.utcnow():
        raise ValueError("Refresh token expired or revoked")
    
    # Generate new access token
    access_token = jwt.encode(
        {
            "user_id": user_id,
            "exp": datetime.utcnow() + timedelta(minutes=15)
        },
        settings.JWT_SECRET,
        algorithm=settings.JWT_ALGORITHM
    )
    
    # Optional: Refresh token rotation (more secure)
    if settings.REFRESH_TOKEN_ROTATION:
        # Generate new refresh token
        new_refresh_token = jwt.encode(
            {
                "user_id": user_id,
                "exp": datetime.utcnow() + timedelta(days=7)
            },
            settings.JWT_SECRET,
            algorithm=settings.JWT_ALGORITHM
        )
        
        # Revoke old refresh token
        db_token.revoked = True
        
        # Save new refresh token
        new_token_hash = hash_token(new_refresh_token)
        new_db_token = RefreshToken(
            user_id=user_id,
            token_hash=new_token_hash,
            expires_at=datetime.utcnow() + timedelta(days=7)
        )
        self.db.add(new_db_token)
        
        await self.db.commit()
        
        return {
            "access_token": access_token,
            "refresh_token": new_refresh_token,
            "token_type": "bearer"
        }
    
    # Return only new access token (no rotation)
    return {
        "access_token": access_token,
        "token_type": "bearer"
    }
```
**Purpose:**
- Verifies refresh token
- Checks database (not revoked)
- Generates new access token
- Optional: Token rotation (revoke old, issue new)

---

## Part 8: Background Sync (iOS)

### Step 14: iOS Background Fetch Triggers

**iOS Files:**

**1. `ios/InboxIQ/InboxIQApp.swift`** - Register Background Tasks
```swift
import BackgroundTasks

@main
struct InboxIQApp: App {
    init() {
        registerBackgroundTasks()
    }
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.inboxiq.sync",
            using: nil
        ) { task in
            handleBackgroundSync(task: task as! BGAppRefreshTask)
        }
    }
    
    func handleBackgroundSync(task: BGAppRefreshTask) {
        let syncService = SyncService.shared
        
        task.expirationHandler = {
            // iOS is killing the task
            syncService.cancelSync()
        }
        
        Task {
            do {
                try await syncService.performBackgroundSync()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
            
            // Schedule next background fetch
            scheduleBackgroundSync()
        }
    }
    
    func scheduleBackgroundSync() {
        let request = BGAppRefreshTaskRequest(
            identifier: "com.inboxiq.sync"
        )
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min
        
        try? BGTaskScheduler.shared.submit(request)
    }
}
```
**Purpose:**
- Registers background fetch task
- Handles iOS waking app in background
- Schedules next background fetch

**2. `ios/InboxIQ/Services/SyncService.swift`** - Background Sync
```swift
func performBackgroundSync() async throws {
    // Optimized for 30-second iOS limit
    
    // 1. Quick sync (delta only)
    let response: SyncResponse = try await apiClient.post("/sync")
    
    // 2. Fetch only new emails (limit 20)
    let newEmails: [Email] = try await apiClient.get(
        "/emails?limit=20&since=\(lastSyncDate)"
    )
    
    // 3. Update Core Data silently
    await updateCoreDataInBackground(newEmails)
    
    // 4. Update badge count
    UNUserNotificationCenter.current().setBadgeCount(newEmails.filter { $0.isUnread }.count)
}
```
**Purpose:**
- Quick sync (optimized for 30-second limit)
- Updates local cache
- Updates badge count
- No UI updates (background)

**3. `ios/Entitlements.plist`** - Enable Background Modes
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```
**Purpose:** Declares background capabilities to iOS

---

## Part 9: Deployment (Railway)

### Step 15: Deploy to Production

**Infrastructure Files:**

**1. `infrastructure/scripts/deploy.sh`** - Deployment Script
```bash
#!/bin/bash
set -e

echo "🚀 InboxIQ Deployment Script"

# Pre-flight checks
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not installed"
    exit 1
fi

if [[ -n $(git status -s) ]]; then
    echo "⚠️  Uncommitted changes detected"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# Environment selection
ENV=${1:-production}
echo "📦 Deploying to: $ENV"

# Run migrations
echo "🗄️  Running database migrations..."
./infrastructure/scripts/run-migrations.sh --env $ENV

# Deploy backend
echo "🚀 Deploying backend service..."
railway up --service backend --environment $ENV

# Deploy worker
echo "⚙️  Deploying worker service..."
railway up --service worker --environment $ENV

# Health checks
echo "🏥 Running health checks..."
./infrastructure/scripts/test-backend.sh --env $ENV

echo "✅ Deployment complete!"
```
**Purpose:**
- Pre-flight checks (CLI installed, git clean)
- Runs database migrations
- Deploys backend + worker
- Runs health checks
- Auto-rollback on failure

**2. `infrastructure/railway/railway.json`** - Railway Configuration
```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "infrastructure/railway/backend.Dockerfile"
  },
  "deploy": {
    "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port $PORT",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10,
    "healthcheckPath": "/health",
    "healthcheckTimeout": 30
  },
  "services": [
    {
      "name": "backend",
      "dockerfile": "infrastructure/railway/backend.Dockerfile",
      "env": {
        "DATABASE_URL": "${{Postgres.DATABASE_URL}}",
        "REDIS_URL": "${{Redis.REDIS_URL}}"
      }
    },
    {
      "name": "worker",
      "dockerfile": "infrastructure/railway/worker.Dockerfile",
      "env": {
        "DATABASE_URL": "${{Postgres.DATABASE_URL}}"
      }
    }
  ]
}
```
**Purpose:**
- Defines two services (backend, worker)
- Specifies Dockerfiles
- Auto-injects database/Redis URLs
- Health check configuration
- Restart policies

**3. `infrastructure/railway/backend.Dockerfile`** - Backend Container
```dockerfile
# Stage 1: Builder
FROM python:3.11-slim as builder

WORKDIR /app

# Install dependencies
COPY backend/requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

WORKDIR /app

# Copy dependencies from builder
COPY --from=builder /root/.local /root/.local

# Copy application code
COPY backend/app ./app
COPY backend/alembic ./alembic
COPY backend/alembic.ini .

# Create non-root user
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Ensure PATH includes user packages
ENV PATH=/root/.local/bin:$PATH

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Run migrations on startup, then start app
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT"]
```
**Purpose:**
- Multi-stage build (smaller image)
- Installs dependencies
- Copies application code
- Runs as non-root user (security)
- Auto-runs migrations on startup
- Health check integrated

**4. `infrastructure/railway/worker.Dockerfile`** - Worker Container
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY backend/app ./app
COPY backend/worker.py .

RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# Worker doesn't need health check (no HTTP)
CMD ["python", "worker.py"]
```
**Purpose:**
- Simpler than backend (no HTTP)
- Runs worker.py continuously
- No health check (not HTTP service)

**5. `infrastructure/docker-compose.yml`** - Local Development
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: inboxiq
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    command: redis-server --requirepass redis_password
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: ../backend
      dockerfile: ../infrastructure/railway/backend.Dockerfile
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/inboxiq
      REDIS_URL: redis://:redis_password@redis:6379
      JWT_SECRET: dev_secret_key
      ENCRYPTION_KEY: dev_encryption_key
      GOOGLE_CLIENT_ID: ${GOOGLE_CLIENT_ID}
      GOOGLE_CLIENT_SECRET: ${GOOGLE_CLIENT_SECRET}
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "alembic upgrade head &&
             uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

  worker:
    build:
      context: ../backend
      dockerfile: ../infrastructure/railway/worker.Dockerfile
    environment:
      DATABASE_URL: postgresql://postgres:postgres@postgres:5432/inboxiq
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
    depends_on:
      postgres:
        condition: service_healthy
    command: python worker.py

volumes:
  postgres_data:
```
**Purpose:**
- Full local development environment
- PostgreSQL + Redis + Backend + Worker
- Health checks ensure services start in order
- Hot reload for development
- Uses same Dockerfiles as production

**6. `infrastructure/.env.example`** - Environment Variables Template
```bash
# Server Configuration
PORT=8000
ENVIRONMENT=production
DEBUG=false
LOG_LEVEL=info

# Database
DATABASE_URL=postgresql://user:password@host:5432/database
DATABASE_POOL_SIZE=10
DATABASE_MAX_OVERFLOW=20

# Redis
REDIS_URL=redis://:password@host:6379

# JWT Authentication
JWT_SECRET=your-super-secret-key-change-this
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7
REFRESH_TOKEN_ROTATION=true

# Encryption (for Google tokens)
ENCRYPTION_KEY=your-fernet-key-44-chars-base64

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
OAUTH_REDIRECT_URI=https://your-app.railway.app/auth/callback

# Anthropic (Claude AI)
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-3-haiku-20240307
ANTHROPIC_MAX_TOKENS=100
ANTHROPIC_TEMPERATURE=0

# Monitoring (Sentry)
SENTRY_DSN=https://...@sentry.io/...
SENTRY_ENVIRONMENT=production
SENTRY_TRACES_SAMPLE_RATE=0.1

# Rate Limiting
RATE_LIMIT_ENABLED=true
RATE_LIMIT_PER_MINUTE=60

# Worker
WORKER_BATCH_SIZE=10
WORKER_POLL_INTERVAL=5
```
**Purpose:**
- Documents all environment variables
- Provides examples
- Used as template for deployment

---

## Key Files Summary

### **Most Important Backend Files**

1. **`backend/app/main.py`** (100 lines)
   - FastAPI application entry point
   - Registers all API routers
   - CORS configuration
   - Startup/shutdown events

2. **`backend/app/services/auth_service.py`** (300 lines)
   - OAuth 2.0 flow with Google
   - JWT token generation/verification
   - Token encryption/hashing
   - User creation/management

3. **`backend/app/services/gmail_service.py`** (250 lines)
   - Gmail API wrapper
   - Email fetching (list, get, history)
   - Email actions (archive, delete, send)
   - Async/await with thread pool

4. **`backend/app/services/sync_service.py`** (200 lines)
   - Email synchronization logic
   - Initial vs delta sync
   - Queue management for AI

5. **`backend/app/services/ai_service.py`** (150 lines)
   - Claude AI integration
   - Email categorization
   - Prompt engineering
   - Error handling with fallbacks

6. **`backend/worker.py`** (100 lines)
   - Background AI processor
   - Polls ai_queue table
   - Batch processing
   - Retry logic

7. **`backend/app/database.py`** (50 lines)
   - SQLAlchemy async engine
   - Database session management
   - Connection pooling

8. **`backend/app/utils/security.py`** (100 lines)
   - Fernet encryption/decryption
   - JWT signing/verification
   - Token hashing (SHA-256)

---

### **Most Important iOS Files**

1. **`ios/InboxIQ/InboxIQApp.swift`** (80 lines)
   - App entry point
   - Environment setup
   - Navigation logic
   - Background task registration

2. **`ios/InboxIQ/Services/AuthService.swift`** (200 lines)
   - OAuth flow implementation
   - Token management
   - Keychain integration

3. **`ios/InboxIQ/Services/APIClient.swift`** (250 lines)
   - HTTP networking layer
   - JWT authentication
   - Auto-refresh on 401
   - Error handling

4. **`ios/InboxIQ/Services/SyncService.swift`** (180 lines)
   - Email synchronization
   - Core Data updates
   - Background sync
   - Pull-to-refresh

5. **`ios/InboxIQ/Services/KeychainService.swift`** (120 lines)
   - Secure token storage
   - Keychain access
   - Error handling

6. **`ios/InboxIQ/ViewModels/HomeViewModel.swift`** (150 lines)
   - Main screen logic
   - Email list state
   - Category filtering

7. **`ios/InboxIQ/ViewModels/AuthViewModel.swift`** (100 lines)
   - Authentication state
   - Login flow coordination

8. **`ios/InboxIQ/CoreData/PersistenceController.swift`** (80 lines)
   - Core Data stack
   - Local database management

9. **`ios/InboxIQ/Views/Home/HomeView.swift`** (120 lines)
   - Main inbox UI
   - Email list display
   - Category filters

10. **`ios/InboxIQ/Views/Detail/EmailDetailView.swift`** (150 lines)
    - Email detail screen
    - Action menu (archive, delete, reply)

---

### **Most Important Infrastructure Files**

1. **`infrastructure/railway/railway.json`** (100 lines)
   - Railway deployment configuration
   - Service definitions
   - Environment variable mapping

2. **`infrastructure/docker-compose.yml`** (150 lines)
   - Local development environment
   - All services (Postgres, Redis, Backend, Worker)
   - Health checks

3. **`infrastructure/scripts/deploy.sh`** (200 lines)
   - Automated deployment script
   - Pre-flight checks
   - Migration execution
   - Health checks
   - Rollback on failure

4. **`infrastructure/railway/backend.Dockerfile`** (40 lines)
   - Backend container definition
   - Multi-stage build
   - Security (non-root user)

5. **`infrastructure/.env.example`** (150 lines)
   - All environment variables documented
   - Examples and defaults

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      USER JOURNEY                           │
└─────────────────────────────────────────────────────────────┘

1. APP LAUNCH
   User opens app
       ↓
   InboxIQApp.swift checks Keychain
       ↓
   [Has tokens?] → Yes → HomeView
                → No  → LoginView

2. LOGIN
   User taps "Sign in with Google"
       ↓
   AuthViewModel → AuthService
       ↓
   iOS → Backend: GET /auth/google/authorize
       ↓
   Backend → AuthService → Returns OAuth URL
       ↓
   iOS opens Safari with Google login
       ↓
   User authenticates, Google redirects with code
       ↓
   iOS → Backend: POST /auth/google/callback {code}
       ↓
   Backend:
     - Exchange code with Google
     - Create User in database
     - Encrypt Google refresh_token
     - Generate JWT tokens
       ↓
   Backend → iOS: {access_token, refresh_token}
       ↓
   iOS saves to Keychain → Navigate to HomeView

3. EMAIL SYNC
   HomeView appears → SyncViewModel.syncEmails()
       ↓
   iOS → Backend: POST /sync (with JWT)
       ↓
   Backend:
     - Verify JWT (get_current_user)
     - Decrypt Google token
     - Fetch from Gmail API
     - Save emails to PostgreSQL
     - Queue for AI (ai_queue table)
       ↓
   Backend → iOS: {synced: 42, queued: 42}
       ↓
   iOS → Backend: GET /emails
       ↓
   Backend → iOS: [email list]
       ↓
   iOS → Core Data (save)
       ↓
   UI updates (SwiftUI observes Core Data)

4. AI CATEGORIZATION (Background)
   Worker polls ai_queue (every 5 seconds)
       ↓
   Find pending emails
       ↓
   For each email:
     Worker → AIService.categorize_email()
         ↓
     AIService → Claude API (Haiku)
         ↓
     Claude → {category: "Primary", confidence: 0.92}
         ↓
     Update email.category in database
         ↓
     Update ai_queue.status = "completed"
       ↓
   Next iOS sync: Categories visible

5. USER TAPS EMAIL
   EmailRowView (tap) → Navigation
       ↓
   EmailDetailView displays full email
       ↓
   User can: Archive, Delete, Reply

6. ARCHIVE EMAIL
   EmailDetailView → archiveEmail()
       ↓
   iOS → Backend: POST /emails/{id}/archive
       ↓
   Backend:
     - Verify ownership
     - GmailService.archive_message()
     - Update email.is_archived = true
       ↓
   iOS removes from inbox view

7. TOKEN REFRESH (Automatic)
   iOS → Backend: Any request (with expired token)
       ↓
   Backend → 401 Unauthorized
       ↓
   APIClient detects 401
       ↓
   APIClient → Backend: POST /auth/refresh {refresh_token}
       ↓
   Backend:
     - Verify refresh_token
     - Check not revoked
     - Generate new access_token
     - Optional: Rotate refresh_token
       ↓
   Backend → iOS: {access_token, [refresh_token]}
       ↓
   iOS saves new token → Retry original request

8. DAILY DIGEST
   SettingsView → User enables digest (12 hours)
       ↓
   iOS → Backend: POST /digest/settings {enabled: true, frequency: 12}
       ↓
   Backend saves to digest_settings table
       ↓
   [Every hour] Worker checks: should_send_digest()
       ↓
   If due:
     DigestService.generate_digest()
         ↓
     Fetch recent emails, group by category
         ↓
     AIService.summarize_emails()
         ↓
     Format HTML email
         ↓
     GmailService.send_message() → User's inbox

9. BACKGROUND SYNC (iOS)
   [Every 15-30 min] iOS wakes app in background
       ↓
   BGTaskScheduler → handleBackgroundSync()
       ↓
   SyncService.performBackgroundSync()
       ↓
   Quick sync (delta only, limit 20)
       ↓
   Update Core Data silently
       ↓
   Update badge count
       ↓
   Schedule next background fetch

10. DEPLOYMENT
    Developer: ./infrastructure/scripts/deploy.sh
        ↓
    Pre-flight checks (Railway CLI, git clean)
        ↓
    Run migrations: alembic upgrade head
        ↓
    Railway: Build Docker images
        ↓
    Railway: Deploy backend service
        ↓
    Railway: Deploy worker service
        ↓
    Run health checks
        ↓
    If healthy: ✅ Deployment complete
    If unhealthy: ❌ Auto-rollback
```

---

## Complete Technology Map

```
┌────────────────────────────────────────────────────────────┐
│                       FRONTEND (iOS)                       │
├────────────────────────────────────────────────────────────┤
│ Language:  Swift                                           │
│ UI:        SwiftUI                                         │
│ Database:  Core Data (SQLite)                              │
│ Storage:   Keychain (tokens)                               │
│ Auth:      ASWebAuthenticationSession                      │
│ Network:   URLSession (async/await)                        │
│ Background: BGTaskScheduler                                │
└────────────────────────────────────────────────────────────┘
                            ↕ HTTPS
┌────────────────────────────────────────────────────────────┐
│                      BACKEND (Railway)                     │
├────────────────────────────────────────────────────────────┤
│ Language:  Python 3.11                                     │
│ Framework: FastAPI (async)                                 │
│ Database:  PostgreSQL 15 (SQLAlchemy)                      │
│ Cache:     Redis (rate limiting)                           │
│ Auth:      JWT (python-jose)                               │
│ Encryption: Fernet (cryptography)                          │
│ Logging:   structlog (JSON)                                │
│ Monitoring: Sentry                                         │
└────────────────────────────────────────────────────────────┘
                ↕                          ↕
┌───────────────────────┐    ┌──────────────────────────────┐
│   Gmail API (Google)  │    │  Claude AI (Anthropic)       │
├───────────────────────┤    ├──────────────────────────────┤
│ - List messages       │    │ Model: Haiku (cheapest)      │
│ - Get message         │    │ Task: Categorization         │
│ - History (delta)     │    │ Cost: ~$0.001 per email      │
│ - Archive/Delete      │    │ Response: JSON               │
│ - Send message        │    └──────────────────────────────┘
└───────────────────────┘
                ↕
┌────────────────────────────────────────────────────────────┐
│                    WORKER (Background)                     │
├────────────────────────────────────────────────────────────┤
│ Process:  Python worker.py                                 │
│ Task:     Poll ai_queue → Categorize → Update              │
│ Interval: 5 seconds                                        │
│ Batch:    10 emails at a time                              │
│ Retries:  Max 3 attempts                                   │
└────────────────────────────────────────────────────────────┘
```

---

## Security Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                         │
└────────────────────────────────────────────────────────────┘

1. TRANSPORT
   - HTTPS only (Railway enforced)
   - TLS 1.3
   - Certificate pinning (optional)

2. AUTHENTICATION
   - OAuth 2.0 with Google (industry standard)
   - JWT tokens (short-lived access, long-lived refresh)
   - Access token: 15 minutes
   - Refresh token: 7 days
   - Token rotation (optional, more secure)

3. STORAGE
   iOS:
   - Keychain (encrypted by iOS)
   - Core Data (unencrypted, but local only)
   
   Backend:
   - Google tokens: Fernet encrypted (AES-128)
   - JWT refresh tokens: SHA-256 hashed
   - Passwords: Not stored (OAuth only)

4. DATABASE
   - PostgreSQL with SSL
   - Connection pooling
   - SQL injection protected (ORM)
   - Row-level security (user_id checks)

5. API
   - Rate limiting (Redis-backed)
   - CORS configured
   - Security headers (HSTS, X-Frame-Options)
   - Request validation (Pydantic)

6. CONTAINERS
   - Non-root users
   - Minimal images (slim)
   - No secrets in images
   - Health checks

7. MONITORING
   - Sentry (error tracking)
   - Structured logging (no PII)
   - Failed login tracking
   - Anomaly detection
```

---

## Cost Breakdown

```
┌────────────────────────────────────────────────────────────┐
│                    MONTHLY COSTS                           │
└────────────────────────────────────────────────────────────┘

INFRASTRUCTURE (Railway)
  - Hobby Plan:           $5/month
  - PostgreSQL:           $10/month (shared)
  - Redis:                $5/month (shared)
  ────────────────────────────────
  Subtotal:               $20/month

AI COSTS (Claude Haiku)
  Assumptions:
  - 1000 users
  - 50 emails/user/day = 50,000 emails/day
  - 1,500,000 emails/month
  
  Haiku pricing:
  - Input: $0.25 per 1M tokens
  - Output: $1.25 per 1M tokens
  - Average: 200 tokens per email (input + output)
  
  Cost: 1,500,000 emails × 200 tokens = 300M tokens
        300M × ($0.25 + $1.25) / 1M = $450/month
  
  WITH OPTIMIZATIONS:
  - Caching (80% hit rate): $90/month
  - Batch processing: $45/month
  - Rule-based fallback: $20/month
  ────────────────────────────────
  Subtotal:               $20-450/month (depending on optimization)

TOTAL MONTHLY COST
  - Minimum (optimized):  $40/month
  - Maximum (unoptimized): $470/month
  - Target:               $100-150/month

COST PER USER (1000 users)
  - Minimum: $0.04/user/month
  - Maximum: $0.47/user/month
  - Target:  $0.10-0.15/user/month

PRICING TO USERS
  - Suggested: $4.99-9.99/month
  - Margin: 95-99% gross margin
  - Break-even: ~10-30 users
```

---

## Performance Metrics

```
┌────────────────────────────────────────────────────────────┐
│                  PERFORMANCE TARGETS                       │
└────────────────────────────────────────────────────────────┘

API RESPONSE TIMES
  - Health check:        < 50ms
  - Auth endpoints:      < 500ms
  - Email list:          < 200ms
  - Email detail:        < 100ms
  - Sync (100 emails):   < 3 seconds

DATABASE
  - Connection pool:     10-20 connections
  - Query timeout:       5 seconds
  - Index coverage:      95%+
  - Backup frequency:    Daily

AI PROCESSING
  - Worker throughput:   10 emails/batch
  - Processing time:     ~1-2 seconds/email
  - Queue backlog:       < 1000 emails
  - Retry limit:         3 attempts

iOS APP
  - Launch time:         < 2 seconds (cached)
  - Sync time:           < 5 seconds
  - Memory usage:        < 100 MB
  - Battery impact:      < 5%/hour

RELIABILITY
  - Backend uptime:      99.9% (8.7 hours/year downtime)
  - Error rate:          < 0.1%
  - Failed requests:     < 1%
```

---

## Conclusion

This walkthrough covered the complete InboxIQ system from user launch to production deployment. Every file serves a specific purpose in the architecture:

- **iOS app** handles UI, local storage, and user interactions
- **Backend API** manages authentication, Gmail sync, and data persistence
- **Worker process** handles AI categorization in background
- **Infrastructure** automates deployment and monitoring

The system is designed to be:
- **Secure** (OAuth, JWT, encryption)
- **Scalable** (async/await, connection pooling, caching)
- **Cost-effective** (Haiku model, optimizations)
- **Reliable** (health checks, retries, monitoring)
- **Maintainable** (clear separation of concerns, documentation)

---

**Document Status:** Complete  
**Version:** 1.0  
**Last Updated:** February 27, 2026  
**Total Pages:** ~80 pages  
**Word Count:** ~15,000 words
