import Foundation

/// Opens an arbitrary URL (app bundle, file/folder, or web link). Abstracted so the workflow
/// runner can be unit-tested without opening anything.
public protocol URLOpening: Sendable {
    @discardableResult
    func open(_ url: URL) -> Bool
}

#if canImport(AppKit)
import AppKit

public struct WorkspaceURLOpener: URLOpening {
    public init() {}
    public func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}
#endif
