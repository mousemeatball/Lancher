import Foundation

/// An immutable, ordered collection of `Folder`s with pure, side-effect-free operations.
///
/// All mutating-sounding methods return a new `FolderList`. This is the single source of truth
/// for which apps live in which folder; an app belongs to **at most one** folder (Launchpad
/// semantics), so `addingApp` first detaches the app from any other folder.
public struct FolderList: Codable, Equatable, Sendable {
    public let folders: [Folder]

    public init(folders: [Folder] = []) {
        self.folders = folders
    }

    // MARK: - Lookup

    public func folder(id: Folder.ID) -> Folder? {
        folders.first { $0.id == id }
    }

    /// Every app id that currently belongs to some folder.
    public var assignedAppIDs: Set<String> {
        Set(folders.flatMap(\.appIDs))
    }

    /// Apps not in any folder, in the order they appear in `apps`.
    public func looseApps(from apps: [AppItem]) -> [AppItem] {
        let assigned = assignedAppIDs
        return apps.filter { !assigned.contains($0.id) }
    }

    /// Apps contained in a folder, ordered by the folder's `appIDs`. Ids with no matching
    /// installed app (e.g. an app was uninstalled) are silently skipped.
    public func apps(inFolder id: Folder.ID, from apps: [AppItem]) -> [AppItem] {
        guard let folder = folder(id: id) else { return [] }
        let byID = Dictionary(apps.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return folder.appIDs.compactMap { byID[$0] }
    }

    // MARK: - Mutations (return new copies)

    public func creating(name: String, appIDs: [String] = []) -> (list: FolderList, id: Folder.ID) {
        let folder = Folder(name: name, appIDs: appIDs)
        let detached = folders.map { detach(appIDs, from: $0) }
        return (FolderList(folders: detached + [folder]), folder.id)
    }

    public func renaming(_ id: Folder.ID, to name: String) -> FolderList {
        FolderList(folders: folders.map { $0.id == id ? $0.renamed(to: name) : $0 })
    }

    public func removingFolder(_ id: Folder.ID) -> FolderList {
        FolderList(folders: folders.filter { $0.id != id })
    }

    /// Attaches `appID` to the target folder, detaching it from any other folder first.
    public func addingApp(_ appID: String, toFolder id: Folder.ID) -> FolderList {
        FolderList(folders: folders.map { folder in
            if folder.id == id { return folder.adding(appID) }
            return folder.removing(appID)
        })
    }

    /// Detaches `appID` from the given folder (the app returns to the loose grid).
    public func removingApp(_ appID: String, fromFolder id: Folder.ID) -> FolderList {
        FolderList(folders: folders.map { $0.id == id ? $0.removing(appID) : $0 })
    }

    // MARK: - Private

    private func detach(_ appIDs: [String], from folder: Folder) -> Folder {
        appIDs.reduce(folder) { $0.removing($1) }
    }
}
