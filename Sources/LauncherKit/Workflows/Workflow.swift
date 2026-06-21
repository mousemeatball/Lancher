import Foundation

/// A "launch many things at once" preset: a set of apps (by `AppItem.id`) plus file/folder paths,
/// opened together. Immutable value type — edits return new copies.
public struct Workflow: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let emoji: String?
    public let appIDs: [String]
    public let paths: [String]

    public init(
        id: UUID = UUID(),
        name: String,
        emoji: String? = nil,
        appIDs: [String] = [],
        paths: [String] = []
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.appIDs = appIDs
        self.paths = paths
    }

    public func renamed(to newName: String) -> Workflow {
        Workflow(id: id, name: newName, emoji: emoji, appIDs: appIDs, paths: paths)
    }

    public func addingApp(_ appID: String) -> Workflow {
        guard !appIDs.contains(appID) else { return self }
        return Workflow(id: id, name: name, emoji: emoji, appIDs: appIDs + [appID], paths: paths)
    }

    public func removingApp(_ appID: String) -> Workflow {
        Workflow(id: id, name: name, emoji: emoji, appIDs: appIDs.filter { $0 != appID }, paths: paths)
    }

    public func addingPath(_ path: String) -> Workflow {
        guard !paths.contains(path) else { return self }
        return Workflow(id: id, name: name, emoji: emoji, appIDs: appIDs, paths: paths + [path])
    }

    /// Total number of things this workflow opens.
    public var itemCount: Int { appIDs.count + paths.count }
}
