#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

/// A folder tile: a rounded square showing either the folder's emoji or a 2×2 mini-grid of its
/// apps' icons, with the folder name beneath.
struct FolderGridItemView: View {
    let folder: Folder
    let previewApps: [AppItem]
    let iconSize: CGFloat
    let hideTitle: Bool
    let action: () -> Void

    private var tileWidth: CGFloat { iconSize + Config.gridItemPadding }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                tile
                    .frame(width: iconSize, height: iconSize)
                if !hideTitle {
                    Text(folder.name)
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
    }

    private var tile: some View {
        RoundedRectangle(cornerRadius: Config.folderTileCornerRadius)
            .fill(backgroundColor)
            .overlay { content }
    }

    @ViewBuilder
    private var content: some View {
        if let emoji = folder.emoji, !emoji.isEmpty {
            Text(emoji).font(.system(size: iconSize * 0.5))
        } else {
            let size = Config.folderPreviewIconSize
            LazyVGrid(columns: [GridItem(.fixed(size), spacing: 4), GridItem(.fixed(size), spacing: 4)], spacing: 4) {
                ForEach(previewApps) { app in
                    Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                        .resizable()
                        .frame(width: size, height: size)
                }
            }
            .padding(6)
        }
    }

    private var backgroundColor: Color {
        if let hex = folder.colorHex, let color = Color(hex: hex) {
            return color.opacity(0.85)
        }
        return Color.white.opacity(0.18)
    }
}

extension Color {
    /// Parse a "#RRGGBB" hex string. Returns nil on malformed input.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let value = UInt32(s, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
#endif
