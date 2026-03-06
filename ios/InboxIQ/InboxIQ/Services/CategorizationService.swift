import Foundation

final class CategorizationService {
    static let shared = CategorizationService()
    private init() {}

    func categorizeAll(limit: Int) async throws -> CategorizeResult {
        // Construct URL with query parameters properly
        guard var components = URLComponents(url: Constants.apiBaseURL.appendingPathComponent("/emails/categorize-all"), resolvingAgainstBaseURL: true) else {
            throw AppError.network("Invalid URL")
        }
        components.queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        
        guard let url = components.url else {
            throw AppError.network("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = KeychainService.shared.getAccessToken() {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AppError.network("Invalid response")
        }
        
        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AppError.network("HTTP \(http.statusCode): \(message)")
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(CategorizeResult.self, from: data)
    }

    func categorizeSingle(emailId: String) async throws -> Email {
        let path = "/emails/\(emailId)/categorize"
        return try await APIClient.shared.request(path, method: "POST")
    }

    func getStats() async throws -> CategoryStats {
        return try await APIClient.shared.request("/categories/stats", method: "GET")
    }
}

// FIXED: Match backend response format
struct CategorizeResult: Decodable {
    let processed: Int    // Backend returns "processed" (number of emails categorized)
    let limit: Int        // Backend returns "limit" (max emails to process)
    
    // Computed properties for convenience
    var categorizedCount: Int { processed }
    var displayMessage: String { "Categorized \(processed) emails" }
}

struct CategoryStats: Decodable {
    let counts: [String: Int]

    enum CodingKeys: String, CodingKey {
        case counts
        case stats
    }

    init(from decoder: Decoder) throws {
        if let dict = try? decoder.singleValueContainer().decode([String: Int].self) {
            counts = dict
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        counts = try container.decodeIfPresent([String: Int].self, forKey: .counts)
            ?? container.decodeIfPresent([String: Int].self, forKey: .stats)
            ?? [:]
    }
}
