import Foundation

enum Constants {
    static let apiBaseURL = URL(string: "http://localhost:8000")!
    static let oauthCallbackScheme = "inboxiq"
    static let oauthCallbackURL = "inboxiq://oauth/callback"
    static let oauthClientId = "535816296321-a722g108h5cqt6ai2v1c7jma0200ij36.apps.googleusercontent.com"
    static let oauthScopes = [
        "https://www.googleapis.com/auth/gmail.modify",
        "openid",
        "email"
    ]
}
