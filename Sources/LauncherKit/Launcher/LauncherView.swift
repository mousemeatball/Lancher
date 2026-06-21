#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import UniformTypeIdentifiers

/// The full-screen launcher: a centered search field above a scrolling grid. The grid shows search
/// results while searching, the contents of an open folder when one is drilled into, or the root
/// grid (folders then loose apps) otherwise.
public struct LauncherView: View {
    @Bindable private var viewModel: LauncherViewModel
    private let onDismiss: () -> Void
    @FocusState private var searchFocused: Bool
    @State private var renameTarget: Folder?
    @State private var renameText: String = ""
    @State private var renameWorkflowTarget: Workflow?
    @State private var renameWorkflowText: String = ""
    @State private var isNamingSpace = false
    @State private var newSpaceText: String = ""
    @State private var draggingID: String?

    public init(viewModel: LauncherViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    private var settings: AppSettings { viewModel.settings }
    private var iconSize: CGFloat { CGFloat(settings.iconSize) }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: iconSize + Config.gridItemPadding), spacing: Config.gridSpacing)]
    }

    public var body: some View {
        ZStack {
            WallpaperView(spec: settings.wallpaper, isActive: viewModel.isPresented)
                .ignoresSafeArea()
            // Dim overlay for legibility; also the click-away dismiss target.
            Color.black.opacity(settings.wallpaper == nil ? 0.45 : 0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            VStack(spacing: Config.contentPadding) {
                SpaceSwitcherView(
                    spaces: viewModel.spaces,
                    activeID: viewModel.activeSpaceID,
                    theme: settings.theme,
                    onApply: { viewModel.applySpace($0) },
                    onSave: { newSpaceText = ""; isNamingSpace = true }
                )
                searchField
                if let folder = viewModel.openFolder { folderHeader(folder) }
                grid
            }
            .padding(Config.contentPadding)

            WidgetHostView(widgets: viewModel.widgets, theme: settings.theme)
        }
        .onAppear { searchFocused = true }
        .alert("Rename Folder", isPresented: isRenaming) {
            TextField("Name", text: $renameText)
            Button("Save") { if let target = renameTarget { viewModel.renameFolder(target.id, to: renameText) } }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Rename Workflow", isPresented: isRenamingWorkflow) {
            TextField("Name", text: $renameWorkflowText)
            Button("Save") { if let target = renameWorkflowTarget { viewModel.renameWorkflow(target.id, to: renameWorkflowText) } }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Save Space", isPresented: $isNamingSpace) {
            TextField("Space name", text: $newSpaceText)
            Button("Save") {
                let name = newSpaceText.trimmingCharacters(in: .whitespacesAndNewlines)
                viewModel.saveSpace(named: name.isEmpty ? "Space \(viewModel.spaces.count + 1)" : name)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Saves the current wallpaper, theme, icon size, folders, and widgets as a Space.")
        }
    }

    // MARK: - Pieces

    private var searchField: some View {
        TextField("Search", text: $viewModel.query)
            .textFieldStyle(.plain)
            .font(.system(size: 22, weight: .regular))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .focused($searchFocused)
            .padding(.vertical, Config.searchFieldVerticalPadding)
            .padding(.horizontal, 16)
            .frame(maxWidth: Config.searchFieldMaxWidth)
            .themedPanel(settings.theme, cornerRadius: 12)
    }

    private func folderHeader(_ folder: Folder) -> some View {
        HStack(spacing: 8) {
            Button { viewModel.closeFolder() } label: {
                Image(systemName: "chevron.left").foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            Text(folder.name).font(.title3).foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var grid: some View {
        if viewModel.isSearching {
            appGrid(viewModel.filteredApps, inFolder: nil)
        } else if let folder = viewModel.openFolder {
            appGrid(viewModel.apps(inFolder: folder.id), inFolder: folder.id)
        } else {
            rootGrid
        }
    }

    private var rootGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Config.gridSpacing) {
                ForEach(viewModel.rootEntries) { entry in
                    entryView(entry)
                        .opacity(draggingID == entry.id ? 0.4 : 1)
                        .onDrag {
                            draggingID = entry.id
                            return NSItemProvider(object: entry.id as NSString)
                        }
                        .onDrop(of: [.text], delegate: GridReorderDelegate(
                            targetID: entry.id,
                            draggingID: $draggingID,
                            onMove: { id, target in viewModel.moveEntry(id, before: target) }
                        ))
                }
            }
            .padding(.horizontal, Config.contentPadding)
            .animation(.default, value: viewModel.rootEntries.map(\.id))
        }
    }

    @ViewBuilder
    private func entryView(_ entry: LauncherGridEntry) -> some View {
        switch entry {
        case .workflow(let workflow):
            WorkflowGridItemView(
                workflow: workflow,
                iconSize: iconSize,
                hideTitle: settings.hideTitles,
                theme: settings.theme
            ) { viewModel.runWorkflow(workflow.id) }
            .contextMenu { workflowMenu(workflow) }
        case .folder(let folder):
            FolderGridItemView(
                folder: folder,
                previewApps: viewModel.previewApps(for: folder),
                iconSize: iconSize,
                hideTitle: settings.hideTitles
            ) { viewModel.openFolder(folder.id) }
            .contextMenu { folderMenu(folder) }
        case .app(let app):
            appTile(app, inFolder: nil)
        }
    }

    private func appGrid(_ apps: [AppItem], inFolder folderID: Folder.ID?) -> some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Config.gridSpacing) {
                ForEach(apps) { app in appTile(app, inFolder: folderID) }
            }
            .padding(.horizontal, Config.contentPadding)
        }
    }

    private func appTile(_ app: AppItem, inFolder folderID: Folder.ID?) -> some View {
        AppGridItemView(
            app: app,
            iconSize: iconSize,
            hideTitle: settings.hideTitles
        ) { viewModel.activate(app) }
            .contextMenu { appMenu(app, inFolder: folderID) }
    }

    // MARK: - Context menus

    @ViewBuilder
    private func appMenu(_ app: AppItem, inFolder folderID: Folder.ID?) -> some View {
        if let folderID {
            Button("Remove from Folder") { viewModel.removeApp(app, fromFolder: folderID) }
        } else {
            Button("New Folder with \(app.name)…") { startNewFolder(with: app) }
            if !viewModel.folders.isEmpty {
                Menu("Add to Folder") {
                    ForEach(viewModel.folders) { folder in
                        Button(folder.name) { viewModel.addApp(app, toFolder: folder.id) }
                    }
                }
            }
            Divider()
            Menu("Add to Workflow") {
                Button("New Workflow…") { startNewWorkflow(with: app) }
                if !viewModel.workflows.isEmpty { Divider() }
                ForEach(viewModel.workflows) { workflow in
                    Button(workflow.name) { viewModel.addApp(app, toWorkflow: workflow.id) }
                }
            }
        }
    }

    @ViewBuilder
    private func workflowMenu(_ workflow: Workflow) -> some View {
        Button("Run") { viewModel.runWorkflow(workflow.id) }
        Button("Rename…") { renameWorkflowText = workflow.name; renameWorkflowTarget = workflow }
        Button("Delete Workflow", role: .destructive) { viewModel.deleteWorkflow(workflow.id) }
    }

    @ViewBuilder
    private func folderMenu(_ folder: Folder) -> some View {
        Button("Rename…") { renameText = folder.name; renameTarget = folder }
        Button("Delete Folder", role: .destructive) { viewModel.deleteFolder(folder.id) }
    }

    // MARK: - Helpers

    private func startNewFolder(with app: AppItem) {
        let id = viewModel.createFolder(with: app.id)
        if let folder = viewModel.folderList.folder(id: id) {
            renameText = folder.name
            renameTarget = folder
        }
    }

    private func startNewWorkflow(with app: AppItem) {
        let id = viewModel.createWorkflow(named: "New Workflow", with: app.id)
        if let workflow = viewModel.workflow(id: id) {
            renameWorkflowText = workflow.name
            renameWorkflowTarget = workflow
        }
    }

    private var isRenaming: Binding<Bool> {
        Binding(get: { renameTarget != nil }, set: { if !$0 { renameTarget = nil } })
    }

    private var isRenamingWorkflow: Binding<Bool> {
        Binding(get: { renameWorkflowTarget != nil }, set: { if !$0 { renameWorkflowTarget = nil } })
    }
}
#endif
