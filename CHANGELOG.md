# Changelog

## Unreleased

- Full-width Wi-Fi tiles show network, band/signal, download rate and latency with
  a clear two-column hierarchy; wired mode shows link speed/IP instead. Full tiles
  hold a reference-counted details subscription without enabling background scans.
- Omarchy settings opens the stock network widget on the current screen in both
  Deck and standalone modes, with an inline error instead of a wrong-monitor
  fallback when that widget is unavailable.
- **Wired networks are supported.** Connected Ethernet takes display priority,
  with Omarchy's icon, negotiated link speed, IP/gateway, throughput and ping.
  Wi-Fi-only band/scan controls disappear; the radio switch remains when a station
  exists, and a wired-only tile opens its page instead of exposing a dead toggle.
- Link selection and Omarchy's wired formatting have unit tests. Physical
  cable/dock verification remains hardware-dependent.
- Rebuilt the connection flow on Quickshell and Omarchy's network model: correct
  `name` identity, secured and PEAP/MSCHAPv2 forms, OWE without a password,
  captive-portal action, and serialized connect/disconnect/forget with visible
  failures, reprompt and a 30-second timeout.
- Added connection details, throughput and ping/loss, band and DNS controls, and
  Omarchy settings as the escape hatch.
- Network delegates now use Omarchy's primitive `wifiRow` snapshots instead of
  retaining live NetworkManager objects. Actions resolve by SSID at click time;
  hidden networks have a localized display label and an explicit form-open flag.
- Password and enterprise fields cooperate with Deck's keyboard cursor, including
  before-item Escape cancellation. The UI ships an English translation catalog.

## 0.1.1

- The tile glyph is a Material icon, matching the other Deck tiles.

## 0.1.0

First release.

- Standalone Omarchy bar widget: Wi-Fi state, network list, connect, disconnect,
  and a password prompt for secured networks with no saved key.
- Deck section (`deck/Section.qml` + `deck/Page.qml`) sharing one state object.
- Scanning is tied to the UI being open, because the device only populates its
  network list while `scannerEnabled` is set.
