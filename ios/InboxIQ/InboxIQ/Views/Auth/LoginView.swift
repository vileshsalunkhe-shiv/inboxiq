import SwiftUI
import Combine
struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showOAuth = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "tray.full")
                .font(.system(size: 64))
                .foregroundStyle(.inboxBlue)
                .accessibilityHidden(true)

            Text("Welcome to InboxIQ")
                .font(.title)
                .fontWeight(.bold)

            Text("Organize your Gmail with intelligent categories.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button {
                showOAuth = true
            } label: {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.inboxBlue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Sign in with Google")

            if authViewModel.isLoading {
                ProgressView()
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showOAuth) {
            OAuthWebView(
                authURL: buildAuthURL(),
                callbackScheme: Constants.oauthCallbackScheme
            ) { result in
                showOAuth = false
                switch result {
                case .success(let url):
                    Task { await authViewModel.handleOAuthCallback(url: url) }
                case .failure:
                    authViewModel.error = AppError.auth("OAuth login canceled")
                }
            }
        }
        .alert(item: $authViewModel.error) { error in
            Alert(title: Text("Login Error"), message: Text(error.localizedDescription))
        }
    }

    private func buildAuthURL() -> URL {
        var components = URLComponents(url: Constants.oauthAuthorizeURL, resolvingAgainstBaseURL: false)
        let scope = Constants.oauthScopes.joined(separator: " ")

        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Constants.oauthClientId),
            URLQueryItem(name: "redirect_uri", value: Constants.oauthBackendCallbackURL),  // Backend handles callback
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]

        return components?.url ?? Constants.oauthAuthorizeURL
    }
}
