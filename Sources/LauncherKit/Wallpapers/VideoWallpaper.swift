#if canImport(AppKit) && canImport(AVKit)
import SwiftUI
import AVKit

/// A looping video wallpaper. Uses an `AVPlayerLooper` over an `AVQueuePlayer`, fills the screen,
/// and **pauses when the launcher is hidden** (`isActive == false`) to save resources.
struct VideoWallpaper: NSViewRepresentable {
    let url: URL
    let isActive: Bool

    func makeNSView(context: Context) -> LoopingPlayerView {
        LoopingPlayerView(url: url)
    }

    func updateNSView(_ nsView: LoopingPlayerView, context: Context) {
        nsView.setActive(isActive)
    }
}

/// Layer-backed NSView hosting a looping AVQueuePlayer.
final class LoopingPlayerView: NSView {
    private let queuePlayer = AVQueuePlayer()
    private var looper: AVPlayerLooper?
    private let playerLayer = AVPlayerLayer()

    init(url: URL) {
        super.init(frame: .zero)
        wantsLayer = true
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.player = queuePlayer
        layer?.addSublayer(playerLayer)
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        queuePlayer.isMuted = true
        queuePlayer.play()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) unavailable") }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }

    func setActive(_ active: Bool) {
        active ? queuePlayer.play() : queuePlayer.pause()
    }
}
#endif
