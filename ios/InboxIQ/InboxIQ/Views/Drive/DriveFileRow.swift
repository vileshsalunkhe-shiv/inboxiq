import SwiftUI

struct DriveFileRow: View {
    let file: DriveFile

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: iconForMimeType(file.mimeType))
                .font(.system(size: AppSpacing.iconLg))
                .foregroundStyle(colorForMimeType(file.mimeType))
                .frame(width: AppSpacing.iconLg)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(file.name)
                    .font(AppTypography.bodyEmphasis)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)

                HStack(spacing: AppSpacing.xs) {
                    Text(formatFileSize(file.size))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    Text("•")
                        .foregroundStyle(AppColor.textSecondary)

                    Text(formatDate(file.modifiedTime))
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(AppColor.textTertiary)
        }
        .padding(.vertical, AppSpacing.xs)
        .contentShape(Rectangle())
    }

    private func iconForMimeType(_ mimeType: String) -> String {
        if mimeType.contains("folder") { return "folder.fill" }
        if mimeType.contains("pdf") { return "doc.fill" }
        if mimeType.contains("image") { return "photo.fill" }
        if mimeType.contains("spreadsheet") || mimeType.contains("excel") {
            return "tablecells.fill"
        }
        if mimeType.contains("document") || mimeType.contains("word") {
            return "doc.text.fill"
        }
        if mimeType.contains("presentation") || mimeType.contains("powerpoint") {
            return "play.rectangle.fill"
        }
        if mimeType.contains("video") { return "video.fill" }
        if mimeType.contains("audio") { return "music.note" }
        return "doc.fill"
    }

    private func colorForMimeType(_ mimeType: String) -> Color {
        if mimeType.contains("folder") { return .yellow }
        if mimeType.contains("pdf") { return .red }
        if mimeType.contains("image") { return .blue }
        if mimeType.contains("spreadsheet") || mimeType.contains("excel") { return .green }
        if mimeType.contains("presentation") { return .orange }
        if mimeType.contains("video") { return .purple }
        return AppColor.primary
    }

    private func formatFileSize(_ bytes: Int) -> String {
        guard bytes > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
