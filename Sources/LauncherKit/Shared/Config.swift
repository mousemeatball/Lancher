import Foundation

/// Centralized constants. There should be no magic numbers or hard-coded strings elsewhere in the
/// codebase — add them here.
public enum Config {
    // Identity.
    public static let appName = "Lancher"
    public static let bundleID = "com.lancher.app"
    public static let version = "0.1.0"
    public static let buildNumber = "1"
    /// `os.Logger` subsystem; also used by the Debug Bridge log category.
    public static let loggingSubsystem = "com.lancher.app"

    // Persistence — everything lives under ~/Library/Application Support/Lancher.
    public static let appSupportFolderName = "Lancher"
    public static let logFileName = "lancher.log"
    public static let settingsFileName = "settings.json"
    public static let spacesFileName = "spaces.json"
    public static let workflowsFileName = "workflows.json"
    public static let widgetsFileName = "widgets.json"
    public static let layoutFileName = "layout.json"

    // Adjustable icon size range (Preferences slider / Spaces).
    public static let iconSizeRange: ClosedRange<Double> = 40...128

    // Wallpapers.
    public static let defaultWeatherCity = "San Francisco"
    public static let wallpaperVideoExtensions: Set<String> = ["mp4", "mov", "avi", "mkv", "m4v"]
    public static let wallpaperImageExtensions: Set<String> = ["png", "jpg", "jpeg", "heic"]

    /// Directories scanned for `.app` bundles. The preferences "extra app sources" feature will
    /// append user-chosen directories to this list.
    public static let defaultAppDirectories: [URL] = [
        URL(filePath: "/Applications"),
        URL(filePath: "/System/Applications"),
        URL(filePath: "/System/Applications/Utilities"),
        FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications"),
    ]

    // Grid / icon sizing (Preferences will make these user-adjustable).
    public static let gridItemWidth: CGFloat = 104
    public static let gridItemPadding: CGFloat = 40   // tile width = iconSize + this
    public static let gridSpacing: CGFloat = 28
    public static let iconSize: CGFloat = 64
    public static let contentPadding: CGFloat = 40
    public static let searchFieldMaxWidth: CGFloat = 480
    public static let searchFieldVerticalPadding: CGFloat = 10

    // Folders (user-created, persisted).
    public static let foldersFileName = "folders.json"
    public static let defaultFolderName = "New Folder"
    public static let folderPreviewIconSize: CGFloat = 22
    public static let folderTileCornerRadius: CGFloat = 16

    // Menu-bar symbol.
    public static let menuBarSymbolName = "square.grid.3x3.fill"

    // Debug Bridge — loopback control server, enabled only with --debug or LANCHER_DEBUG=1.
    public static let debugBridgePort: UInt16 = 53127
    public static let debugBridgeInfoFileName = "debug-bridge.json"
    public static let debugTokenHeader = "x-lancher-token"

    /// Returns the app-support directory, creating it if needed.
    public static func appSupportDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appending(path: appSupportFolderName)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
