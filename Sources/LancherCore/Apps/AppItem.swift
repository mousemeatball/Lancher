import Foundation

/// An installed application discovered on disk.
///
/// Immutable value type: discovery produces fresh `AppItem`s; nothing mutates them in place.
public struct AppItem: Identifiable, Hashable, Sendable {
    /// Stable identity — the bundle identifier when available, otherwise the file path.
    public let id: String
    public let name: String
    public let bundleID: String?
    public let url: URL
    /// Raw `LSApplicationCategoryType` (e.g. "public.app-category.productivity"), if declared.
    public let category: String?

    public init(id: String, name: String, bundleID: String?, url: URL, category: String?) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.url = url
        self.category = category
    }
}
