import Foundation

enum Constants {
    static let appName = "InboxIQ"
    static let apiBaseURL = URL(string: "https://inboxiq-production-5368.up.railway.app")!
    static let oauthCallbackScheme = "com.googleusercontent.apps.535816296321-0l834ob6tluso0d4hr8igp4ehe80mc4b"
    static let oauthCallbackURL = "com.googleusercontent.apps.535816296321-0l834ob6tluso0d4hr8igp4ehe80mc4b:/oauth2redirect"
    static let oauthAuthorizeURL = URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    static let keychainService = "com.inboxiq.ios"
    static let oauthClientId = "535816296321-0l834ob6tluso0d4hr8igp4ehe80mc4b.apps.googleusercontent.com"
    static let oauthScopes = ["https://www.googleapis.com/auth/gmail.modify", "openid", "email"]
    static let keychainAccessGroup = "$(AppIdentifierPrefix)com.inboxiq.shared"
    static let backgroundFetchInterval: TimeInterval = 60 * 15

    // Calendar OAuth
    static let calendarCallbackScheme = "inboxiq"
    static let calendarCallbackPath = "/calendar/callback"
}

enum APIPath {
    static let authLogin = "/auth/ios/login"
    static let authRefresh = "/auth/refresh"
    static let authLogout = "/auth/logout"
    static let emails = "/emails"
    static let emailSync = "/emails/sync"
    static let categories = "/categories"
    static let digestSettings = "/digest/settings"
    static let pushRegister = "/push/register"

    // Calendar
    static let calendarAuthInitiate = "/calendar/auth/initiate"
    static let calendarCallback = "/calendar/callback"
    static let calendarStatus = "/calendar/status"
    static let calendarEvents = "/calendar/events"
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
