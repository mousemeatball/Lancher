import Foundation

/// JSON-backed folder store at ~/Library/Application Support/Lancher/folders.json.
public struct FolderStore: FolderStoring {
    public init() {}

    private func fileURL() throws -> URL {
        try Config.appSupportDirectory().appending(path: Config.foldersFileName)
    }

    public func load() -> FolderList {
        guard let url = try? fileURL(),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode(FolderList.self, from: data)
        else { return FolderList() }
        return list
    }

    public func save(_ list: FolderList) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(list)
        try data.write(to: try fileURL(), options: [.atomic])
    }
}
