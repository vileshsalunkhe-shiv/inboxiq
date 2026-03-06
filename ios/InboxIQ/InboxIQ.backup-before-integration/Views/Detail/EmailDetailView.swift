import SwiftUI
import CoreData

struct EmailDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var error: AppError?
    @State private var selectedCategoryName: String

    let email: EmailEntity

    init(email: EmailEntity) {
        self.email = email
        _selectedCategoryName = State(initialValue: email.category?.name ?? "None")
    }

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
                    CategoryBadge(
                        name: category.name,
                        icon: CategoryColors.symbol(for: category.name),
                        color: Color.fromHex(CategoryColors.colorHex(for: category.name)),
                        isLarge: true
                    )
                }

                Picker("Category", selection: $selectedCategoryName) {
                    Text("None").tag("None")
                    ForEach(CategoryColors.all) { category in
                        Text(category.name).tag(category.name)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Change category")
                .onChange(of: selectedCategoryName) { newValue in
                    updateCategory(name: newValue)
                }

                if let summary = email.aiSummary, !summary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AI Summary")
                            .font(.headline)
                        Text(summary)
                            .foregroundStyle(.primary)
                    }
                }

                if confidenceValue > 0.8 {
                    Text("AI Confidence: \(Int(confidenceValue * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

    private var confidenceValue: Double {
        email.confidenceScore ?? 0
    }

    private func updateCategory(name: String) {
        if name == "None" {
            email.category = nil
        } else {
            let category = CategoryEntity.fetchOrCreate(name: name, context: viewContext)
            email.category = category
        }

        do {
            try viewContext.save()
        } catch {
            self.error = AppError.coreData("Failed to update category")
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
