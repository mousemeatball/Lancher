import Testing
import Foundation
@testable import LancherCore

@Suite struct AppDiscoveryServiceTests {
    @Test func discoversSortedDedupedAppsAndParsesInfoPlist() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        try makeFakeApp(named: "Zeta", bundleID: "com.test.zeta", in: dir)
        try makeFakeApp(named: "Alpha", bundleID: "com.test.alpha", in: dir)
        try makeFakeApp(named: "NoPlist", bundleID: nil, includeInfoPlist: false, in: dir)

        let apps = AppDiscoveryService(searchDirectories: [dir]).discoverApps()

        // Sorted case-insensitively by name.
        #expect(apps.map(\.name) == ["Alpha", "NoPlist", "Zeta"])
        // Bundle id parsed from Info.plist.
        #expect(apps.first { $0.name == "Zeta" }?.bundleID == "com.test.zeta")
        // Missing Info.plist falls back to filename, no bundle id, id == path.
        let noPlist = try #require(apps.first { $0.name == "NoPlist" })
        #expect(noPlist.bundleID == nil)
        #expect(noPlist.id == noPlist.url.path)
    }

    @Test func ignoresNonAppEntries() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        try makeFakeApp(named: "Real", bundleID: "com.test.real", in: dir)
        try "noise".write(to: dir.appending(path: "README.txt"), atomically: true, encoding: .utf8)

        let apps = AppDiscoveryService(searchDirectories: [dir]).discoverApps()
        #expect(apps.map(\.name) == ["Real"])
    }

    @Test func missingDirectoryIsSkipped() {
        let missing = URL(filePath: NSTemporaryDirectory())
            .appending(path: "lancher-missing-\(UUID().uuidString)")
        let apps = AppDiscoveryService(searchDirectories: [missing]).discoverApps()
        #expect(apps.isEmpty)
    }

    // MARK: - Helpers

    private func makeTempDir() throws -> URL {
        let dir = URL(filePath: NSTemporaryDirectory())
            .appending(path: "LancherTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeFakeApp(
        named name: String,
        bundleID: String?,
        includeInfoPlist: Bool = true,
        in dir: URL
    ) throws {
        let contents = dir.appending(path: "\(name).app/Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        guard includeInfoPlist else { return }

        var info: [String: Any] = ["CFBundleName": name]
        if let bundleID { info["CFBundleIdentifier"] = bundleID }
        let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
        try data.write(to: contents.appending(path: "Info.plist"))
    }
}
