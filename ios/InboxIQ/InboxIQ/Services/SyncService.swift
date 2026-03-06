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
        let emails: [EmailPayload]
        let nextPageToken: String?
        let hasMore: Bool
        let totalFetched: Int
        
        enum CodingKeys: String, CodingKey {
            case emails
            case nextPageToken = "next_page_token"
            case hasMore = "has_more"
            case totalFetched = "total_fetched"
        }
    }

    struct EmailPayload: Decodable {
        let id: String
        let gmailId: String
        let subject: String
        let sender: String
        let snippet: String
        let category: String?
        let aiSummary: String?
        let aiConfidence: Double?
        let receivedAt: String
        let isUnread: Bool
        let isStarred: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case gmailId = "gmail_id"
            case subject
            case sender
            case snippet = "body_preview"
            case category
            case aiSummary = "ai_summary"
            case aiConfidence = "ai_confidence"
            case receivedAt = "received_date"
            case isUnread = "is_unread"
            case isStarred = "is_starred"
        }
    }

    func sync(context: NSManagedObjectContext) async throws {
        print("🔍 SYNC START: Context = \(context), Thread = \(Thread.current)")

        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

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

        print("✅ Fetched \(emailsResponse.emails.count) emails from backend")

        // Step 3: Save to CoreData using background context
        try await backgroundContext.perform {
            print("🔍 INSIDE backgroundContext.perform: Thread=\(Thread.current)")

            // Get the current user FIRST
            let user = UserEntity.fetchOrCreateCurrent(context: backgroundContext)

            // Create categories if needed
            var categoryMap: [String: CategoryEntity] = [:]
            for email in emailsResponse.emails {
                if let categoryName = email.category, !categoryName.isEmpty {
                    if categoryMap[categoryName] == nil {
                        // Use name-based lookup for categories
                        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
                        request.predicate = NSPredicate(format: "name == %@", categoryName)
                        request.fetchLimit = 1

                        let category: CategoryEntity
                        if let existing = try? backgroundContext.fetch(request).first {
                            category = existing
                        } else {
                            category = CategoryEntity(context: backgroundContext)
                            category.id = UUID()
                            category.name = categoryName
                            category.color = CategoryColors.colorHex(for: categoryName)
                            category.icon = CategoryColors.symbol(for: categoryName)
                        }
                        categoryMap[categoryName] = category
                    }
                }
            }

            // Create/update emails
            print("🔍 Processing \(emailsResponse.emails.count) emails...")
            var createdCount = 0
            for (index, emailPayload) in emailsResponse.emails.enumerated() {
                print("🔍 Email \(index): gmailId=\(emailPayload.gmailId)")

                // Use gmailId as unique identifier (backend uses integer IDs, not UUIDs)
                let fetchRequest: NSFetchRequest<EmailEntity> = EmailEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "gmailId == %@", emailPayload.gmailId)
                fetchRequest.fetchLimit = 1

                let email: EmailEntity
                if let existing = try? backgroundContext.fetch(fetchRequest).first {
                    email = existing
                    print("📧 Found existing email: \(emailPayload.subject ?? "No Subject")")
                } else {
                    email = EmailEntity(context: backgroundContext)
                    email.id = UUID() // Generate new UUID for CoreData
                    email.gmailId = emailPayload.gmailId
                    print("✨ Creating new email: \(emailPayload.subject ?? "No Subject")")
                    createdCount += 1
                }
                email.subject = emailPayload.subject ?? "No Subject"
                email.sender = emailPayload.sender ?? "Unknown"
                email.snippet = self.stripHTML(emailPayload.snippet ?? "")
                email.aiSummary = emailPayload.aiSummary
                email.confidenceScore = emailPayload.aiConfidence
                email.isUnread = emailPayload.isUnread

                // Parse date
                if let date = self.parseDate(emailPayload.receivedAt) {
                    email.receivedAt = date
                } else {
                    print("⚠️ Date parsing failed for email: \(emailPayload.subject ?? "No subject"), defaulting to NOW")
                    email.receivedAt = Date()  // This is why everything shows "in 0 sec"!
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

            print("🔍 BEFORE SAVE: hasChanges=\(backgroundContext.hasChanges), Thread=\(Thread.current)")
            print("🔍 Inserted objects: \(backgroundContext.insertedObjects.count)")
            print("🔍 Updated objects: \(backgroundContext.updatedObjects.count)")

            if backgroundContext.hasChanges {
                do {
                    // Check for validation errors before saving
                    for object in backgroundContext.insertedObjects {
                        if let email = object as? EmailEntity {
                            print("📧 Inserting email: \(email.subject) (id: \(email.id))")
                            do {
                                try backgroundContext.obtainPermanentIDs(for: [email])
                            } catch {
                                print("❌ Failed to obtain permanent ID: \(error)")
                            }
                        }
                    }

                    try backgroundContext.save()
                    print("✅ backgroundContext.save() returned successfully")

                    // Verify IMMEDIATELY after save (still in perform block)
                    let verifyRequest: NSFetchRequest<EmailEntity> = EmailEntity.fetchRequest()
                    let count = try backgroundContext.count(for: verifyRequest)
                    print("🔍 VERIFY: Total emails in database: \(count)")

                    if count == 0 {
                        print("⚠️ COUNT IS ZERO! Checking inserted objects...")
                        print("   Inserted: \(backgroundContext.insertedObjects.count)")
                        print("   Registered: \(backgroundContext.registeredObjects.count)")
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

        // Force main context to refresh and re-fetch with new sort order
        Task { @MainActor in
            print("🔄 Refreshing main context on main thread...")
            
            // Refresh all objects with merge changes
            for object in context.registeredObjects {
                context.refresh(object, mergeChanges: true)
            }
            
            // Save to trigger FetchRequest updates
            if context.hasChanges {
                try? context.save()
            }
            
            print("✅ Main context refreshed - View should re-sort now")
        }
    }

    private func parseDate(_ dateString: String) -> Date? {
        // Backend sends: "2026-03-05T16:04:05" (no timezone)
        // We need to append 'Z' to make it valid ISO8601
        let dateWithTimezone = dateString.hasSuffix("Z") ? dateString : dateString + "Z"
        
        print("📅 Parsing date: '\(dateString)' → '\(dateWithTimezone)'")
        
        let formatter = ISO8601DateFormatter()
        
        // Try with fractional seconds first
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateWithTimezone) {
            print("✅ Parsed successfully: \(date)")
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateWithTimezone) {
            print("✅ Parsed successfully: \(date)")
            return date
        }
        
        print("❌ Failed to parse date: '\(dateString)'")
        return nil
    }
    
    private func stripHTML(_ html: String) -> String {
        // Remove HTML tags
        var text = html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode common HTML entities
        text = text
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#x2F;", with: "/")
            .replacingOccurrences(of: "͏", with: "")  // Zero-width invisible character
        
        // Remove excessive whitespace
        text = text.replacingOccurrences(of: "[ \t]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
