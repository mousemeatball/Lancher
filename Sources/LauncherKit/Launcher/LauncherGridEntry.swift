import Foundation

/// A single cell in the root launcher grid: either a folder or a loose app. Folders sort before
/// loose apps.
public enum LauncherGridEntry: Identifiable, Sendable {
    case workflow(Workflow)
    case folder(Folder)
    case file(CustomItem)
    case app(AppItem)

    public var id: String {
        switch self {
        case .workflow(let workflow): return "workflow:\(workflow.id.uuidString)"
        case .folder(let folder): return "folder:\(folder.id.uuidString)"
        case .file(let item): return item.id
        case .app(let app): return "app:\(app.id)"
        }
    }
}
