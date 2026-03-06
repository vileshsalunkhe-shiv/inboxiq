import Foundation
import CoreData
import Combine
@MainActor
final class CalendarListViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: AppError?

    func refresh(context: NSManagedObjectContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await CalendarService.shared.syncCalendar(context: context)
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.network("Failed to sync calendar")
        }
    }

    func createEvent(
        context: NSManagedObjectContext,
        summary: String,
        startDate: Date,
        endDate: Date,
        description: String?,
        location: String?,
        attendees: [String]?
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let user = UserEntity.fetchOrCreateCurrent(context: context)
            let request = CalendarEventCreateRequest(
                summary: summary,
                startTime: formatDate(startDate),
                endTime: formatDate(endDate),
                description: description?.isEmpty == true ? nil : description,
                location: location?.isEmpty == true ? nil : location,
                attendees: attendees?.filter { !$0.isEmpty }
            )
            let created = try await CalendarService.shared.createEvent(userId: user.id, request: request)

            try await context.perform {
                let entity = CalendarEventEntity.fetchOrCreate(eventId: created.id, context: context)
                entity.summary = created.summary ?? "(No Title)"
                entity.eventDescription = created.description
                entity.startDate = CalendarService.shared.parseDate(created.start) ?? startDate
                entity.endDate = CalendarService.shared.parseDate(created.end) ?? endDate
                entity.location = created.location
                entity.htmlLink = created.htmlLink
                entity.user = user

                if context.hasChanges {
                    try context.save()
                }
            }
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.network("Failed to create event")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
