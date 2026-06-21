#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

/// A single app tile: icon above an optional single-line name. Honors a custom icon override and
/// the global icon style; loads the system icon on demand otherwise.
struct AppGridItemView: View {
    let app: AppItem
    let iconSize: CGFloat
    let hideTitle: Bool
    var overrideImagePath: String? = nil
    var iconStyle: IconStyle = .original
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
        if let overrideImagePath, let custom = NSImage(contentsOfFile: overrideImagePath) {
            return custom    // user's own icon — used as-is
        }
        let base = NSWorkspace.shared.icon(forFile: app.url.path)
        return IconRenderer.render(base, style: iconStyle, key: app.id)
    }
}
#endif
