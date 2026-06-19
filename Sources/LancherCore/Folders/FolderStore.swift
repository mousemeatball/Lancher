import Foundation

/// Persists folders as JSON under `~/Library/Application Support/Lancher/folders.json`.
///
/// A missing or unreadable file is treated as "no folders yet" rather than an error, so a
/// first run (or a corrupt file) degrades gracefully to an empty grid instead of crashing.
public struct FolderStore: FolderStoring {
    private let fileURL: URL

    /// - Parameter directory: override the storage directory (used by tests). Defaults to the
    ///   app's Application Support directory.
    public init(directory: URL? = nil) {
        let base = directory ?? Self.defaultDirectory()
        self.fileURL = base.appending(path: Config.foldersFileName)
    }

    public func load() -> FolderList {
        guard let data = try? Data(contentsOf: fileURL) else { return FolderList() }
        return (try? JSONDecoder().decode(FolderList.self, from: data)) ?? FolderList()
    }

    public func save(_ folders: FolderList) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(folders)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func defaultDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Library/Application Support")
        return appSupport.appending(path: Config.appSupportFolderName)
    }
}
