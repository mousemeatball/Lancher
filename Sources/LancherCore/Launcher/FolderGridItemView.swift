#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

/// A folder cell: a rounded tile showing a 2×2 preview of the first few app icons, with the
/// folder name beneath — sized to line up with `AppGridItemView`.
public struct FolderGridItemView: View {
    private let folder: Folder
    private let previewApps: [AppItem]

    public init(folder: Folder, previewApps: [AppItem]) {
        self.folder = folder
        self.previewApps = previewApps
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(Config.folderPreviewIconSize), spacing: 6), count: 2)
    }

    public var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
                .overlay(
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(previewApps) { app in
                            Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path))
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: Config.folderPreviewIconSize, height: Config.folderPreviewIconSize)
                        }
                    }
                    .padding(8)
                )
                .frame(width: Config.iconSize, height: Config.iconSize)

            Text(folder.name)
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
