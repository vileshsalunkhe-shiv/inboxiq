import SwiftUI

struct EmailRowView: View {
    let email: EmailEntity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.fromHex(email.category?.color ?? "#4F46E5"))
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(email.sender)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(email.receivedAt.relativeDescription())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(email.subject)
                    .fontWeight(email.isUnread ? .bold : .regular)
                    .lineLimit(1)

                if let summary = email.aiSummary, !summary.isEmpty {
                    Text(summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Text(email.snippet)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let category = email.category {
                    CategoryBadge(
                        name: category.name,
                        icon: categoryIcon,
                        color: categoryColor
                    )
                    .accessibilityLabel(Text("\(category.name) email"))
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var categoryDefinition: CategoryDefinition? {
        guard let category = email.category else { return nil }
        return CategoryColors.definition(for: category.name)
    }

    private var categoryColor: Color {
        guard let category = email.category else { return .clear }
        return Color.fromHex(categoryDefinition?.colorHex ?? category.color)
    }

    private var categoryIcon: String {
        guard let category = email.category else { return "tag.fill" }
        return categoryDefinition?.symbol ?? category.icon
    }
}
