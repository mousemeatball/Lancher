#if canImport(SwiftUI)
import SwiftUI

extension View {
    /// Themed panel background: translucent blur ("Liquid Glass") or a solid translucent fill.
    @ViewBuilder
    func themedPanel(_ theme: AppTheme, cornerRadius: CGFloat) -> some View {
        switch theme {
        case .liquidGlass:
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
        case .flat:
            self.background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
#endif
