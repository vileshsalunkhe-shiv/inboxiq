import Foundation

enum Constants {
    static let appName = "InboxIQ"
    static let apiBaseURL = URL(string: "https://api.inboxiq.app")!
    static let oauthCallbackScheme = "inboxiq"
    static let oauthCallbackURL = "inboxiq://oauth/callback"
    static let oauthAuthorizeURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    static let keychainService = "com.inboxiq.ios"
    static let oauthClientId = "YOUR_GOOGLE_CLIENT_ID"
    static let oauthScopes = ["https://www.googleapis.com/auth/gmail.readonly", "email", "profile"]
    static let keychainAccessGroup = "$(AppIdentifierPrefix)com.inboxiq.shared"
    static let backgroundFetchInterval: TimeInterval = 60 * 15
}

enum APIPath {
    static let authLogin = "/auth/login"
    static let authRefresh = "/auth/refresh"
    static let authLogout = "/auth/logout"
    static let emails = "/emails"
    static let emailSync = "/emails/sync"
    static let categories = "/categories"
    static let digestSettings = "/digest/settings"
    static let pushRegister = "/push/register"
}

enum AppError: LocalizedError, Identifiable {
    case network(String)
    case auth(String)
    case decoding(String)
    case coreData(String)
    case unknown(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .network(let message): return "Network error: \(message)"
        case .auth(let message): return "Authentication error: \(message)"
        case .decoding(let message): return "Data error: \(message)"
        case .coreData(let message): return "Database error: \(message)"
        case .unknown(let message): return "Unexpected error: \(message)"
        }
    }
}
