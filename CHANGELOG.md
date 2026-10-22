# Changelog

## 0.1.1

- The tile glyph is a Material icon, matching the other Deck tiles.

## 0.1.0

First release.

- Standalone Omarchy bar widget: Wi-Fi state, network list, connect, disconnect,
  and a password prompt for secured networks with no saved key.
- Deck section (`deck/Section.qml` + `deck/Page.qml`) sharing one state object.
- Scanning is tied to the UI being open, because the device only populates its
  network list while `scannerEnabled` is set.
