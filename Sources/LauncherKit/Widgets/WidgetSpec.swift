import Foundation

/// A corner-anchored widget on the launcher overlay. Immutable value type; persisted and
/// snapshotted into Spaces.
public struct WidgetSpec: Identifiable, Codable, Sendable, Hashable {
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case clock
        case affirmation
        case weather
    }

    public enum Corner: String, Codable, Sendable, CaseIterable {
        case topLeading
        case topTrailing
        case bottomLeading
        case bottomTrailing
    }

    public let id: UUID
    public var kind: Kind
    public var corner: Corner
    /// Affirmation text, or the city for the weather widget.
    public var text: String?

    public init(id: UUID = UUID(), kind: Kind, corner: Corner = .topTrailing, text: String? = nil) {
        self.id = id
        self.kind = kind
        self.corner = corner
        self.text = text
    }
}
