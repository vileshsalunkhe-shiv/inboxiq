import SwiftUI

struct EmptyStateView: View {
    let title: String
    let message: String
    var systemImage: String = "tray"

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: systemImage)
                .font(.system(size: AppSpacing.iconXxl))
                .foregroundStyle(AppColor.textTertiary)
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.lg)
    }
}
