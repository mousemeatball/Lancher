import Testing
import Foundation
@testable import LancherCore

@Suite struct FolderTests {
    // MARK: - Folder (value type)

    @Test func addingAppendsAppID() {
        let folder = Folder(name: "Work").adding("a")
        #expect(folder.appIDs == ["a"])
    }

    @Test func addingIsIdempotent() {
        let folder = Folder(name: "Work", appIDs: ["a"]).adding("a")
        #expect(folder.appIDs == ["a"])
    }

    @Test func removingDropsAppID() {
        let folder = Folder(name: "Work", appIDs: ["a", "b"]).removing("a")
        #expect(folder.appIDs == ["b"])
    }

    @Test func renamedChangesNameKeepsAppsAndID() {
        let original = Folder(name: "Work", appIDs: ["a"])
        let renamed = original.renamed(to: "Office")
        #expect(renamed.name == "Office")
        #expect(renamed.id == original.id)
        #expect(renamed.appIDs == ["a"])
    }
}

@Suite struct FolderListTests {
    private func apps(_ names: [String]) -> [AppItem] {
        names.map { AppItem(id: $0, name: $0, bundleID: $0, url: URL(filePath: "/\($0).app"), category: nil) }
    }

    @Test func creatingAddsNamedFolder() {
        let (list, id) = FolderList().creating(name: "Work")
        #expect(list.folders.count == 1)
        #expect(list.folder(id: id)?.name == "Work")
    }

    @Test func creatingSeedsAppsAndDetachesFromOthers() {
        let (withWork, workID) = FolderList().creating(name: "Work", appIDs: ["Mail"])
        // Seeding a new folder with "Mail" must remove it from the older folder.
        let (withFun, _) = withWork.creating(name: "Fun", appIDs: ["Mail"])
        #expect(withFun.folder(id: workID)?.appIDs == [])
        #expect(withFun.assignedAppIDs == ["Mail"])
    }

    @Test func addingAppMovesItBetweenFolders() {
        let (a, idA) = FolderList().creating(name: "A", appIDs: ["Mail"])
        let (b, idB) = a.creating(name: "B")
        let moved = b.addingApp("Mail", toFolder: idB)
        #expect(moved.folder(id: idA)?.appIDs == [])
        #expect(moved.folder(id: idB)?.appIDs == ["Mail"])
    }

    @Test func looseAppsExcludeAssignedApps() {
        let (list, _) = FolderList().creating(name: "Work", appIDs: ["Mail"])
        let loose = list.looseApps(from: apps(["Mail", "Safari", "Notes"]))
        #expect(loose.map(\.id) == ["Safari", "Notes"])
    }

    @Test func removingAppReturnsItToLoose() {
        let (list, id) = FolderList().creating(name: "Work", appIDs: ["Mail"])
        let updated = list.removingApp("Mail", fromFolder: id)
        #expect(updated.assignedAppIDs.isEmpty)
        #expect(updated.looseApps(from: apps(["Mail"])).map(\.id) == ["Mail"])
    }

    @Test func renamingUpdatesName() {
        let (list, id) = FolderList().creating(name: "Work")
        #expect(list.renaming(id, to: "Office").folder(id: id)?.name == "Office")
    }

    @Test func removingFolderDropsIt() {
        let (list, id) = FolderList().creating(name: "Work")
        #expect(list.removingFolder(id).folders.isEmpty)
    }

    @Test func appsInFolderPreserveOrderAndSkipMissing() {
        let (list, id) = FolderList().creating(name: "Work", appIDs: ["Notes", "Gone", "Mail"])
        let resolved = list.apps(inFolder: id, from: apps(["Mail", "Notes"]))
        #expect(resolved.map(\.id) == ["Notes", "Mail"])
    }
}
