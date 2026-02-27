import Foundation
import SwiftUI

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
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            error = AppError.auth("Missing authorization code")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await AuthService.shared.exchangeAuthCode(code)
            userEmail = response.userEmail
            isAuthenticated = true
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.auth("Login failed")
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
