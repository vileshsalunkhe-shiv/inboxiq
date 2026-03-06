import SwiftUI
import CoreData
import Combine

struct EmailListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EmailEntity.receivedAt, ascending: false)]
    ) private var emails: FetchedResults<EmailEntity>

    @State private var error: AppError?

    let selectedCategory: CategoryDefinition?
    let searchText: String
    @Binding var scrollToTopTrigger: Bool

    private var filteredEmails: [EmailEntity] {
        let filtered = emails.filter { email in
            let matchesCategory = selectedCategory == nil || email.category?.name == selectedCategory?.name
            let matchesSearch = searchText.isEmpty ||
                email.subject.localizedCaseInsensitiveContains(searchText) ||
                email.sender.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
        return filtered
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
        .alert(item: $error) { error in
            Alert(title: Text("Update Failed"), message: Text(error.localizedDescription))
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
            self.error = AppError.coreData("Failed to update email")
        }
    }

    private func deleteEmail(_ email: EmailEntity) {
        viewContext.delete(email)
        do {
            try viewContext.save()
        } catch {
            self.error = AppError.coreData("Failed to delete email")
        }
    }
}
