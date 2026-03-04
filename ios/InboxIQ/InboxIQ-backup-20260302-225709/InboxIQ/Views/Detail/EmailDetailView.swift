import SwiftUI
import CoreData
struct EmailDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var error: AppError?

    let email: EmailEntity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(email.subject)
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(email.sender)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(email.receivedAt.formattedDate())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                if let category = email.category {
                    Text("\(category.icon) \(category.name)")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.fromHex(category.color).opacity(0.2))
                        .clipShape(Capsule())
                }

                Divider()

                Text(email.snippet)
                    .font(.body)
                    .foregroundStyle(.primary)

                HStack(spacing: 16) {
                    Button {
                        archiveEmail()
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        deleteEmail()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Email")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $error) { error in
            Alert(title: Text("Action Failed"), message: Text(error.localizedDescription))
        }
    }

    private func archiveEmail() {
        email.isUnread = false
        do {
            try viewContext.save()
        } catch {
            self.error = AppError.coreData("Failed to archive email")
        }
    }

    private func deleteEmail() {
        viewContext.delete(email)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            self.error = AppError.coreData("Failed to delete email")
        }
    }
}
