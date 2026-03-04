import Foundation
import CoreData
import Combine

@MainActor
final class SyncViewModel: ObservableObject {
    @Published var lastSyncDate: Date?
    @Published var isSyncing = false
    @Published var error: AppError?

    func performSync(context: NSManagedObjectContext) async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            try await SyncService.shared.sync(context: context)
            lastSyncDate = Date()
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.network("Background sync failed")
        }
    }
}

