import Foundation

struct Email: Identifiable, Hashable, Codable {
    let id: String  // Changed from UUID to String to match backend integer IDs
    let gmailId: String
    let subject: String
    let sender: String
    let snippet: String  // Kept same - maps to backend's body_preview
    let category: Category?
    let aiSummary: String?
    let aiConfidence: Double?
    let receivedAt: Date  // Kept same - maps to backend's received_date
    let syncedAt: Date  // Will default to current date if not provided
    var isUnread: Bool
    var isStarred: Bool  // Added missing field

    // Map JSON keys to Swift property names
    enum CodingKeys: String, CodingKey {
        case id
        case gmailId = "gmail_id"
        case subject
        case sender
        case snippet = "body_preview"  // Backend sends body_preview, iOS uses snippet
        case category
        case aiSummary = "ai_summary"
        case aiConfidence = "ai_confidence"
        case receivedAt = "received_date"  // Backend sends received_date, iOS uses receivedAt
        case isUnread = "is_unread"
        case isStarred = "is_starred"
    }

    // Custom decoder to handle missing syncedAt and date parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        gmailId = try container.decode(String.self, forKey: .gmailId)
        subject = try container.decode(String.self, forKey: .subject)
        sender = try container.decode(String.self, forKey: .sender)
        snippet = try container.decodeIfPresent(String.self, forKey: .snippet) ?? ""
        category = try container.decodeIfPresent(Category.self, forKey: .category)
        aiSummary = try container.decodeIfPresent(String.self, forKey: .aiSummary)
        aiConfidence = try container.decodeIfPresent(Double.self, forKey: .aiConfidence)
        
        // Parse received_date string to Date
        let dateString = try container.decode(String.self, forKey: .receivedAt)
        let formatter = ISO8601DateFormatter()
        receivedAt = formatter.date(from: dateString) ?? Date()
        
        // syncedAt not in backend response, default to now
        syncedAt = Date()
        
        isUnread = try container.decode(Bool.self, forKey: .isUnread)
        isStarred = try container.decode(Bool.self, forKey: .isStarred)
    }

    // Manual init for local creation
    init(
        id: String = UUID().uuidString,
        gmailId: String,
        subject: String,
        sender: String,
        snippet: String,
        category: Category? = nil,
        aiSummary: String? = nil,
        aiConfidence: Double? = nil,
        receivedAt: Date,
        syncedAt: Date = Date(),
        isUnread: Bool = true,
        isStarred: Bool = false
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
        self.isStarred = isStarred
    }
}

struct AttachmentInfo: Codable, Identifiable {
    let index: Int
    let filename: String
    let mimeType: String
    let size: Int
    
    var id: Int { index }
    
    enum CodingKeys: String, CodingKey {
        case index, filename
        case mimeType = "mime_type"
        case size
    }
}

struct EmailBody: Codable {
    let messageId: String
    let htmlBody: String?
    let textBody: String?
    let hasAttachments: Bool
    let attachments: [AttachmentInfo]
    
    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case htmlBody = "html_body"
        case textBody = "text_body"
        case hasAttachments = "has_attachments"
        case attachments
    }
}
