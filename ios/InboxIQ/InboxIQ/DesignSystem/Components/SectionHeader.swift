import SwiftUI

struct SectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppTypography.headline)
                .foregroundStyle(AppColor.textPrimary)
            Divider()
                .background(AppColor.separator)
        }
    }
}
