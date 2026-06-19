import Foundation

/// One cell in the root launcher grid: either a folder or a loose (un-foldered) app.
/// Lets the grid render a mixed list with stable `ForEach` identity.
public enum LauncherGridEntry: Identifiable {
    case folder(Folder)
    case app(AppItem)

    public var id: String {
        switch self {
        case .folder(let folder): "folder:\(folder.id)"
        case .app(let app): "app:\(app.id)"
        }
    }
}
