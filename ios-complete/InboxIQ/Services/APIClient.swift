import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let session = URLSession(configuration: .default)
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        try await request(path, method: method, body: body, allowRefresh: true)
    }

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil,
        allowRefresh: Bool
    ) async throws -> T {
        var request = URLRequest(url: Constants.apiBaseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainService.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.network("Invalid response")
        }

        if http.statusCode == 401 {
            if allowRefresh && path != APIPath.authRefresh {
                Logger.warning("Access token expired, attempting refresh")
                try await refreshToken()
                return try await self.request(path, method: method, body: body, allowRefresh: false)
            } else {
                throw AppError.auth("Session expired")
            }
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.network("HTTP \(http.statusCode): \(message)")
        }

        if data.isEmpty, T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            Logger.error("Decoding error: \(error.localizedDescription)")
            throw AppError.decoding("Failed to decode response")
        }
    }

    private func refreshToken() async throws {
        guard let refreshToken = KeychainService.shared.getRefreshToken() else {
            throw AppError.auth("Missing refresh token")
        }

        struct RefreshRequest: Encodable { 
            let refreshToken: String
            
            enum CodingKeys: String, CodingKey {
                case refreshToken = "refresh_token"
            }
        }
        struct RefreshResponse: Decodable { 
            let accessToken: String
            let refreshToken: String
            
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case refreshToken = "refresh_token"
            }
        }

        let response: RefreshResponse = try await request(
            APIPath.authRefresh,
            method: "POST",
            body: RefreshRequest(refreshToken: refreshToken),
            allowRefresh: false
        )

        try KeychainService.shared.saveAccessToken(response.accessToken)
        try KeychainService.shared.saveRefreshToken(response.refreshToken)
    }
}

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ value: Encodable) {
        self.encodeClosure = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
