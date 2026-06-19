import Testing
import Foundation
@testable import LancherCore

@Suite struct FolderStoreTests {
    /// A unique temp directory per test so runs never collide.
    private func tempDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "LancherTests-\(UUID().uuidString)")
    }

    @Test func loadReturnsEmptyWhenNothingSaved() {
        let store = FolderStore(directory: tempDirectory())
        #expect(store.load().folders.isEmpty)
    }

    @Test func saveThenLoadRoundTrips() throws {
        let directory = tempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = FolderStore(directory: directory)
        let (list, _) = FolderList().creating(name: "Work", appIDs: ["Mail", "Slack"])
        try store.save(list)

        let reloaded = FolderStore(directory: directory).load()
        #expect(reloaded == list)
    }

    @Test func loadReturnsEmptyForCorruptFile() throws {
        let directory = tempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: directory.appending(path: Config.foldersFileName))

        #expect(FolderStore(directory: directory).load().folders.isEmpty)
    }
}
