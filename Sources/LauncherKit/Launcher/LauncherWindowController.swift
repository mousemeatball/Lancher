#if canImport(AppKit) && canImport(SwiftUI)
import AppKit
import SwiftUI

/// Owns the full-screen launcher panel: builds it lazily, positions it on the display under the
/// cursor, and dismisses it on Esc, on click-away, after a launch, or when the app is deactivated.
@MainActor
public final class LauncherWindowController: NSObject, NSWindowDelegate {
    private let viewModel: LauncherViewModel
    private var panel: KeyablePanel?

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
        super.init()
        viewModel.onClose = { [weak self] in self?.hide() }
    }

    public var isVisible: Bool { panel?.isVisible ?? false }

    public func toggle() {
        isVisible ? hide() : show()
    }

    public func show() {
        viewModel.resetPresentation()
        let panel = panel ?? makePanel()
        self.panel = panel
        panel.setFrame(screenUnderCursor().frame, display: true)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    public func hide() {
        panel?.orderOut(nil)
    }

    /// Render the current launcher window to PNG for the Debug Bridge's `/screenshot`. Summons the
    /// window first if needed so a capture is always available.
    public func snapshotPNG() -> Data? {
        if !isVisible { show() }
        guard let view = panel?.contentView else { return nil }
        view.layoutSubtreeIfNeeded()
        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return nil }
        view.cacheDisplay(in: view.bounds, to: rep)
        return rep.representation(using: .png, properties: [:])
    }

    // MARK: - Construction

    private func makePanel() -> KeyablePanel {
        let panel = KeyablePanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.delegate = self
        // Esc backs out of an open folder first; otherwise it dismisses the launcher.
        panel.onEscape = { [weak self] in
            guard let self else { return }
            if viewModel.openFolder != nil {
                viewModel.closeFolder()
            } else {
                hide()
            }
        }

        let host = NSHostingView(
            rootView: LauncherView(viewModel: viewModel, onDismiss: { [weak self] in self?.hide() })
        )
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
        return panel
    }

    /// The screen containing the mouse cursor, falling back to the main screen.
    private func screenUnderCursor() -> NSScreen {
        let location = NSEvent.mouseLocation
        return NSScreen.screens.first { $0.frame.contains(location) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    // MARK: - NSWindowDelegate

    /// Dismiss when the user switches away (click into another app / Cmd-Tab).
    public func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
#endif
