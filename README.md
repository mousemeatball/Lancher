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
| 10 | `.dmg` packaging + from-scratch app icon | ✅ Done |
| 4–9 | Liquid Glass, Wallpapers, Widgets, Spaces, Workflows, Hot corners/Prefs | ⬜ Planned |

See [`BUILD_PROMPT.txt`](BUILD_PROMPT.txt) for the full spec and phase-by-phase build guide.

### Working today
- Scans `/Applications`, `/System/Applications`, Utilities, and `~/Applications`; parses each
  `Info.plist` (name, bundle id, category); de-duplicated and sorted. Finds hidden Cryptex apps
  like Safari.
- **⌥Space from anywhere** (Carbon hotkey — no Accessibility permission) toggles a full-screen
  panel on the display under the cursor. Live case-insensitive search; click to launch.
- **Folders:** right-click an app → *New Folder…* / *Add to Folder*; click a folder to open it
  (Esc backs out); right-click to rename/delete. Saved to `~/Library/Application Support/Lancher`.

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
