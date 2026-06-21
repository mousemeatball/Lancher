import Foundation

/// A captured clipboard entry (text or link).
public struct ClipboardItem: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let text: String
    public let date: Date

    public init(id: UUID = UUID(), text: String, date: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
    }

    public enum Kind: Sendable { case text, link }

    public var kind: Kind {
        let lower = text.lowercased()
        return (lower.hasPrefix("http://") || lower.hasPrefix("https://")) ? .link : .text
    }

    public var preview: String {
        let oneLine = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        return oneLine.count > 80 ? String(oneLine.prefix(80)) + "…" : oneLine
    }
}
