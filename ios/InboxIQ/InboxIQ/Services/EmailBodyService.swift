import Foundation

// EmailBody struct is now defined in Models/Email.swift

final class EmailBodyService {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchEmailBody(gmailId: String) async throws -> EmailBody {
        let endpoint = "/api/emails/\(gmailId)/body"
        let response: EmailBody = try await apiClient.request(endpoint)
        return response
    }
}
