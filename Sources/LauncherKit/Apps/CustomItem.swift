import Foundation

/// A user-added file or folder shown on the grid as a launchable tile ("Custom Files & Folders").
public struct CustomItem: Identifiable, Hashable, Sendable {
    public let path: String
    public var id: String { "file:\(path)" }
    public var name: String { (path as NSString).lastPathComponent }
    public var url: URL { URL(filePath: path) }

    public init(path: String) { self.path = path }
}
