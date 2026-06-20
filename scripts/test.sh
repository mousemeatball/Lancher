#!/usr/bin/env bash
# Run the test suite.
#
# This machine may have only the Command Line Tools (no full Xcode). Under CLT, Swift Testing
# ships as a framework that is not on the default search path, and its private
# lib_TestingInterop.dylib must be on the rpath. With full Xcode installed, plain `swift test`
# resolves everything — so we detect and adapt.
set -euo pipefail
cd "$(dirname "$0")/.."

DEV="$(xcode-select -p 2>/dev/null || true)"
FW="$DEV/Library/Developer/Frameworks"
LIB="$DEV/Library/Developer/usr/lib"

if [[ -d "$FW" && -f "$LIB/lib_TestingInterop.dylib" ]]; then
  exec swift test \
    -Xswiftc -F -Xswiftc "$FW" \
    -Xlinker -F -Xlinker "$FW" \
    -Xlinker -rpath -Xlinker "$FW" \
    -Xlinker -rpath -Xlinker "$LIB" "$@"
else
  exec swift test "$@"
fi
