import Foundation
import Observation

/// Drives the launcher UI: holds the immutable app list, the live search query, and launch
/// behavior. Filtering is a pure function so it is trivially testable.
@Observable
@MainActor
public final class LauncherViewModel {
    public let allApps: [AppItem]
    public var query: String = ""
    public var lastError: String?

    /// The user's folders, persisted via `folderStore`. A value type — every edit reassigns it.
    public private(set) var folderList: FolderList
    /// The folder the user has drilled into, or `nil` for the root grid.
    public private(set) var openFolderID: Folder.ID?

    /// User settings (theme, icon size, hide titles, wallpaper), persisted.
    public private(set) var settings: AppSettings

    /// Called after a successful launch so the host window can dismiss itself.
    public var onClose: () -> Void = {}
    /// Called whenever settings change (e.g. so the wallpaper engine can re-render).
    public var onSettingsChange: (AppSettings) -> Void = { _ in }

    private let launcher: AppLaunching
    private let folderStore: FolderStoring
    private let settingsStore: SettingsStoring

    public init(
        apps: [AppItem],
        launcher: AppLaunching,
        folderStore: FolderStoring = FolderStore(),
        settingsStore: SettingsStoring = SettingsStore()
    ) {
        self.allApps = apps
        self.launcher = launcher
        self.folderStore = folderStore
        self.settingsStore = settingsStore
        self.folderList = folderStore.load()
        self.settings = settingsStore.load()
    }

    // MARK: - Settings

    public func updateSettings(_ newSettings: AppSettings) {
        settings = newSettings
        onSettingsChange(newSettings)
        do { try settingsStore.save(newSettings) }
        catch { lastError = "Couldn't save settings: \(error.localizedDescription)" }
    }

    // MARK: - Search

    public var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var filteredApps: [AppItem] {
        Self.filter(apps: allApps, query: query)
    }

    /// Pure, side-effect-free filter — case-insensitive substring match on the app name.
    nonisolated public static func filter(apps: [AppItem], query: String) -> [AppItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    // MARK: - Root grid composition

    public var folders: [Folder] { folderList.folders }
    public var looseApps: [AppItem] { folderList.looseApps(from: allApps) }

    /// The root grid: folders first, then apps that aren't in any folder.
    public var rootEntries: [LauncherGridEntry] {
        folders.map(LauncherGridEntry.folder) + looseApps.map(LauncherGridEntry.app)
    }

    public var openFolder: Folder? {
        openFolderID.flatMap(folderList.folder(id:))
    }

    public func apps(inFolder id: Folder.ID) -> [AppItem] {
        folderList.apps(inFolder: id, from: allApps)
    }

    /// Up to four icons used to draw a folder tile's mini preview.
    public func previewApps(for folder: Folder) -> [AppItem] {
        Array(apps(inFolder: folder.id).prefix(4))
    }

    // MARK: - Navigation

    public func openFolder(_ id: Folder.ID) { openFolderID = id }
    public func closeFolder() { openFolderID = nil }

    // MARK: - Folder mutations

    @discardableResult
    public func createFolder(named name: String = Config.defaultFolderName, with appID: AppItem.ID? = nil) -> Folder.ID {
        let (updated, id) = folderList.creating(name: name, appIDs: appID.map { [$0] } ?? [])
        apply(updated)
        return id
    }

    public func renameFolder(_ id: Folder.ID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        apply(folderList.renaming(id, to: trimmed))
    }

    public func deleteFolder(_ id: Folder.ID) {
        if openFolderID == id { openFolderID = nil }
        apply(folderList.removingFolder(id))
    }

    public func addApp(_ app: AppItem, toFolder id: Folder.ID) {
        apply(folderList.addingApp(app.id, toFolder: id))
    }

    public func removeApp(_ app: AppItem, fromFolder id: Folder.ID) {
        apply(folderList.removingApp(app.id, fromFolder: id))
    }

    // MARK: - Presentation

    /// Reset transient UI state — called each time the launcher is summoned.
    public func resetPresentation() {
        query = ""
        openFolderID = nil
        lastError = nil
    }

    // MARK: - Activation

    public func activate(_ app: AppItem) {
        do {
            try launcher.launch(app)
            lastError = nil
            onClose()
        } catch {
            lastError = error.localizedDescription
        }
    }

    // MARK: - Private

    /// Commit a new folder list and persist it; a write failure surfaces as `lastError` but the
    /// in-memory change still takes effect for this session.
    private func apply(_ updated: FolderList) {
        folderList = updated
        do {
            try folderStore.save(updated)
        } catch {
            lastError = "Couldn't save folders: \(error.localizedDescription)"
        }
    }
}
