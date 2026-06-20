import Foundation
import os

/// App-wide logging. Structured `os.Logger` categories (viewable in Console / `log stream`) plus an
/// append-only file log under Application Support so a Debug Bridge user can `tail -f` activity.
public enum Log {
    public static let app = Logger(subsystem: Config.loggingSubsystem, category: "app")
    public static let launcher = Logger(subsystem: Config.loggingSubsystem, category: "launcher")
    public static let bridge = Logger(subsystem: Config.loggingSubsystem, category: "debug-bridge")

    private static let fileQueue = DispatchQueue(label: "\(Config.loggingSubsystem).filelog")

    /// Mirror a notable line to both the unified log (info) and the file log.
    public static func event(_ logger: Logger, _ message: String) {
        logger.info("\(message, privacy: .public)")
        appendToFile(message)
    }

    /// Append a line to ~/Library/Application Support/Lancher/lancher.log (best-effort).
    public static func appendToFile(_ message: String) {
        fileQueue.async {
            guard let dir = try? Config.appSupportDirectory() else { return }
            let url = dir.appending(path: Config.logFileName)
            let line = "[\(timestamp())] \(message)\n"
            let data = Data(line.utf8)
            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                _ = try? handle.seekToEnd()
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: url)
            }
        }
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}
