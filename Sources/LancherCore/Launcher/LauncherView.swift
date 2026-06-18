#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// The full-screen launcher surface: a search field over an adaptive grid of apps.
/// Liquid Glass (Phase 4) will replace `.ultraThinMaterial` on macOS 26.
public struct LauncherView: View {
    @Bindable private var viewModel: LauncherViewModel
    @FocusState private var searchFocused: Bool

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: Config.gridItemWidth), spacing: Config.gridSpacing)]
    }

    public var body: some View {
        VStack(spacing: Config.contentPadding) {
            TextField("Search apps…", text: $viewModel.query)
                .textFieldStyle(.plain)
                .font(.title2)
                .multilineTextAlignment(.center)
                .focused($searchFocused)
                .frame(maxWidth: 480)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: .capsule)

            ScrollView {
                LazyVGrid(columns: columns, spacing: Config.gridSpacing) {
                    ForEach(viewModel.filteredApps) { app in
                        Button {
                            viewModel.activate(app)
                        } label: {
                            AppGridItemView(app: app)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Config.contentPadding)
            }

            if let error = viewModel.lastError {
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, Config.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onAppear { searchFocused = true }
        .onExitCommand { viewModel.onClose() }
    }
}
#endif
