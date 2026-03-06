import SwiftUI

struct ToastData: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
}

enum ToastStyle {
    case success
    case error
    case info

    var backgroundColor: Color {
        switch self {
        case .success: return AppColor.success
        case .error: return AppColor.error
        case .info: return AppColor.secondary
        }
    }
}

struct ToastView: View {
    let text: String
    let style: ToastStyle

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(style.backgroundColor.opacity(0.92))
            .clipShape(Capsule())
            .shadow(radius: 8)
            .accessibilityLabel(text)
    }
}
