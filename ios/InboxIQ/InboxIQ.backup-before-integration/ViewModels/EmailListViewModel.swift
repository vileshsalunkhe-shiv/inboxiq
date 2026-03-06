import Foundation
import CoreData
import Combine
import SwiftUI

@MainActor
final class EmailListViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isCategorizing = false
    @Published var showSuccessToast = false
    @Published var error: AppError?
    @Published var selectedCategory: CategoryDefinition?
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

    func categorizeAll(context: NSManagedObjectContext) async {
        guard !isCategorizing else { return }
        isCategorizing = true
        defer { isCategorizing = false }

        do {
            _ = try await CategorizationService.shared.categorizeAll(limit: 200)
            try await SyncService.shared.sync(context: context)
            showToast()
        } catch let error as AppError {
            self.error = error
        } catch {
            self.error = AppError.network("Failed to categorize emails")
        }
    }

    private func showToast() {
        withAnimation(.easeInOut) {
            showSuccessToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut) {
                self.showSuccessToast = false
            }
        }
    }
}
