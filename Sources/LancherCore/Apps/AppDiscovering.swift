import Foundation

/// Abstraction over app discovery so the launcher can be tested against fixtures
/// (repository pattern — business logic depends on this, not on the filesystem).
public protocol AppDiscovering {
    func discoverApps() -> [AppItem]
}
