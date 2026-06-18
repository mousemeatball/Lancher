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
}
