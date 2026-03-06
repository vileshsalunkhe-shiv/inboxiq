import Foundation

extension String {
    var emailAddresses: [String] {
        split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func isValidEmail() -> Bool {
        let regex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return range(of: regex, options: .regularExpression) != nil
    }

    func isValidEmailList() -> Bool {
        let emails = emailAddresses
        guard !emails.isEmpty else { return false }
        return emails.allSatisfy { $0.isValidEmail() }
    }

    func firstEmailAddress() -> String {
        let candidates = emailAddresses
        return candidates.first ?? self
    }
}
