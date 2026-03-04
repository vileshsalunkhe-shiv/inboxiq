import SwiftUI
import CoreData

struct EmailListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \EmailEntity.receivedAt, ascending: false)]
    ) private var emails: FetchedResults<EmailEntity>

    @State private var error: AppError?

    let selectedCategory: CategoryEntity?
    let searchText: String

    var filteredEmails: [EmailEntity] {
        emails.filter { email in
            let matchesCategory = selectedCategory == nil || email.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                email.subject.localizedCaseInsensitiveContains(searchText) ||
                email.sender.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var groupedEmails: [(String, [EmailEntity])] {
        let grouped = Dictionary(grouping: filteredEmails) { email in
            email.receivedAt.formattedDate(style: .medium)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        Group {
            if filteredEmails.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No emails yet")
                        .font(.headline)
                    Text("Pull down to sync your inbox.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedEmails, id: \.0) { section, items in
                        Section(section) {
                            ForEach(items) { email in
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
        .alert(item: $error) { error in
            Alert(title: Text("Update Failed"), message: Text(error.localizedDescription))
        }
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
