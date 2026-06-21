#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

/// A single app tile: icon above an optional single-line name. Loads the icon on demand.
struct AppGridItemView: View {
    let app: AppItem
    let iconSize: CGFloat
    let hideTitle: Bool
    let action: () -> Void

    private var tileWidth: CGFloat { iconSize + Config.gridItemPadding }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: iconSize, height: iconSize)
                if !hideTitle {
                    Text(app.name)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: tileWidth)
                }
            }
            .frame(width: tileWidth)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(app.name)
    }

    private var icon: NSImage {
        NSWorkspace.shared.icon(forFile: app.url.path)
    }
}
#endif
