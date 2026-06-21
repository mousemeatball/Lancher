import Foundation

/// On-disk shape: the spaces plus which one is active.
public struct SpacesData: Codable, Sendable {
    public var spaces: [Space]
    public var activeID: UUID?

    public init(spaces: [Space] = [], activeID: UUID? = nil) {
        self.spaces = spaces
        self.activeID = activeID
    }
}

/// Repository abstraction for persisting spaces.
public protocol SpaceStoring: Sendable {
    func load() -> SpacesData
    func save(_ data: SpacesData) throws
}

/// JSON-backed store at ~/Library/Application Support/Lancher/spaces.json.
public struct SpaceStore: SpaceStoring {
    public init() {}

    public func load() -> SpacesData {
        JSONFileStore.load(SpacesData.self, from: Config.spacesFileName) ?? SpacesData()
    }

    public func save(_ data: SpacesData) throws {
        try JSONFileStore.save(data, to: Config.spacesFileName)
    }
}
