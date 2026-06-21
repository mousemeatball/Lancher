#if canImport(AppKit)
import AppKit

/// Composition root: wires discovery → view model → window controller, registers the global summon
/// hotkey (⌥Space), and (when launched with `--debug`) stands up the loopback Debug Bridge.
///
/// Discovery runs synchronously at init, which is fine for the app count under `/Applications`.
/// A later phase can move indexing off the main actor and watch for changes via FSEvents.
@MainActor
public final class AppEnvironment {
    private let viewModel: LauncherViewModel
    private let controller: LauncherWindowController
    private let preferences: PreferencesWindowController
    private var hotKey: GlobalHotKey?
    private var hotCorners: HotCorners?
    private var debugBridge: DebugBridge?

    public init(
        discovery: AppDiscovering = AppDiscoveryService(),
        launcher: AppLaunching = WorkspaceAppLauncher()
    ) {
        let apps = discovery.discoverApps()
        let viewModel = LauncherViewModel(apps: apps, launcher: launcher)
        self.viewModel = viewModel
        self.controller = LauncherWindowController(viewModel: viewModel)
        self.preferences = PreferencesWindowController(viewModel: viewModel)
        Log.event(Log.app, "Lancher \(Config.version) launched — discovered \(apps.count) apps")

        // Summon from anywhere with ⌥Space. Falls back to the menu-bar item if registration fails.
        self.hotKey = GlobalHotKey { [weak self] in
            MainActor.assumeIsolated { self?.toggleLauncher() }
        }
        if hotKey == nil {
            Log.event(Log.app, "Failed to register ⌥Space hotkey — use the menu-bar item instead")
        }

        // Hot-corner summon; kept in sync with settings.
        let hotCorners = HotCorners { [weak self] in self?.summon() }
        self.hotCorners = hotCorners
        viewModel.onSettingsChange = { [weak self] settings in
            self?.hotCorners?.update(enabled: settings.hotCornerEnabled, corner: settings.hotCorner)
        }
        hotCorners.update(enabled: viewModel.settings.hotCornerEnabled, corner: viewModel.settings.hotCorner)

        if DebugBridge.isEnabled() {
            startDebugBridge()
        }

        // Apply any schedule-selected Space at launch.
        viewModel.applyScheduledSpaceIfNeeded()
    }

    public func toggleLauncher() {
        // Honor schedule-based Space switching each time the launcher is summoned.
        viewModel.applyScheduledSpaceIfNeeded()
        controller.toggle()
    }

    /// Always-show summon (used by the hot corner).
    private func summon() {
        viewModel.applyScheduledSpaceIfNeeded()
        controller.show()
    }

    public func showPreferences() {
        preferences.show()
    }

    // MARK: - Debug Bridge

    private func startDebugBridge() {
        debugBridge = DebugBridge(
            stateProvider: { [weak self] in self?.debugState() ?? .unavailable },
            commandHandler: { [weak self] command in
                self?.debugPerform(command) ?? DebugResult(ok: false, message: "host unavailable")
            },
            screenshotProvider: { [weak self] in self?.controller.snapshotPNG() }
        )
        if debugBridge == nil {
            Log.event(Log.bridge, "Debug Bridge failed to start (port \(Config.debugBridgePort) in use?)")
        }
    }

    private func debugState() -> DebugState {
        DebugState(
            app: Config.appName,
            version: Config.version,
            appCount: viewModel.allApps.count,
            query: viewModel.query,
            visible: controller.isVisible,
            filteredCount: viewModel.filteredApps.count,
            folderCount: viewModel.folders.count,
            looseCount: viewModel.looseApps.count,
            openFolder: viewModel.openFolder?.name,
            theme: viewModel.settings.theme.rawValue,
            iconSize: viewModel.settings.iconSize,
            hideTitles: viewModel.settings.hideTitles,
            wallpaper: viewModel.settings.wallpaper?.id,
            activeSpace: viewModel.activeSpace?.name,
            workflowCount: viewModel.workflows.count,
            widgetCount: viewModel.widgets.count,
            lastError: viewModel.lastError
        )
    }

