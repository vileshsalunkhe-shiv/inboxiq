import SwiftUI
import AuthenticationServices

struct OAuthWebView: View {
    let authURL: URL
    let callbackScheme: String
    let onComplete: (Result<URL, Error>) -> Void

    @State private var session: ASWebAuthenticationSession?

    var body: some View {
        ProgressView("Opening secure login...")
            .onAppear {
                startSession()
            }
            .accessibilityLabel("OAuth login in progress")
    }

    private func startSession() {
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { url, error in
            if let error = error {
                onComplete(.failure(error))
                return
            }
            if let url = url {
                onComplete(.success(url))
            }
        }
        session.presentationContextProvider = WebAuthPresentationContextProvider.shared
        session.prefersEphemeralWebBrowserSession = true
        self.session = session
        session.start()
    }
}

final class WebAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = WebAuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
