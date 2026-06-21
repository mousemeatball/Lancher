# Lancher

A customizable full-screen **app launcher for macOS** — a Launchpad alternative for macOS 26
Tahoe, and an original competitor to LaunchMe. Built from scratch (no third-party code, icons, or
trademarks).

## Install (local .dmg)

```sh
./scripts/package-dmg.sh          # produces dist/Lancher-0.1.0.dmg
open dist/Lancher-0.1.0.dmg       # then drag Lancher onto Applications
```

It's a **menu-bar app** (no Dock icon) — look for the grid icon in the menu bar, then press
**⌥Space** (or use the menu) to summon the launcher. The build is ad-hoc signed (not notarized):
a locally built copy runs fine; a copy moved to another Mac needs **right-click → Open** once.

## Status

| Phase | Scope | State |
|-------|-------|-------|
| 0 | Scaffold, modules, GitHub publish | ✅ Done |
| 1 | Discovery → search → launch in a full-screen overlay; ⌥Space hotkey | ✅ Done |
| 2 | Debug Bridge (drive/inspect over HTTP) + logging | ✅ Done |
| 3 | User folders (color/emoji, CRUD), persisted | ✅ Done |
| 4 | Themes (Liquid Glass / Flat) + settings (icon size, hide titles) | ✅ Done |
| 5 | Wallpapers — color / image / video / dynamic Sun / Weather | ✅ Done |
| 6 | Widgets — clock, affirmation, weather (corner-anchored) | ✅ Done |
| 7 | Spaces — snapshot & restore settings/folders/widgets, schedulable | ✅ Done |
| 8 | Workflows — open many apps/files at once | ✅ Done |
| 9 | Hot corners + Preferences window | ✅ Done |
| 10 | `.dmg` packaging + from-scratch app icon | ✅ Done |

See [`BUILD_PROMPT.txt`](BUILD_PROMPT.txt) for the full spec and phase-by-phase build guide.
Backlog: 3-finger trackpad gesture summon, file search, clipboard history, AI command bar.

### Working today
- Scans `/Applications`, `/System/Applications`, Utilities, and `~/Applications`; parses each
  `Info.plist`; de-duplicated and sorted. Finds hidden Cryptex apps like Safari.
- **⌥Space** (or a **hot corner**, or the menu) toggles a full-screen panel on the display under
  the cursor. Live search; click to launch.
- **Folders:** right-click an app → *New Folder…* / *Add to Folder*; click to open (Esc backs out);
  rename/delete via right-click.
- **Workflows:** right-click an app → *Add to Workflow*; a workflow tile opens all its apps/files
  at once.
- **Wallpapers:** color, image, looping video (paused when hidden), dynamic Sun (time of day), and
  Weather (Open-Meteo) — set in Preferences.
- **Widgets:** clock, affirmation, and weather, anchored to any corner.
- **Spaces:** save the current theme/wallpaper/icon size/folders/widgets as a named Space; switch
  from the chips at the top or automatically on a schedule.
- **Preferences** (⌘,): theme, icon size, hide titles, wallpaper, hot corner, launch at login.
- All state persists under `~/Library/Application Support/Lancher`.

## Build, run & test

```sh
swift build                 # compile
./scripts/test.sh           # run the test suite (Swift Testing; works under CLT-only)
./scripts/run.sh            # run from source (menu-bar app; ⌥Space to summon)
./scripts/run.sh --debug    # also start the loopback Debug Bridge
./scripts/package-dmg.sh    # build dist/Lancher-<version>.dmg
open -a "Visual Studio Code" .
```

Requires macOS 26 Tahoe. Command Line Tools are sufficient (no full Xcode needed).

## Debug Bridge — interact with the running app

With `--debug`, a loopback-only (127.0.0.1) token-authed HTTP server starts. The base URL + token
are printed and written to `~/Library/Application Support/Lancher/debug-bridge.json`.

```sh
INFO="$HOME/Library/Application Support/Lancher/debug-bridge.json"
TOKEN=$(grep -oE '[0-9a-f]{32}' "$INFO" | head -1); BASE=http://127.0.0.1:53127
curl -s "$BASE/state" -H "x-lancher-token: $TOKEN"                                   # snapshot
curl -s -XPOST "$BASE/command" -H "x-lancher-token: $TOKEN" -d '{"cmd":"summon"}'    # show it
curl -s "$BASE/screenshot" -H "x-lancher-token: $TOKEN" -o /tmp/lancher.png          # PNG
```

Commands: `summon`, `dismiss`, `toggle`, `search` (`q`), `launch` (`bundleID`/`name`),
`create-folder`, `open-folder`, `clear-folders`.

## Architecture

- **`Lancher`** (executable) — thin bootstrap: `NSApplication` + menu-bar `AppDelegate`.
- **`LauncherKit`** (library) — all models, services, view models, and views (testable).

MVVM, immutable value types, repository pattern behind protocols, one type per file.

## Branches

- `main` — current v2.
- `archive/v1` — the original prototype, preserved for reference.
