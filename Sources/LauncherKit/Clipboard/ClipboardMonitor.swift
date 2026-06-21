#if canImport(AppKit)
import AppKit

/// Polls the general pasteboard for new text and reports it. Uses a MainActor task loop (avoids the
/// Sendable pitfalls of Timer blocks). App-lifetime object; `stop()` cancels.
@MainActor
public final class ClipboardMonitor {
    private var task: Task<Void, Never>?
    private var lastChangeCount: Int
    private let onCapture: (String) -> Void

    public init(onCapture: @escaping (String) -> Void) {
        self.onCapture = onCapture
        self.lastChangeCount = NSPasteboard.general.changeCount
        start()
    }

    private func start() {
        task = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Config.clipboardPollInterval))
                self?.poll()
            }
        }
    }

    private func poll() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        if let string = pasteboard.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onCapture(string)
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
    }
}
#endif
