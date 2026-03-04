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
        print("🔍 SYNC START: Context = \(context), Thread = \(Thread.current)")
        
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
        
        // Step 3: Save to CoreData using context.perform
        try await context.perform {
            print("🔍 INSIDE context.perform: Thread=\(Thread.current)")
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            // Get the current user FIRST
            let user = UserEntity.fetchOrCreateCurrent(context: context)
            
            // Create categories if needed
            var categoryMap: [String: CategoryEntity] = [:]
            for email in emailsResponse.items {
                if let categoryName = email.category, !categoryName.isEmpty {
                    if categoryMap[categoryName] == nil {
                        // Use name-based lookup for categories
                        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
                        request.predicate = NSPredicate(format: "name == %@", categoryName)
                        request.fetchLimit = 1
                        
                        let category: CategoryEntity
                        if let existing = try? context.fetch(request).first {
                            category = existing
                        } else {
                            category = CategoryEntity(context: context)
                            category.id = UUID()
                            category.name = categoryName
                            category.color = self.colorForCategory(categoryName)
                            category.icon = self.iconForCategory(categoryName)
                        }
                        categoryMap[categoryName] = category
                    }
                }
            }
            
            // Create/update emails
            print("🔍 Processing \(emailsResponse.items.count) emails...")
            var createdCount = 0
            for (index, emailPayload) in emailsResponse.items.enumerated() {
                print("🔍 Email \(index): gmailId=\(emailPayload.gmailId)")
                
                // Use gmailId as unique identifier (backend uses integer IDs, not UUIDs)
                let fetchRequest: NSFetchRequest<EmailEntity> = EmailEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "gmailId == %@", emailPayload.gmailId)
                fetchRequest.fetchLimit = 1
                
                let email: EmailEntity
                if let existing = try? context.fetch(fetchRequest).first {
                    email = existing
                    print("📧 Found existing email: \(emailPayload.subject ?? "No Subject")")
                } else {
                    email = EmailEntity(context: context)
                    email.id = UUID() // Generate new UUID for CoreData
                    email.gmailId = emailPayload.gmailId
                    print("✨ Creating new email: \(emailPayload.subject ?? "No Subject")")
                    createdCount += 1
                }
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
                
                // CRITICAL: Link email to user
                email.user = user
            }
            
            print("🔍 SUMMARY: Created \(createdCount) new emails")
                
            // Update user last sync
            user.lastSyncDate = Date()
            
            print("🔍 BEFORE SAVE: hasChanges=\(context.hasChanges), Thread=\(Thread.current)")
            print("🔍 Inserted objects: \(context.insertedObjects.count)")
            print("🔍 Updated objects: \(context.updatedObjects.count)")
            
            if context.hasChanges {
                do {
                    // Check for validation errors before saving
                    for object in context.insertedObjects {
                        if let email = object as? EmailEntity {
                            print("📧 Inserting email: \(email.subject) (id: \(email.id))")
                            do {
                                try context.obtainPermanentIDs(for: [email])
                            } catch {
                                print("❌ Failed to obtain permanent ID: \(error)")
                            }
                        }
                    }
                    
                    try context.save()
                    print("✅ context.save() returned successfully")
                    
                    // Verify IMMEDIATELY after save (still in perform block)
                    let verifyRequest: NSFetchRequest<EmailEntity> = EmailEntity.fetchRequest()
                    let count = try context.count(for: verifyRequest)
                    print("🔍 VERIFY: Total emails in database: \(count)")
                    
                    if count == 0 {
                        print("⚠️ COUNT IS ZERO! Checking inserted objects...")
                        print("   Inserted: \(context.insertedObjects.count)")
                        print("   Registered: \(context.registeredObjects.count)")
                    }
                    
                    // Check parent context
                    if let parent = context.parent {
                        print("⚠️ Has parent context: \(parent)")
                        if parent.hasChanges {
                            try parent.save()
                            print("✅ Saved parent")
                        }
                    } else {
                        print("✅ No parent context - this is the root")
                    }
                } catch {
                    print("❌ SAVE ERROR: \(error)")
                    print("   Description: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("   Domain: \(nsError.domain)")
                        print("   Code: \(nsError.code)")
                        print("   UserInfo: \(nsError.userInfo)")
                    }
                    throw error
                }
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
