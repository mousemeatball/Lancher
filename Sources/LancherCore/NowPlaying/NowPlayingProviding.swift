import Foundation

/// Abstraction over reading and controlling the current track, so the Now Playing view model
/// can be tested with a fake instead of driving real media apps (repository pattern).
public protocol NowPlayingProviding: Sendable {
    /// The current track from whichever supported app is playing (or most recently active),
    /// or `nil` when nothing is available.
    func snapshot() -> NowPlaying?

    /// Raw artwork bytes for the given source, when the source exposes data rather than a URL
    /// (Apple Music). Returns `nil` if unavailable.
    func artworkData(for source: NowPlaying.Source) -> Data?

    func playPause(source: NowPlaying.Source)
    func next(source: NowPlaying.Source)
    func previous(source: NowPlaying.Source)
}
