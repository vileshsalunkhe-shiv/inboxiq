import Foundation

enum Constants {
    static let appName = "InboxIQ"
    static let apiBaseURL = URL(string: "http://localhost:8000")!
    static let oauthCallbackScheme = "http"  // Changed for ASWebAuthenticationSession
    static let oauthCallbackURL = "http://localhost:8000/auth/google/callback"
    static let oauthAuthorizeURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    static let keychainService = "com.inboxiq.ios"
    static let oauthClientId = "535816296321-a722g108h5cqt6ai2v1c7jma0200ij36.apps.googleusercontent.com"
    static let oauthScopes = ["https://www.googleapis.com/auth/gmail.modify", "openid", "email"]
    static let keychainAccessGroup = "$(AppIdentifierPrefix)com.inboxiq.shared"
    static let backgroundFetchInterval: TimeInterval = 60 * 15
}
