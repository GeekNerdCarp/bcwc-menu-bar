#!/bin/sh
# Packages "BCWC Menu Bar.app" into dist/BCWC-Menu-Bar.dmg with an Applications shortcut.
set -e
cd "$(dirname "$0")"
./build-app.sh
rm -rf dist staging
mkdir -p dist staging
cp -R "BCWC Menu Bar.app" staging/
ln -s /Applications staging/Applications
hdiutil create -volname "BCWC Menu Bar" -srcfolder staging -ov -format UDZO dist/BCWC-Menu-Bar.dmg
rm -rf staging
echo "Built dist/BCWC-Menu-Bar.dmg"
