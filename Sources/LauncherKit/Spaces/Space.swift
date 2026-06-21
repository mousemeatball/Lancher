import Foundation

/// A saved environment: a snapshot of settings (theme/icon size/wallpaper), folders, and widgets,
/// optionally switched automatically on a schedule. Immutable value type.
public struct Space: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let settings: AppSettings
    public let folders: FolderList
    public let widgets: [WidgetSpec]
    public let schedule: SpaceSchedule?

    public init(
        id: UUID = UUID(),
        name: String,
        settings: AppSettings,
        folders: FolderList,
        widgets: [WidgetSpec],
        schedule: SpaceSchedule? = nil
    ) {
        self.id = id
        self.name = name
        self.settings = settings
        self.folders = folders
        self.widgets = widgets
        self.schedule = schedule
    }

    public func renamed(to newName: String) -> Space {
        Space(id: id, name: newName, settings: settings, folders: folders, widgets: widgets, schedule: schedule)
    }

    public func scheduled(_ schedule: SpaceSchedule?) -> Space {
        Space(id: id, name: name, settings: settings, folders: folders, widgets: widgets, schedule: schedule)
    }
}
