#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

/// A single app cell: icon above a single-line, truncated name.
public struct AppGridItemView: View {
    private let app: AppItem

    public init(app: AppItem) {
        self.app = app
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: Config.iconSize, height: Config.iconSize)
            Text(app.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: Config.gridItemWidth)
        }
        .frame(width: Config.gridItemWidth)
        .contentShape(Rectangle())
    }
}
#endif
