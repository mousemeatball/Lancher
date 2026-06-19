# Lancher

A customizable full-screen **app launcher for macOS** — a Launchpad alternative, built from
scratch (not derived from any other app's code or assets).

## Download

[![Download the latest .dmg](https://img.shields.io/badge/Download-Lancher.dmg-2ea44f?logo=apple&logoColor=white)](https://github.com/mousemeatball/Lancher/releases/latest)

Grab the latest **`Lancher-x.y.z.dmg`** from the [Releases page](https://github.com/mousemeatball/Lancher/releases/latest),
open it, and drag **Lancher** onto **Applications**.

> **First launch:** the build is ad-hoc signed (not notarized), so a *downloaded* copy is
> quarantined by macOS. The first time, **right-click Lancher → Open** (or run
> `xattr -dr com.apple.quarantine /Applications/Lancher.app`) to get past Gatekeeper. It's a
> menu-bar app — look for the grid icon, then press **⌥Space**.

## Status

| Phase | Scope | State |
|-------|-------|-------|
| 0 | Project scaffold, modules, design rules | ✅ Done |
| 1 | App discovery → searchable grid → launch in a full-screen overlay | ✅ Done |
| 2 | Global hotkey (⌥Space), click-away dismissal | ✅ In progress (hotkey done; hot corners next) |
| 3 | User-created folders + Now Playing (Apple Music / Spotify) widget | ✅ Done |
| 4+ | Customization, wallpapers, widgets, productivity, monetization, … | ⬜ Planned |

### Working today
- Scans `/Applications`, `/System/Applications`, Utilities, and `~/Applications` for installed apps.
- Parses each `Info.plist` (name, bundle id, category); sorted + de-duplicated.
- **⌥Space from anywhere** (global Carbon hotkey — no Accessibility permission needed) toggles a
  borderless full-screen panel on the display under the cursor. Also via the menu-bar item.
- Live case-insensitive search; click an app to launch it.
- **User-created folders:** right-click an app → *New Folder…* or *Add to "<folder>"*. Click a
  folder to open it; right-click to rename/delete. An app lives in at most one folder, and your
  layout is saved to `~/Library/Application Support/Lancher/folders.json`.
- **Now Playing widget:** when Apple Music or Spotify is playing, a corner widget shows the
  artwork, title, and artist with ⏮ ⏯ ⏭ controls. Read/controlled via public AppleScript (no
  private frameworks) — the first control triggers a one-time macOS Automation permission prompt.
- Dismisses on **Esc** (or *Esc* backs out of an open folder), on launching an app, or when you
  switch to another app.

## Architecture
- **`Lancher`** (executable) — thin `@main` entry + `AppDelegate`.
- **`LancherCore`** (library) — models, services, view models, views (testable).
  - `Apps/` — `AppItem`, discovery, launching (behind protocols for DI/testing).
  - `Launcher/` — `LauncherViewModel` (pure filtering + folder ops), SwiftUI views, the `NSPanel` controller.
  - `Folders/` — `Folder`/`FolderList` (immutable), `FolderStoring` repository + JSON `FolderStore`.
  - `NowPlaying/` — `NowPlaying` model, `NowPlayingProviding` + AppleScript-backed controller, view model, widget.
  - `Input/` — `GlobalHotKey` (Carbon `RegisterEventHotKey`).
  - `App/` — `AppEnvironment` composition root. `Shared/` — `Config` constants.

MVVM, immutable value types, repository pattern, one type per file.

## Build & run
```sh
swift build               # compile
./scripts/test.sh         # run the test suite (46 passing)
./scripts/run.sh          # launch from source (menu-bar app; ⌥Space to summon)
./scripts/package-dmg.sh  # build a distributable dist/Lancher-<version>.dmg
```
> Opens directly in Xcode too — just open `Package.swift`.

**Why the test wrapper?** This machine has only the Command Line Tools (no full Xcode), so
`XCTest` is unavailable — tests use **Swift Testing**. Under CLT, Swift Testing ships as a
framework that isn't on the default search path, so `scripts/test.sh` adds the framework
search path and the `lib_TestingInterop.dylib` rpath. With full Xcode installed, plain
`swift test` works and the script detects that automatically.

### Testing the .dmg
Open `dist/Lancher-<version>.dmg`, drag **Lancher** to Applications, and launch it. It is a
menu-bar app — look for the grid icon in the menu bar, then press **⌥Space** (or use the menu).
The build is ad-hoc signed, not notarized: created locally it runs fine, but if you copy it to
another Mac, right-click → **Open** the first time (or allow it under System Settings →
Privacy & Security).

## Notes
- Deployment target is macOS 14 for now (stable APIs); production targets macOS 26 Tahoe for
  native **Liquid Glass**.
- Built independently from public feature descriptions — contains no third-party code, icons,
  or trademarks. If distributed, use an original name and icon.
