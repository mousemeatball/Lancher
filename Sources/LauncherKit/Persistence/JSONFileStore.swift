import Foundation

/// Small helper for atomic JSON persistence under Application Support. Used by the settings,
/// spaces, and workflows stores to avoid repeating load/save boilerplate.
enum JSONFileStore {
    static func url(_ fileName: String) throws -> URL {
        try Config.appSupportDirectory().appending(path: fileName)
    }

    static func load<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        guard let url = try? url(fileName),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    static func save<T: Encodable>(_ value: T, to fileName: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(value)
        try data.write(to: try url(fileName), options: [.atomic])
    }
}
