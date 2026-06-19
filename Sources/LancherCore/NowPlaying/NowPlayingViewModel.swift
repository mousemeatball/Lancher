#if canImport(AppKit)
import AppKit
import Foundation
import Observation

/// Drives the Now Playing widget: polls the provider while the launcher is visible, exposes the
/// current track plus resolved artwork, and forwards playback controls.
///
/// AppleScript offers no change notifications, so we poll on a timer — but only while the overlay
/// is on screen (`startPolling`/`stopPolling`), to avoid sending Apple events in the background.
@Observable
@MainActor
public final class NowPlayingViewModel {
    public private(set) var current: NowPlaying?
    public private(set) var artwork: NSImage?

    private let provider: NowPlayingProviding
    private let pollInterval: TimeInterval
    private var timer: Timer?
    /// Track identity for which artwork was last resolved, so play/pause doesn't reload it.
    private var artworkIdentity: String?

    public init(
        provider: NowPlayingProviding,
        pollInterval: TimeInterval = Config.nowPlayingPollInterval
    ) {
        self.provider = provider
        self.pollInterval = pollInterval
    }

    // MARK: - Lifecycle

    public func startPolling() {
        refresh()
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    public func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Polling

    public func refresh() {
        let snapshot = provider.snapshot()
        guard snapshot != current else { return }
        current = snapshot
        resolveArtwork(for: snapshot)
    }

    // MARK: - Controls

    public func playPause() { withCurrentSource { provider.playPause(source: $0) } }
    public func next() { withCurrentSource { provider.next(source: $0) } }
    public func previous() { withCurrentSource { provider.previous(source: $0) } }

    // MARK: - Private

    private func withCurrentSource(_ action: (NowPlaying.Source) -> Void) {
        guard let source = current?.source else { return }
        action(source)
        // Reflect the new state quickly without waiting for the next poll tick.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            refresh()
        }
    }

    private func resolveArtwork(for snapshot: NowPlaying?) {
        guard let snapshot else {
            artwork = nil
            artworkIdentity = nil
            return
        }
        guard snapshot.trackIdentity != artworkIdentity else { return }
        artworkIdentity = snapshot.trackIdentity
        artwork = nil

        if let url = snapshot.artworkURL {
            loadRemoteArtwork(url, for: snapshot.trackIdentity)
        } else if let data = provider.artworkData(for: snapshot.source) {
            artwork = NSImage(data: data)
        }
    }

    private func loadRemoteArtwork(_ url: URL, for identity: String) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = NSImage(data: data) else { return }
            Task { @MainActor in
                guard let self, self.current?.trackIdentity == identity else { return }
                self.artwork = image
            }
        }.resume()
    }
}
#endif
