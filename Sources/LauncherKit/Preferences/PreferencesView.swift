#if canImport(SwiftUI) && canImport(AppKit)
import SwiftUI
import ServiceManagement

/// The Preferences form. Reads/writes the live `LauncherViewModel.settings`; every change persists
/// immediately and is reflected in the launcher.
public struct PreferencesView: View {
    @Bindable private var viewModel: LauncherViewModel
    @State private var launchAtLogin = false

    public init(viewModel: LauncherViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: themeBinding) {
                    ForEach(AppTheme.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                HStack {
                    Text("Icon size")
                    Slider(value: iconSizeBinding, in: Config.iconSizeRange)
                    Text("\(Int(viewModel.settings.iconSize))").monospacedDigit().frame(width: 34)
                }
                Toggle("Hide titles", isOn: hideTitlesBinding)
            }

            Section("Wallpaper") {
                Picker("Wallpaper", selection: wallpaperKindBinding) {
                    Text("Default").tag(WallpaperSpec.Kind?.none)
                    ForEach(WallpaperSpec.Kind.allCases, id: \.self) {
                        Text($0.rawValue.capitalized).tag(WallpaperSpec.Kind?.some($0))
                    }
                }
            }

            Section("Summon") {
                Picker("Shortcut", selection: shortcutBinding) {
                    ForEach(HotKeyCombo.presets) { Text($0.name).tag($0) }
                }
                Toggle("Hot corner", isOn: hotCornerBinding)
                Picker("Corner", selection: cornerBinding) {
                    ForEach(ScreenCorner.allCases, id: \.self) { Text($0.displayName).tag($0) }
                }
                .disabled(!viewModel.settings.hotCornerEnabled)
            }

            Section("App Sources") {
                ForEach(viewModel.settings.extraAppDirectories, id: \.self) { path in
                    HStack {
                        Text((path as NSString).lastPathComponent).help(path)
                        Spacer()
                        Button("Remove") { removeAppSource(path) }
                    }
                }
                Button("Add Folder…") { addAppSource() }
                Text("Extra folders are scanned for apps. Changes apply on next launch.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if !viewModel.hiddenApps.isEmpty {
                Section("Hidden Apps") {
                    ForEach(viewModel.hiddenApps) { app in
                        HStack {
                            Text(app.name)
                            Spacer()
                            Button("Unhide") { viewModel.unhideApp(app.id) }
                        }
                    }
                }
            }

            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in setLaunchAtLogin(newValue) }
                LabeledContent("Spaces", value: "\(viewModel.spaces.count)")
                LabeledContent("Workflows", value: "\(viewModel.workflows.count)")
                LabeledContent("Widgets", value: "\(viewModel.widgets.count)")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 540)
        .onAppear { launchAtLogin = (SMAppService.mainApp.status == .enabled) }
    }

    // MARK: - Bindings (each persists via updateSettings)

    private var themeBinding: Binding<AppTheme> {
        Binding(get: { viewModel.settings.theme },
                set: { viewModel.updateSettings(viewModel.settings.with(theme: $0)) })
    }
    private var iconSizeBinding: Binding<Double> {
        Binding(get: { viewModel.settings.iconSize },
                set: { viewModel.updateSettings(viewModel.settings.with(iconSize: $0)) })
    }
    private var hideTitlesBinding: Binding<Bool> {
        Binding(get: { viewModel.settings.hideTitles },
                set: { viewModel.updateSettings(viewModel.settings.with(hideTitles: $0)) })
    }
    private var hotCornerBinding: Binding<Bool> {
        Binding(get: { viewModel.settings.hotCornerEnabled },
                set: { viewModel.updateSettings(viewModel.settings.with(hotCornerEnabled: $0)) })
    }
    private var cornerBinding: Binding<ScreenCorner> {
        Binding(get: { viewModel.settings.hotCorner },
                set: { viewModel.updateSettings(viewModel.settings.with(hotCorner: $0)) })
    }
    private var wallpaperKindBinding: Binding<WallpaperSpec.Kind?> {
        Binding(get: { viewModel.settings.wallpaper?.kind },
                set: { kind in
                    let spec = kind.map { WallpaperSpec(kind: $0) }
                    viewModel.updateSettings(viewModel.settings.with(wallpaper: .some(spec)))
                })
    }

    private var shortcutBinding: Binding<HotKeyCombo> {
        Binding(
            get: {
                HotKeyCombo.presets.first {
                    $0.keyCode == viewModel.settings.hotKeyKeyCode && $0.modifiers == viewModel.settings.hotKeyModifiers
                } ?? HotKeyCombo.presets[0]
            },
            set: { combo in
                viewModel.updateSettings(viewModel.settings.with(
                    hotKeyKeyCode: combo.keyCode, hotKeyModifiers: combo.modifiers))
            }
        )
    }

    private func addAppSource() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        var dirs = viewModel.settings.extraAppDirectories
        guard !dirs.contains(url.path) else { return }
        dirs.append(url.path)
        viewModel.updateSettings(viewModel.settings.with(extraAppDirectories: dirs))
    }

    private func removeAppSource(_ path: String) {
        let dirs = viewModel.settings.extraAppDirectories.filter { $0 != path }
        viewModel.updateSettings(viewModel.settings.with(extraAppDirectories: dirs))
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            // Reflect the real status (registration can fail when run from source rather than .app).
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }
}
#endif
