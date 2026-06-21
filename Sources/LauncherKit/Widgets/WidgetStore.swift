import Foundation

/// Repository abstraction for persisting widgets.
public protocol WidgetStoring: Sendable {
    func load() -> [WidgetSpec]
    func save(_ widgets: [WidgetSpec]) throws
}

/// JSON-backed store at ~/Library/Application Support/Lancher/widgets.json.
public struct WidgetStore: WidgetStoring {
    public init() {}

    public func load() -> [WidgetSpec] {
        JSONFileStore.load([WidgetSpec].self, from: Config.widgetsFileName) ?? []
    }

    public func save(_ widgets: [WidgetSpec]) throws {
        try JSONFileStore.save(widgets, to: Config.widgetsFileName)
    }
}
