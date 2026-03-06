import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let accessTokenKey = "inboxiq.accessToken"
    private let refreshTokenKey = "inboxiq.refreshToken"

    func saveAccessToken(_ token: String) throws {
        try save(token, for: accessTokenKey)
    }

    func saveRefreshToken(_ token: String) throws {
        try save(token, for: refreshTokenKey)
    }

    func getAccessToken() -> String? {
        read(for: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        read(for: refreshTokenKey)
    }

    func clearTokens() throws {
        try delete(for: accessTokenKey)
        try delete(for: refreshTokenKey)
    }

    private func save(_ value: String, for key: String) throws {
        let data = Data(value.utf8)

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        if let accessGroup = validatedAccessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        SecItemDelete(query as CFDictionary)

        var newQuery = query
        newQuery[kSecValueData as String] = data

        let status = SecItemAdd(newQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AppError.auth("Failed to save token (status: \(status))")
        }
    }

    private func read(for key: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        if let accessGroup = validatedAccessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private func delete(for key: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key
        ]
        if let accessGroup = validatedAccessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw AppError.auth("Failed to delete token (status: \(status))")
        }
    }

    private var validatedAccessGroup: String? {
        let value = Constants.keychainAccessGroup.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty { return nil }
        if value.contains("$") || value.contains("(") || value.contains(")") {
            return nil
        }
        return value
    }
}
