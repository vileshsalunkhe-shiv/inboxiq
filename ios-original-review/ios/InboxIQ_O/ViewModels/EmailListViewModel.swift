import Foundation
import CoreData

@MainActor
final class EmailListViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var selectedCategory: CategoryEntity?
    @Published var searchText: String = ""

    func refresh(context: NSManagedObjectContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await SyncService.shared.sync(context: context)
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.network("Failed to sync emails")
        }
    }
}
