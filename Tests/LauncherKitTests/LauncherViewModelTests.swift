import Testing
import Foundation
@testable import LauncherKit

/// Records launches and can simulate failure, without opening anything.
private final class MockLauncher: AppLaunching, @unchecked Sendable {
    private(set) var launched: [AppItem] = []
    var shouldFail = false

    func launch(_ app: AppItem) throws {
        if shouldFail { throw LaunchError.failed(appName: app.name) }
        launched.append(app)
    }
}

private func app(_ name: String, id: String? = nil) -> AppItem {
    AppItem(id: id ?? name, name: name, url: URL(filePath: "/Applications/\(name).app"),
            bundleID: id, category: nil)
}

@MainActor
@Suite struct LauncherViewModelTests {
    @Test func filterIsCaseInsensitiveSubstring() {
        let apps = [app("Safari"), app("Mail"), app("Maps")]
        #expect(LauncherViewModel.filter(apps: apps, query: "ma").map(\.name) == ["Mail", "Maps"])
        #expect(LauncherViewModel.filter(apps: apps, query: "SAFARI").map(\.name) == ["Safari"])
    }

    @Test func emptyQueryReturnsAllApps() {
        let apps = [app("Safari"), app("Mail")]
        #expect(LauncherViewModel.filter(apps: apps, query: "   ").count == 2)
    }

    @Test func activateLaunchesAndCloses() {
        let launcher = MockLauncher()
        let viewModel = LauncherViewModel(apps: [app("Safari")], launcher: launcher)
        var closed = false
        viewModel.onClose = { closed = true }

        viewModel.activate(app("Safari"))

        #expect(launcher.launched.map(\.name) == ["Safari"])
        #expect(closed)
        #expect(viewModel.lastError == nil)
    }

    @Test func activateFailureSetsErrorAndDoesNotClose() {
        let launcher = MockLauncher()
        launcher.shouldFail = true
        let viewModel = LauncherViewModel(apps: [app("Safari")], launcher: launcher)
        var closed = false
        viewModel.onClose = { closed = true }

        viewModel.activate(app("Safari"))

        #expect(viewModel.lastError != nil)
        #expect(!closed)
    }

    @Test func resetPresentationClearsQueryAndError() {
        let viewModel = LauncherViewModel(apps: [], launcher: MockLauncher())
        viewModel.query = "abc"
        viewModel.lastError = "boom"
        viewModel.resetPresentation()
        #expect(viewModel.query.isEmpty)
        #expect(viewModel.lastError == nil)
    }
}
