import Foundation

struct CalendarEventPayload: Codable, Hashable {
    let id: String
    let summary: String?
    let description: String?
    let start: String
    let end: String
    let location: String?
    let attendees: [CalendarAttendee]?
    let htmlLink: String?

    enum CodingKeys: String, CodingKey {
        case id
        case summary
        case description
        case start
        case end
        case location
        case attendees
        case htmlLink = "html_link"
    }
}

struct CalendarAttendee: Codable, Hashable {
    let email: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case email
        case displayName = "display_name"
    }
}

struct CalendarEventCreateRequest: Encodable {
    let summary: String
    let startTime: String
    let endTime: String
    let description: String?
    let location: String?
    let attendees: [String]?

    enum CodingKeys: String, CodingKey {
        case summary
        case startTime = "start_time"
        case endTime = "end_time"
        case description
        case location
        case attendees
    }
}
