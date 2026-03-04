import Foundation
import CoreData

final class CalendarService {
    static let shared = CalendarService()
    private init() {}

    struct CalendarAuthInitiateResponse: Decodable {
        let authorizationURL: String
        let state: String

        enum CodingKeys: String, CodingKey {
            case authorizationURL = "authorization_url"
            case state
        }
    }

    struct CalendarStatusResponse: Decodable {
        let connected: Bool
        let email: String?
        let hasRefreshToken: Bool?
        let tokenExpiry: String?
        let isExpired: Bool?

        enum CodingKeys: String, CodingKey {
            case connected
            case email
            case hasRefreshToken = "has_refresh_token"
            case tokenExpiry = "token_expiry"
            case isExpired = "is_expired"
        }
    }

    struct CalendarCallbackResponse: Decodable {
        let status: String?
    }

    func initiateAuth(userId: UUID) async throws -> CalendarAuthInitiateResponse {
        let path = "\(APIPath.calendarAuthInitiate)?user_id=\(userId.uuidString)"
        return try await APIClient.shared.request(path)
    }

    func handleCallback(code: String, state: String) async throws -> CalendarCallbackResponse {
        let path = "\(APIPath.calendarCallback)?code=\(code)&state=\(state)"
        return try await APIClient.shared.request(path)
    }

    func checkStatus(userId: UUID) async throws -> CalendarStatusResponse {
        let path = "\(APIPath.calendarStatus)?user_id=\(userId.uuidString)"
        return try await APIClient.shared.request(path)
    }

    func fetchEvents(userId: UUID, maxResults: Int = 10) async throws -> [CalendarEventPayload] {
        let path = "\(APIPath.calendarEvents)?user_id=\(userId.uuidString)&max_results=\(maxResults)"
        return try await APIClient.shared.request(path)
    }

    func createEvent(userId: UUID, request: CalendarEventCreateRequest) async throws -> CalendarEventPayload {
        let path = "\(APIPath.calendarEvents)?user_id=\(userId.uuidString)"
        return try await APIClient.shared.request(path, method: "POST", body: request)
    }

    func syncCalendar(context: NSManagedObjectContext, maxResults: Int = 10) async throws {
        let user = UserEntity.fetchOrCreateCurrent(context: context)
        let events = try await fetchEvents(userId: user.id, maxResults: maxResults)

        try await context.perform {
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            for event in events {
                let entity = CalendarEventEntity.fetchOrCreate(eventId: event.id, context: context)
                entity.summary = event.summary ?? "(No Title)"
                entity.eventDescription = event.description
                entity.startDate = self.parseDate(event.start) ?? Date()
                entity.endDate = self.parseDate(event.end) ?? Date()
                entity.location = event.location
                entity.htmlLink = event.htmlLink
                entity.user = user
            }

            if context.hasChanges {
                try context.save()
            }
        }
    }

    func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}
