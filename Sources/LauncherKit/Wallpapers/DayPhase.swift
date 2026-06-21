import Foundation

/// Time-of-day phase used by the dynamic Sun wallpaper. Pure + testable (no SwiftUI here).
public enum DayPhase: String, Sendable, CaseIterable {
    case night
    case dawn
    case day
    case dusk

    /// Coarse phase from a 0–23 hour. Dawn ~5–7, day ~7–17, dusk ~17–20, else night.
    public static func phase(forHour hour: Int) -> DayPhase {
        switch hour {
        case 5..<8: return .dawn
        case 8..<17: return .day
        case 17..<20: return .dusk
        default: return .night
        }
    }
}
