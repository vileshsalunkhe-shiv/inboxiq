import Foundation

final class EmailActionService {
    static let shared = EmailActionService()
    private init() {}

    func archiveEmail(email: EmailEntity) async throws {
        let backendId = try await resolveBackendId(for: email)
        let _: SimpleActionResponse = try await APIClient.shared.request(
            "\(APIPath.emails)/\(backendId)/archive",
            method: "POST"
        )
    }

    func deleteEmail(email: EmailEntity) async throws {
        let backendId = try await resolveBackendId(for: email)
        let _: SimpleActionResponse = try await APIClient.shared.request(
            "\(APIPath.emails)/\(backendId)",
            method: "DELETE"
        )
        EmailActionCache.clear(email: email)
    }

    func updateStar(email: EmailEntity, starred: Bool) async throws {
        let backendId = try await resolveBackendId(for: email)
        let _: SimpleActionResponse = try await APIClient.shared.request(
            "\(APIPath.emails)/\(backendId)/star",
            method: "PUT",
            body: StarStatusRequest(starred: starred)
        )
    }

    func updateReadStatus(email: EmailEntity, read: Bool) async throws {
        let backendId = try await resolveBackendId(for: email)
        let _: SimpleActionResponse = try await APIClient.shared.request(
            "\(APIPath.emails)/\(backendId)/read",
            method: "PUT",
            body: ReadStatusRequest(read: read)
        )
    }

    func composeEmail(
        to: [String],
        subject: String,
        body: String,
        attachments: [EmailAttachmentPayload]
    ) async throws {
        let _: MessageActionResponse = try await APIClient.shared.request(
            "\(APIPath.emails)/compose",
            method: "POST",
            body: ComposeEmailRequest(
                to: to,
                subject: subject,
                body: body,
                attachments: attachments
            )
        )
    }

    func replyEmail(
        email: EmailEntity,
        body: String,
        replyAll: Bool
    ) async throws {
        let backendId = try await resolveBackendId(for: email)
        let _: MessageActionResponse = try await APIClient.shared.request(
            "\(APIPath.emails)/\(backendId)/reply",
            method: "POST",
            body: ReplyEmailRequest(body: body, replyAll: replyAll)
        )
    }

    func forwardEmail(
        email: EmailEntity,
        to: [String],
        body: String,
        attachments: [EmailAttachmentPayload]
    ) async throws {
        let backendId = try await resolveBackendId(for: email)
        let _: MessageActionResponse = try await APIClient.shared.request(
            "\(APIPath.emails)/\(backendId)/forward",
            method: "POST",
            body: ForwardEmailRequest(to: to, body: body, attachments: attachments)
        )
    }

    private func resolveBackendId(for email: EmailEntity) async throws -> Int {
        if let cached = EmailActionCache.backendId(for: email) {
            return cached
        }

        let response: EmailListResponse = try await APIClient.shared.request(APIPath.emails)
        guard let match = response.emails.first(where: { $0.gmailId == email.gmailId }) else {
            throw AppError.network("Unable to find email on server")
        }

        guard let backendId = Int(match.id) else {
            throw AppError.decoding("Invalid email id format")
        }

        EmailActionCache.store(backendId: backendId, for: email)
        return backendId
    }
}

private enum EmailActionCache {
    private static func key(for email: EmailEntity) -> String {
        "backend_email_id_\(email.gmailId)"
    }

    static func backendId(for email: EmailEntity) -> Int? {
        let value = UserDefaults.standard.integer(forKey: key(for: email))
        return value == 0 ? nil : value
    }

    static func store(backendId: Int, for email: EmailEntity) {
        UserDefaults.standard.set(backendId, forKey: key(for: email))
    }

    static func clear(email: EmailEntity) {
        UserDefaults.standard.removeObject(forKey: key(for: email))
    }
}

struct EmailAttachmentPayload: Codable, Hashable {
    let filename: String
    let contentType: String
    let data: String

    enum CodingKeys: String, CodingKey {
        case filename
        case contentType = "content_type"
        case data
    }
}

struct ComposeEmailRequest: Encodable {
    let to: [String]
    let subject: String
    let body: String
    let attachments: [EmailAttachmentPayload]
}

struct ReplyEmailRequest: Encodable {
    let body: String
    let replyAll: Bool

    enum CodingKeys: String, CodingKey {
        case body
        case replyAll = "reply_all"
    }
}

struct ForwardEmailRequest: Encodable {
    let to: [String]
    let body: String
    let attachments: [EmailAttachmentPayload]
}

struct MessageActionResponse: Decodable {
    let messageId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case status
    }
}

struct SimpleActionResponse: Decodable {
    let status: String
}

struct StarStatusRequest: Encodable {
    let starred: Bool
}

struct ReadStatusRequest: Encodable {
    let read: Bool
}

struct EmailListResponse: Decodable {
    let emails: [EmailListItem]

    enum CodingKeys: String, CodingKey {
        case emails
        case items
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let emails = try? container.decode([EmailListItem].self, forKey: .emails) {
            self.emails = emails
        } else if let items = try? container.decode([EmailListItem].self, forKey: .items) {
            self.emails = items
        } else {
            self.emails = []
        }
    }
}

struct EmailListItem: Decodable {
    let id: String
    let gmailId: String

    enum CodingKeys: String, CodingKey {
        case id
        case gmailId = "gmail_id"
    }
}
