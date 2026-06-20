import Foundation

/// Scans a set of directories for `.app` bundles, reads each bundle's `Info.plist` for its display
/// name, identifier, and category, then returns a de-duplicated, name-sorted list.
///
/// Parsing reads `Contents/Info.plist` directly (rather than `Bundle(url:)`) so it is robust for
/// test fixtures and apps with unusual structures, and always yields *something* (falling back to
/// the file name) for any `.app` it finds.
public struct AppDiscoveryService: AppDiscovering {
    private let directories: [URL]

    public init(directories: [URL] = Config.defaultAppDirectories) {
        self.directories = directories
    }

    public func discoverApps() -> [AppItem] {
        var seen = Set<String>()
        var items: [AppItem] = []
        for directory in directories {
            for bundleURL in appBundles(in: directory) {
                let item = Self.makeItem(from: bundleURL)
                guard seen.insert(item.id).inserted else { continue }
                items.append(item)
            }
        }
        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func appBundles(in directory: URL) -> [URL] {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return entries.filter { $0.pathExtension == "app" }
    }

    /// Builds an `AppItem` from a bundle URL, parsing `Contents/Info.plist` when present.
    static func makeItem(from url: URL) -> AppItem {
        let info = infoDictionary(for: url)
        let bundleID = info?["CFBundleIdentifier"] as? String
        let name = (info?["CFBundleDisplayName"] as? String)
            ?? (info?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let category = info?["LSApplicationCategoryType"] as? String
        let id = bundleID ?? url.path
        return AppItem(id: id, name: name, url: url, bundleID: bundleID, category: category)
    }

    private static func infoDictionary(for bundleURL: URL) -> [String: Any]? {
        let plistURL = bundleURL.appending(path: "Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        else { return nil }
        return plist as? [String: Any]
    }
}
