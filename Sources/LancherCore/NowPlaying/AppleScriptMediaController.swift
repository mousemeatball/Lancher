#if canImport(AppKit)
import AppKit

/// Reads and controls Apple Music / Spotify via AppleScript.
///
/// Uses only public scripting interfaces (no private `MediaRemote` framework). It never targets
/// an app that isn't already running, so asking "what's playing?" can't launch Music or Spotify.
/// Sending these Apple events triggers a one-time macOS Automation permission prompt per target
/// app; if the user declines, calls fail quietly and the widget simply shows nothing.
///
/// `NSAppleScript` is not thread-safe; all calls must come from the main thread. The owning
/// `NowPlayingViewModel` is `@MainActor`, which guarantees that.
public struct AppleScriptMediaController: NowPlayingProviding {
    public init() {}

    // MARK: - Reading

    public func snapshot() -> NowPlaying? {
        let candidates = NowPlaying.Source.allCases
            .filter(isRunning)
            .compactMap(snapshot(for:))
        return candidates.first(where: \.isPlaying) ?? candidates.first
    }

    public func artworkData(for source: NowPlaying.Source) -> Data? {
        guard source == .appleMusic, isRunning(source) else { return nil }
        let script = """
        tell application "\(source.rawValue)"
            try
                return data of artwork 1 of current track
            on error
                return missing value
            end try
        end tell
        """
        guard let descriptor = run(script), descriptor.descriptorType != typeNull else { return nil }
        let data = descriptor.data
        return data.isEmpty ? nil : data
    }

    // MARK: - Controls

    public func playPause(source: NowPlaying.Source) { control("playpause", source) }
    public func next(source: NowPlaying.Source) { control("next track", source) }
    public func previous(source: NowPlaying.Source) { control("previous track", source) }

    // MARK: - Private

    private func isRunning(_ source: NowPlaying.Source) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == source.bundleID }
    }

    private func snapshot(for source: NowPlaying.Source) -> NowPlaying? {
        let artworkLine = source == .spotify ? " & linefeed & (artwork url of t)" : ""
        let script = """
        tell application "\(source.rawValue)"
            try
                set st to player state as text
                set t to current track
                return st & linefeed & (name of t) & linefeed & (artist of t) & linefeed & (album of t)\(artworkLine)
            on error
                return "stopped"
            end try
        end tell
        """
        guard let output = run(script)?.stringValue else { return nil }
        return Self.parse(output, source: source)
    }

    private func control(_ command: String, _ source: NowPlaying.Source) {
        guard isRunning(source) else { return }
        _ = run("tell application \"\(source.rawValue)\" to \(command)")
    }

    /// Parses the newline-separated AppleScript output into a `NowPlaying`. Exposed for tests.
    static func parse(_ output: String, source: NowPlaying.Source) -> NowPlaying? {
        let lines = output.components(separatedBy: "\n")
        guard let state = lines.first, state != "stopped", lines.count >= 4 else { return nil }
        let album = lines[3].isEmpty ? nil : lines[3]
        let artworkURL = lines.count >= 5 ? URL(string: lines[4]) : nil
        return NowPlaying(
            source: source,
            title: lines[1],
            artist: lines[2],
            album: album,
            isPlaying: state == "playing",
            artworkURL: artworkURL
        )
    }

    private func run(_ source: String) -> NSAppleEventDescriptor? {
        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            // Most common cause: the user denied the Automation permission. Don't spam — the
            // widget already degrades to showing nothing.
            NSLog("Lancher: AppleScript error: \(error)")
            return nil
        }
        return result
    }
}
#endif
