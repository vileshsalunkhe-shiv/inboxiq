import SwiftUI

struct EmailRowView: View {
    let email: EmailEntity

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.fromHex(email.category?.color ?? "#4F46E5"))
                .frame(width: 10, height: 10)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 4) {
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

                Text(email.snippet)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let category = email.category {
                    Text("\(category.icon) \(category.name)")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.fromHex(category.color).opacity(0.15))
                        .clipShape(Capsule())
                        .accessibilityLabel("Category \(category.name)")
                }
            }
        }
        .padding(.vertical, 6)
    }
}
