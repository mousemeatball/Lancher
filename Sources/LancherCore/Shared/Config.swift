import Foundation

/// Centralized constants. No magic numbers elsewhere in the codebase.
public enum Config {
    /// Directories scanned for `.app` bundles. "Extra app sources" (build prompt Phase 1)
    /// will append user-chosen directories to this list.
    public static let defaultAppDirectories: [URL] = [
        URL(filePath: "/Applications"),
        URL(filePath: "/System/Applications"),
        URL(filePath: "/System/Applications/Utilities"),
        FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications"),
    ]

    // Grid / icon sizing (Phase 4 will make these user-adjustable).
    public static let gridItemWidth: CGFloat = 104
    public static let gridSpacing: CGFloat = 28
    public static let iconSize: CGFloat = 64
    public static let contentPadding: CGFloat = 40
    public static let searchFieldMaxWidth: CGFloat = 480
    public static let searchFieldVerticalPadding: CGFloat = 10

    // Folders (user-created, persisted).
    public static let appSupportFolderName = "Lancher"
    public static let foldersFileName = "folders.json"
    public static let defaultFolderName = "New Folder"
    /// Side length of each of the (up to four) mini icons in a folder tile's preview.
    public static let folderPreviewIconSize: CGFloat = 22

    // Now Playing widget.
    public static let nowPlayingPollInterval: TimeInterval = 3
    public static let nowPlayingWidgetWidth: CGFloat = 300
    public static let nowPlayingArtworkSize: CGFloat = 56
    public static let nowPlayingCornerRadius: CGFloat = 14
}
