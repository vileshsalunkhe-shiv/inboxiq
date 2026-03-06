import SwiftUI

struct CategoryFilterSheet: View {
    @Binding var selectedCategory: CategoryDefinition?
    var onSelection: (() -> Void)?

    var body: some View {
        NavigationStack {
            List {
                Button {
                    selectedCategory = nil
                    onSelection?()
                } label: {
                    HStack {
                        Text("All Emails")
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.inboxBlue)
                        }
                    }
                }

                ForEach(CategoryColors.all) { category in
                    Button {
                        selectedCategory = category
                        onSelection?()
                    } label: {
                        HStack(spacing: 12) {
                            CategoryBadge(
                                name: category.name,
                                icon: category.symbol,
                                color: category.color
                            )
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.name)
                                    .foregroundStyle(.primary)
                                Text(category.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedCategory == category {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.inboxBlue)
                            }
                        }
                    }
                    .accessibilityLabel(Text("Filter by \(category.name)"))
                }
            }
            .navigationTitle("Filter Emails")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    CategoryFilterSheet(selectedCategory: .constant(nil))
}
