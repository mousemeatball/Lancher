import SwiftUI
import AppKit
import LancherCore

/// Menu-bar–resident launcher app. The environment (discovery, window, global hotkey) is
/// built in `applicationDidFinishLaunching` so the Carbon hotkey registers once the app is up.
@main
struct LancherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Lancher", systemImage: "square.grid.3x3.fill") {
            Button("Open Lancher  (⌥Space)") {
                appDelegate.environment?.toggleLauncher()
            }
            Divider()
            Button("Quit Lancher") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var environment: AppEnvironment?

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment = AppEnvironment()
    }
}
