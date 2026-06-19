import Testing
import Foundation
import AppKit
@testable import LancherCore

@Suite struct NowPlayingParsingTests {
    @Test func parsesSpotifyTrackWithArtwork() {
        let output = "playing\nSong\nArtist\nAlbum\nhttps://img.example/cover.jpg"
        let track = AppleScriptMediaController.parse(output, source: .spotify)
        #expect(track?.title == "Song")
        #expect(track?.artist == "Artist")
        #expect(track?.album == "Album")
        #expect(track?.isPlaying == true)
        #expect(track?.artworkURL == URL(string: "https://img.example/cover.jpg"))
    }

    @Test func parsesAppleMusicWithoutArtworkURL() {
        let track = AppleScriptMediaController.parse("paused\nSong\nArtist\nAlbum", source: .appleMusic)
        #expect(track?.source == .appleMusic)
        #expect(track?.isPlaying == false)
        #expect(track?.artworkURL == nil)
    }

    @Test func stoppedOutputReturnsNil() {
        #expect(AppleScriptMediaController.parse("stopped", source: .spotify) == nil)
    }

    @Test func emptyAlbumBecomesNil() {
        let track = AppleScriptMediaController.parse("playing\nSong\nArtist\n", source: .spotify)
        #expect(track?.album == nil)
    }
}

/// Records control calls and returns a configurable snapshot/artwork without driving real apps.
private final class FakeNowPlayingProvider: NowPlayingProviding, @unchecked Sendable {
    var snapshotToReturn: NowPlaying?
    var artworkToReturn: Data?
    private(set) var controls: [(command: String, source: NowPlaying.Source)] = []

    func snapshot() -> NowPlaying? { snapshotToReturn }
    func artworkData(for source: NowPlaying.Source) -> Data? { artworkToReturn }
    func playPause(source: NowPlaying.Source) { controls.append(("playPause", source)) }
    func next(source: NowPlaying.Source) { controls.append(("next", source)) }
    func previous(source: NowPlaying.Source) { controls.append(("previous", source)) }
}

@MainActor
@Suite struct NowPlayingViewModelTests {
    private func track(_ title: String, source: NowPlaying.Source = .spotify, playing: Bool = true) -> NowPlaying {
        NowPlaying(source: source, title: title, artist: "Artist", album: "Album", isPlaying: playing)
    }

    private func pngData() -> Data {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        )!
        return rep.representation(using: .png, properties: [:])!
    }

    @Test func refreshPublishesCurrentTrack() {
        let provider = FakeNowPlayingProvider()
        provider.snapshotToReturn = track("Song")
        let viewModel = NowPlayingViewModel(provider: provider)

        viewModel.refresh()

        #expect(viewModel.current?.title == "Song")
    }

    @Test func refreshClearsWhenNothingPlaying() {
        let provider = FakeNowPlayingProvider()
        provider.snapshotToReturn = track("Song")
        let viewModel = NowPlayingViewModel(provider: provider)
        viewModel.refresh()

        provider.snapshotToReturn = nil
        viewModel.refresh()

        #expect(viewModel.current == nil)
        #expect(viewModel.artwork == nil)
    }

    @Test func playPauseForwardsToProviderWithCurrentSource() {
        let provider = FakeNowPlayingProvider()
        provider.snapshotToReturn = track("Song", source: .appleMusic)
        let viewModel = NowPlayingViewModel(provider: provider)
        viewModel.refresh()

        viewModel.playPause()

        #expect(provider.controls.first?.command == "playPause")
        #expect(provider.controls.first?.source == .appleMusic)
    }

    @Test func nextAndPreviousForward() {
        let provider = FakeNowPlayingProvider()
        provider.snapshotToReturn = track("Song")
        let viewModel = NowPlayingViewModel(provider: provider)
        viewModel.refresh()

        viewModel.next()
        viewModel.previous()

        #expect(provider.controls.map(\.command) == ["next", "previous"])
    }

    @Test func controlsNoOpWhenNothingPlaying() {
        let provider = FakeNowPlayingProvider()
        let viewModel = NowPlayingViewModel(provider: provider)

        viewModel.playPause()

        #expect(provider.controls.isEmpty)
    }

    @Test func appleMusicArtworkResolvedFromProviderData() {
        let provider = FakeNowPlayingProvider()
        provider.snapshotToReturn = track("Song", source: .appleMusic)
        provider.artworkToReturn = pngData()
        let viewModel = NowPlayingViewModel(provider: provider)

        viewModel.refresh()

        #expect(viewModel.artwork != nil)
    }
}
