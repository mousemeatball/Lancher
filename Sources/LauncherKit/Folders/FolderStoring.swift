import Foundation

/// Repository abstraction for persisting the user's folders, so the view model can be tested with
/// an in-memory implementation.
public protocol FolderStoring: Sendable {
    func load() -> FolderList
    func save(_ list: FolderList) throws
}
