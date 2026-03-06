import SwiftUI

enum AppColor {
    static let primary = Color.fromHex("#007AFF")
    static let secondary = Color.fromHex("#5856D6")
    static let accent = Color.fromHex("#FFD60A")

    static let backgroundPrimary = Color.dynamic(
        light: Color.white,
        dark: Color(red: 0.07, green: 0.07, blue: 0.09)
    )
    static let backgroundSecondary = Color.dynamic(
        light: Color(red: 0.96, green: 0.96, blue: 0.98),
        dark: Color(red: 0.12, green: 0.12, blue: 0.16)
    )
    static let backgroundTertiary = Color.dynamic(
        light: Color(red: 0.92, green: 0.92, blue: 0.95),
        dark: Color(red: 0.18, green: 0.18, blue: 0.24)
    )

    static let textPrimary = Color.dynamic(light: .black, dark: .white)
    static let textSecondary = Color.dynamic(
        light: Color(UIColor.darkGray),
        dark: Color(UIColor.lightGray)
    )
    static let textTertiary = Color.dynamic(
        light: Color(UIColor.gray),
        dark: Color(UIColor.systemGray2)
    )
    static let textDisabled = Color.dynamic(
        light: Color(UIColor.systemGray3),
        dark: Color(UIColor.systemGray)
    )

    static let border = Color.dynamic(
        light: Color.black.opacity(0.1),
        dark: Color.white.opacity(0.18)
    )
    static let separator = Color.dynamic(
        light: Color.black.opacity(0.08),
        dark: Color.white.opacity(0.12)
    )
    static let shadow = Color.black.opacity(0.2)

    static let success = Color.fromHex("#34C759")
    static let warning = Color.fromHex("#FF9500")
    static let error = Color.fromHex("#FF3B30")
    static let info = primary

    static func categoryColor(name: String) -> Color {
        CategoryColors.definition(for: name)?.color ?? Color.fromHex("#8E8E93")
    }

    static func categoryBackground(for color: Color) -> Color {
        Color.dynamic(
            light: color.opacity(0.16),
            dark: color.opacity(0.3)
        )
    }
}

extension Color {
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
