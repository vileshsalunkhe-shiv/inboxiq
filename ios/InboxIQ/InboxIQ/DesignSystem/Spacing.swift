import SwiftUI

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48

    static let cornerRadiusSm: CGFloat = 4
    static let cornerRadiusMd: CGFloat = 8
    static let cornerRadiusLg: CGFloat = 12
    static let cornerRadiusXl: CGFloat = 16

    static let iconSm: CGFloat = 16
    static let iconMd: CGFloat = 20
    static let iconLg: CGFloat = 24
    static let iconXl: CGFloat = 32
    static let iconXxl: CGFloat = 40
}

extension View {
    func appPadding(_ value: CGFloat = AppSpacing.md) -> some View {
        padding(value)
    }

    func appPadding(_ edges: Edge.Set, _ value: CGFloat = AppSpacing.md) -> some View {
        padding(edges, value)
    }
}
