import Foundation

/// Spotlight-backed file search via `mdfind` (name match within the user's home). Returns a small,
/// bounded list of file URLs. Runs off the main thread; safe to call from a SwiftUI `.task`.
public enum FileSearchService {
    public static func search(_ query: String, limit: Int = Config.fileSearchLimit) async -> [URL] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(filePath: "/usr/bin/mdfind")
                process.arguments = [
                    "-onlyin", FileManager.default.homeDirectoryForCurrentUser.path,
                    "-name", trimmed,
                ]
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()
                do { try process.run() } catch { continuation.resume(returning: []); return }

                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()

                let urls = String(decoding: data, as: UTF8.self)
                    .split(separator: "\n")
                    .prefix(limit)
                    .map { URL(filePath: String($0)) }
                continuation.resume(returning: Array(urls))
            }
        }
    }
}
