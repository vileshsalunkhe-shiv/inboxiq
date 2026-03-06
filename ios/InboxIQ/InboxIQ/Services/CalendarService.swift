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
        guard var components = URLComponents(url: Constants.apiBaseURL.appendingPathComponent(APIPath.calendarAuthInitiate), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "user_id", value: userId.uuidString)]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainService.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CalendarAuthInitiateResponse.self, from: data)
    }

    func handleCallback(code: String, state: String) async throws -> CalendarCallbackResponse {
        // FIX: Use URLComponents instead of string concatenation
        // OLD: let path = "\(APIPath.calendarCallback)?code=\(code)&state=\(state)"
        guard var components = URLComponents(url: Constants.apiBaseURL.appendingPathComponent(APIPath.calendarCallback), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "state", value: state)
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainService.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CalendarCallbackResponse.self, from: data)
    }

    func checkStatus(userId: UUID) async throws -> CalendarStatusResponse {
        guard var components = URLComponents(url: Constants.apiBaseURL.appendingPathComponent(APIPath.calendarStatus), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "user_id", value: userId.uuidString)]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainService.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(CalendarStatusResponse.self, from: data)
    }

    func fetchEvents(userId: UUID, maxResults: Int = 10) async throws -> [CalendarEventPayload] {
        // FIX: Use URLComponents instead of string concatenation
        // OLD: let path = "\(APIPath.calendarEvents)?user_id=\(userId.uuidString)&max_results=\(maxResults)"
        guard var components = URLComponents(url: Constants.apiBaseURL.appendingPathComponent(APIPath.calendarEvents), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [
            URLQueryItem(name: "user_id", value: userId.uuidString),
            URLQueryItem(name: "max_results", value: "\(maxResults)")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = KeychainService.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([CalendarEventPayload].self, from: data)
    }

    func createEvent(userId: UUID, request: CalendarEventCreateRequest) async throws -> CalendarEventPayload {
        // FIX: Use URLComponents instead of string concatenation
        // OLD: let path = "\(APIPath.calendarEvents)?user_id=\(userId.uuidString)"
        guard var components = URLComponents(url: Constants.apiBaseURL.appendingPathComponent(APIPath.calendarEvents), resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        components.queryItems = [URLQueryItem(name: "user_id", value: userId.uuidString)]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainService.shared.getAccessToken() {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, _) = try await URLSession.shared.data(for: urlRequest)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CalendarEventPayload.self, from: data)
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
