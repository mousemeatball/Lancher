import Foundation

/// The ordered collection of a user's folders. Immutable: each mutating-looking method returns a
/// new `FolderList`. Enforces the invariant that an app belongs to **at most one** folder.
public struct FolderList: Codable, Sendable, Equatable {
    public private(set) var folders: [Folder]

    public init(folders: [Folder] = []) {
        self.folders = folders
    }

    // MARK: - Lookup

    public func folder(id: Folder.ID) -> Folder? {
        folders.first { $0.id == id }
    }

    /// Apps inside a folder, resolved against the live discovered set, preserving folder order.
    public func apps(inFolder id: Folder.ID, from allApps: [AppItem]) -> [AppItem] {
        guard let folder = folder(id: id) else { return [] }
        let byID = Dictionary(uniqueKeysWithValues: allApps.map { ($0.id, $0) })
        return folder.appIDs.compactMap { byID[$0] }
    }

    /// Apps that are not in any folder.
    public func looseApps(from allApps: [AppItem]) -> [AppItem] {
        let claimed = Set(folders.flatMap(\.appIDs))
        return allApps.filter { !claimed.contains($0.id) }
    }

    // MARK: - Mutations (return new copies)

    /// Creates a folder, optionally seeded with apps (removed from any other folder first).
    public func creating(name: String, appIDs: [String] = []) -> (list: FolderList, id: Folder.ID) {
        var next = self
        for appID in appIDs { next = next.removingAppFromAllFolders(appID) }
        let folder = Folder(name: name, appIDs: appIDs)
        next.folders.append(folder)
        return (next, folder.id)
    }

    public func renaming(_ id: Folder.ID, to name: String) -> FolderList {
        mapping(id) { $0.renamed(to: name) }
    }

    public func styling(_ id: Folder.ID, colorHex: String?, emoji: String?) -> FolderList {
        mapping(id) { $0.styled(colorHex: colorHex, emoji: emoji) }
    }

    public func removingFolder(_ id: Folder.ID) -> FolderList {
        FolderList(folders: folders.filter { $0.id != id })
    }

    /// Adds an app to a folder, first removing it from any folder it currently lives in.
    public func addingApp(_ appID: String, toFolder id: Folder.ID) -> FolderList {
        removingAppFromAllFolders(appID).mapping(id) { $0.addingApp(appID) }
    }

    public func removingApp(_ appID: String, fromFolder id: Folder.ID) -> FolderList {
        mapping(id) { $0.removingApp(appID) }
    }

    // MARK: - Private

    private func mapping(_ id: Folder.ID, _ transform: (Folder) -> Folder) -> FolderList {
        FolderList(folders: folders.map { $0.id == id ? transform($0) : $0 })
    }

    private func removingAppFromAllFolders(_ appID: String) -> FolderList {
        FolderList(folders: folders.map { $0.removingApp(appID) })
    }
}
