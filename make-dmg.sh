#!/bin/sh
# Builds, notarizes and packages "BCWC Menu Bar" into dist/BCWC-Menu-Bar.dmg.
# Needs a notarytool keychain profile (default name BCWC-notary); see README for store-credentials.
set -e
cd "$(dirname "$0")"
PROFILE="${NOTARY_PROFILE:-BCWC-notary}"
APP="BCWC Menu Bar.app"

./build-app.sh

# Notarize the app first so the stapled ticket travels inside the DMG.
WORK="$(mktemp -d)"
ditto -c -k --keepParent "$APP" "$WORK/app.zip"
xcrun notarytool submit "$WORK/app.zip" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
rm -rf "$WORK"

rm -rf dist staging
mkdir -p dist staging
ditto --norsrc --noextattr --noqtn "$APP" "staging/$APP"
ln -s /Applications staging/Applications
hdiutil create -volname "BCWC Menu Bar" -srcfolder staging -ov -format UDZO dist/BCWC-Menu-Bar.dmg
rm -rf staging

# Sign the DMG itself, then notarize and staple it.
codesign --force --timestamp --sign "${SIGN_ID:-Developer ID Application: Matthew Carpenter (VBZR4H3CRQ)}" dist/BCWC-Menu-Bar.dmg
xcrun notarytool submit dist/BCWC-Menu-Bar.dmg --keychain-profile "$PROFILE" --wait
xcrun stapler staple dist/BCWC-Menu-Bar.dmg
spctl --assess --type open --context context:primary-signature -v dist/BCWC-Menu-Bar.dmg
echo "Built and notarized dist/BCWC-Menu-Bar.dmg"
