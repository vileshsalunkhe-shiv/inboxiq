import Foundation
import CoreData

final class SyncService {
    static let shared = SyncService()
    private init() {}

    struct SyncResponse: Decodable {
        let status: String
        let emailsSynced: Int
        
        enum CodingKeys: String, CodingKey {
            case status
            case emailsSynced = "emails_synced"
        }
    }
    
    struct EmailsResponse: Decodable {
        let items: [EmailPayload]
        let total: Int
    }

    struct EmailPayload: Decodable {
        let id: String
        let gmailId: String
        let subject: String
        let sender: String
        let snippet: String
        let category: String?
        let receivedAt: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case gmailId = "gmail_id"
            case subject
            case sender
            case snippet
            case category
            case receivedAt = "received_at"
        }
    }

    func sync(context: NSManagedObjectContext) async throws {
        // Step 1: Trigger backend sync
        let syncResponse: SyncResponse = try await APIClient.shared.request(
            APIPath.emailSync,
            method: "POST"
        )
        
        print("✅ Backend sync completed: \(syncResponse.emailsSynced) emails synced")
        
        // Step 2: Fetch emails from backend
        let emailsResponse: EmailsResponse = try await APIClient.shared.request(
            APIPath.emails,
            method: "GET"
        )
        
        print("✅ Fetched \(emailsResponse.items.count) emails from backend")
        
        // Step 3: Save to CoreData
        try await context.perform {
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            // Create categories if needed
            var categoryMap: [String: CategoryEntity] = [:]
            for email in emailsResponse.items {
                if let categoryName = email.category, !categoryName.isEmpty {
                    if categoryMap[categoryName] == nil {
                        let category = CategoryEntity.fetchOrCreate(name: categoryName, context: context)
                        category.name = categoryName
                        category.color = self.colorForCategory(categoryName)
                        category.icon = self.iconForCategory(categoryName)
                        categoryMap[categoryName] = category
                    }
                }
            }
            
            // Create/update emails
            for emailPayload in emailsResponse.items {
                guard let emailId = UUID(uuidString: emailPayload.id) else { continue }
                
                let email = EmailEntity.fetchOrCreate(id: emailId, context: context)
                email.id = emailId
                email.gmailId = emailPayload.gmailId
                email.subject = emailPayload.subject ?? "No Subject"
                email.sender = emailPayload.sender ?? "Unknown"
                email.snippet = emailPayload.snippet ?? ""
                email.isUnread = true // Default
                
                // Parse date
                if let date = self.parseDate(emailPayload.receivedAt) {
                    email.receivedAt = date
                } else {
                    email.receivedAt = Date()
                }
                
                email.syncedAt = Date()
                
                // Set category
                if let categoryName = emailPayload.category, !categoryName.isEmpty {
                    email.category = categoryMap[categoryName]
                }
            }
            
            // Update user last sync
            let user = UserEntity.fetchOrCreateCurrent(context: context)
            user.lastSyncDate = Date()
            
            if context.hasChanges {
                try context.save()
                print("✅ Saved \(emailsResponse.items.count) emails to CoreData")
            }
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
    
    private func colorForCategory(_ name: String) -> String {
        switch name.lowercased() {
        case "important", "urgent": return "red"
        case "work", "business": return "blue"
        case "personal": return "green"
        case "finance", "bills": return "orange"
        case "social", "updates": return "purple"
        default: return "gray"
        }
    }
    
    private func iconForCategory(_ name: String) -> String {
        switch name.lowercased() {
        case "important", "urgent": return "exclamationmark.circle.fill"
        case "work", "business": return "briefcase.fill"
        case "personal": return "person.fill"
        case "finance", "bills": return "dollarsign.circle.fill"
        case "social", "updates": return "bell.fill"
        default: return "folder.fill"
        }
    }
}
