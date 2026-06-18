import Foundation

/// Scans the configured directories for `.app` bundles and parses each `Info.plist`.
///
/// Stores only `[URL]` (a `Sendable` value) so the type stays `Sendable`; `FileManager`
/// is accessed via `.default` inside methods rather than stored.
public struct AppDiscoveryService: AppDiscovering, Sendable {
    private let searchDirectories: [URL]

    public init(searchDirectories: [URL] = Config.defaultAppDirectories) {
        self.searchDirectories = searchDirectories
    }

    public func discoverApps() -> [AppItem] {
        let fileManager = FileManager.default
        var seenIDs = Set<String>()
        var items: [AppItem] = []

        for directory in searchDirectories {
            let entries = (try? fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil
            )) ?? []

            for url in entries where url.pathExtension == "app" {
                let item = makeItem(at: url)
                if seenIDs.insert(item.id).inserted {
                    items.append(item)
                }
            }
        }

        return items.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private func makeItem(at url: URL) -> AppItem {
        let info = readInfoPlist(at: url)
        let name = (info?["CFBundleDisplayName"] as? String)
            ?? (info?["CFBundleName"] as? String)
            ?? url.deletingPathExtension().lastPathComponent
        let bundleID = info?["CFBundleIdentifier"] as? String
        let category = info?["LSApplicationCategoryType"] as? String

        return AppItem(
            id: bundleID ?? url.path,
            name: name,
            bundleID: bundleID,
            url: url,
            category: category
        )
    }

    /// Reads `Contents/Info.plist` directly rather than via `Bundle`, which is more robust
    /// for fixtures and avoids `Bundle`'s caching quirks.
    private func readInfoPlist(at appURL: URL) -> [String: Any]? {
        let plistURL = appURL.appending(path: "Contents/Info.plist")
        guard
            let data = try? Data(contentsOf: plistURL),
            let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dictionary = object as? [String: Any]
        else { return nil }
        return dictionary
    }
}
