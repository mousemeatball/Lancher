import Testing
import Foundation
@testable import LauncherKit

@Suite struct AppSettingsTests {
    @Test func withReturnsModifiedCopy() {
        let base = AppSettings()
        let updated = base.with(theme: .flat, hideTitles: true)
        #expect(base.theme == .liquidGlass)        // original unchanged
        #expect(updated.theme == .flat)
        #expect(updated.hideTitles == true)
        #expect(updated.iconSize == base.iconSize)  // untouched field preserved
    }

    @Test func iconSizeIsClampedToRange() {
        #expect(AppSettings().with(iconSize: 5).iconSize == Config.iconSizeRange.lowerBound)
        #expect(AppSettings().with(iconSize: 9999).iconSize == Config.iconSizeRange.upperBound)
    }

    @Test func roundTripsThroughJSON() throws {
        let settings = AppSettings(theme: .flat, iconSize: 96, hideTitles: true, wallpaper: .sun)
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: data)
        #expect(decoded == settings)
    }

    @Test func wallpaperSpecIdentity() {
        #expect(WallpaperSpec.color("#FFFFFF").id == "color:#FFFFFF")
        #expect(WallpaperSpec.sun.id == "sun:")
    }
}
