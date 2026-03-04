import Foundation
import CoreData

extension EmailEntity {
    static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> EmailEntity {
        let fetchRequest: NSFetchRequest<EmailEntity> = EmailEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let existing = try? context.fetch(fetchRequest).first {
            return existing
        }
        
        let entity = EmailEntity(context: context)
        entity.id = id
        return entity
    }
}
