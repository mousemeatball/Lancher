import Foundation

/// JSON snapshot of the launcher returned by `GET /state`. Fields are added as later phases land
/// (active space, wallpaper, widgets); all new fields stay optional for backward compatibility.
public struct DebugState: Codable, Sendable {
    public var app: String
    public var version: String
    public var appCount: Int
    public var query: String
    public var visible: Bool
    public var filteredCount: Int
    public var folderCount: Int
    public var looseCount: Int
    public var openFolder: String?
    public var lastError: String?

    public init(
        app: String,
        version: String,
        appCount: Int,
        query: String,
        visible: Bool,
        filteredCount: Int,
        folderCount: Int = 0,
        looseCount: Int = 0,
        openFolder: String? = nil,
        lastError: String?
    ) {
        self.app = app
        self.version = version
        self.appCount = appCount
        self.query = query
        self.visible = visible
        self.filteredCount = filteredCount
        self.folderCount = folderCount
        self.looseCount = looseCount
        self.openFolder = openFolder
        self.lastError = lastError
    }

    public static let unavailable = DebugState(
        app: Config.appName, version: Config.version, appCount: 0,
        query: "", visible: false, filteredCount: 0, lastError: "host unavailable"
    )
}

/// A command posted to `POST /command`. Optional fields cover all current verbs; more are added as
/// later phases introduce new commands (e.g. `space`, `workflow`, `wallpaper`).
public struct DebugCommand: Decodable, Sendable {
    public let cmd: String
    public let q: String?
    public let bundleID: String?
    public let name: String?
}

/// Result of a command, returned as JSON.
public struct DebugResult: Encodable, Sendable {
    public let ok: Bool
    public let message: String?

    public init(ok: Bool, message: String? = nil) {
        self.ok = ok
        self.message = message
    }
}
