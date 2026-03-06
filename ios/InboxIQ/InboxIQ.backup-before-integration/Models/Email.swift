import Foundation

struct Email: Identifiable, Hashable, Codable {
    let id: UUID
    let gmailId: String
    let subject: String
    let sender: String
    let snippet: String
    let category: Category?
    let aiSummary: String?
    let aiConfidence: Double?
    let receivedAt: Date
    let syncedAt: Date
    var isUnread: Bool

    init(
        id: UUID = UUID(),
        gmailId: String,
        subject: String,
        sender: String,
        snippet: String,
        category: Category? = nil,
        aiSummary: String? = nil,
        aiConfidence: Double? = nil,
        receivedAt: Date,
        syncedAt: Date,
        isUnread: Bool = true
    ) {
        self.id = id
        self.gmailId = gmailId
        self.subject = subject
        self.sender = sender
        self.snippet = snippet
        self.category = category
        self.aiSummary = aiSummary
        self.aiConfidence = aiConfidence
        self.receivedAt = receivedAt
        self.syncedAt = syncedAt
        self.isUnread = isUnread
    }
}
