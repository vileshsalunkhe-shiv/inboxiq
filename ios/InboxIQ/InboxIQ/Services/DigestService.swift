import Foundation

final class DigestService {
    static let shared = DigestService()
    private init() {}

    func previewDigest() async throws -> DigestPreview {
        try await APIClient.shared.request(DigestAPIPath.preview)
    }

    func sendDigest() async throws -> DigestResult {
        try await APIClient.shared.request(DigestAPIPath.send, method: "POST")
    }

    func getPreferences() async throws -> DigestPreferences {
        try await APIClient.shared.request(DigestAPIPath.preferences)
    }

    func updatePreferences(_ prefs: DigestPreferences) async throws {
        let _: EmptyResponse = try await APIClient.shared.request(
            DigestAPIPath.preferences,
            method: "PUT",
            body: prefs
        )
    }
}

private enum DigestAPIPath {
    static let preview = "/api/digest/preview"
    static let send = "/api/digest/send"
    static let preferences = APIPath.digestSettings
}
