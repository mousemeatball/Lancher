import Foundation

/// Fetches the current weather condition for a city from Open-Meteo (free, no API key). Returns
/// nil on any failure so the wallpaper can fall back gracefully.
public enum WeatherService {
    private struct GeoResponse: Decodable {
        struct Result: Decodable { let latitude: Double; let longitude: Double }
        let results: [Result]?
    }
    private struct ForecastResponse: Decodable {
        struct Current: Decodable { let weather_code: Int }
        let current: Current?
    }

    public static func fetch(city: String?) async -> WeatherCondition? {
        let trimmed = (city ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let cityName = trimmed.isEmpty ? Config.defaultWeatherCity : trimmed
        guard let coords = await geocode(cityName) else { return nil }
        return await currentCondition(latitude: coords.0, longitude: coords.1)
    }

    private static func geocode(_ city: String) async -> (Double, Double)? {
        guard let encoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://geocoding-api.open-meteo.com/v1/search?name=\(encoded)&count=1")
        else { return nil }
        guard let data = try? await URLSession.shared.data(from: url).0,
              let response = try? JSONDecoder().decode(GeoResponse.self, from: data),
              let first = response.results?.first
        else { return nil }
        return (first.latitude, first.longitude)
    }

    private static func currentCondition(latitude: Double, longitude: Double) async -> WeatherCondition? {
        guard let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=weather_code")
        else { return nil }
        guard let data = try? await URLSession.shared.data(from: url).0,
              let response = try? JSONDecoder().decode(ForecastResponse.self, from: data),
              let code = response.current?.weather_code
        else { return nil }
        return WeatherCondition.from(wmoCode: code)
    }
}
