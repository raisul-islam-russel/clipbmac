#!/bin/bash
# ClipBMac: build a universal (Apple Silicon + Intel) .app and a ready-to-install .dmg.
#
#   bash scripts/build.sh                 # builds version 1.0.0
#   VERSION=1.2.0 bash scripts/build.sh   # custom version (CI sets this from the git tag)
#
# Output: build/ClipBMac.app and build/ClipBMac.dmg
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="${VERSION:-1.0.0}"
NAME=ClipBMac
OUT=build
APP="$OUT/$NAME.app"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools are required. A install prompt will appear; re-run this script afterwards."
  xcode-select --install || true
  exit 1
fi

rm -rf "${OUT:?}"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "-> Compiling (Apple Silicon + Intel)..."
swiftc -O -swift-version 5 -target arm64-apple-macos13.0  src/main.swift -o "$OUT/$NAME-arm64"
swiftc -O -swift-version 5 -target x86_64-apple-macos13.0 src/main.swift -o "$OUT/$NAME-x86_64"
lipo -create "$OUT/$NAME-arm64" "$OUT/$NAME-x86_64" -output "$APP/Contents/MacOS/$NAME"
rm -f "${OUT:?}/${NAME:?}-arm64" "${OUT:?}/${NAME:?}-x86_64"

echo "-> Icon..."
if swift scripts/make_icon.swift "$OUT/$NAME.iconset" 2>/dev/null && iconutil -c icns "$OUT/$NAME.iconset" -o "$APP/Contents/Resources/$NAME.icns" 2>/dev/null; then
  ICON_KEY="<key>CFBundleIconFile</key><string>$NAME</string>"
else
  ICON_KEY=""; echo "  (icon skipped)"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>$NAME</string>
<key>CFBundleDisplayName</key><string>$NAME</string>
<key>CFBundleIdentifier</key><string>com.tecpion.clipbmac</string>
<key>CFBundleExecutable</key><string>$NAME</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$VERSION</string>
<key>CFBundleVersion</key><string>$VERSION</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
$ICON_KEY
</dict></plist>
PLIST

echo "-> Signing (ad-hoc)..."
codesign --force --deep --sign - "$APP"

echo "-> Making DMG..."
STAGE="$OUT/dmg"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$NAME" -srcfolder "$STAGE" -ov -format UDZO "$OUT/$NAME.dmg" >/dev/null
rm -rf "${STAGE:?}"

echo "DONE: $PWD/$OUT/$NAME.dmg (version $VERSION)"
