import Testing
import Foundation
@testable import LauncherKit

private func app(_ name: String) -> AppItem {
    AppItem(id: name, name: name, url: URL(filePath: "/Applications/\(name).app"), bundleID: name, category: nil)
}

/// Records every URL it is asked to open.
private final class RecordingOpener: URLOpening, @unchecked Sendable {
    private(set) var opened: [URL] = []
    var failPaths: Set<String> = []
    func open(_ url: URL) -> Bool {
        opened.append(url)
        return !failPaths.contains(url.path)
    }
}

private final class MemoryWorkflowStore: WorkflowStoring, @unchecked Sendable {
    var workflows: [Workflow]
    init(_ workflows: [Workflow] = []) { self.workflows = workflows }
    func load() -> [Workflow] { workflows }
    func save(_ workflows: [Workflow]) throws { self.workflows = workflows }
}

private final class NoopLauncher: AppLaunching, @unchecked Sendable {
    func launch(_ app: AppItem) throws {}
}

@Suite struct WorkflowModelTests {
    @Test func addingAppsIsIdempotentAndImmutable() {
        let base = Workflow(name: "W")
        let once = base.addingApp("A")
        let twice = once.addingApp("A").addingApp("B")
        #expect(base.appIDs.isEmpty)            // original unchanged
        #expect(once.appIDs == ["A"])
        #expect(twice.appIDs == ["A", "B"])
    }

    @Test func itemCountSumsAppsAndPaths() {
        let w = Workflow(name: "W", appIDs: ["A", "B"], paths: ["/tmp/x"])
        #expect(w.itemCount == 3)
    }
}

@Suite struct WorkflowRunnerTests {
    @Test func resolvesAppsAndOpensPaths() {
        let opener = RecordingOpener()
        let runner = WorkflowRunner(opener: opener)
        let workflow = Workflow(name: "Work", appIDs: ["Xcode", "GHOST"], paths: ["/tmp/notes.txt"])

        let result = runner.run(workflow, apps: [app("Xcode")])

        // Xcode resolves, GHOST does not; the path is opened too.
        #expect(opener.opened.map(\.path) == ["/Applications/Xcode.app", "/tmp/notes.txt"])
        #expect(result.opened == 2)
        #expect(result.failed == 0)
    }

    @Test func reportsFailures() {
        let opener = RecordingOpener()
        opener.failPaths = ["/tmp/bad"]
        let runner = WorkflowRunner(opener: opener)
        let result = runner.run(Workflow(name: "W", paths: ["/tmp/bad"]), apps: [])
        #expect(result.failed == 1)
    }
}

@MainActor
@Suite struct LauncherViewModelWorkflowTests {
    private func makeVM(opener: URLOpening) -> LauncherViewModel {
        LauncherViewModel(
            apps: [app("Xcode"), app("Mail")],
            launcher: NoopLauncher(),
            folderStore: makeMemoryFolderStore(),
            settingsStore: makeMemorySettingsStore(),
            workflowStore: MemoryWorkflowStore(),
            workflowRunner: WorkflowRunner(opener: opener)
        )
    }

    @Test func createAddRunPersists() {
        let opener = RecordingOpener()
        let store = MemoryWorkflowStore()
        let vm = LauncherViewModel(
            apps: [app("Xcode")], launcher: NoopLauncher(),
            folderStore: makeMemoryFolderStore(), settingsStore: makeMemorySettingsStore(),
            workflowStore: store, workflowRunner: WorkflowRunner(opener: opener)
        )
        let id = vm.createWorkflow(named: "Dev", with: "Xcode")
        #expect(store.workflows.first?.appIDs == ["Xcode"])  // persisted
        #expect(vm.rootEntries.first.map { if case .workflow = $0 { return true } else { return false } } == true)

        var closed = false
        vm.onClose = { closed = true }
        vm.runWorkflow(id)
        #expect(opener.opened.map(\.path) == ["/Applications/Xcode.app"])
        #expect(closed)
    }
}

// Shared in-memory stores for view-model tests.
private func makeMemoryFolderStore() -> FolderStoring { InMemoryFolderStore() }
private func makeMemorySettingsStore() -> SettingsStoring { InMemorySettingsStore() }

private final class InMemoryFolderStore: FolderStoring, @unchecked Sendable {
    var list = FolderList()
    func load() -> FolderList { list }
    func save(_ list: FolderList) throws { self.list = list }
}
private final class InMemorySettingsStore: SettingsStoring, @unchecked Sendable {
    var settings = AppSettings()
    func load() -> AppSettings { settings }
    func save(_ settings: AppSettings) throws { self.settings = settings }
}
