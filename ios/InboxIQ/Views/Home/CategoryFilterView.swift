import SwiftUI
import CoreData

struct CategoryFilterView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)]
    ) private var categories: FetchedResults<CategoryEntity>

    @Binding var selectedCategory: CategoryEntity?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(categories) { category in
                    categoryChip(title: category.name, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func categoryChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.inboxBlue : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color(.systemGray4), lineWidth: isSelected ? 0 : 1)
                )
        }
        .accessibilityLabel(title)
    }
}
