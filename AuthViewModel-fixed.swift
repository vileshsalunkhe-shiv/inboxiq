import Foundation
import SwiftUI
import Combine
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userEmail: String?
    
    func handleOAuthCallback(url: URL) async {
        // Extract code from callback URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            errorMessage = "Invalid callback URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Send code to backend (using iOS-specific endpoint)
            let loginURL = Constants.apiBaseURL.appendingPathComponent("/auth/ios/login")
            var request = URLRequest(url: loginURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["code": code]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response from server"
                isLoading = false
                return
            }
            
            if httpResponse.statusCode == 200 {
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                userEmail = loginResponse.user_email
                isAuthenticated = true
                print("✅ Login successful: \(loginResponse.user_email)")
            } else {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                errorMessage = "Login failed (\(httpResponse.statusCode)): \(errorText)"
                print("❌ Login failed: \(errorText)")
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
            print("❌ Error: \(error)")
        }
        
        isLoading = false
    }
}

struct LoginResponse: Codable {
    let access_token: String  // Note: snake_case from backend
    let refresh_token: String
    let expires_in: Int
    let user_email: String    // Backend now includes this
}
