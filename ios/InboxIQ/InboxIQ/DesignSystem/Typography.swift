import SwiftUI

enum AppTypography {
    static let titleLarge = Font.system(.largeTitle, design: .default).weight(.bold)
    static let titleMedium = Font.system(.title2, design: .default).weight(.semibold)
    static let titleSmall = Font.system(.title3, design: .default).weight(.semibold)

    static let headline = Font.system(.headline, design: .default)
    static let subheadline = Font.system(.subheadline, design: .default)

    static let body = Font.system(.body, design: .default)
    static let bodyEmphasis = Font.system(.body, design: .default).weight(.semibold)

    static let caption = Font.system(.caption, design: .default)
    static let captionSmall = Font.system(.caption2, design: .default)

    static let button = Font.system(.callout, design: .default).weight(.semibold)
}
