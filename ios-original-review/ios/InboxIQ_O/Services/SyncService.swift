import Foundation
import CoreData

final class SyncService {
    static let shared = SyncService()
    private init() {}

    struct SyncResponse: Decodable {
        let emails: [EmailPayload]
        let categories: [CategoryPayload]
        let lastSyncDate: Date
    }

    struct EmailPayload: Decodable {
        let id: UUID
        let gmailId: String
        let subject: String
        let sender: String
        let snippet: String
        let categoryId: UUID?
        let receivedAt: Date
        let syncedAt: Date
        let isUnread: Bool
    }

    struct CategoryPayload: Decodable {
        let id: UUID
        let name: String
        let color: String
        let icon: String
        let count: Int
    }

    func sync(context: NSManagedObjectContext) async throws {
        let response: SyncResponse = try await APIClient.shared.request(
            APIPath.emailSync,
            method: "POST"
        )

        try await context.perform {
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            for category in response.categories {
                let entity = CategoryEntity.fetchOrCreate(id: category.id, context: context)
                entity.id = category.id
                entity.name = category.name
                entity.color = category.color
                entity.icon = category.icon
                entity.count = Int64(category.count)
            }

            for email in response.emails {
                let entity = EmailEntity.fetchOrCreate(id: email.id, context: context)
                entity.id = email.id
                entity.gmailId = email.gmailId
                entity.subject = email.subject
                entity.sender = email.sender
                entity.snippet = email.snippet
                entity.receivedAt = email.receivedAt
                entity.syncedAt = email.syncedAt
                entity.isUnread = email.isUnread

                if let categoryId = email.categoryId {
                    entity.category = CategoryEntity.fetchOrCreate(id: categoryId, context: context)
                }
            }

            let user = UserEntity.fetchOrCreateCurrent(context: context)
            user.lastSyncDate = response.lastSyncDate

            if context.hasChanges {
                try context.save()
            }
        }
    }
}
