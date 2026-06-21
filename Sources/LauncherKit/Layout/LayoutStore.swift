import Foundation

/// Persists the user's custom ordering of root-grid entries as a list of entry ids
/// (e.g. "app:com.apple.Safari", "folder:<uuid>", "workflow:<uuid>"). Entries not present in the
/// saved order fall back to the default order and are appended after known ones.
public protocol LayoutStoring: Sendable {
    func load() -> [String]
    func save(_ order: [String]) throws
}

/// JSON-backed store at ~/Library/Application Support/Lancher/layout.json.
public struct LayoutStore: LayoutStoring {
    public init() {}

    public func load() -> [String] {
        JSONFileStore.load([String].self, from: Config.layoutFileName) ?? []
    }

    public func save(_ order: [String]) throws {
        try JSONFileStore.save(order, to: Config.layoutFileName)
    }
}
