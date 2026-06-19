import Foundation

/// A user-created folder grouping a set of apps (referenced by their stable `AppItem.id`).
///
/// Immutable value type: every "edit" (`renamed`, `adding`, `removing`) returns a fresh copy
/// rather than mutating in place, matching the rest of the codebase.
public struct Folder: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    /// Ordered `AppItem.id`s contained in this folder. Order is preserved for display.
    public let appIDs: [String]

    public init(id: String = UUID().uuidString, name: String, appIDs: [String] = []) {
        self.id = id
        self.name = name
        self.appIDs = appIDs
    }

    public func renamed(to newName: String) -> Folder {
        Folder(id: id, name: newName, appIDs: appIDs)
    }

    /// Returns a copy with `appID` appended, or `self` if it is already present.
    public func adding(_ appID: String) -> Folder {
        guard !appIDs.contains(appID) else { return self }
        return Folder(id: id, name: name, appIDs: appIDs + [appID])
    }

    public func removing(_ appID: String) -> Folder {
        Folder(id: id, name: name, appIDs: appIDs.filter { $0 != appID })
    }
}
