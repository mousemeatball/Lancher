#!/usr/bin/env bash
# Build and launch Lancher. It is a menu-bar app — look for the grid icon in the menu bar, then
# choose "Open Lancher" (or, once the global hotkey lands, press ⌥Space).
#
# Pass --debug to enable the loopback Debug Bridge (the port + token are printed to the log).
set -euo pipefail
cd "$(dirname "$0")/.."
exec swift run Lancher "$@"
