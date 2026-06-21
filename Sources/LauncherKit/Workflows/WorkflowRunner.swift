import Foundation

/// Runs a workflow by resolving its app ids against the live app list and opening every app and
/// path in order.
public struct WorkflowRunner: Sendable {
    private let opener: URLOpening

    public init(opener: URLOpening) {
        self.opener = opener
    }

    #if canImport(AppKit)
    public init() {
        self.opener = WorkspaceURLOpener()
    }
    #endif

    @discardableResult
    public func run(_ workflow: Workflow, apps: [AppItem]) -> (opened: Int, failed: Int) {
        let byID = Dictionary(apps.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var urls: [URL] = workflow.appIDs.compactMap { byID[$0]?.url }
        urls += workflow.paths.map { URL(filePath: $0) }

        var opened = 0
        var failed = 0
        for url in urls {
            if opener.open(url) { opened += 1 } else { failed += 1 }
        }
        return (opened, failed)
    }
}
