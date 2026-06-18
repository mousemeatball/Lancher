#!/usr/bin/env bash
# Build and launch Lancher. It is a menu-bar app — look for the grid icon in the menu bar,
# then choose "Open Lancher" (or press the global shortcut ⌥Space) to show the launcher.
set -euo pipefail
cd "$(dirname "$0")/.."
exec swift run Lancher "$@"
