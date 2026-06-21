import Testing
import Foundation
@testable import LauncherKit

private func app(_ name: String) -> AppItem {
    AppItem(id: name, name: name, url: URL(filePath: "/Applications/\(name).app"), bundleID: name, category: nil)
}
private final class NL: AppLaunching, @unchecked Sendable { func launch(_ app: AppItem) throws {} }
private final class MF: FolderStoring, @unchecked Sendable { var l = FolderList(); func load() -> FolderList { l }; func save(_ x: FolderList) throws { l = x } }
private final class MS: SettingsStoring, @unchecked Sendable { var s = AppSettings(); func load() -> AppSettings { s }; func save(_ x: AppSettings) throws { s = x } }
private final class MC: ClipboardStoring, @unchecked Sendable { var i: [ClipboardItem] = []; func load() -> [ClipboardItem] { i }; func save(_ x: [ClipboardItem]) throws { i = x } }

@Suite struct ClipboardItemTests {
    @Test func detectsLinks() {
        #expect(ClipboardItem(text: "https://example.com").kind == .link)
        #expect(ClipboardItem(text: "just text").kind == .text)
    }
    @Test func previewTruncates() {
        let long = String(repeating: "a", count: 200)
        #expect(ClipboardItem(text: long).preview.count <= 81)
    }
}

@MainActor
@Suite struct ClipboardViewModelTests {
    private func makeVM(_ store: MC) -> LauncherViewModel {
        LauncherViewModel(apps: [app("A")], launcher: NL(),
                          folderStore: MF(), settingsStore: MS(), clipboardStore: store)
    }

    @Test func recordPrependsDedupesAndPersists() {
        let store = MC()
        let vm = makeVM(store)
        vm.recordClipboard("one")
        vm.recordClipboard("two")
        vm.recordClipboard("one")   // moves to front, no duplicate
        #expect(vm.clipboardItems.map(\.text) == ["one", "two"])
        #expect(store.i.map(\.text) == ["one", "two"])  // persisted
    }

    @Test func ignoresImmediateDuplicate() {
        let vm = makeVM(MC())
        vm.recordClipboard("x")
        vm.recordClipboard("x")
        #expect(vm.clipboardItems.count == 1)
    }

    @Test func clearEmpties() {
        let vm = makeVM(MC())
        vm.recordClipboard("x")
        vm.clearClipboard()
        #expect(vm.clipboardItems.isEmpty)
    }
}
