import Foundation

/// Icon appearance treatment applied to app icons in the grid.
/// - original: untouched
/// - dark / light / tinted: "System App Icons" appearance variants
/// - clearColored: glassy monochrome tint ("Clear Colored Icons")
public enum IconStyle: String, Codable, Sendable, CaseIterable {
    case original
    case dark
    case light
    case tinted
    case clearColored

    public var displayName: String {
        switch self {
        case .original: return "Original"
        case .dark: return "Dark"
        case .light: return "Light"
        case .tinted: return "Tinted"
        case .clearColored: return "Clear Colored"
        }
    }
}
