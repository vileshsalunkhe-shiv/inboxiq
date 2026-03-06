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
        if let token = KeychainService.shared.getAccessToken() {
            Logger.info("🔑 Found saved token in Keychain (length: \(token.count))")
            isAuthenticated = true
            Logger.info("✅ User authenticated from saved session")
        } else {
            Logger.info("ℹ️ No saved token found - user needs to sign in")
            isAuthenticated = false
        }
    }

    func handleOAuthCallback(url: URL) async {
        Logger.info("🔗 OAuth callback received: \(url.absoluteString)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Logger.error("❌ Invalid callback URL")
            error = AppError.auth("Invalid callback URL")
            return
        }

        // Check for error first
        if let errorParam = components.queryItems?.first(where: { $0.name == "error" })?.value {
            Logger.error("❌ OAuth error: \(errorParam)")
            error = AppError.auth("OAuth error: \(errorParam)")
            return
        }

        // Log all query parameters for debugging
        Logger.info("📋 Query parameters:")
        components.queryItems?.forEach { item in
            Logger.info("  - \(item.name): \(item.value?.prefix(20) ?? "nil")...")
        }

        // Extract JWT tokens AND user_id from backend redirect (inboxiq://login?access_token=...&user_id=...)
        guard let accessToken = components.queryItems?.first(where: { $0.name == "access_token" })?.value,
              let refreshToken = components.queryItems?.first(where: { $0.name == "refresh_token" })?.value,
              let email = components.queryItems?.first(where: { $0.name == "user_email" })?.value,
              let userIdString = components.queryItems?.first(where: { $0.name == "user_id" })?.value,
              let userId = UUID(uuidString: userIdString) else {
            Logger.error("❌ Missing tokens or user_id in callback")
            Logger.error("  access_token: \(components.queryItems?.first(where: { $0.name == "access_token" })?.value != nil ? "present" : "MISSING")")
            Logger.error("  refresh_token: \(components.queryItems?.first(where: { $0.name == "refresh_token" })?.value != nil ? "present" : "MISSING")")
            Logger.error("  user_email: \(components.queryItems?.first(where: { $0.name == "user_email" })?.value != nil ? "present" : "MISSING")")
            Logger.error("  user_id: \(components.queryItems?.first(where: { $0.name == "user_id" })?.value != nil ? "present" : "MISSING")")
            error = AppError.auth("Missing tokens or user_id in callback")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Save JWT tokens from backend
            try KeychainService.shared.saveAccessToken(accessToken)
            try KeychainService.shared.saveRefreshToken(refreshToken)
            
            // Save user_id to UserDefaults for API calls
            UserDefaults.standard.set(userIdString, forKey: "backend_user_id")
            
            userEmail = email
            Logger.info("🔄 Setting isAuthenticated = true")
            isAuthenticated = true
            Logger.info("✅ Login successful for \(email) with backend user_id: \(userIdString)")
            Logger.info("✅ isAuthenticated is now: \(isAuthenticated)")
        } catch {
            self.error = AppError.auth("Failed to save tokens: \(error.localizedDescription)")
            Logger.error("❌ Failed to save tokens: \(error)")
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
