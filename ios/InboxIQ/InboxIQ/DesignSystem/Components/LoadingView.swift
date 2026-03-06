import SwiftUI

struct LoadingView: View {
    var text: String? = nil

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
                .tint(AppColor.primary)
            if let text {
                Text(text)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.md)
        .accessibilityLabel(Text(text ?? "Loading"))
    }
}
