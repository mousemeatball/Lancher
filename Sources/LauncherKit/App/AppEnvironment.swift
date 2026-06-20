#if canImport(AppKit)
import AppKit
import os

/// Composition root. Phase 0 keeps this minimal — it just owns a logger and exposes the entry
/// points the menu-bar `AppDelegate` calls. Later phases wire discovery → view model → launcher
/// window controller and register the global hotkey here.
@MainActor
public final class AppEnvironment {
    private let log = Logger(subsystem: Config.loggingSubsystem, category: "app")

    public init() {
        log.info("Lancher \(Config.version, privacy: .public) launched")
    }

    /// Toggle the launcher overlay. Placeholder until Phase 1 wires the real window.
    public func toggleLauncher() {
        log.info("toggleLauncher (Phase 0 placeholder — window arrives in Phase 1)")
    }
}
#endif
