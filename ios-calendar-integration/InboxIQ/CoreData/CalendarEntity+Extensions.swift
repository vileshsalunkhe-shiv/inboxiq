import CoreData
import Foundation

extension CalendarEventEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CalendarEventEntity> {
        NSFetchRequest<CalendarEventEntity>(entityName: "CalendarEventEntity")
    }

    static func fetchOrCreate(eventId: String, context: NSManagedObjectContext) -> CalendarEventEntity {
        let request: NSFetchRequest<CalendarEventEntity> = CalendarEventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "eventId == %@", eventId)
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        let entity = CalendarEventEntity(context: context)
        entity.id = UUID()
        entity.eventId = eventId
        return entity
    }
}

extension UserEntity {
    func setCalendarConnected(_ connected: Bool, context: NSManagedObjectContext) {
        calendarConnected = connected
        do {
            try context.save()
        } catch {
            Logger.error("Failed to update calendar connection: \(error.localizedDescription)")
        }
    }
}
