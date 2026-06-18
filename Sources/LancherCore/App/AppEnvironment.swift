#if canImport(AppKit) && canImport(SwiftUI)
import Foundation
import Observation

/// Composition root: wires discovery → view model → window controller, and registers the
/// global summon hotkey (⌥Space).
///
/// Discovery runs synchronously at init, which is fine for the app count in `/Applications`.
/// Production should move indexing off the main actor and watch for changes via FSEvents.
@Observable
@MainActor
public final class AppEnvironment {
    private let controller: LauncherWindowController
    private var hotKey: GlobalHotKey?

    public init(
        discovery: AppDiscovering = AppDiscoveryService(),
        launcher: AppLaunching = WorkspaceAppLauncher()
    ) {
        let apps = discovery.discoverApps()
        let viewModel = LauncherViewModel(apps: apps, launcher: launcher)
        self.controller = LauncherWindowController(viewModel: viewModel)

        // Summon from anywhere with ⌥Space. Falls back to the menu-bar item if registration fails.
        self.hotKey = GlobalHotKey { [weak self] in
            self?.toggleLauncher()
        }
    }

    public func toggleLauncher() {
        controller.toggle()
    }
}
#endif
