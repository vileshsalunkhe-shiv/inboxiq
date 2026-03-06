import SwiftUI

extension Color {
    static let inboxBlue = Color(red: 0.31, green: 0.46, blue: 0.90)
    static let inboxPurple = Color(red: 0.58, green: 0.38, blue: 0.92)
    static let inboxGreen = Color(red: 0.20, green: 0.80, blue: 0.45)
    static let inboxOrange = Color(red: 0.98, green: 0.64, blue: 0.20)
    static let inboxPink = Color(red: 0.96, green: 0.33, blue: 0.55)
    
    static func fromHex(_ hex: String) -> Color {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        return Color(red: red, green: green, blue: blue)
    }
}

extension ShapeStyle where Self == Color {
    static var inboxBlue: Color { .inboxBlue }
}
