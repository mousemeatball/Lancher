import Foundation

/// A display corner used for the hot-corner summon trigger.
public enum ScreenCorner: String, Codable, Sendable, CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    public var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomRight: return "Bottom Right"
        }
    }
}
