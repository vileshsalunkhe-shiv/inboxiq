import Foundation
import CommonCrypto

final class APIClient: NSObject, URLSessionDelegate {
    static let shared = APIClient()
    private override init() {
        super.init()
    }

    /// SSL Certificate Pinning Configuration
    ///
    /// This implementation uses public key hash pinning for enhanced security.
    /// The public key hash(es) are precomputed from the Railway backend certificate.
    ///
    /// **Security Benefits:**
    /// - Pins to the actual public key, not just hostname
    /// - Survives certificate rotation if the same key pair is used
    /// - More resistant to certificate compromise and MITM attacks
    ///
    /// **Maintenance:**
    /// - If Railway rotates certificates with a new key pair, update expectedPublicKeyHashes
    /// - To extract the hash, run in DEBUG mode and check console output
    /// - Alternative: Use OpenSSL command documented in README-SSL-PINNING.md
    ///
    /// **Testing:**
    /// - Verify pinning succeeds for Railway backend
    /// - Verify pinning fails for other domains
    /// - Test with network proxy to ensure MITM protection works
    private let expectedPublicKeyHashes: Set<String> = [
        // Placeholder - replace with actual Railway public key hash (base64)
        "RAILWAY_PUBLIC_KEY_HASH_BASE64_HERE"
    ]

    private func publicKeyHash(for certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        publicKeyData.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(publicKeyData.count), &hash)
        }

        return Data(hash).base64EncodedString()
    }

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
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

    #if DEBUG
    // Development mode: Log the actual hash for pinning configuration
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        if let hash = publicKeyHash(for: serverCertificate) {
            print("🔐 SERVER PUBLIC KEY HASH: \(hash)")
            print("📋 Copy this hash to expectedPublicKeyHashes array")
            print("🌐 Host: \(challenge.protectionSpace.host)")
        }

        Logger.warning("⚠️ DEVELOPMENT MODE: SSL pinning bypassed")
        let credential = URLCredential(trust: serverTrust)
        completionHandler(.useCredential, credential)
    }
    #else
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            Logger.warning("SSL challenge failed: invalid authentication method")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            Logger.warning("SSL challenge failed: no server certificate")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        guard let serverPublicKeyHash = publicKeyHash(for: serverCertificate) else {
            Logger.warning("SSL challenge failed: could not extract public key")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        if expectedPublicKeyHashes.contains(serverPublicKeyHash) {
            Logger.info("SSL pinning: certificate validated")
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            Logger.warning("SSL pinning failed: public key hash mismatch", metadata: [
                "expected_count": "\(expectedPublicKeyHashes.count)",
                "received_prefix": "\(serverPublicKeyHash.prefix(8))"
            ])
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    #endif

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
            guard let empty = EmptyResponse() as? T else {
                throw AppError.decoding("Failed to decode empty response")
            }
            return empty
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
