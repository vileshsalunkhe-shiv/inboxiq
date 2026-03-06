import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
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
        .background(AppColor.primary)
        .foregroundStyle(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cornerRadiusLg, style: .continuous))
        .shadow(color: AppColor.shadow.opacity(0.25), radius: 6, x: 0, y: 4)
        .accessibilityLabel(Text(title))
    }
}
