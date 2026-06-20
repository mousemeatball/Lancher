import Testing
@testable import LauncherKit

@Suite struct ConfigTests {
    @Test func identityConstantsAreSet() {
        #expect(Config.appName == "Lancher")
        #expect(Config.bundleID == "com.lancher.app")
        #expect(!Config.version.isEmpty)
    }

    @Test func defaultAppDirectoriesIncludeApplications() {
        let paths = Config.defaultAppDirectories.map(\.path)
        #expect(paths.contains("/Applications"))
        #expect(paths.contains("/System/Applications"))
    }
}
