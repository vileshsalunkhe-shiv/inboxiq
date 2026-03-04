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

        // Extract tokens from URL parameters
        guard let accessToken = components.queryItems?.first(where: { $0.name == "access_token" })?.value,
              let refreshToken = components.queryItems?.first(where: { $0.name == "refresh_token" })?.value,
              let email = components.queryItems?.first(where: { $0.name == "user_email" })?.value else {
            error = AppError.auth("Missing tokens in callback")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            try KeychainService.shared.saveAccessToken(accessToken)
            try KeychainService.shared.saveRefreshToken(refreshToken)
            userEmail = email
            isAuthenticated = true
        } catch {
            self.error = AppError.auth("Failed to save tokens")
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
