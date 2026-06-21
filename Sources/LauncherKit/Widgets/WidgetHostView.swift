#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// Lays out widgets at their assigned corners over the launcher. Decorative (non-interactive) so
/// clicks still fall through to the dismiss layer.
struct WidgetHostView: View {
    let widgets: [WidgetSpec]
    let theme: AppTheme

    var body: some View {
        ZStack {
            ForEach(widgets) { spec in
                widgetView(spec)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(for: spec.corner))
                    .padding(Config.contentPadding)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func widgetView(_ spec: WidgetSpec) -> some View {
        switch spec.kind {
        case .clock: ClockWidget(theme: theme)
        case .affirmation: AffirmationWidget(text: spec.text, theme: theme)
        case .weather: WeatherWidget(city: spec.text, theme: theme)
        }
    }

    private func alignment(for corner: WidgetSpec.Corner) -> Alignment {
        switch corner {
        case .topLeading: return .topLeading
        case .topTrailing: return .topTrailing
        case .bottomLeading: return .bottomLeading
        case .bottomTrailing: return .bottomTrailing
        }
    }
}
#endif
