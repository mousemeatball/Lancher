import AppKit
import LauncherKit

/// Owns the menu-bar status item and the `AppEnvironment` composition root. Kept thin: all real
/// logic lives in `LauncherKit`.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var environment: AppEnvironment?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        environment = AppEnvironment()
        setUpMenuBar()
    }

    private func setUpMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: Config.menuBarSymbolName,
            accessibilityDescription: Config.appName
        )

        let menu = NSMenu()
        menu.addItem(
            withTitle: "Open \(Config.appName)",
            action: #selector(openLauncher),
            keyEquivalent: ""
        )
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit \(Config.appName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        item.menu = menu
        statusItem = item
    }

    @objc private func openLauncher() {
        environment?.toggleLauncher()
    }
}
