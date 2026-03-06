import SwiftUI

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: AppSpacing.iconMd, weight: .semibold))
                }
                Text(title)
                    .font(AppTypography.button)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .foregroundStyle(AppColor.primary)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLg, style: .continuous)
                .stroke(AppColor.primary, lineWidth: 1)
        )
        .accessibilityLabel(Text(title))
    }
}
