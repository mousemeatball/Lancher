import Testing
import Foundation
@testable import LauncherKit

private func app(_ name: String) -> AppItem {
    AppItem(id: name, name: name, url: URL(filePath: "/Applications/\(name).app"), bundleID: name, category: nil)
}
private final class NoLaunch: AppLaunching, @unchecked Sendable { func launch(_ app: AppItem) throws {} }
private final class MemFold: FolderStoring, @unchecked Sendable { var l = FolderList(); func load() -> FolderList { l }; func save(_ x: FolderList) throws { l = x } }
private final class MemSet: SettingsStoring, @unchecked Sendable { var s = AppSettings(); func load() -> AppSettings { s }; func save(_ x: AppSettings) throws { s = x } }
private final class MemLayout: LayoutStoring, @unchecked Sendable { var o: [String] = []; func load() -> [String] { o }; func save(_ x: [String]) throws { o = x } }

@MainActor
@Suite struct LayoutOrderTests {
    private func makeVM(_ layout: MemLayout) -> LauncherViewModel {
        LauncherViewModel(
            apps: [app("Alpha"), app("Beta"), app("Gamma")],
            launcher: NoLaunch(),
            folderStore: MemFold(), settingsStore: MemSet(),
            layoutStore: layout
        )
    }

    @Test func defaultOrderIsAlphabetical() {
        let vm = makeVM(MemLayout())
        #expect(vm.rootEntries.map(\.id) == ["app:Alpha", "app:Beta", "app:Gamma"])
    }

    @Test func moveReordersAndPersists() {
        let store = MemLayout()
        let vm = makeVM(store)
        // Move Gamma before Alpha.
        vm.moveEntry("app:Gamma", before: "app:Alpha")
        #expect(vm.rootEntries.map(\.id) == ["app:Gamma", "app:Alpha", "app:Beta"])
        #expect(store.o == ["app:Gamma", "app:Alpha", "app:Beta"])   // persisted
    }

    @Test func newAppsAppendAfterOrderedOnes() {
        let store = MemLayout()
        store.o = ["app:Gamma", "app:Beta"]   // Alpha not in saved order
        let vm = makeVM(store)
        // Gamma, Beta first (per order); Alpha (unknown) appended after.
        #expect(vm.rootEntries.map(\.id) == ["app:Gamma", "app:Beta", "app:Alpha"])
    }

    @Test func movingOntoItselfIsNoop() {
        let vm = makeVM(MemLayout())
        vm.moveEntry("app:Beta", before: "app:Beta")
        #expect(vm.rootEntries.map(\.id) == ["app:Alpha", "app:Beta", "app:Gamma"])
    }
}
