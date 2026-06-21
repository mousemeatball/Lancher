import Testing
import Foundation
@testable import LauncherKit

private func app(_ name: String) -> AppItem {
    AppItem(id: name, name: name, url: URL(filePath: "/Applications/\(name).app"), bundleID: name, category: nil)
}

private final class MemoryWidgetStore: WidgetStoring, @unchecked Sendable {
    var widgets: [WidgetSpec]
    init(_ widgets: [WidgetSpec] = []) { self.widgets = widgets }
    func load() -> [WidgetSpec] { widgets }
    func save(_ widgets: [WidgetSpec]) throws { self.widgets = widgets }
}
private final class NoopLauncher2: AppLaunching, @unchecked Sendable {
    func launch(_ app: AppItem) throws {}
}
private final class MemFolders: FolderStoring, @unchecked Sendable {
    var list = FolderList(); func load() -> FolderList { list }; func save(_ l: FolderList) throws { list = l }
}
private final class MemSettings: SettingsStoring, @unchecked Sendable {
    var s = AppSettings(); func load() -> AppSettings { s }; func save(_ v: AppSettings) throws { s = v }
}

@Suite struct WidgetSpecTests {
    @Test func roundTripsThroughJSON() throws {
        let widget = WidgetSpec(kind: .affirmation, corner: .bottomLeading, text: "Focus")
        let data = try JSONEncoder().encode(widget)
        let decoded = try JSONDecoder().decode(WidgetSpec.self, from: data)
        #expect(decoded == widget)
    }
}

@MainActor
@Suite struct LauncherViewModelWidgetTests {
    @Test func addRemoveClearPersists() {
        let store = MemoryWidgetStore()
        let vm = LauncherViewModel(
            apps: [app("A")], launcher: NoopLauncher2(),
            folderStore: MemFolders(), settingsStore: MemSettings(),
            workflowStore: WorkflowStore(), workflowRunner: WorkflowRunner(opener: NoopOpener()),
            widgetStore: store
        )
        let id = vm.addWidget(kind: .clock, corner: .topLeading)
        #expect(vm.widgets.count == 1)
        #expect(store.widgets.first?.kind == .clock)   // persisted
        vm.removeWidget(id)
        #expect(vm.widgets.isEmpty)
        _ = vm.addWidget(kind: .weather, text: "Tokyo")
        vm.clearWidgets()
        #expect(vm.widgets.isEmpty)
    }
}

private final class NoopOpener: URLOpening, @unchecked Sendable {
    func open(_ url: URL) -> Bool { true }
}
