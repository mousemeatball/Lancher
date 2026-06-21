#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// A workflow tile: a "bolt" badge (or the workflow's emoji) above its name. Tapping runs it.
struct WorkflowGridItemView: View {
    let workflow: Workflow
    let iconSize: CGFloat
    let hideTitle: Bool
    let theme: AppTheme
    let action: () -> Void

    private var tileWidth: CGFloat { iconSize + Config.gridItemPadding }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: Config.folderTileCornerRadius)
                    .fill(Color.accentColor.opacity(0.85))
                    .frame(width: iconSize, height: iconSize)
                    .overlay {
                        if let emoji = workflow.emoji, !emoji.isEmpty {
                            Text(emoji).font(.system(size: iconSize * 0.5))
                        } else {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: iconSize * 0.42))
                                .foregroundStyle(.white)
                        }
                    }
                if !hideTitle {
                    Text(workflow.name)
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
        .help("\(workflow.name) — opens \(workflow.itemCount) item(s)")
    }
}
#endif
