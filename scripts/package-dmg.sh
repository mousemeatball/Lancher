#!/usr/bin/env bash
# Package Lancher into a .app bundle and a .dmg for local testing.
#
# The app is ad-hoc signed (not notarized). That is fine for running on THIS Mac: a
# locally created .dmg has no quarantine flag, so Gatekeeper won't block it. Moving it to
# another Mac would require notarization.
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Lancher"
BUNDLE_ID="com.lancher.app"
VERSION="0.1.0"
BUILD_NUMBER="1"

echo "==> Building release…"
swift build -c release --product "$APP_NAME"
BIN_DIR="$(swift build -c release --show-bin-path)"
BIN="$BIN_DIR/$APP_NAME"
[ -f "$BIN" ] || { echo "error: binary not found at $BIN" >&2; exit 1; }

DIST="dist"
APP="$DIST/$APP_NAME.app"
echo "==> Assembling $APP …"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
printf 'APPL????' > "$APP/Contents/PkgInfo"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>${APP_NAME}</string>
	<key>CFBundleDisplayName</key><string>${APP_NAME}</string>
	<key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
	<key>CFBundleExecutable</key><string>${APP_NAME}</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
	<key>CFBundleShortVersionString</key><string>${VERSION}</string>
	<key>LSMinimumSystemVersion</key><string>14.0</string>
	<key>LSUIElement</key><true/>
	<key>NSHighResolutionCapable</key><true/>
	<key>NSPrincipalClass</key><string>NSApplication</string>
	<key>NSHumanReadableCopyright</key><string>Lancher — local test build</string>
</dict>
</plist>
PLIST

echo "==> Ad-hoc signing…"
codesign --force --sign - "$APP"
codesign --verify --verbose "$APP"

echo "==> Building DMG…"
STAGING="$DIST/dmg"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
DMG="$DIST/${APP_NAME}-${VERSION}.dmg"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

echo "==> Done."
echo "    App: $APP"
echo "    DMG: $DMG"
