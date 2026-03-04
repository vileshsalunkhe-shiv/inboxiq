import Foundation

final class AuthService {
    static let shared = AuthService()
    private init() {}

    struct LoginResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let userEmail: String
    }

    func exchangeAuthCode(_ code: String) async throws -> LoginResponse {
        struct Request: Encodable { let code: String }
        let response: LoginResponse = try await APIClient.shared.request(
            APIPath.authLogin,
            method: "POST",
            body: Request(code: code)
        )
        try KeychainService.shared.saveAccessToken(response.accessToken)
        try KeychainService.shared.saveRefreshToken(response.refreshToken)
        return response
    }

    func logout() async throws {
        struct Request: Encodable { let token: String }
        let token = KeychainService.shared.getAccessToken() ?? ""
        _ = try? await APIClient.shared.request(
            APIPath.authLogout,
            method: "POST",
            body: Request(token: token)
        ) as EmptyResponse
        try KeychainService.shared.clearTokens()
    }
}

struct EmptyResponse: Decodable {}