    private func debugPerform(_ command: DebugCommand) -> DebugResult {
        switch command.cmd {
        case "summon", "show":
            controller.show()
            return DebugResult(ok: true, message: "shown")
        case "dismiss", "hide":
            controller.hide()
            return DebugResult(ok: true, message: "hidden")
        case "toggle":
            controller.toggle()
            return DebugResult(ok: true, message: controller.isVisible ? "shown" : "hidden")
        case "search":
            controller.show()
            viewModel.query = command.q ?? ""
            return DebugResult(ok: true, message: "\(viewModel.filteredApps.count) results")
        case "launch":
            guard let app = findApp(for: command) else {
                return DebugResult(ok: false, message: "app not found")
            }
            viewModel.activate(app)
            return DebugResult(ok: viewModel.lastError == nil, message: viewModel.lastError ?? "launched \(app.name)")
        case "create-folder":
            // `name` is the folder's name; the optional seed app is matched by `bundleID`/`q` only.
            let seed = command.bundleID.flatMap { id in viewModel.allApps.first { $0.bundleID == id || $0.id == id } }
                ?? command.q.flatMap { q in viewModel.allApps.first { $0.name.localizedCaseInsensitiveContains(q) } }
            let id = viewModel.createFolder(named: command.name ?? Config.defaultFolderName, with: seed?.id)
            return DebugResult(ok: true, message: "folder \(id) seeded=\(seed?.name ?? "none") (\(viewModel.folders.count) total)")
        case "open-folder":
            guard let folder = viewModel.folders.first(where: { $0.name.localizedCaseInsensitiveContains(command.name ?? command.q ?? "") }) else {
                return DebugResult(ok: false, message: "folder not found")
            }
            controller.show()
            viewModel.openFolder(folder.id)
            return DebugResult(ok: true, message: "opened \(folder.name)")
        case "clear-folders":
            for folder in viewModel.folders { viewModel.deleteFolder(folder.id) }
            return DebugResult(ok: true, message: "cleared")
        case "set-pref":
            let theme = command.theme.flatMap(AppTheme.init(rawValue:))
            viewModel.updateSettings(viewModel.settings.with(
                theme: theme,
                iconSize: command.iconSize,
                hideTitles: command.hideTitles
            ))
            let s = viewModel.settings
            return DebugResult(ok: true, message: "theme=\(s.theme.rawValue) iconSize=\(Int(s.iconSize)) hideTitles=\(s.hideTitles)")
        case "create-workflow":
            let id = viewModel.createWorkflow(named: command.name ?? "Workflow")
            // Seed with apps matched by bundleID or name from the `apps` array.
            for needle in command.apps ?? [] {
                if let app = viewModel.allApps.first(where: { $0.bundleID == needle || $0.id == needle || $0.name.localizedCaseInsensitiveContains(needle) }) {
                    viewModel.addApp(app, toWorkflow: id)
                }
            }
            let count = viewModel.workflow(id: id)?.itemCount ?? 0
            return DebugResult(ok: true, message: "workflow \(id) with \(count) item(s)")
        case "run-workflow":
            guard let workflow = viewModel.workflows.first(where: { $0.name.localizedCaseInsensitiveContains(command.name ?? command.q ?? "") }) else {
                return DebugResult(ok: false, message: "workflow not found")
            }
            viewModel.runWorkflow(workflow.id)
            return DebugResult(ok: true, message: "ran \(workflow.name)")
        case "clear-workflows":
            for workflow in viewModel.workflows { viewModel.deleteWorkflow(workflow.id) }
            return DebugResult(ok: true, message: "cleared")
        case "set-wallpaper":
            let spec: WallpaperSpec? = command.kind
                .flatMap(WallpaperSpec.Kind.init(rawValue:))
                .map { WallpaperSpec(kind: $0, value: command.value) }
            viewModel.updateSettings(viewModel.settings.with(wallpaper: .some(spec)))
            controller.show()
            return DebugResult(ok: true, message: "wallpaper=\(spec?.id ?? "none")")
        case "add-widget":
            guard let kind = command.kind.flatMap(WidgetSpec.Kind.init(rawValue:)) else {
                return DebugResult(ok: false, message: "unknown widget kind")
            }
            let corner = command.name.flatMap(WidgetSpec.Corner.init(rawValue:)) ?? .topTrailing
            viewModel.addWidget(kind: kind, corner: corner, text: command.value)
            controller.show()
            return DebugResult(ok: true, message: "\(kind.rawValue) @ \(corner.rawValue) (\(viewModel.widgets.count) total)")
        case "clear-widgets":
            viewModel.clearWidgets()
            return DebugResult(ok: true, message: "cleared")
        case "save-space":
            let id = viewModel.saveSpace(named: command.name ?? "Space \(viewModel.spaces.count + 1)")
            return DebugResult(ok: true, message: "saved \(viewModel.spaces.first { $0.id == id }?.name ?? "?") (\(viewModel.spaces.count) total)")
        case "apply-space":
            guard let space = viewModel.spaces.first(where: { $0.name.localizedCaseInsensitiveContains(command.name ?? command.q ?? "") }) else {
                return DebugResult(ok: false, message: "space not found")
            }
            viewModel.applySpace(space.id)
            controller.show()
            return DebugResult(ok: true, message: "applied \(space.name)")
        case "clear-spaces":
            viewModel.clearSpaces()
            return DebugResult(ok: true, message: "cleared")
        default:
            return DebugResult(ok: false, message: "unknown command '\(command.cmd)'")
        }
    }

    private func findApp(for command: DebugCommand) -> AppItem? {
        if let bundleID = command.bundleID {
            return viewModel.allApps.first { $0.bundleID == bundleID || $0.id == bundleID }
        }
        if let needle = command.name ?? command.q {
            return viewModel.allApps.first { $0.name.localizedCaseInsensitiveContains(needle) }
        }
        return nil
    }
}
#endif
