# Lancher

A customizable full-screen **app launcher for macOS** — a Launchpad alternative for macOS 26
Tahoe. Built from scratch (no third-party code, icons, or trademarks).

> **Status:** v2 in active development. This README is expanded in the final polish phase.

## Build & run

```sh
swift build               # compile
./scripts/test.sh         # run the test suite
./scripts/run.sh          # launch from source (menu-bar app — look for the grid icon)
./scripts/run.sh --debug  # also start the loopback Debug Bridge (port + token in the log)
./scripts/package-dmg.sh  # build a distributable dist/Lancher-<version>.dmg
```

Requires macOS 26 Tahoe and the Swift toolchain (Command Line Tools are enough — tests use
Swift Testing via `scripts/test.sh`).

## Architecture

- **`Lancher`** (executable) — thin bootstrap: `NSApplication` + menu-bar `AppDelegate`.
- **`LauncherKit`** (library) — all models, services, view models, and views (testable).

MVVM, immutable value types, repository pattern, one type per file.

## Branches

- `main` — current v2.
- `archive/v1` — the original prototype, preserved for reference.
