#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SwiftUI

/// Borderless panel that must be able to become key so the search field can take focus.
private final class LauncherPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Owns the full-screen overlay window that hosts `LauncherView`.
///
/// Opens on the display under the cursor, floats above other windows, and dismisses on Esc,
/// on launching an app, or when the user switches away (`hidesOnDeactivate`).
@MainActor
public final class LauncherWindowController {
    private var panel: LauncherPanel?
    private let viewModel: LauncherViewModel

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
        self.viewModel.onClose = { [weak self] in self?.hide() }
    }

    public func toggle() {
        if let panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    public func show() {
        let panel = panel ?? makePanel()
        self.panel = panel

        if let screen = screenUnderCursor() {
            panel.setFrame(screen.frame, display: true)
        }
        viewModel.query = ""
        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    public func hide() {
        panel?.orderOut(nil)
    }

    private func makePanel() -> LauncherPanel {
        let panel = LauncherPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = true
        panel.contentView = NSHostingView(rootView: LauncherView(viewModel: viewModel))
        return panel
    }

    /// The screen containing the cursor — so the launcher opens where the user is looking.
    private func screenUnderCursor() -> NSScreen? {
        let location = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(location, $0.frame, false) } ?? NSScreen.main
    }
}
#endif
