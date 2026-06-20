import Foundation

/// An installed application, as discovered on disk.
///
/// A pure value type so it is `Sendable` and trivially testable. The icon is intentionally *not*
/// stored here — views load it on demand from `url` via `NSWorkspace` — which keeps the model free
/// of AppKit and cheap to copy.
public struct AppItem: Identifiable, Hashable, Sendable {
    /// Bundle identifier when available, otherwise the file-system path. Used for de-duplication.
    public let id: String
    public let name: String
    public let url: URL
    public let bundleID: String?
    public let category: String?

    public init(id: String, name: String, url: URL, bundleID: String?, category: String?) {
        self.id = id
        self.name = name
        self.url = url
        self.bundleID = bundleID
        self.category = category
    }
}
