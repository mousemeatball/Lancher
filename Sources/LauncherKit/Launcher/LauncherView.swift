#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// The full-screen launcher: a centered search field above a scrolling grid of app tiles.
public struct LauncherView: View {
    @Bindable private var viewModel: LauncherViewModel
    /// Called when the user clicks empty space — the host dismisses the overlay.
    private let onDismiss: () -> Void
    @FocusState private var searchFocused: Bool

    public init(viewModel: LauncherViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: Config.gridItemWidth), spacing: Config.gridSpacing)]
    }

    public var body: some View {
        ZStack {
            // Dimmed backdrop; clicking it dismisses the launcher.
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack(spacing: Config.contentPadding) {
                searchField
                appGrid
            }
            .padding(Config.contentPadding)
        }
        .onAppear { searchFocused = true }
    }

    private var searchField: some View {
        TextField("Search", text: $viewModel.query)
            .textFieldStyle(.plain)
            .font(.system(size: 22, weight: .regular))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .focused($searchFocused)
            .padding(.vertical, Config.searchFieldVerticalPadding)
            .frame(maxWidth: Config.searchFieldMaxWidth)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var appGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Config.gridSpacing) {
                ForEach(viewModel.filteredApps) { app in
                    AppGridItemView(app: app) { viewModel.activate(app) }
                }
            }
            .padding(.horizontal, Config.contentPadding)
        }
    }
}
#endif
