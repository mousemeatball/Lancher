import Foundation

/// Repository abstraction for persisting workflows.
public protocol WorkflowStoring: Sendable {
    func load() -> [Workflow]
    func save(_ workflows: [Workflow]) throws
}

/// JSON-backed store at ~/Library/Application Support/Lancher/workflows.json.
public struct WorkflowStore: WorkflowStoring {
    public init() {}

    public func load() -> [Workflow] {
        JSONFileStore.load([Workflow].self, from: Config.workflowsFileName) ?? []
    }

    public func save(_ workflows: [Workflow]) throws {
        try JSONFileStore.save(workflows, to: Config.workflowsFileName)
    }
}
