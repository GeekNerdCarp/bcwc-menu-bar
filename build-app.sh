#!/bin/sh
# Builds "BCWC Menu Bar.app": a menu bar only app (no Dock icon), signed ad hoc for local use.
# Embeds Sparkle.framework for automatic updates from appcast.xml.
set -e
cd "$(dirname "$0")"
swift build -c release
APP="BCWC Menu Bar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/Frameworks"
cp .build/release/BCWCMenuBar "$APP/Contents/MacOS/BCWCMenuBar"
cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp -R Resources/scenes "$APP/Contents/Resources/scenes"
cp -R .build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework "$APP/Contents/Frameworks/"
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
    <key>CFBundleShortVersionString</key><string>1.5</string>
    <key>CFBundleVersion</key><string>6</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>SUFeedURL</key><string>https://raw.githubusercontent.com/GeekNerdCarp/bcwc-menu-bar/main/appcast.xml</string>
    <key>SUPublicEDKey</key><string>DF+W9Oxmnawg0meDOk/ecm7s1tZ89uh9irrYM4M9spg=</string>
    <key>SUEnableAutomaticChecks</key><true/>
    <key>SUAllowsAutomaticUpdates</key><true/>
    <key>SUScheduledCheckInterval</key><integer>86400</integer>
</dict>
</plist>
PLIST
# Sign inside-out with the Developer ID and hardened runtime, which notarization requires.
# Falls back to ad-hoc signing when SIGN_ID is set to "-".
SIGN_ID="${SIGN_ID:-Developer ID Application: Matthew Carpenter (VBZR4H3CRQ)}"
# Signing fails if macOS has tagged files in the project folder (com.apple.provenance), so sign a clean copy.
WORK="$(mktemp -d)"
ditto --norsrc --noextattr --noqtn "$APP" "$WORK/$APP"
SIGNED="$WORK/$APP"
FW="$SIGNED/Contents/Frameworks/Sparkle.framework"
for item in "$FW"/Versions/B/XPCServices/*.xpc "$FW/Versions/B/Updater.app" "$FW/Versions/B/Autoupdate"; do
    [ -e "$item" ] && codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$item"
done
codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$FW"
codesign --force --options runtime --timestamp --sign "$SIGN_ID" "$SIGNED"
codesign --verify --deep --strict "$SIGNED"
rm -rf "$APP"
ditto --norsrc --noextattr --noqtn "$SIGNED" "$APP"
rm -rf "$WORK"
echo "Built $APP"
