#!/bin/sh
# Builds "BCWC Menu Bar.app": a menu bar only app (no Dock icon), signed ad hoc for local use.
set -e
cd "$(dirname "$0")"
swift build -c release
APP="BCWC Menu Bar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/BCWCMenuBar "$APP/Contents/MacOS/BCWCMenuBar"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp -R Resources/scenes "$APP/Contents/Resources/scenes"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>BCWC Menu Bar</string>
    <key>CFBundleDisplayName</key><string>BCWC Menu Bar</string>
    <key>CFBundleExecutable</key><string>BCWCMenuBar</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIdentifier</key><string>cloud.bcwc.menubar</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.3</string>
    <key>CFBundleVersion</key><string>4</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
codesign --force --sign - "$APP"
echo "Built $APP"
