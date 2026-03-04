import Foundation
import CoreData

extension UserEntity {
    static func fetchOrCreateCurrent(context: NSManagedObjectContext) -> UserEntity {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.fetchLimit = 1
        
        if let existing = try? context.fetch(fetchRequest).first {
            return existing
        }
        
        let entity = UserEntity(context: context)
        entity.id = UUID()
        return entity
    }
}
