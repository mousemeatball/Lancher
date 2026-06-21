import Foundation

/// Declarative description of a wallpaper. Stored in `AppSettings` and Spaces; rendered by the
/// `WallpaperEngine`. A value type so it is trivially Codable/Sendable and snapshot-friendly.
public struct WallpaperSpec: Codable, Sendable, Equatable, Identifiable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case color    // `value` = "#RRGGBB"
        case image    // `value` = file path (png/jpg/heic)
        case video    // `value` = file path (mp4/mov/avi/mkv)
        case sun      // dynamic, computed from local time
        case weather  // dynamic, `value` = optional city name (else CoreLocation)
    }

    public var kind: Kind
    public var value: String?

    public var id: String { "\(kind.rawValue):\(value ?? "")" }

    public init(kind: Kind, value: String? = nil) {
        self.kind = kind
        self.value = value
    }

    public static func color(_ hex: String) -> WallpaperSpec { .init(kind: .color, value: hex) }
    public static func image(_ path: String) -> WallpaperSpec { .init(kind: .image, value: path) }
    public static func video(_ path: String) -> WallpaperSpec { .init(kind: .video, value: path) }
    public static let sun = WallpaperSpec(kind: .sun)
    public static func weather(_ city: String? = nil) -> WallpaperSpec { .init(kind: .weather, value: city) }
}
