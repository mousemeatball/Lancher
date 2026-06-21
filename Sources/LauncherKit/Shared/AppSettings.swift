import Foundation

/// User-adjustable launcher settings. An immutable value type — edits return new copies. Persisted
/// by `SettingsStoring` and snapshotted into Spaces.
public struct AppSettings: Codable, Sendable, Equatable {
    public var theme: AppTheme
    public var iconSize: Double
    public var hideTitles: Bool
    /// Identifier of the active wallpaper (see `WallpaperSpec`); nil means the default backdrop.
    public var wallpaper: WallpaperSpec?

    public init(
        theme: AppTheme = .liquidGlass,
        iconSize: Double = Double(Config.iconSize),
        hideTitles: Bool = false,
        wallpaper: WallpaperSpec? = nil
    ) {
        self.theme = theme
        self.iconSize = iconSize
        self.hideTitles = hideTitles
        self.wallpaper = wallpaper
    }

    public func with(
        theme: AppTheme? = nil,
        iconSize: Double? = nil,
        hideTitles: Bool? = nil,
        wallpaper: WallpaperSpec?? = nil
    ) -> AppSettings {
        AppSettings(
            theme: theme ?? self.theme,
            iconSize: (iconSize ?? self.iconSize).clamped(to: Config.iconSizeRange),
            hideTitles: hideTitles ?? self.hideTitles,
            wallpaper: wallpaper ?? self.wallpaper
        )
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
