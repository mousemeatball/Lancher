import Foundation

/// Weather scene categories for the dynamic Weather wallpaper. Pure + testable.
public enum WeatherCondition: String, Sendable, CaseIterable {
    case clear
    case cloudy
    case rain
    case snow
    case thunderstorm

    /// Maps a WMO weather code (as returned by Open-Meteo `weather_code`) to a scene.
    public static func from(wmoCode code: Int) -> WeatherCondition {
        switch code {
        case 0, 1: return .clear
        case 2, 3, 45, 48: return .cloudy
        case 51...67, 80...82: return .rain
        case 71...77, 85, 86: return .snow
        case 95...99: return .thunderstorm
        default: return .cloudy
        }
    }

    public var symbolName: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "snowflake"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        }
    }
}
