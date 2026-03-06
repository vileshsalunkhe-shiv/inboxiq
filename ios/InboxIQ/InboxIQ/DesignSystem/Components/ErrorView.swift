import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    var actionTitle: String = "Retry"
    var onRetry: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: AppSpacing.iconXl))
                .foregroundStyle(AppColor.error)
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
            Text(message)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
            if let onRetry {
                PrimaryButton(title: actionTitle, systemImage: "arrow.clockwise", action: onRetry)
            }
        }
        .padding(AppSpacing.lg)
    }
}
