import Foundation
import Observation

/// Drives the launcher UI: holds the immutable app list, the live search query, and launch
/// behavior. Filtering is a pure function so it is trivially testable.
@Observable
@MainActor
public final class LauncherViewModel {
    public let allApps: [AppItem]
    public var query: String = ""
    public var lastError: String?

    /// Called after a successful launch so the host window can dismiss itself.
    public var onClose: () -> Void = {}

    private let launcher: AppLaunching

    public init(apps: [AppItem], launcher: AppLaunching) {
        self.allApps = apps
        self.launcher = launcher
    }

    // MARK: - Search

    public var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var filteredApps: [AppItem] {
        Self.filter(apps: allApps, query: query)
    }

    /// Pure, side-effect-free filter — case-insensitive substring match on the app name.
    nonisolated public static func filter(apps: [AppItem], query: String) -> [AppItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    // MARK: - Presentation

    /// Reset transient UI state — called each time the launcher is summoned.
    public func resetPresentation() {
        query = ""
        lastError = nil
    }

    // MARK: - Activation

    public func activate(_ app: AppItem) {
        do {
            try launcher.launch(app)
            lastError = nil
            onClose()
        } catch {
            lastError = error.localizedDescription
        }
    }
}
