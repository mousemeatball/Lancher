import Foundation

/// A user-created folder grouping apps. An immutable value type — every edit returns a new copy.
/// `appIDs` reference `AppItem.id`; the live `AppItem`s are resolved against the discovered set so
/// the folder survives apps being installed/removed.
public struct Folder: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let name: String
    public let appIDs: [String]
    /// Optional hex color (e.g. "#4C6BFF") and emoji for the folder tile.
    public let colorHex: String?
    public let emoji: String?

    public init(
        id: UUID = UUID(),
        name: String,
        appIDs: [String] = [],
        colorHex: String? = nil,
        emoji: String? = nil
    ) {
        self.id = id
        self.name = name
        self.appIDs = appIDs
        self.colorHex = colorHex
        self.emoji = emoji
    }

    public func renamed(to newName: String) -> Folder {
        Folder(id: id, name: newName, appIDs: appIDs, colorHex: colorHex, emoji: emoji)
    }

    public func addingApp(_ appID: String) -> Folder {
        guard !appIDs.contains(appID) else { return self }
        return Folder(id: id, name: name, appIDs: appIDs + [appID], colorHex: colorHex, emoji: emoji)
    }

    public func removingApp(_ appID: String) -> Folder {
        Folder(id: id, name: name, appIDs: appIDs.filter { $0 != appID }, colorHex: colorHex, emoji: emoji)
    }

    public func styled(colorHex: String?, emoji: String?) -> Folder {
        Folder(id: id, name: name, appIDs: appIDs, colorHex: colorHex, emoji: emoji)
    }
}
