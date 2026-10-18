# Wi-Fi

Wi-Fi status, networks and connection for Omarchy. A bar widget, or a section
inside [Deck](https://github.com/mutex-solutions/omarchy-deck).

## Standalone

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-wifi --enable
```

Click the Wi-Fi icon: the connected network in its own group, the rest below,
signal on the right, and a password field for a network that needs one.

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

## How it is built

| File | Role |
| --- | --- |
| `State.qml` | enabled state, device, networks, connect and join |
| `deck/Section.qml` | the five members Deck reads |
| `deck/Page.qml` | the panel content |
| `Panel.qml` | the standalone bar widget and its popup |

State comes from Quickshell's `Networking` service, the same one the stock
Omarchy network panel reads, so there is no helper and no polling.

Scanning is enabled only while the UI is open: the device does not populate its
network list otherwise, and a scanner running behind a closed panel is waste.

The footer opens Omarchy's own network panel for the long tail this plugin does
not implement, such as enterprise authentication.

## Requirements

Omarchy 4.x with NetworkManager.

## Licence

MIT. See [LICENSE](LICENSE).
