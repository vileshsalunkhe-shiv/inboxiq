import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOAuth = false
    
    var body: some View {
        VStack(spacing: 24) {
            if authViewModel.isAuthenticated {
                // Success screen
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("Login Successful! 🎉")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    if let email = authViewModel.userEmail {
                        Text(email)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Check your backend terminal logs!")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding()
                }
            } else {
                // Login screen
                Spacer()
                
                Image(systemName: "envelope.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("InboxIQ")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("OAuth Test")
                    .foregroundColor(.secondary)
                
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
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                
                if authViewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                if let error = authViewModel.errorMessage {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                
                Spacer()
            }
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
                case .failure(let error):
                    authViewModel.errorMessage = "OAuth failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func buildAuthURL() -> URL {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        let scope = Constants.oauthScopes.joined(separator: " ")
        
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Constants.oauthClientId),
            URLQueryItem(name: "redirect_uri", value: Constants.oauthCallbackURL),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        
        return components.url!
    }
}
