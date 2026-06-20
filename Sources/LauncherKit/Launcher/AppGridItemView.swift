#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

/// A single app tile: icon above a single-line name. Loads the icon on demand from the app URL.
struct AppGridItemView: View {
    let app: AppItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: Config.iconSize, height: Config.iconSize)
                Text(app.name)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: Config.gridItemWidth)
            }
            .frame(width: Config.gridItemWidth)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var icon: NSImage {
        NSWorkspace.shared.icon(forFile: app.url.path)
    }
}
#endif
