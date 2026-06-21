import Foundation

/// Repository abstraction for persisting clipboard history.
public protocol ClipboardStoring: Sendable {
    func load() -> [ClipboardItem]
    func save(_ items: [ClipboardItem]) throws
}

/// JSON-backed store at ~/Library/Application Support/Lancher/clipboard.json.
public struct ClipboardStore: ClipboardStoring {
    public init() {}

    public func load() -> [ClipboardItem] {
        JSONFileStore.load([ClipboardItem].self, from: Config.clipboardFileName) ?? []
    }

    public func save(_ items: [ClipboardItem]) throws {
        try JSONFileStore.save(items, to: Config.clipboardFileName)
    }
}
