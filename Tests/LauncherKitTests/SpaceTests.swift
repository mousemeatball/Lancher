import Testing
import Foundation
@testable import LauncherKit

private func app(_ name: String) -> AppItem {
    AppItem(id: name, name: name, url: URL(filePath: "/Applications/\(name).app"), bundleID: name, category: nil)
}
private final class NoLauncher: AppLaunching, @unchecked Sendable { func launch(_ app: AppItem) throws {} }
private final class MemF: FolderStoring, @unchecked Sendable { var l = FolderList(); func load() -> FolderList { l }; func save(_ x: FolderList) throws { l = x } }
private final class MemS: SettingsStoring, @unchecked Sendable { var s = AppSettings(); func load() -> AppSettings { s }; func save(_ x: AppSettings) throws { s = x } }
private final class MemW: WorkflowStoring, @unchecked Sendable { var w: [Workflow] = []; func load() -> [Workflow] { w }; func save(_ x: [Workflow]) throws { w = x } }
private final class MemWid: WidgetStoring, @unchecked Sendable { var w: [WidgetSpec] = []; func load() -> [WidgetSpec] { w }; func save(_ x: [WidgetSpec]) throws { w = x } }
private final class MemSp: SpaceStoring, @unchecked Sendable { var d = SpacesData(); func load() -> SpacesData { d }; func save(_ x: SpacesData) throws { d = x } }
private final class NoOpener: URLOpening, @unchecked Sendable { func open(_ url: URL) -> Bool { true } }

@Suite struct SpaceSchedulerTests {
    private func date(weekday: Int, hour: Int, minute: Int) -> Date {
        // 2024-01-07 is a Sunday (weekday 1). Offset to the desired weekday.
        var comps = DateComponents()
        comps.year = 2024; comps.month = 1; comps.day = 6 + weekday; comps.hour = hour; comps.minute = minute
        return Calendar(identifier: .gregorian).date(from: comps)!
    }

    private func space(_ name: String, weekdays: Set<Int>, hour: Int, minute: Int) -> Space {
        Space(name: name, settings: AppSettings(), folders: FolderList(), widgets: [],
              schedule: SpaceSchedule(weekdays: weekdays, hour: hour, minute: minute))
    }

    @Test func picksLatestStartedScheduleForToday() {
        let work = space("Work", weekdays: [2], hour: 9, minute: 0)   // Monday 09:00
        let night = space("Night", weekdays: [2], hour: 18, minute: 0) // Monday 18:00
        let cal = Calendar(identifier: .gregorian)
        #expect(SpaceScheduler.activeSpace(at: date(weekday: 2, hour: 10, minute: 0), among: [work, night], calendar: cal)?.name == "Work")
        #expect(SpaceScheduler.activeSpace(at: date(weekday: 2, hour: 20, minute: 0), among: [work, night], calendar: cal)?.name == "Night")
    }

    @Test func returnsNilBeforeAnyStartOrWrongDay() {
        let work = space("Work", weekdays: [2], hour: 9, minute: 0)
        let cal = Calendar(identifier: .gregorian)
        #expect(SpaceScheduler.activeSpace(at: date(weekday: 2, hour: 8, minute: 0), among: [work], calendar: cal) == nil)
        #expect(SpaceScheduler.activeSpace(at: date(weekday: 3, hour: 10, minute: 0), among: [work], calendar: cal) == nil)
    }
}

@MainActor
@Suite struct LauncherViewModelSpaceTests {
    private func makeVM() -> LauncherViewModel {
        LauncherViewModel(
            apps: [app("A"), app("B")], launcher: NoLauncher(),
            folderStore: MemF(), settingsStore: MemS(),
            workflowStore: MemW(), workflowRunner: WorkflowRunner(opener: NoOpener()),
            widgetStore: MemWid(), spaceStore: MemSp()
        )
    }

    @Test func saveSnapshotsAndApplyRestores() {
        let vm = makeVM()
        // Set up "Gaming": flat theme, big icons, a widget, a folder.
        vm.updateSettings(vm.settings.with(theme: .flat, iconSize: 120))
        vm.addWidget(kind: .clock)
        vm.createFolder(named: "Games", with: "A")
        let gaming = vm.saveSpace(named: "Gaming")

        // Change away from that state.
        vm.updateSettings(vm.settings.with(theme: .liquidGlass, iconSize: 64))
        vm.clearWidgets()
        #expect(vm.settings.theme == .liquidGlass)
        #expect(vm.widgets.isEmpty)

        // Applying restores the snapshot.
        vm.applySpace(gaming)
        #expect(vm.settings.theme == .flat)
        #expect(vm.settings.iconSize == 120)
        #expect(vm.widgets.count == 1)
        #expect(vm.folders.contains { $0.name == "Games" })
        #expect(vm.activeSpace?.name == "Gaming")
    }
}
