import Foundation

struct EmailBody: Codable, Equatable {
    let emailId: String
    let bodyText: String?
    let bodyHtml: String?
    let hasAttachments: Bool
    let fetchedAt: String?

    enum CodingKeys: String, CodingKey {
        case emailId = "email_id"
        case bodyText = "body_text"
        case bodyHtml = "body_html"
        case hasAttachments = "has_attachments"
        case fetchedAt = "fetched_at"
    }
}

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
