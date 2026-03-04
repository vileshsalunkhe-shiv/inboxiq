import Foundation
import os

enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.inboxiq"
    private static let category = "InboxIQ"
    private static let logger = os.Logger(subsystem: subsystem, category: category)

    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }

    static func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
