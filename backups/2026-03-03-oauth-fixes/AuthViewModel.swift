import Foundation
import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var userEmail: String?

    func loadSession() {
        if KeychainService.shared.getAccessToken() != nil {
            isAuthenticated = true
        }
    }

    func handleOAuthCallback(url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            error = AppError.auth("Invalid callback URL")
            return
        }

        // Check for error first
        if let errorParam = components.queryItems?.first(where: { $0.name == "error" })?.value {
            error = AppError.auth("OAuth error: \(errorParam)")
            return
        }

        // Extract authorization code from Google OAuth callback
        guard let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            error = AppError.auth("Missing authorization code in callback")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Send code to backend, which creates user and returns JWT tokens
            let response = try await AuthService.shared.exchangeAuthCode(code)
            userEmail = response.userEmail
            isAuthenticated = true
            Logger.info("✅ Login successful for \(response.userEmail)")
        } catch let error as AppError {
            self.error = error
            Logger.error("❌ Login failed: \(error.localizedDescription)")
        } catch {
            self.error = AppError.auth("Login failed: \(error.localizedDescription)")
            Logger.error("❌ Login failed: \(error)")
        }
    }

    func logout() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AuthService.shared.logout()
            isAuthenticated = false
            userEmail = nil
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.auth("Logout failed")
        }
    }
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let userEmail: String
}
