import Foundation

/// Abstracts launching so the view model can be unit-tested without actually opening apps.
public protocol AppLaunching: Sendable {
    func launch(_ app: AppItem) throws
}

/// Errors surfaced to the UI when a launch fails.
public enum LaunchError: LocalizedError {
    case failed(appName: String)

    public var errorDescription: String? {
        switch self {
        case .failed(let appName): return "Couldn't open \(appName)."
        }
    }
}
