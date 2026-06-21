#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// Live clock + date.
struct ClockWidget: View {
    let theme: AppTheme
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 2) {
                Text(context.date, format: .dateTime.hour().minute())
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                Text(context.date, format: .dateTime.weekday(.wide).month().day())
                    .font(.caption)
                    .opacity(0.8)
            }
            .foregroundStyle(.white)
            .padding(20)
            .themedPanel(theme, cornerRadius: 18)
        }
    }
}

/// A custom affirmation / note.
struct AffirmationWidget: View {
    let text: String?
    let theme: AppTheme
    var body: some View {
        Text((text?.isEmpty == false ? text! : "You've got this."))
            .font(.title3.weight(.medium))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(20)
            .frame(maxWidth: 260)
            .themedPanel(theme, cornerRadius: 18)
    }
}

/// Current weather for a city (Open-Meteo); falls back gracefully while loading/offline.
struct WeatherWidget: View {
    let city: String?
    let theme: AppTheme
    @State private var condition: WeatherCondition?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: condition?.symbolName ?? "cloud.fill")
                .font(.system(size: 34))
            VStack(alignment: .leading, spacing: 2) {
                Text(city?.isEmpty == false ? city! : Config.defaultWeatherCity)
                    .font(.headline)
                Text((condition?.rawValue ?? "loading…").capitalized)
                    .font(.caption).opacity(0.8)
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .themedPanel(theme, cornerRadius: 18)
        .task { condition = await WeatherService.fetch(city: city) }
    }
}
#endif
