import Foundation

/// Abstraction over folder persistence (repository pattern) so the view model can be tested
/// against an in-memory double instead of touching the filesystem.
public protocol FolderStoring: Sendable {
    /// Returns the persisted folders, or an empty list if nothing has been saved yet.
    func load() -> FolderList
    func save(_ folders: FolderList) throws
}
