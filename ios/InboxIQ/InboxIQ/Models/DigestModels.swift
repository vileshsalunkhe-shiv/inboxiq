import Foundation

struct DigestPreview: Codable {
    let html: String
    let generatedAt: Date
    let emailCount: Int
    let calendarEventCount: Int

    enum CodingKeys: String, CodingKey {
        case html
        case generatedAt = "generated_at"
        case emailCount = "email_count"
        case calendarEventCount = "calendar_event_count"
    }
}

struct DigestResult: Codable {
    let success: Bool
    let messageId: String?
    let sentAt: Date
    let recipient: String

    enum CodingKeys: String, CodingKey {
        case success
        case messageId = "message_id"
        case sentAt = "sent_at"
        case recipient
    }
}

struct DigestPreferences: Codable {
    var enabled: Bool
    var preferredTime: Date
    var lastSentAt: Date?

    enum CodingKeys: String, CodingKey {
        case enabled
        case preferredTime = "preferred_time"
        case lastSentAt = "last_sent_at"
    }

    init(enabled: Bool, preferredTime: Date, lastSentAt: Date?) {
        self.enabled = enabled
        self.preferredTime = preferredTime
        self.lastSentAt = lastSentAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? true

        if let timeString = try? container.decode(String.self, forKey: .preferredTime),
           let timeOnly = DigestTimeFormatter.timeOnlyDate(from: timeString) {
            preferredTime = timeOnly
        } else if let dateValue = try? container.decode(Date.self, forKey: .preferredTime) {
            preferredTime = dateValue
        } else {
            preferredTime = DigestTimeFormatter.defaultPreferredTime
        }

        lastSentAt = try? container.decode(Date.self, forKey: .lastSentAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(DigestTimeFormatter.timeString(from: preferredTime), forKey: .preferredTime)
        try container.encodeIfPresent(lastSentAt, forKey: .lastSentAt)
    }
}

enum DigestTimeFormatter {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static var defaultPreferredTime: Date {
        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    }

    static func timeString(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func timeOnlyDate(from string: String) -> Date? {
        guard let date = formatter.date(from: string) else { return nil }
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return Calendar.current.date(bySettingHour: components.hour ?? 7,
                                     minute: components.minute ?? 0,
                                     second: 0,
                                     of: Date())
    }
}
