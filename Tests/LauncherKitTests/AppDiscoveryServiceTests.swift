import Testing
import Foundation
@testable import LauncherKit

@Suite struct AppDiscoveryServiceTests {
    /// Creates a throwaway directory containing one fake `.app` with the given Info.plist values.
    private func makeFixtureDir(
        appFileName: String,
        bundleID: String?,
        displayName: String?
    ) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "LancherTests-\(UUID().uuidString)")
        let app = root.appending(path: appFileName)
        let contents = app.appending(path: "Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)

        var info: [String: Any] = [:]
        if let bundleID { info["CFBundleIdentifier"] = bundleID }
        if let displayName { info["CFBundleName"] = displayName }
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contents.appending(path: "Info.plist"))
        return root
    }

    @Test func discoversAndParsesAppFromInfoPlist() throws {
        let dir = try makeFixtureDir(appFileName: "Cool.app", bundleID: "com.example.cool", displayName: "Cool App")
        defer { try? FileManager.default.removeItem(at: dir) }

        let apps = AppDiscoveryService(directories: [dir]).discoverApps()

        #expect(apps.count == 1)
        #expect(apps.first?.name == "Cool App")
        #expect(apps.first?.bundleID == "com.example.cool")
        #expect(apps.first?.id == "com.example.cool")
    }

    @Test func fallsBackToFileNameWhenInfoPlistMissingName() throws {
        let dir = try makeFixtureDir(appFileName: "Bare.app", bundleID: nil, displayName: nil)
        defer { try? FileManager.default.removeItem(at: dir) }

        let apps = AppDiscoveryService(directories: [dir]).discoverApps()

        #expect(apps.first?.name == "Bare")
        #expect(apps.first?.id == apps.first?.url.path)
    }

    @Test func deduplicatesByBundleIDAcrossDirectories() throws {
        let dirA = try makeFixtureDir(appFileName: "Dup.app", bundleID: "com.example.dup", displayName: "Dup")
        let dirB = try makeFixtureDir(appFileName: "Dup.app", bundleID: "com.example.dup", displayName: "Dup")
        defer { try? FileManager.default.removeItem(at: dirA); try? FileManager.default.removeItem(at: dirB) }

        let apps = AppDiscoveryService(directories: [dirA, dirB]).discoverApps()

        #expect(apps.count == 1)
    }

    @Test func returnsEmptyForMissingDirectory() {
        let missing = URL(filePath: "/nonexistent-\(UUID().uuidString)")
        #expect(AppDiscoveryService(directories: [missing]).discoverApps().isEmpty)
    }

    /// Regression: `.skipsHiddenFiles` used to drop `hidden`-flagged bundles (like Safari, which is
    /// a hidden Cryptex symlink). Discovery must still find a bundle marked hidden.
    @Test func discoversHiddenFlaggedBundle() throws {
        let dir = try makeFixtureDir(appFileName: "Secret.app", bundleID: "com.example.secret", displayName: "Secret")
        defer { try? FileManager.default.removeItem(at: dir) }
        var appURL = dir.appending(path: "Secret.app")
        var values = URLResourceValues()
        values.isHidden = true
        try appURL.setResourceValues(values)

        let apps = AppDiscoveryService(directories: [dir]).discoverApps()
        #expect(apps.contains { $0.bundleID == "com.example.secret" })
    }

    @Test func sortsByNameCaseInsensitively() throws {
        let dir = try makeFixtureDir(appFileName: "zebra.app", bundleID: "com.z", displayName: "zebra")
        let app2 = dir.appending(path: "Apple.app").appending(path: "Contents")
        try FileManager.default.createDirectory(at: app2, withIntermediateDirectories: true)
        let data = try PropertyListSerialization.data(
            fromPropertyList: ["CFBundleIdentifier": "com.a", "CFBundleName": "Apple"],
            format: .xml, options: 0
        )
        try data.write(to: app2.appending(path: "Info.plist"))
        defer { try? FileManager.default.removeItem(at: dir) }

        let names = AppDiscoveryService(directories: [dir]).discoverApps().map(\.name)
        #expect(names == ["Apple", "zebra"])
    }
}
