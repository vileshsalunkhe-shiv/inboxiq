import Foundation

extension EmailEntity {
    private var starredKey: String { "email_starred_\(gmailId)" }
    private var archivedKey: String { "email_archived_\(gmailId)" }

    var isStarred: Bool {
        get { UserDefaults.standard.bool(forKey: starredKey) }
        set { UserDefaults.standard.set(newValue, forKey: starredKey) }
    }

    var isArchived: Bool {
        get { UserDefaults.standard.bool(forKey: archivedKey) }
        set { UserDefaults.standard.set(newValue, forKey: archivedKey) }
    }
}
