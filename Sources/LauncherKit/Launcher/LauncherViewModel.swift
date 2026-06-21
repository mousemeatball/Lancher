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

    /// Whether the launcher overlay is currently on screen (drives video-wallpaper play/pause).
    public private(set) var isPresented: Bool = false
    public func setPresented(_ presented: Bool) { isPresented = presented }

    /// Called after a successful launch so the host window can dismiss itself.
    public var onClose: () -> Void = {}
    /// Called whenever settings change (e.g. so the wallpaper engine can re-render).
    public var onSettingsChange: (AppSettings) -> Void = { _ in }

    /// The user's workflows ("launch many at once" presets), persisted.
    public private(set) var workflows: [Workflow]

    /// The user's corner widgets, persisted.
    public private(set) var widgets: [WidgetSpec]

    /// Saved Spaces and which one is active.
    public private(set) var spaces: [Space]
    public private(set) var activeSpaceID: Space.ID?

    /// User's custom ordering of root entries (entry ids); empty means default order.
    public private(set) var layoutOrder: [String]

    private let launcher: AppLaunching
    private let folderStore: FolderStoring
    private let settingsStore: SettingsStoring
    private let workflowStore: WorkflowStoring
    private let workflowRunner: WorkflowRunner
    private let widgetStore: WidgetStoring
    private let spaceStore: SpaceStoring
    private let layoutStore: LayoutStoring

    public init(
        apps: [AppItem],
        launcher: AppLaunching,
        folderStore: FolderStoring = FolderStore(),
        settingsStore: SettingsStoring = SettingsStore(),
        workflowStore: WorkflowStoring = WorkflowStore(),
        workflowRunner: WorkflowRunner = WorkflowRunner(),
        widgetStore: WidgetStoring = WidgetStore(),
        spaceStore: SpaceStoring = SpaceStore(),
        layoutStore: LayoutStoring = LayoutStore()
    ) {
        self.allApps = apps
        self.launcher = launcher
        self.folderStore = folderStore
        self.settingsStore = settingsStore
        self.workflowStore = workflowStore
        self.workflowRunner = workflowRunner
        self.widgetStore = widgetStore
        self.spaceStore = spaceStore
        self.layoutStore = layoutStore
        self.folderList = folderStore.load()
        self.settings = settingsStore.load()
        self.workflows = workflowStore.load()
        self.widgets = widgetStore.load()
        let spacesData = spaceStore.load()
        self.spaces = spacesData.spaces
        self.activeSpaceID = spacesData.activeID
        self.layoutOrder = layoutStore.load()
    }

    // MARK: - Custom layout (drag to rearrange)

    /// Move the entry with `id` to just before `targetID` in the root grid, and persist the order.
    public func moveEntry(_ id: String, before targetID: String) {
        guard id != targetID else { return }
        var ids = rootEntries.map(\.id)
        guard let fromIndex = ids.firstIndex(of: id) else { return }
        let moved = ids.remove(at: fromIndex)
        if let toIndex = ids.firstIndex(of: targetID) {
            ids.insert(moved, at: toIndex)
        } else {
            ids.append(moved)
        }
        layoutOrder = ids
        do { try layoutStore.save(ids) }
        catch { lastError = "Couldn't save layout: \(error.localizedDescription)" }
    }

    // MARK: - Spaces

    public var activeSpace: Space? { spaces.first { $0.id == activeSpaceID } }

    /// Snapshot the current settings, folders, and widgets into a new Space.
    @discardableResult
    public func saveSpace(named name: String, schedule: SpaceSchedule? = nil) -> Space.ID {
        let space = Space(name: name, settings: settings, folders: folderList, widgets: widgets, schedule: schedule)
        spaces.append(space)
        activeSpaceID = space.id
        persistSpaces()
        return space.id
    }

    /// Apply a Space: restore its settings, folders, and widgets (each persisted).
    public func applySpace(_ id: Space.ID) {
        guard let space = spaces.first(where: { $0.id == id }) else { return }
        updateSettings(space.settings)
        apply(space.folders)
        widgets = space.widgets
        persistWidgets()
        activeSpaceID = id
        persistSpaces()
    }

    public func deleteSpace(_ id: Space.ID) {
        spaces.removeAll { $0.id == id }
        if activeSpaceID == id { activeSpaceID = nil }
        persistSpaces()
    }

    public func clearSpaces() {
        spaces.removeAll()
        activeSpaceID = nil
        persistSpaces()
    }

    /// Apply the schedule-selected Space if it differs from the active one.
    public func applyScheduledSpaceIfNeeded(at date: Date = Date()) {
        guard let scheduled = SpaceScheduler.activeSpace(at: date, among: spaces),
              scheduled.id != activeSpaceID
        else { return }
        applySpace(scheduled.id)
    }

    private func persistSpaces() {
        do { try spaceStore.save(SpacesData(spaces: spaces, activeID: activeSpaceID)) }
        catch { lastError = "Couldn't save spaces: \(error.localizedDescription)" }
    }

    // MARK: - Widgets

    @discardableResult
    public func addWidget(kind: WidgetSpec.Kind, corner: WidgetSpec.Corner = .topTrailing, text: String? = nil) -> WidgetSpec.ID {
        let widget = WidgetSpec(kind: kind, corner: corner, text: text)
        widgets.append(widget)
        persistWidgets()
        return widget.id
    }

    public func removeWidget(_ id: WidgetSpec.ID) {
        widgets.removeAll { $0.id == id }
        persistWidgets()
    }

    public func clearWidgets() {
        widgets.removeAll()
        persistWidgets()
    }

    private func persistWidgets() {
        do { try widgetStore.save(widgets) }
        catch { lastError = "Couldn't save widgets: \(error.localizedDescription)" }
    }

    // MARK: - Workflows

    @discardableResult
    public func createWorkflow(named name: String, with appID: AppItem.ID? = nil) -> Workflow.ID {
        let workflow = Workflow(name: name, appIDs: appID.map { [$0] } ?? [])
        workflows.append(workflow)
        persistWorkflows()
        return workflow.id
    }

    public func renameWorkflow(_ id: Workflow.ID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        mutateWorkflow(id) { $0.renamed(to: trimmed) }
    }

    public func addApp(_ app: AppItem, toWorkflow id: Workflow.ID) {
        mutateWorkflow(id) { $0.addingApp(app.id) }
    }

    public func deleteWorkflow(_ id: Workflow.ID) {
        workflows.removeAll { $0.id == id }
        persistWorkflows()
    }

    public func workflow(id: Workflow.ID) -> Workflow? {
        workflows.first { $0.id == id }
    }

    /// Run a workflow: opens all its apps and paths, then dismisses the launcher.
    public func runWorkflow(_ id: Workflow.ID) {
        guard let workflow = workflow(id: id) else { return }
        let result = workflowRunner.run(workflow, apps: allApps)
        if result.failed > 0 { lastError = "Workflow '\(workflow.name)': \(result.failed) item(s) failed to open" }
        onClose()
    }

    private func mutateWorkflow(_ id: Workflow.ID, _ transform: (Workflow) -> Workflow) {
        workflows = workflows.map { $0.id == id ? transform($0) : $0 }
        persistWorkflows()
    }

    private func persistWorkflows() {
        do { try workflowStore.save(workflows) }
        catch { lastError = "Couldn't save workflows: \(error.localizedDescription)" }
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

    /// If the query is a math expression, its formatted result (calculator in the search field).
    public var calculatorResult: String? {
        guard let value = ExpressionEvaluator.evaluate(query) else { return nil }
        if value == value.rounded() && abs(value) < 1e15 { return String(Int(value)) }
        return String(format: "%g", value)
    }

    // MARK: - Root grid composition

    public var folders: [Folder] { folderList.folders }
    public var looseApps: [AppItem] {
        let hidden = settings.hiddenIDSet
        return folderList.looseApps(from: allApps).filter { !hidden.contains($0.id) }
    }

    /// Apps the user has hidden (shown in Preferences for unhiding).
    public var hiddenApps: [AppItem] {
        let hidden = settings.hiddenIDSet
        return allApps.filter { hidden.contains($0.id) }
    }

    public func hideApp(_ app: AppItem) {
        guard !settings.hiddenAppIDs.contains(app.id) else { return }
        updateSettings(settings.with(hiddenAppIDs: settings.hiddenAppIDs + [app.id]))
    }

    public func unhideApp(_ id: String) {
        updateSettings(settings.with(hiddenAppIDs: settings.hiddenAppIDs.filter { $0 != id }))
    }

    /// User-added files/folders shown on the grid.
    public var customItems: [CustomItem] { settings.customItems.map(CustomItem.init) }

    /// Apps grouped by humanized category (Categories page). Includes all apps (even hidden ones),
    /// matching LaunchMe where hidden apps remain reachable via Categories.
    public var appsByCategory: [(name: String, apps: [AppItem])] {
        Dictionary(grouping: allApps) { Self.humanCategory($0.category) }
            .map { (name: $0.key, apps: $0.value.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) }
            .sorted { $0.name < $1.name }
    }

    static func humanCategory(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "Other" }
        let stripped = raw.replacingOccurrences(of: "public.app-category.", with: "")
        return stripped.split(separator: "-").map { $0.capitalized }.joined(separator: " ")
    }

    /// The root grid. Default order is workflows, folders, custom items, then loose apps; if the
    /// user has a custom `layoutOrder`, entries are sorted by it (unknown/new entries keep default
    /// order and are appended after known ones).
    public var rootEntries: [LauncherGridEntry] {
        let base = workflows.map(LauncherGridEntry.workflow)
            + folders.map(LauncherGridEntry.folder)
            + customItems.map(LauncherGridEntry.file)
            + looseApps.map(LauncherGridEntry.app)
        guard !layoutOrder.isEmpty else { return base }

        let rank = Dictionary(uniqueKeysWithValues: layoutOrder.enumerated().map { ($1, $0) })
        return base.enumerated().sorted { lhs, rhs in
            switch (rank[lhs.element.id], rank[rhs.element.id]) {
            case let (l?, r?): return l < r
            case (_?, nil): return true       // known entries before unknown
            case (nil, _?): return false
            case (nil, nil): return lhs.offset < rhs.offset   // preserve default order
            }
        }.map(\.element)
    }

    public var openFolder: Folder? {
        openFolderID.flatMap(folderList.folder(id:))
    }

    public func apps(inFolder id: Folder.ID) -> [AppItem] {
        let hidden = settings.hiddenIDSet
        return folderList.apps(inFolder: id, from: allApps).filter { !hidden.contains($0.id) }
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

    /// Drop a dragged grid entry ("app:<id>") into a folder. Ignores non-app entries.
    public func dropEntry(_ entryID: String, intoFolder folderID: Folder.ID) {
        let prefix = "app:"
        guard entryID.hasPrefix(prefix) else { return }
        let appID = String(entryID.dropFirst(prefix.count))
        guard let app = allApps.first(where: { $0.id == appID }) else { return }
        addApp(app, toFolder: folderID)
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

    /// Open a user-added file/folder (reuses the workflow runner's URL opener).
    public func openItem(_ item: CustomItem) {
        _ = workflowRunner.run(Workflow(name: item.name, paths: [item.path]), apps: allApps)
        onClose()
    }

    // MARK: - Custom items & icons

    public func addCustomItem(path: String) {
        guard !settings.customItems.contains(path) else { return }
        updateSettings(settings.with(customItems: settings.customItems + [path]))
    }

    public func removeCustomItem(path: String) {
        updateSettings(settings.with(customItems: settings.customItems.filter { $0 != path }))
    }

    public func iconOverridePath(for app: AppItem) -> String? {
        settings.customIcons[app.id]
    }

    public func setCustomIcon(_ path: String, for app: AppItem) {
        var icons = settings.customIcons
        icons[app.id] = path
        updateSettings(settings.with(customIcons: icons))
    }

    public func resetCustomIcon(for app: AppItem) {
        var icons = settings.customIcons
        icons[app.id] = nil
        updateSettings(settings.with(customIcons: icons))
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
