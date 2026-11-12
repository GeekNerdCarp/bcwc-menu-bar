# BCWC Menu Bar

A menu bar app for [Brown County Weather Center](https://www.bcwc.cloud). It shows the current condition icon and temperature in the menu bar. Click it for current conditions, active NWS alerts, the next six hours, the NWS forecast and radar status.

## Install

1. Open the `.dmg` from the [Releases](../../releases) page.
2. Drag **BCWC Menu Bar** into **Applications**.
3. Open it from Applications. The first time, macOS may ask you to confirm, because the app is not notarized (see below).

To start it at login, add it under System Settings → General → Login Items.

## Build

Requires macOS 13 or later with Xcode command line tools.

```sh
./build-app.sh          # builds "BCWC Menu Bar.app"
./make-dmg.sh           # builds dist/BCWC-Menu-Bar.dmg
```

## Notes

- Data comes from the public BCWC endpoints at bcwc.cloud. Nothing is stored or sent elsewhere.
- The app is signed ad hoc, not with an Apple Developer ID, so it is not notarized. Gatekeeper will warn on first launch. Right-click the app and choose Open to run it once.
