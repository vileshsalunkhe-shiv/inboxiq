import SwiftUI

struct CategoryDefinition: Identifiable, Hashable {
    let name: String
    let colorHex: String
    let symbol: String
    let description: String

    var id: String { name }
    var color: Color { Color.fromHex(colorHex) }
    var accessibilityLabel: String { "\(name) email" }
}

enum CategoryColors {
    static let all: [CategoryDefinition] = [
        CategoryDefinition(name: "Urgent", colorHex: "#FF3B30", symbol: "exclamationmark.circle.fill", description: "Needs immediate attention"),
        CategoryDefinition(name: "Action Required", colorHex: "#FF9500", symbol: "bolt.fill", description: "Requires response/action"),
        CategoryDefinition(name: "Finance", colorHex: "#FFD700", symbol: "dollarsign.circle.fill", description: "Banks, credit cards, investments, bills"),
        CategoryDefinition(name: "FYI", colorHex: "#007AFF", symbol: "info.circle.fill", description: "Informational, no action needed"),
        CategoryDefinition(name: "Newsletter", colorHex: "#AF52DE", symbol: "newspaper.fill", description: "Subscriptions, marketing"),
        CategoryDefinition(name: "Receipt", colorHex: "#34C759", symbol: "receipt.fill", description: "Purchase confirmations"),
        CategoryDefinition(name: "Spam", colorHex: "#8E8E93", symbol: "nosign", description: "Junk, unwanted")
    ]

    static func definition(for name: String) -> CategoryDefinition? {
        all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    static func colorHex(for name: String) -> String {
        definition(for: name)?.colorHex ?? "#8E8E93"
    }

    static func symbol(for name: String) -> String {
        definition(for: name)?.symbol ?? "tag.fill"
    }

    static func description(for name: String) -> String {
        definition(for: name)?.description ?? ""
    }
}
