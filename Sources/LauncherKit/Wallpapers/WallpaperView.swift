#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import AppKit

/// Renders the backdrop for a `WallpaperSpec`. Falls back to a dark gradient when no wallpaper is
/// set or an asset can't be loaded. `isActive` gates video playback (pause when hidden).
public struct WallpaperView: View {
    let spec: WallpaperSpec?
    let isActive: Bool

    public init(spec: WallpaperSpec?, isActive: Bool) {
        self.spec = spec
        self.isActive = isActive
    }

    public var body: some View {
        switch spec?.kind {
        case .none:
            defaultBackdrop
        case .color:
            (Color(hex: spec?.value ?? "") ?? .black).ignoresSafeArea()
        case .image:
            imageBackdrop
        case .video:
            videoBackdrop
        case .sun:
            SunWallpaper()
        case .weather:
            WeatherWallpaper(city: spec?.value)
        }
    }

    private var defaultBackdrop: some View {
        LinearGradient(
            colors: [Color(red: 0.07, green: 0.08, blue: 0.12), Color(red: 0.02, green: 0.02, blue: 0.04)],
            startPoint: .top, endPoint: .bottom
        ).ignoresSafeArea()
    }

    @ViewBuilder
    private var imageBackdrop: some View {
        if let path = spec?.value, let image = NSImage(contentsOfFile: path) {
            Image(nsImage: image).resizable().aspectRatio(contentMode: .fill).ignoresSafeArea()
        } else {
            defaultBackdrop
        }
    }

    @ViewBuilder
    private var videoBackdrop: some View {
        if let path = spec?.value, FileManager.default.fileExists(atPath: path) {
            VideoWallpaper(url: URL(filePath: path), isActive: isActive).ignoresSafeArea()
        } else {
            defaultBackdrop
        }
    }
}

/// Dynamic Sun: a sky gradient that shifts with the local time of day.
struct SunWallpaper: View {
    var body: some View {
        let hour = Calendar.current.component(.hour, from: Date())
        return LinearGradient(colors: Self.colors(for: DayPhase.phase(forHour: hour)),
                              startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }

    static func colors(for phase: DayPhase) -> [Color] {
        switch phase {
        case .night: return [Color(red: 0.03, green: 0.04, blue: 0.12), Color(red: 0.0, green: 0.0, blue: 0.03)]
        case .dawn:  return [Color(red: 0.98, green: 0.70, blue: 0.50), Color(red: 0.30, green: 0.35, blue: 0.55)]
        case .day:   return [Color(red: 0.36, green: 0.66, blue: 0.98), Color(red: 0.75, green: 0.88, blue: 1.0)]
        case .dusk:  return [Color(red: 0.96, green: 0.52, blue: 0.36), Color(red: 0.20, green: 0.16, blue: 0.36)]
        }
    }
}

/// Dynamic Weather: fetches the condition for a city and renders a matching gradient + symbol.
struct WeatherWallpaper: View {
    let city: String?
    @State private var condition: WeatherCondition?

    var body: some View {
        ZStack {
            LinearGradient(colors: Self.colors(for: condition), startPoint: .top, endPoint: .bottom)
            if let condition {
                Image(systemName: condition.symbolName)
                    .font(.system(size: 120))
                    .foregroundStyle(.white.opacity(0.85))
                    .offset(y: -120)
            }
        }
        .ignoresSafeArea()
        .task { condition = await WeatherService.fetch(city: city) }
    }

    static func colors(for condition: WeatherCondition?) -> [Color] {
        switch condition {
        case .clear: return [Color(red: 0.36, green: 0.66, blue: 0.98), Color(red: 0.80, green: 0.90, blue: 1.0)]
        case .cloudy, .none: return [Color(red: 0.45, green: 0.50, blue: 0.58), Color(red: 0.22, green: 0.26, blue: 0.32)]
        case .rain: return [Color(red: 0.30, green: 0.36, blue: 0.45), Color(red: 0.12, green: 0.16, blue: 0.22)]
        case .snow: return [Color(red: 0.78, green: 0.84, blue: 0.92), Color(red: 0.55, green: 0.62, blue: 0.72)]
        case .thunderstorm: return [Color(red: 0.20, green: 0.22, blue: 0.30), Color(red: 0.05, green: 0.06, blue: 0.10)]
        }
    }
}
#endif
