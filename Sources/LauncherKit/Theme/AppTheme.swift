import Foundation

/// Visual theme for the launcher surfaces. `liquidGlass` uses translucent blur materials
/// (macOS 26 glass aesthetic); `flat` uses solid translucent fills.
public enum AppTheme: String, Codable, Sendable, CaseIterable {
    case liquidGlass
    case flat

    public var displayName: String {
        switch self {
        case .liquidGlass: return "Liquid Glass"
        case .flat: return "Flat"
        }
    }
}
