import QtQuick
import Quickshell
import Quickshell.Networking

// Wi-Fi state. One instance, shared by the standalone bar widget and Deck.
//
// The device only populates `networks` while its scanner is enabled, so
// setScanning is part of the lifecycle: the panel turns it on while open and
// off when it closes, and a Deck page does the same for its own lifetime.
Item {
  id: s

  readonly property bool active: Networking.wifiEnabled
  readonly property string label: "Wi-Fi"
  readonly property string icon: "󰖩"

  readonly property var device: {
    var devs = Networking.devices ? Networking.devices.values : []
    for (var i = 0; i < devs.length; i++)
      if (devs[i] && devs[i].type === DeviceType.Wifi) return devs[i]
    return null
  }

  readonly property var nets: {
    var src = device && device.networks ? device.networks.values : []
    var out = []
    for (var i = 0; i < src.length; i++) if (src[i]) out.push(src[i])
    out.sort(function(a, b) {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      return (b.signalStrength || 0) - (a.signalStrength || 0)
    })
    return out
  }

  readonly property var connected: {
    for (var i = 0; i < nets.length; i++) if (nets[i].connected) return nets[i]
    return null
  }

  readonly property var others: {
    var out = []
    for (var i = 0; i < nets.length; i++) if (!nets[i].connected) out.push(nets[i])
    return out
  }

  readonly property string detail: {
    if (!active) return "off"
    return connected ? String(connected.ssid || connected.name || "connected") : "on"
  }

  function toggle() {
    Networking.wifiEnabled = !Networking.wifiEnabled
  }

  function setScanning(on) {
    if (device) device.scannerEnabled = !!on
  }

  function needsPassword(net) {
    if (!net || net.known) return false
    return net.security !== WifiSecurityType.Open
  }

  function activate(net) {
    if (!net) return
    if (net.connected) { net.disconnect(); return }
    if (needsPassword(net)) return   // the page asks, then calls join()
    net.connect()
  }

  function join(net, psk) {
    if (!net) return
    net.connectWithPsk(String(psk))
  }

  function netLabel(net) {
    if (!net) return ""
    return String(net.ssid || net.name || "?")
  }

  function strength(net) {
    return net ? Number(net.signalStrength || 0) : 0
  }
}
