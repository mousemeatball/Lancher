import Testing
import Foundation
@testable import LancherCore

/// Spy launcher to verify activation behavior without touching the real workspace.
private final class SpyAppLauncher: AppLaunching {
    private(set) var launched: [AppItem] = []
    var errorToThrow: Error?

    func launch(_ app: AppItem) throws {
        if let errorToThrow { throw errorToThrow }
        launched.append(app)
    }
}

@Suite struct LauncherViewModelTests {
    private func app(_ name: String) -> AppItem {
        AppItem(id: name, name: name, bundleID: name, url: URL(filePath: "/\(name).app"), category: nil)
    }

    private var sample: [AppItem] {
        ["Safari", "Notes", "Terminal", "Calendar"].map(app)
    }

    // MARK: - Filtering (pure function)

    @Test func emptyQueryReturnsAllApps() {
        #expect(LauncherViewModel.filter(apps: sample, query: "") == sample)
    }

    @Test func whitespaceQueryReturnsAllApps() {
        #expect(LauncherViewModel.filter(apps: sample, query: "   ") == sample)
    }

    @Test func queryFiltersBySubstring() {
        #expect(LauncherViewModel.filter(apps: sample, query: "saf").map(\.name) == ["Safari"])
    }

    @Test func queryIsCaseInsensitive() {
        #expect(LauncherViewModel.filter(apps: sample, query: "SAFARI").map(\.name) == ["Safari"])
    }

    @Test func noMatchReturnsEmpty() {
        #expect(LauncherViewModel.filter(apps: sample, query: "zzz").isEmpty)
    }

    // MARK: - Activation

    @Test @MainActor func activateLaunchesAppAndCloses() {
        let spy = SpyAppLauncher()
        let target = app("Safari")
        let viewModel = LauncherViewModel(apps: [target], launcher: spy)
        var didClose = false
        viewModel.onClose = { didClose = true }

        viewModel.activate(target)

        #expect(spy.launched == [target])
        #expect(didClose)
        #expect(viewModel.lastError == nil)
    }

    @Test @MainActor func activateFailureSetsErrorAndDoesNotClose() {
        let spy = SpyAppLauncher()
        spy.errorToThrow = LaunchError.failedToLaunch("Safari")
        let target = app("Safari")
        let viewModel = LauncherViewModel(apps: [target], launcher: spy)
        var didClose = false
        viewModel.onClose = { didClose = true }

        viewModel.activate(target)

        #expect(spy.launched.isEmpty)
        #expect(!didClose)
        #expect(viewModel.lastError == "Couldn't launch Safari.")
    }
}
