#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// A compact row of Space chips with a "Save" button. Tapping a chip applies that Space.
struct SpaceSwitcherView: View {
    let spaces: [Space]
    let activeID: Space.ID?
    let theme: AppTheme
    let onApply: (Space.ID) -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(spaces) { space in
                chip(title: space.name, active: space.id == activeID) { onApply(space.id) }
            }
            chip(title: "＋ Save", active: false, action: onSave)
        }
    }

    private func chip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(active ? Color.accentColor.opacity(0.9) : Color.white.opacity(0.14))
                )
        }
        .buttonStyle(.plain)
    }
}
#endif
