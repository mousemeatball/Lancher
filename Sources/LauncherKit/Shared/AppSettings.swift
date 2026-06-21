import Foundation

/// User-adjustable launcher settings. An immutable value type — edits return new copies. Persisted
/// by `SettingsStoring` and snapshotted into Spaces. Decoding tolerates older files missing newer
/// keys (each falls back to its default).
public struct AppSettings: Codable, Sendable, Equatable {
    public var theme: AppTheme
    public var iconSize: Double
    public var hideTitles: Bool
    /// Identifier of the active wallpaper (see `WallpaperSpec`); nil means the default backdrop.
    public var wallpaper: WallpaperSpec?
    public var hotCornerEnabled: Bool
    public var hotCorner: ScreenCorner

    public init(
        theme: AppTheme = .liquidGlass,
        iconSize: Double = Double(Config.iconSize),
        hideTitles: Bool = false,
        wallpaper: WallpaperSpec? = nil,
        hotCornerEnabled: Bool = false,
        hotCorner: ScreenCorner = .topLeft
    ) {
        self.theme = theme
        self.iconSize = iconSize
        self.hideTitles = hideTitles
        self.wallpaper = wallpaper
        self.hotCornerEnabled = hotCornerEnabled
        self.hotCorner = hotCorner
    }

    private enum CodingKeys: String, CodingKey {
        case theme, iconSize, hideTitles, wallpaper, hotCornerEnabled, hotCorner
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        theme = try c.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .liquidGlass
        iconSize = try c.decodeIfPresent(Double.self, forKey: .iconSize) ?? Double(Config.iconSize)
        hideTitles = try c.decodeIfPresent(Bool.self, forKey: .hideTitles) ?? false
        wallpaper = try c.decodeIfPresent(WallpaperSpec.self, forKey: .wallpaper)
        hotCornerEnabled = try c.decodeIfPresent(Bool.self, forKey: .hotCornerEnabled) ?? false
        hotCorner = try c.decodeIfPresent(ScreenCorner.self, forKey: .hotCorner) ?? .topLeft
    }

    public func with(
        theme: AppTheme? = nil,
        iconSize: Double? = nil,
        hideTitles: Bool? = nil,
        wallpaper: WallpaperSpec?? = nil,
        hotCornerEnabled: Bool? = nil,
        hotCorner: ScreenCorner? = nil
    ) -> AppSettings {
        AppSettings(
            theme: theme ?? self.theme,
            iconSize: (iconSize ?? self.iconSize).clamped(to: Config.iconSizeRange),
            hideTitles: hideTitles ?? self.hideTitles,
            wallpaper: wallpaper ?? self.wallpaper,
            hotCornerEnabled: hotCornerEnabled ?? self.hotCornerEnabled,
            hotCorner: hotCorner ?? self.hotCorner
        )
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
