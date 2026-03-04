import Foundation
import CoreData

extension CategoryEntity {
    static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> CategoryEntity {
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let existing = try? context.fetch(fetchRequest).first {
            return existing
        }
        
        let entity = CategoryEntity(context: context)
        entity.id = id
        return entity
    }
    
    static func fetchOrCreate(name: String, context: NSManagedObjectContext) -> CategoryEntity {
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        
        if let existing = try? context.fetch(fetchRequest).first {
            return existing
        }
        
        let entity = CategoryEntity(context: context)
        entity.id = UUID()
        entity.name = name
        return entity
    }
}
