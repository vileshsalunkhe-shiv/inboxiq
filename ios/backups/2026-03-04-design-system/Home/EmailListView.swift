import SwiftUI
import CoreData
import Combine

struct EmailListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var emails: FetchedResults<EmailEntity>

    @State private var error: AppError?
    @State private var lastFailedOperation: (() async -> Void)?

    let selectedCategory: CategoryDefinition?
    let searchText: String
    @Binding var scrollToTopTrigger: Bool

    init(selectedCategory: CategoryDefinition?, searchText: String, scrollToTopTrigger: Binding<Bool>) {
        self.selectedCategory = selectedCategory
        self.searchText = searchText
        self._scrollToTopTrigger = scrollToTopTrigger
        _emails = FetchRequest(
            fetchRequest: EmailListViewModel.makeFetchRequest(
                selectedCategory: selectedCategory,
                searchText: searchText
            ),
            animation: .default
        )
    }

    private var filteredEmails: [EmailEntity] {
        Array(emails)
    }

    private var groupedEmails: [(String, [EmailEntity])] {
        let grouped = Dictionary(grouping: filteredEmails) { email in
            email.receivedAt.formattedDate(style: .medium)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        ScrollViewReader { proxy in
            Group {
                if filteredEmails.isEmpty {
                    emptyStateView
                } else {
                    List {
                        Color.clear
                            .frame(height: 0)
                            .id("top")

                        ForEach(groupedEmails, id: \.0) { section, items in
                            Section(section) {
                                ForEach(items, id: \.self) { email in
                                    NavigationLink {
                                        EmailDetailView(email: email)
                                    } label: {
                                        EmailRowView(email: email)
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            deleteEmail(email)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            archiveEmail(email)
                                        } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        .tint(.inboxBlue)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .onChange(of: selectedCategory?.name) { _ in
                withAnimation(.easeInOut) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
            .onChange(of: scrollToTopTrigger) { shouldScroll in
                guard shouldScroll else { return }
                withAnimation(.easeInOut) {
                    proxy.scrollTo("top", anchor: .top)
                }
                DispatchQueue.main.async {
                    scrollToTopTrigger = false
                }
            }
        }
        .alert("Update Failed", isPresented: Binding(
            get: { error != nil },
            set: { isPresented in if !isPresented { error = nil } }
        )) {
            Button("Retry") {
                Task {
                    await retryLastOperation()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(emptyTitle)
                .font(.headline)
            Text(emptySubtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyTitle: String {
        if let selectedCategory {
            return "No \(selectedCategory.name) emails"
        }
        return "No emails yet"
    }

    private var emptySubtitle: String {
        if let selectedCategory {
            return "Try a different filter or categorize your inbox."
        }
        return "Pull down to sync your inbox."
    }

    private func archiveEmail(_ email: EmailEntity) {
        email.isUnread.toggle()
        do {
            try viewContext.save()
        } catch {
            lastFailedOperation = { @MainActor in
                self.archiveEmail(email)
            }
            self.error = AppError.coreData("Failed to update email")
        }
    }

    private func deleteEmail(_ email: EmailEntity) {
        viewContext.delete(email)
        do {
            try viewContext.save()
        } catch {
            lastFailedOperation = { @MainActor in
                self.deleteEmail(email)
            }
            self.error = AppError.coreData("Failed to delete email")
        }
    }

    private func retryLastOperation() async {
        if let operation = lastFailedOperation {
            await operation()
        }
    }
}
