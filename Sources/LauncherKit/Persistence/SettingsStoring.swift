import Foundation

/// Repository abstraction for persisting `AppSettings`, so the view model can be tested in memory.
public protocol SettingsStoring: Sendable {
    func load() -> AppSettings
    func save(_ settings: AppSettings) throws
}
