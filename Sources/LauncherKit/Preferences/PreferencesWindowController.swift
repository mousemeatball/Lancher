#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SwiftUI

/// Hosts the Preferences form in a standard window, lazily created and reused.
@MainActor
public final class PreferencesWindowController {
    private let viewModel: LauncherViewModel
    private var window: NSWindow?

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    public func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: PreferencesView(viewModel: viewModel))
            let window = NSWindow(contentViewController: hosting)
            window.title = "\(Config.appName) Preferences"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
#endif
