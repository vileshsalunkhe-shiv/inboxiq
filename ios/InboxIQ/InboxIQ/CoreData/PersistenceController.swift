import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "InboxIQ")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                Logger.error("Core Data failed to load: \(error.localizedDescription)")
                fatalError("Core Data store failed to load: \(error)")
            }
            print("✅ Persistent store loaded: \(description.url?.path ?? "unknown")")
            print("✅ Store type: \(description.type)")
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        print("✅ PersistenceController initialized")
        print("   Context: \(container.viewContext)")
        print("   Coordinator: \(container.viewContext.persistentStoreCoordinator)")
    }
}

// MARK: - Core Data Entities

@objc(EmailEntity)
public class EmailEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var gmailId: String
    @NSManaged public var subject: String
    @NSManaged public var sender: String
    @NSManaged public var snippet: String
    @NSManaged public var receivedAt: Date
    @NSManaged public var syncedAt: Date
    @NSManaged public var isUnread: Bool
    @NSManaged public var category: CategoryEntity?
    @NSManaged public var user: UserEntity?
}

@objc(CategoryEntity)
public class CategoryEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var color: String
    @NSManaged public var icon: String
    @NSManaged public var count: Int64
    @NSManaged public var emails: NSSet?
}

@objc(UserEntity)
public class UserEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var email: String
    @NSManaged public var lastSyncDate: Date?
    @NSManaged public var emails: NSSet?
    @NSManaged public var calendarConnected: Bool
    @NSManaged public var calendarEvents: NSSet?
}

@objc(CalendarEventEntity)
public class CalendarEventEntity: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var eventId: String
    @NSManaged public var summary: String
    @NSManaged public var eventDescription: String?
    @NSManaged public var startDate: Date
    @NSManaged public var endDate: Date
    @NSManaged public var location: String?
    @NSManaged public var htmlLink: String?
    @NSManaged public var user: UserEntity?
}

// MARK: - Fetch Helpers

extension EmailEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmailEntity> {
        NSFetchRequest<EmailEntity>(entityName: "EmailEntity")
    }

    static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> EmailEntity {
        let request: NSFetchRequest<EmailEntity> = EmailEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let entity = EmailEntity(context: context)
        entity.id = id
        return entity
    }
}

extension CategoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> CategoryEntity {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let entity = CategoryEntity(context: context)
        entity.id = id
        return entity
    }
}

extension UserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    static func fetchOrCreateCurrent(context: NSManagedObjectContext) -> UserEntity {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let entity = UserEntity(context: context)
        entity.id = UUID()
        entity.calendarConnected = false
        return entity
    }
}
