#if canImport(AppKit)
import AppKit

/// Launches apps through `NSWorkspace`.
public struct WorkspaceAppLauncher: AppLaunching {
    public init() {}

    public func launch(_ app: AppItem) throws {
        guard NSWorkspace.shared.open(app.url) else {
            throw LaunchError.failed(appName: app.name)
        }
    }
}
#endif
