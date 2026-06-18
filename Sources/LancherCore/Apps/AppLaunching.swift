import Foundation

/// Abstraction over launching an app, so the view model can be tested with a spy.
public protocol AppLaunching {
    func launch(_ app: AppItem) throws
}

public enum LaunchError: LocalizedError {
    case failedToLaunch(String)

    public var errorDescription: String? {
        switch self {
        case .failedToLaunch(let name): "Couldn't launch \(name)."
        }
    }
}

#if canImport(AppKit)
import AppKit

/// Production launcher backed by `NSWorkspace`.
public struct WorkspaceAppLauncher: AppLaunching {
    public init() {}

    public func launch(_ app: AppItem) throws {
        guard NSWorkspace.shared.open(app.url) else {
            throw LaunchError.failedToLaunch(app.name)
        }
    }
}
#endif
