# Wi-Fi

Wi-Fi status, networks and connection for Omarchy. A bar widget, or a section
inside [Deck](https://github.com/mutex-solutions/omarchy-deck).

## Standalone

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-wifi --enable
```

Click the Wi-Fi icon for connection details, throughput and ping/loss, band and DNS
controls, and the grouped network list. Secured networks open an inline password
form; PEAP/MSCHAPv2 enterprise networks also ask for identity, while OWE joins
without credentials. Known networks can be disconnected or forgotten (confirmed
in two steps), and a captive portal gets a sign-in action. Omarchy settings is the
escape hatch for the long tail.

## Wired too

A connected Ethernet device takes display priority, matching Omarchy. The page shows
its negotiated speed, IP/gateway, throughput, totals, ping and DNS controls, while
Wi-Fi-only band and scan sections disappear. With both kinds available the Wi-Fi
radio switch and network list remain usable. On a wired-only machine the Wi-Fi switch
is hidden and Deck opens the page on click instead of exposing a dead toggle.

The details come from Omarchy's `omarchy-network-status --verbose`; link icons and
speed labels use its network model. Unit tests cover Ethernet/Wi-Fi selection and
formatting. A physical cable/dock test is still required for hardware verification.

## Inside Deck

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-wifi
```

Then add the section to Deck's registry:

```json
{ "id": "wifi", "title": "Wi-Fi",
  "file": "/home/YOU/.config/omarchy/plugins/mutex-solutions.wifi/deck/Section.qml",
  "page": "/home/YOU/.config/omarchy/plugins/mutex-solutions.wifi/deck/Page.qml" }
```

`install-bundle.sh` in the Deck repo does this for every section at once.

The full-width tile shows the connected network, band/signal, download rate and
latency; wired mode uses link speed and IP. Full tiles subscribe to link details
with reference counting, including size previews, but never enable scanning behind
a closed page. Half and compact tiles keep Deck's standard body.

## How it is built

| File | Role |
| --- | --- |
| `State.qml` | enabled state, device, networks, connect and join |
| `deck/Section.qml` | the five members Deck reads |
| `deck/Page.qml` | the panel content |
| `Panel.qml` | the standalone bar widget and its popup |

State comes from Quickshell's `Networking` service, with security, failure and
enterprise helpers imported from Omarchy's network model. Band and DNS changes go
through Omarchy's own commands. Details and throughput are polled while shown;
scanning is tied to the UI being open and is rebound after device changes.

Network delegates contain Omarchy's primitive `wifiRow` snapshots. Live network
objects are resolved by SSID only when an action or failure signal needs them, so
scan churn cannot leave a delegate holding a deleted object. Passwords reach the
enterprise helper over stdin, never a process argument.

The footer opens Omarchy's own network panel for the long tail this plugin does
not implement.

## Requirements

Omarchy 4.x with NetworkManager.

## Licence

MIT. See [LICENSE](LICENSE).
