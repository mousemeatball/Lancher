import Foundation

/// Abstracts app discovery so the launcher can be tested with a fixed, in-memory app list.
public protocol AppDiscovering: Sendable {
    func discoverApps() -> [AppItem]
}
