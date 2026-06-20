import Testing
import Foundation
@testable import LauncherKit

private func app(_ name: String) -> AppItem {
    AppItem(id: name, name: name, url: URL(filePath: "/Applications/\(name).app"), bundleID: name, category: nil)
}

@Suite struct FolderListTests {
    @Test func creatingFolderSeedsAppsAndReturnsID() {
        let (list, id) = FolderList().creating(name: "Work", appIDs: ["Xcode"])
        #expect(list.folders.count == 1)
        #expect(list.folder(id: id)?.name == "Work")
        #expect(list.folder(id: id)?.appIDs == ["Xcode"])
    }

    @Test func appBelongsToAtMostOneFolder() {
        let (initial, a) = FolderList().creating(name: "A", appIDs: ["App"])
        let (withB, b) = initial.creating(name: "B")
        let list = withB.addingApp("App", toFolder: b)
        #expect(list.folder(id: a)?.appIDs.isEmpty == true)
        #expect(list.folder(id: b)?.appIDs == ["App"])
    }

    @Test func looseAppsExcludeFoldered() {
        let all = [app("A"), app("B"), app("C")]
        let (list, _) = FolderList().creating(name: "F", appIDs: ["B"])
        #expect(list.looseApps(from: all).map(\.name) == ["A", "C"])
    }

    @Test func appsInFolderResolveAgainstLiveSet() {
        let all = [app("A"), app("B")]
        let (list, id) = FolderList().creating(name: "F", appIDs: ["B", "GHOST"])
        #expect(list.apps(inFolder: id, from: all).map(\.name) == ["B"]) // GHOST not installed
    }

    @Test func renameAndDeleteAndRemove() {
        var (list, id) = FolderList().creating(name: "Old", appIDs: ["A"])
        list = list.renaming(id, to: "New")
        #expect(list.folder(id: id)?.name == "New")
        list = list.removingApp("A", fromFolder: id)
        #expect(list.folder(id: id)?.appIDs.isEmpty == true)
        list = list.removingFolder(id)
        #expect(list.folders.isEmpty)
    }

    @Test func roundTripsThroughJSON() throws {
        let (list, _) = FolderList().creating(name: "F", appIDs: ["A", "B"])
        let data = try JSONEncoder().encode(list)
        let decoded = try JSONDecoder().decode(FolderList.self, from: data)
        #expect(decoded == list)
    }
}

/// In-memory folder store for view-model tests.
private final class MemoryFolderStore: FolderStoring, @unchecked Sendable {
    var list: FolderList
    init(_ list: FolderList = FolderList()) { self.list = list }
    func load() -> FolderList { list }
    func save(_ list: FolderList) throws { self.list = list }
}

@MainActor
@Suite struct LauncherViewModelFolderTests {
    @Test func createPersistsAndComposesRootEntries() {
        let store = MemoryFolderStore()
        let vm = LauncherViewModel(apps: [app("A"), app("B")], launcher: NoopLauncher(), folderStore: store)
        let id = vm.createFolder(named: "Games", with: "A")
        #expect(store.list.folder(id: id)?.appIDs == ["A"])     // persisted
        #expect(vm.folders.count == 1)
        #expect(vm.looseApps.map(\.name) == ["B"])
        // Root grid: folder first, then loose app.
        #expect(vm.rootEntries.first.map { if case .folder = $0 { return true } else { return false } } == true)
    }

    @Test func resetPresentationClosesOpenFolder() {
        let vm = LauncherViewModel(apps: [app("A")], launcher: NoopLauncher(), folderStore: MemoryFolderStore())
        let id = vm.createFolder(named: "F", with: "A")
        vm.openFolder(id)
        #expect(vm.openFolder?.id == id)
        vm.resetPresentation()
        #expect(vm.openFolder == nil)
    }
}

private final class NoopLauncher: AppLaunching, @unchecked Sendable {
    func launch(_ app: AppItem) throws {}
}
