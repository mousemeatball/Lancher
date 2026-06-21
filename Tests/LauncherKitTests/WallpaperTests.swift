import Testing
@testable import LauncherKit

@Suite struct WallpaperLogicTests {
    @Test func dayPhaseBuckets() {
        #expect(DayPhase.phase(forHour: 6) == .dawn)
        #expect(DayPhase.phase(forHour: 12) == .day)
        #expect(DayPhase.phase(forHour: 18) == .dusk)
        #expect(DayPhase.phase(forHour: 2) == .night)
        #expect(DayPhase.phase(forHour: 23) == .night)
    }

    @Test func weatherCodeMapping() {
        #expect(WeatherCondition.from(wmoCode: 0) == .clear)
        #expect(WeatherCondition.from(wmoCode: 3) == .cloudy)
        #expect(WeatherCondition.from(wmoCode: 61) == .rain)
        #expect(WeatherCondition.from(wmoCode: 71) == .snow)
        #expect(WeatherCondition.from(wmoCode: 95) == .thunderstorm)
        #expect(WeatherCondition.from(wmoCode: 999) == .cloudy) // unknown -> cloudy
    }

    @Test func wallpaperSpecMakersRoundTrip() {
        #expect(WallpaperSpec.video("/a/b.mp4").kind == .video)
        #expect(WallpaperSpec.weather("Tokyo").value == "Tokyo")
    }
}
