#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// Compact Now Playing widget: artwork, track/artist, and transport controls. Rendered in the
/// corner of the launcher overlay. Shown only when something is actually playing/paused.
public struct NowPlayingView: View {
    @Bindable private var viewModel: NowPlayingViewModel

    public init(viewModel: NowPlayingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if let track = viewModel.current {
            HStack(spacing: 12) {
                artwork
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.callout.weight(.semibold))
                        .lineLimit(1)
                    Text(subtitle(for: track))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    controls(isPlaying: track.isPlaying)
                        .padding(.top, 2)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(width: Config.nowPlayingWidgetWidth)
            .background(.thinMaterial, in: .rect(cornerRadius: Config.nowPlayingCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Config.nowPlayingCornerRadius)
                    .strokeBorder(.white.opacity(0.08))
            )
        }
    }

    private var artwork: some View {
        Group {
            if let image = viewModel.artwork {
                Image(nsImage: image).resizable().interpolation(.high)
            } else {
                ZStack {
                    Color.secondary.opacity(0.2)
                    Image(systemName: "music.note")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .scaledToFill()
        .frame(width: Config.nowPlayingArtworkSize, height: Config.nowPlayingArtworkSize)
        .clipShape(.rect(cornerRadius: 6))
    }

    private func controls(isPlaying: Bool) -> some View {
        HStack(spacing: 18) {
            controlButton("backward.fill", action: viewModel.previous)
            controlButton(isPlaying ? "pause.fill" : "play.fill", action: viewModel.playPause)
            controlButton("forward.fill", action: viewModel.next)
        }
    }

    private func controlButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName).font(.callout)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }

    private func subtitle(for track: NowPlaying) -> String {
        [track.artist, track.album].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " — ")
    }
}
#endif
