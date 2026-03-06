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
    @Published var lastFailedOperation: (() async -> Void)?

    static func makeFetchRequest(
        selectedCategory: CategoryDefinition?,
        searchText: String
    ) -> NSFetchRequest<EmailEntity> {
        let request: NSFetchRequest<EmailEntity> = EmailEntity.fetchRequest()
        var predicates: [NSPredicate] = []

        if let category = selectedCategory {
            predicates.append(NSPredicate(format: "category.name == %@", category.name))
        }

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            let searchPredicate = NSPredicate(
                format: "subject CONTAINS[cd] %@ OR sender CONTAINS[cd] %@",
                trimmedSearch,
                trimmedSearch
            )
            predicates.append(searchPredicate)
        }

        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }

        request.sortDescriptors = [NSSortDescriptor(keyPath: \EmailEntity.receivedAt, ascending: false)]
        return request
    }

    func retryLastOperation() async {
        if let operation = lastFailedOperation {
            await operation()
        }
    }

    func refresh(context: NSManagedObjectContext) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await SyncService.shared.sync(context: context)
        } catch let error as AppError {
            lastFailedOperation = { [weak self] in
                await self?.refresh(context: context)
            }
            self.error = error
        } catch {
            lastFailedOperation = { [weak self] in
                await self?.refresh(context: context)
            }
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
            lastFailedOperation = { [weak self] in
                await self?.categorizeAll(context: context)
            }
            self.error = error
        } catch {
            lastFailedOperation = { [weak self] in
                await self?.categorizeAll(context: context)
            }
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
