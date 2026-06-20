#if canImport(AppKit)
import AppKit

/// A borderless `NSPanel` that can still become key (so the search field accepts typing) and
/// reports Esc presses via `onEscape`.
@MainActor
final class KeyablePanel: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// AppKit routes the Esc key to `cancelOperation(_:)`.
    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}
#endif
