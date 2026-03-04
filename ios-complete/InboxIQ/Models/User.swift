import Foundation

struct User: Identifiable, Hashable, Codable {
    let id: UUID
    let email: String
    let lastSyncDate: Date?

    init(id: UUID = UUID(), email: String, lastSyncDate: Date? = nil) {
        self.id = id
        self.email = email
        self.lastSyncDate = lastSyncDate
    }
}
