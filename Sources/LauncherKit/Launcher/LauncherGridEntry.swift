import Foundation

/// A single cell in the root launcher grid: either a folder or a loose app. Folders sort before
/// loose apps.
public enum LauncherGridEntry: Identifiable, Sendable {
    case folder(Folder)
    case app(AppItem)

    public var id: String {
        switch self {
        case .folder(let folder): return "folder:\(folder.id.uuidString)"
        case .app(let app): return "app:\(app.id)"
        }
    }
}
