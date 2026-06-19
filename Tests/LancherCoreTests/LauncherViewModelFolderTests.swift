import Testing
import Foundation
@testable import LancherCore

/// In-memory store so view-model folder behavior is tested without touching the filesystem.
private final class InMemoryFolderStore: FolderStoring, @unchecked Sendable {
    private(set) var saved: FolderList
    private(set) var saveCount = 0

    init(_ initial: FolderList = FolderList()) { self.saved = initial }

    func load() -> FolderList { saved }
    func save(_ folders: FolderList) throws {
        saved = folders
        saveCount += 1
    }
}

private struct NoopLauncher: AppLaunching {
    func launch(_ app: AppItem) throws {}
}

@MainActor
@Suite struct LauncherViewModelFolderTests {
    private func app(_ name: String) -> AppItem {
        AppItem(id: name, name: name, bundleID: name, url: URL(filePath: "/\(name).app"), category: nil)
    }

    private func makeViewModel(
        apps names: [String] = ["Mail", "Safari", "Notes"],
        store: FolderStoring = InMemoryFolderStore()
    ) -> LauncherViewModel {
        LauncherViewModel(apps: names.map(app), launcher: NoopLauncher(), folderStore: store)
    }

    @Test func createFolderPersistsIt() {
        let store = InMemoryFolderStore()
        let viewModel = makeViewModel(store: store)

        viewModel.createFolder(named: "Work")

        #expect(viewModel.folders.map(\.name) == ["Work"])
        #expect(store.saved.folders.count == 1)
        #expect(store.saveCount == 1)
    }

    @Test func addingAppMovesItOutOfLoose() {
        let viewModel = makeViewModel()
        let id = viewModel.createFolder(named: "Work")

        viewModel.addApp(app("Mail"), toFolder: id)

        #expect(viewModel.apps(inFolder: id).map(\.id) == ["Mail"])
        #expect(viewModel.looseApps.map(\.id) == ["Safari", "Notes"])
    }

    @Test func createFolderWithAppSeedsIt() {
        let viewModel = makeViewModel()
        let id = viewModel.createFolder(with: app("Safari").id)
        #expect(viewModel.apps(inFolder: id).map(\.id) == ["Safari"])
    }

    @Test func removeAppFromFolderReturnsItToLoose() {
        let viewModel = makeViewModel()
        let id = viewModel.createFolder(with: app("Mail").id)

        viewModel.removeApp(app("Mail"), fromFolder: id)

        #expect(viewModel.apps(inFolder: id).isEmpty)
        #expect(viewModel.looseApps.contains { $0.id == "Mail" })
    }

    @Test func openAndCloseFolderDrivesNavigation() {
        let viewModel = makeViewModel()
        let id = viewModel.createFolder(named: "Work")

        viewModel.openFolder(id)
        #expect(viewModel.openFolder?.id == id)

        viewModel.closeFolder()
        #expect(viewModel.openFolder == nil)
    }

    @Test func deletingOpenFolderClearsNavigation() {
        let viewModel = makeViewModel()
        let id = viewModel.createFolder(named: "Work")
        viewModel.openFolder(id)

        viewModel.deleteFolder(id)

        #expect(viewModel.openFolder == nil)
        #expect(viewModel.folders.isEmpty)
    }

    @Test func resetPresentationClearsQueryAndOpenFolder() {
        let viewModel = makeViewModel()
        let id = viewModel.createFolder(named: "Work")
        viewModel.openFolder(id)
        viewModel.query = "saf"

        viewModel.resetPresentation()

        #expect(viewModel.query.isEmpty)
        #expect(viewModel.openFolder == nil)
    }

    @Test func loadsExistingFoldersFromStoreOnInit() {
        let (seeded, _) = FolderList().creating(name: "Preexisting")
        let viewModel = makeViewModel(store: InMemoryFolderStore(seeded))
        #expect(viewModel.folders.map(\.name) == ["Preexisting"])
    }

    @Test func rootEntriesListFoldersBeforeLooseApps() {
        let viewModel = makeViewModel()
        let id = viewModel.createFolder(named: "Work")
        viewModel.addApp(app("Mail"), toFolder: id)

        let ids = viewModel.rootEntries.map(\.id)
        #expect(ids.first == "folder:\(id)")
        #expect(ids.contains("app:Safari"))
        #expect(!ids.contains("app:Mail"))
    }
}
