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
    /// Extra directories to scan for `.app` bundles, in addition to the system defaults.
    public var extraAppDirectories: [String]
    /// `AppItem.id`s the user has hidden from the grid (still findable via search).
    public var hiddenAppIDs: [String]
    /// Global summon hotkey (Carbon key code + modifier mask).
    public var hotKeyKeyCode: UInt32
    public var hotKeyModifiers: UInt32
    /// User-added files/folders shown on the grid (paths).
    public var customItems: [String]
    /// Per-app icon overrides: `AppItem.id` → image file path.
    public var customIcons: [String: String]
    /// Icon appearance treatment.
    public var iconStyle: IconStyle
    /// Feature toggles.
    public var clipboardEnabled: Bool
    public var gestureEnabled: Bool

    public init(
        theme: AppTheme = .liquidGlass,
        iconSize: Double = Double(Config.iconSize),
        hideTitles: Bool = false,
        wallpaper: WallpaperSpec? = nil,
        hotCornerEnabled: Bool = false,
        hotCorner: ScreenCorner = .topLeft,
        extraAppDirectories: [String] = [],
        hiddenAppIDs: [String] = [],
        hotKeyKeyCode: UInt32 = Config.defaultHotKeyKeyCode,
        hotKeyModifiers: UInt32 = Config.defaultHotKeyModifiers,
        customItems: [String] = [],
        customIcons: [String: String] = [:],
        iconStyle: IconStyle = .original,
        clipboardEnabled: Bool = true,
        gestureEnabled: Bool = false
    ) {
        self.theme = theme
        self.iconSize = iconSize
        self.hideTitles = hideTitles
        self.wallpaper = wallpaper
        self.hotCornerEnabled = hotCornerEnabled
        self.hotCorner = hotCorner
        self.extraAppDirectories = extraAppDirectories
        self.hiddenAppIDs = hiddenAppIDs
        self.hotKeyKeyCode = hotKeyKeyCode
        self.hotKeyModifiers = hotKeyModifiers
        self.customItems = customItems
        self.customIcons = customIcons
        self.iconStyle = iconStyle
        self.clipboardEnabled = clipboardEnabled
        self.gestureEnabled = gestureEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case theme, iconSize, hideTitles, wallpaper, hotCornerEnabled, hotCorner
        case extraAppDirectories, hiddenAppIDs, hotKeyKeyCode, hotKeyModifiers
        case customItems, customIcons, iconStyle, clipboardEnabled, gestureEnabled
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        theme = try c.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .liquidGlass
        iconSize = try c.decodeIfPresent(Double.self, forKey: .iconSize) ?? Double(Config.iconSize)
        hideTitles = try c.decodeIfPresent(Bool.self, forKey: .hideTitles) ?? false
        wallpaper = try c.decodeIfPresent(WallpaperSpec.self, forKey: .wallpaper)
        hotCornerEnabled = try c.decodeIfPresent(Bool.self, forKey: .hotCornerEnabled) ?? false
        hotCorner = try c.decodeIfPresent(ScreenCorner.self, forKey: .hotCorner) ?? .topLeft
        extraAppDirectories = try c.decodeIfPresent([String].self, forKey: .extraAppDirectories) ?? []
        hiddenAppIDs = try c.decodeIfPresent([String].self, forKey: .hiddenAppIDs) ?? []
        hotKeyKeyCode = try c.decodeIfPresent(UInt32.self, forKey: .hotKeyKeyCode) ?? Config.defaultHotKeyKeyCode
        hotKeyModifiers = try c.decodeIfPresent(UInt32.self, forKey: .hotKeyModifiers) ?? Config.defaultHotKeyModifiers
        customItems = try c.decodeIfPresent([String].self, forKey: .customItems) ?? []
        customIcons = try c.decodeIfPresent([String: String].self, forKey: .customIcons) ?? [:]
        iconStyle = try c.decodeIfPresent(IconStyle.self, forKey: .iconStyle) ?? .original
        clipboardEnabled = try c.decodeIfPresent(Bool.self, forKey: .clipboardEnabled) ?? true
        gestureEnabled = try c.decodeIfPresent(Bool.self, forKey: .gestureEnabled) ?? false
    }

    public var hiddenIDSet: Set<String> { Set(hiddenAppIDs) }

    public func with(
        theme: AppTheme? = nil,
        iconSize: Double? = nil,
        hideTitles: Bool? = nil,
        wallpaper: WallpaperSpec?? = nil,
        hotCornerEnabled: Bool? = nil,
        hotCorner: ScreenCorner? = nil,
        extraAppDirectories: [String]? = nil,
        hiddenAppIDs: [String]? = nil,
        hotKeyKeyCode: UInt32? = nil,
        hotKeyModifiers: UInt32? = nil,
        customItems: [String]? = nil,
        customIcons: [String: String]? = nil,
        iconStyle: IconStyle? = nil,
        clipboardEnabled: Bool? = nil,
        gestureEnabled: Bool? = nil
    ) -> AppSettings {
        AppSettings(
            theme: theme ?? self.theme,
            iconSize: (iconSize ?? self.iconSize).clamped(to: Config.iconSizeRange),
            hideTitles: hideTitles ?? self.hideTitles,
            wallpaper: wallpaper ?? self.wallpaper,
            hotCornerEnabled: hotCornerEnabled ?? self.hotCornerEnabled,
            hotCorner: hotCorner ?? self.hotCorner,
            extraAppDirectories: extraAppDirectories ?? self.extraAppDirectories,
            hiddenAppIDs: hiddenAppIDs ?? self.hiddenAppIDs,
            hotKeyKeyCode: hotKeyKeyCode ?? self.hotKeyKeyCode,
            hotKeyModifiers: hotKeyModifiers ?? self.hotKeyModifiers,
            customItems: customItems ?? self.customItems,
            customIcons: customIcons ?? self.customIcons,
            iconStyle: iconStyle ?? self.iconStyle,
            clipboardEnabled: clipboardEnabled ?? self.clipboardEnabled,
            gestureEnabled: gestureEnabled ?? self.gestureEnabled
        )
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
