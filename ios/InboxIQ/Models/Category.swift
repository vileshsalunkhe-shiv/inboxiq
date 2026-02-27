import Foundation

struct Category: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let colorHex: String
    let icon: String
    let count: Int

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        icon: String,
        count: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.count = count
    }
}
