#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI

/// The full-screen launcher surface: a search field over an adaptive grid of apps and folders,
/// with a Now Playing widget in the corner. Liquid Glass (Phase 4) will replace
/// `.ultraThinMaterial` on macOS 26.
///
/// Content has three modes: live search results (flat, spanning every app), an opened folder's
/// contents, or the root grid (folders followed by un-foldered apps).
public struct LauncherView: View {
    @Bindable private var viewModel: LauncherViewModel
    private let nowPlaying: NowPlayingViewModel
    @FocusState private var searchFocused: Bool
    @State private var renameTarget: Folder?
    @State private var renameText: String = ""

    public init(viewModel: LauncherViewModel, nowPlaying: NowPlayingViewModel) {
        self.viewModel = viewModel
        self.nowPlaying = nowPlaying
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: Config.gridItemWidth), spacing: Config.gridSpacing)]
    }

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: Config.contentPadding) {
                searchField
                if let folder = viewModel.openFolder, !viewModel.isSearching {
                    folderTitleBar(folder)
                }
                content
                if let error = viewModel.lastError {
                    Text(error).font(.callout).foregroundStyle(.red)
                }
            }
            .padding(.vertical, Config.contentPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            NowPlayingView(viewModel: nowPlaying)
                .padding(Config.contentPadding)
        }
        .background(.ultraThinMaterial)
        .onAppear { searchFocused = true }
        .onExitCommand(perform: handleExit)
        .alert("Rename Folder", isPresented: renamePresented) {
            TextField("Folder name", text: $renameText)
            Button("Rename") { commitRename() }
            Button("Cancel", role: .cancel) { renameTarget = nil }
        }
    }

    // MARK: - Header

    private var searchField: some View {
        TextField("Search apps…", text: $viewModel.query)
            .textFieldStyle(.plain)
            .font(.title2)
            .multilineTextAlignment(.center)
            .focused($searchFocused)
            .frame(maxWidth: Config.searchFieldMaxWidth)
            .padding(.vertical, Config.searchFieldVerticalPadding)
            .background(.thinMaterial, in: .capsule)
    }

    private func folderTitleBar(_ folder: Folder) -> some View {
        HStack {
            Button { viewModel.closeFolder() } label: {
                Label("All Apps", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            Spacer()
            Text(folder.name).font(.headline)
            Spacer()
            // Mirror the back button's width so the title stays centered.
            Label("All Apps", systemImage: "chevron.left").hidden()
        }
        .padding(.horizontal, Config.contentPadding)
    }

    // MARK: - Content modes

    @ViewBuilder private var content: some View {
        if viewModel.isSearching {
            appsGrid(viewModel.filteredApps) { addToFolderMenu($0) }
        } else if let folder = viewModel.openFolder {
            let folderApps = viewModel.apps(inFolder: folder.id)
            if folderApps.isEmpty {
                emptyFolderHint
            } else {
                appsGrid(folderApps) { folderItemMenu($0, folder: folder) }
            }
        } else {
            rootGrid
        }
    }

    private var rootGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Config.gridSpacing) {
                ForEach(viewModel.rootEntries) { entry in
                    rootCell(entry)
                }
            }
            .padding(.horizontal, Config.contentPadding)
        }
    }

    @ViewBuilder private func rootCell(_ entry: LauncherGridEntry) -> some View {
        switch entry {
        case .folder(let folder):
            Button { viewModel.openFolder(folder.id) } label: {
                FolderGridItemView(folder: folder, previewApps: viewModel.previewApps(for: folder))
            }
            .buttonStyle(.plain)
            .contextMenu { folderContextMenu(folder) }
        case .app(let app):
            appButton(app).contextMenu { addToFolderMenu(app) }
        }
    }

    private func appsGrid<Menu: View>(
        _ apps: [AppItem],
        @ViewBuilder menu: @escaping (AppItem) -> Menu
    ) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Config.gridSpacing) {
                ForEach(apps) { app in
                    appButton(app).contextMenu { menu(app) }
                }
            }
            .padding(.horizontal, Config.contentPadding)
        }
    }

    private func appButton(_ app: AppItem) -> some View {
        Button { viewModel.activate(app) } label: { AppGridItemView(app: app) }
            .buttonStyle(.plain)
    }

    private var emptyFolderHint: some View {
        VStack {
            Spacer()
            Text("This folder is empty.").foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Context menus

    @ViewBuilder private func addToFolderMenu(_ app: AppItem) -> some View {
        Button("New Folder…") { newFolder(with: app) }
        if !viewModel.folders.isEmpty {
            Divider()
            ForEach(viewModel.folders) { folder in
                Button("Add to “\(folder.name)”") { viewModel.addApp(app, toFolder: folder.id) }
            }
        }
    }

    @ViewBuilder private func folderItemMenu(_ app: AppItem, folder: Folder) -> some View {
        Button("Remove from Folder") { viewModel.removeApp(app, fromFolder: folder.id) }
        let others = viewModel.folders.filter { $0.id != folder.id }
        if !others.isEmpty {
            Divider()
            ForEach(others) { destination in
                Button("Move to “\(destination.name)”") { viewModel.addApp(app, toFolder: destination.id) }
            }
        }
    }

    @ViewBuilder private func folderContextMenu(_ folder: Folder) -> some View {
        Button("Rename…") { beginRename(folder) }
        Button("Delete Folder", role: .destructive) { viewModel.deleteFolder(folder.id) }
    }

    // MARK: - Actions

    private func handleExit() {
        if viewModel.openFolder != nil && !viewModel.isSearching {
            viewModel.closeFolder()
        } else {
            viewModel.onClose()
        }
    }

    private func newFolder(with app: AppItem) {
        let id = viewModel.createFolder(with: app.id)
        renameTarget = viewModel.folderList.folder(id: id)
        renameText = Config.defaultFolderName
    }

    private func beginRename(_ folder: Folder) {
        renameTarget = folder
        renameText = folder.name
    }

    private func commitRename() {
        if let target = renameTarget {
            viewModel.renameFolder(target.id, to: renameText)
        }
        renameTarget = nil
    }

    private var renamePresented: Binding<Bool> {
        Binding(get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } })
    }
}
#endif
