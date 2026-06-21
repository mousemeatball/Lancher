#if canImport(AppKit)
import AppKit

/// Summons the launcher when the cursor hits a chosen screen corner. Uses passive mouse-move
/// monitors (no Accessibility permission required) and re-arms only after the cursor leaves the
/// corner, so it fires once per entry.
@MainActor
public final class HotCorners {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var enabled = false
    private var corner: ScreenCorner = .topLeft
    private var armed = true
    private let threshold: CGFloat = 4
    private let handler: () -> Void

    public init(handler: @escaping () -> Void) {
        self.handler = handler
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
            MainActor.assumeIsolated { [weak self] in self?.evaluate() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { event in
            MainActor.assumeIsolated { [weak self] in self?.evaluate() }
            return event
        }
    }

    public func update(enabled: Bool, corner: ScreenCorner) {
        self.enabled = enabled
        self.corner = corner
    }

    private func evaluate() {
        guard enabled else { return }
        let location = NSEvent.mouseLocation
        guard let screen = (NSScreen.screens.first { $0.frame.contains(location) }) ?? NSScreen.main else { return }
        let frame = screen.frame

        let inCorner: Bool
        switch corner {
        case .topLeft:     inCorner = location.x <= frame.minX + threshold && location.y >= frame.maxY - threshold
        case .topRight:    inCorner = location.x >= frame.maxX - threshold && location.y >= frame.maxY - threshold
        case .bottomLeft:  inCorner = location.x <= frame.minX + threshold && location.y <= frame.minY + threshold
        case .bottomRight: inCorner = location.x >= frame.maxX - threshold && location.y <= frame.minY + threshold
        }

        if inCorner {
            if armed { armed = false; handler() }
        } else {
            armed = true
        }
    }

    /// Remove the event monitors. (Not called from `deinit` — this is an app-lifetime object;
    /// monitors are released on process exit. A `@MainActor deinit` can't touch this state.)
    public func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }
}
#endif
