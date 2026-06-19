import Foundation

/// An immutable snapshot of what a supported media app is currently playing.
public struct NowPlaying: Equatable, Sendable {
    /// A media app Lancher can read from and control. The raw value is the AppleScript
    /// application name used to address it.
    public enum Source: String, Sendable, CaseIterable {
        case appleMusic = "Music"
        case spotify = "Spotify"

        /// The bundle identifier used to check whether the app is running (so we never launch
        /// it just to ask what's playing).
        public var bundleID: String {
            switch self {
            case .appleMusic: "com.apple.Music"
            case .spotify: "com.spotify.client"
            }
        }

        public var displayName: String {
            switch self {
            case .appleMusic: "Apple Music"
            case .spotify: "Spotify"
            }
        }
    }

    public let source: Source
    public let title: String
    public let artist: String
    public let album: String?
    public let isPlaying: Bool
    /// Remote artwork (Spotify exposes a URL); Apple Music artwork is fetched as raw data
    /// separately via `NowPlayingProviding.artworkData(for:)`.
    public let artworkURL: URL?

    public init(
        source: Source,
        title: String,
        artist: String,
        album: String?,
        isPlaying: Bool,
        artworkURL: URL? = nil
    ) {
        self.source = source
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.artworkURL = artworkURL
    }

    /// Stable identity of the track itself (ignores play/pause state) — used to avoid
    /// reloading artwork when only the playback state changed.
    public var trackIdentity: String { "\(source.rawValue)|\(title)|\(artist)" }
}
