import Foundation

/// JSON-backed settings store at ~/Library/Application Support/Lancher/settings.json.
public struct SettingsStore: SettingsStoring {
    public init() {}

    public func load() -> AppSettings {
        JSONFileStore.load(AppSettings.self, from: Config.settingsFileName) ?? AppSettings()
    }

    public func save(_ settings: AppSettings) throws {
        try JSONFileStore.save(settings, to: Config.settingsFileName)
    }
}
