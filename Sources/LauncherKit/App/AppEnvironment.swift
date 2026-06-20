#if canImport(AppKit)
import AppKit
import os

/// Composition root: wires discovery → view model → window controller, and registers the global
/// summon hotkey (⌥Space).
///
/// Discovery runs synchronously at init, which is fine for the app count under `/Applications`.
/// A later phase can move indexing off the main actor and watch for changes via FSEvents.
@MainActor
public final class AppEnvironment {
    private let controller: LauncherWindowController
    private var hotKey: GlobalHotKey?
    private let log = Logger(subsystem: Config.loggingSubsystem, category: "app")

    public init(
        discovery: AppDiscovering = AppDiscoveryService(),
        launcher: AppLaunching = WorkspaceAppLauncher()
    ) {
        let apps = discovery.discoverApps()
        let viewModel = LauncherViewModel(apps: apps, launcher: launcher)
        self.controller = LauncherWindowController(viewModel: viewModel)
        log.info("Discovered \(apps.count, privacy: .public) apps")

        // Summon from anywhere with ⌥Space. Falls back to the menu-bar item if registration fails.
        self.hotKey = GlobalHotKey { [weak self] in
            MainActor.assumeIsolated { self?.toggleLauncher() }
        }
        if hotKey == nil {
            log.error("Failed to register global hotkey — use the menu-bar item instead")
        }
    }

    public func toggleLauncher() {
        controller.toggle()
    }
}
#endif
