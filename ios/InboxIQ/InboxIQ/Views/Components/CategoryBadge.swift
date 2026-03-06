import SwiftUI

struct CategoryBadge: View {
    let name: String
    let icon: String
    let color: Color
    var isLarge: Bool = false

    @Environment(\.colorSchemeContrast) private var colorContrast
    @State private var isVisible = false

    private var backgroundOpacity: Double {
        colorContrast == .increased ? 0.28 : 0.16
    }

    var body: some View {
        HStack(spacing: isLarge ? 8 : 6) {
            Image(systemName: icon)
                .font(isLarge ? .headline : .caption)
            Text(name)
                .font(isLarge ? .subheadline.weight(.semibold) : .caption)
        }
        .padding(.horizontal, isLarge ? 12 : 8)
        .padding(.vertical, isLarge ? 8 : 4)
        .background(color.opacity(backgroundOpacity))
        .foregroundStyle(color)
        .clipShape(Capsule())
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
            }
        }
        .accessibilityLabel(Text("\(name) email"))
    }
}

#Preview {
    CategoryBadge(
        name: "Urgent",
        icon: "exclamationmark.circle.fill",
        color: Color.fromHex("#FF3B30"),
        isLarge: true
    )
}
