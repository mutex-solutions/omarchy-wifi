import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.Commons
import "/usr/share/omarchy/shell/plugins/panels/network/Model.js" as NetModel
import "LinkModel.js" as LinkModel

// Wi-Fi state shared by the standalone widget and Deck. Network discovery and
// connection still belong to Quickshell/NetworkManager; the read-only helpers
// imported from Omarchy keep security, formatting and failure semantics aligned.
Item {
  id: s

  Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  readonly property bool networkManagerAvailable: Networking.backend === NetworkBackendType.NetworkManager
  readonly property var devices: Networking.devices ? Networking.devices.values : []
  function findDevice(type) {
    var fallback = null
    for (var i = 0; i < devices.length; i++) {
      var dev = devices[i]
      if (!dev || dev.type !== type) continue
      if (dev.connected) return dev
      if (!fallback) fallback = dev
    }
    return fallback
  }

  readonly property var device: findDevice(DeviceType.Wifi)
  readonly property var wiredDevice: findDevice(DeviceType.Wired)
  readonly property bool wifiAvailable: device !== null
  readonly property bool available: networkManagerAvailable && (wifiAvailable || wiredDevice !== null)
  readonly property bool canToggle: networkManagerAvailable && wifiAvailable
  readonly property bool wifiOn: Networking.wifiEnabled
  readonly property string kind: LinkModel.linkKind(
    !!(wiredDevice && wiredDevice.connected), !!connected, !!(device && device.connected))
  readonly property bool hasConnection: kind !== "disconnected"
  readonly property bool active: hasConnection || wifiOn
  readonly property int signalStrength: connected ? Math.round(strength(connected) * 100) : 0
  readonly property string label: kind === "ethernet" ? strings.t("wifi.ethernet") : strings.t("wifi.wiFi")
  readonly property string icon: NetModel.connectionIcon(kind, signalStrength, connectivity)

  readonly property var nets: {
    var src = device && device.networks ? device.networks.values : []
    var out = []
    for (var i = 0; i < src.length; i++) if (src[i]) out.push(src[i])
    out.sort(function(a, b) {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      if (a.known !== b.known) return a.known ? -1 : 1
      return strength(b) - strength(a)
    })
    return out
  }

  // Primitive model rows: NetworkManager can destroy a WifiNetwork while a
  // delegate incubates. Resolve the live object again only for an action.
  readonly property var rows: {
    var out = []
    for (var i = 0; i < nets.length; i++) out.push(NetModel.wifiRow(nets[i]))
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

  readonly property string wiredSpeed: info.type === "ethernet"
    ? NetModel.formatHeaderSpeed(info.speed || "", I18n.formatNumber) : ""
  readonly property string detail: {
    if (kind === "ethernet") return wiredSpeed !== "" ? wiredSpeed : strings.t("wifi.connected")
    if (!active) return "off"
    if (connected) return displayName(connected)
    return kind === "wifi" ? strings.t("wifi.connected") : "on"
  }

  // scannerEnabled is shared and has no reference counting. Remember the exact
  // device this instance enabled, and re-apply after device or panel changes.
  property bool scanWanted: false
  property int fullTileUsers: 0
  readonly property bool detailsWanted: scanWanted || fullTileUsers > 0
  property var scannerDevice: null
  property bool scanning: false

  function setFullTileDetails(on) {
    if (on) {
      fullTileUsers += 1
      refreshDetails()
    } else fullTileUsers = Math.max(0, fullTileUsers - 1)
  }

  function applyScanner(on) {
    var next = scanWanted ? device : null
    if (scannerDevice && scannerDevice !== next) scannerDevice.scannerEnabled = false
    scannerDevice = next
    if (scannerDevice) scannerDevice.scannerEnabled = !!on
  }

  function setScanning(on) {
    scanWanted = !!on
    scanRestart.stop()
    if (scanWanted) {
      scanning = true
      applyScanner(false)
      // Defer re-enabling so a stock panel closing in the same transition cannot
      // leave Deck's newly opened page with scanning switched off.
      scanRestart.start()
      refreshDetails()
    } else {
      scanning = false
      applyScanner(false)
    }
  }

  onDeviceChanged: if (scanWanted) setScanning(true)
  onNetsChanged: {
    scanning = false
    checkActionCompletion()
  }
  Component.onDestruction: {
    scanRestart.stop()
    if (scannerDevice) scannerDevice.scannerEnabled = false
  }

  Timer {
    id: scanRestart
    interval: 100
    onTriggered: s.applyScanner(true)
  }

  function toggle() { Networking.wifiEnabled = !Networking.wifiEnabled }
  function strength(net) { return net ? Number(net.signalStrength || 0) : 0 }
  function netLabel(net) {
    if (!net) return ""
    return String(net.ssid !== undefined ? net.ssid : (net.name || ""))
  }
  function displayName(net) {
    var name = netLabel(net)
    return name !== "" ? name : strings.t("wifi.hiddenNetwork")
  }
  function networkForName(name) {
    for (var i = 0; i < nets.length; i++)
      if (nets[i] && netLabel(nets[i]) === String(name || "")) return nets[i]
    return null
  }
  function resolveNetwork(net) {
    return net && net.ssid !== undefined ? networkForName(netLabel(net)) : net
  }
  function needsPassword(net) {
    return net && !net.known && NetModel.requiresCredentials(net.security, WifiSecurityType.Open, WifiSecurityType.Owe)
  }
  function isEnterprise(net) {
    return net && (net.security === WifiSecurityType.Wpa2Eap || net.security === WifiSecurityType.WpaEap)
  }
  function canForget(net) { return NetModel.canForgetNetwork(net) }

  // One serialized network operation, with visible completion, failure and a
  // timeout instead of a silently disconnected click.
  property string actionName: ""
  property string actionKind: ""
  property string failureName: ""
  property string failureReason: ""
  readonly property bool busy: actionKind !== ""

  function runAction(kind, net, callback) {
    net = resolveNetwork(net)
    if (busy || !net) return
    actionName = netLabel(net)
    actionKind = kind
    failureName = ""
    failureReason = ""
    callback(net)
    actionTimeout.restart()
  }

  function clearAction() {
    actionTimeout.stop()
    actionName = ""
    actionKind = ""
    failureName = ""
    failureReason = ""
    refreshDetails()
  }

  function failAction(net, reason) {
    if (!net || actionKind === "" || actionName !== netLabel(net)) return false
    actionTimeout.stop()
    failureName = actionName
    failureReason = NetModel.networkFailureReason(reason, needsPassword(net) || net.known, failReasons,
      function(key, fallback) { return fallback })
    var reprompt = NetModel.shouldRepromptPassphrase(reason, needsPassword(net) || net.known, failReasons)
    actionName = ""
    actionKind = ""
    return reprompt
  }

  function checkActionCompletion() {
    if (actionKind === "") return
    var net = networkForName(actionName)
    if (!net) return
    if (actionKind === "connect" && net.connected) clearAction()
    else if (actionKind === "disconnect" && !net.connected && !net.stateChanging) clearAction()
    else if (actionKind === "forget" && !net.known && !net.stateChanging) clearAction()
  }

  function activate(net) {
    if (!net || busy) return
    if (net.connected) runAction("disconnect", net, function(n) { n.disconnect() })
    else if (needsPassword(net)) return
    else runAction("connect", net, function(n) { n.connect() })
  }

  function join(net, identity, psk) {
    if (!net || busy || String(psk).length === 0) return
    runAction("connect", net, function(n) {
      if (isEnterprise(n)) {
        enterpriseConnect.secret = String(psk)
        enterpriseConnect.command = ["bash", "-c", NetModel.enterpriseConnectScript,
          "nmcli-eap", netLabel(n), String(identity)]
        enterpriseConnect.running = true
      } else {
        n.connectWithPsk(String(psk))
      }
    })
  }

  function forget(net) {
    if (!canForget(net)) return
    runAction("forget", net, function(n) { n.forget() })
  }

  readonly property var failReasons: ({
    NoSecrets: ConnectionFailReason.NoSecrets,
    WifiAuthTimeout: ConnectionFailReason.WifiAuthTimeout,
    WifiNetworkLost: ConnectionFailReason.WifiNetworkLost,
    WifiClientDisconnected: ConnectionFailReason.WifiClientDisconnected,
    WifiClientFailed: ConnectionFailReason.WifiClientFailed
  })

  Timer {
    id: actionTimeout
    interval: 30000
    onTriggered: {
      if (s.actionName !== "") {
        s.failureName = s.actionName
        s.failureReason = s.actionKind === "connect" ? "Connection timed out" : "Action timed out"
      }
      s.actionName = ""
      s.actionKind = ""
    }
  }

  Process {
    id: enterpriseConnect
    property string secret: ""
    stdinEnabled: true
    onStarted: {
      write(secret + "\n")
      secret = ""
    }
  }

  // Omarchy's native connectivity probe and portal helper, including its
  // Tailscale-exit-node handling.
  readonly property bool connectivityChecksEnabled: Networking.canCheckConnectivity && Networking.connectivityCheckEnabled
  readonly property string connectivity: NetModel.connectivityState(kind,
    Networking.connectivity, ({ Portal: NetworkConnectivity.Portal, Limited: NetworkConnectivity.Limited,
      Full: NetworkConnectivity.Full, None: NetworkConnectivity.None }), connectivityChecksEnabled)
  readonly property bool hasCaptivePortal: connectivity === "portal"
  readonly property bool restricted: hasCaptivePortal || connectivity === "limited"

  function checkConnectivity() {
    if (connectivityChecksEnabled && hasConnection) Networking.checkConnectivity()
  }
  function openCaptivePortal() {
    if (hasCaptivePortal) Quickshell.execDetached(["omarchy-network-captive-portal", NetModel.captivePortalUrl])
  }
  onKindChanged: Qt.callLater(checkConnectivity)
  onConnectivityChecksEnabledChanged: Qt.callLater(checkConnectivity)
  Timer {
    interval: 10000
    repeat: true
    running: s.restricted && s.connectivityChecksEnabled
    onTriggered: s.checkConnectivity()
  }

  // Stock connection details, sampled only while the UI is open.
  property var info: ({})
  property real downloadRate: 0
  property real uploadRate: 0
  property real prevSampleTime: 0
  property real prevRxBytes: 0
  property real prevTxBytes: 0
  property string prevIface: ""
  property var routerPingSamples: []
  property var internetPingSamples: []
  property string pingIface: ""
  property real internetPingLatency: -1
  property real internetPingPacketLoss: 0

  readonly property string ipAddress: info.ip || ""
  readonly property string gateway: info.gateway || ""
  readonly property string pingText: NetModel.formatPingLatency(internetPingLatency,
    NetModel.internetPingReadable(internetPingSamples, connectivity), function(k, v) { return v },
    function(v, d) { return d === undefined ? String(v) : Number(v).toFixed(d) })
  readonly property string packetLossText: NetModel.formatPacketLoss(internetPingPacketLoss,
    NetModel.internetPingReadable(internetPingSamples, connectivity),
    function(v, d) { return d === undefined ? String(v) : Number(v).toFixed(d) })
  readonly property string downloadText: NetModel.formatRate(downloadRate,
    function(v, d) { return d === undefined ? String(v) : Number(v).toFixed(d) })
  readonly property string uploadText: NetModel.formatRate(uploadRate,
    function(v, d) { return d === undefined ? String(v) : Number(v).toFixed(d) })
  readonly property string downloadTotalText: NetModel.formatBytes(info.rx_bytes,
    function(v, d) { return d === undefined ? String(v) : Number(v).toFixed(d) })
  readonly property string uploadTotalText: NetModel.formatBytes(info.tx_bytes,
    function(v, d) { return d === undefined ? String(v) : Number(v).toFixed(d) })
  readonly property string frequencyText: info.freq ? Number(info.freq / 1000).toFixed(Number(info.freq) >= 5925 ? 0 : 1) + " GHz" : ""

  function updateDetails(raw) {
    var next = NetModel.parseKeyValue(raw)
    if (settingKind === "band" && !next.iface) return
    info = next
    var rate = NetModel.throughputState({
      prevIface: prevIface, prevRxBytes: prevRxBytes, prevTxBytes: prevTxBytes,
      prevSampleTime: prevSampleTime, downloadRate: downloadRate, uploadRate: uploadRate
    }, next, Date.now() / 1000)
    prevIface = rate.prevIface
    prevRxBytes = rate.prevRxBytes
    prevTxBytes = rate.prevTxBytes
    prevSampleTime = rate.prevSampleTime
    downloadRate = rate.downloadRate
    uploadRate = rate.uploadRate
    var ping = NetModel.pingLatencyState({ pingIface: pingIface,
      routerPingSamples: routerPingSamples, internetPingSamples: internetPingSamples }, next, 20, 5)
    pingIface = ping.pingIface
    routerPingSamples = ping.routerPingSamples
    internetPingSamples = ping.internetPingSamples
    internetPingLatency = ping.internetPingLatency
    internetPingPacketLoss = ping.internetPingPacketLoss
  }

  function refreshDetails() {
    if (!detailsWanted) return
    checkConnectivity()
    if (!detailsProc.running) detailsProc.running = true
    if (!bandProc.running) bandProc.running = true
    if (!dnsProc.running) dnsProc.running = true
  }

  Process {
    id: detailsProc
    command: ["omarchy-network-status", "--verbose"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: s.updateDetails(text)
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: s.detailsWanted
    onTriggered: if (!detailsProc.running) detailsProc.running = true
  }

  // Omarchy's band and DNS engines; only the presentation is Deck-owned.
  property string bandCurrent: ""
  property string bandSelected: "auto"
  property var bandAvailable: []
  property string dnsProvider: "DHCP"
  property string pendingSetting: ""
  property string settingKind: ""
  property string settingError: ""

  function updateBand(raw) {
    var status = NetModel.parseBandStatus(raw)
    if (settingKind === "band" && status.available.length === 0) return
    bandCurrent = status.band
    bandSelected = status.selected
    bandAvailable = status.available
  }

  function setBand(band) {
    if (!band || settingKind !== "") return
    settingError = ""
    settingKind = "band"
    pendingSetting = band
    settingProc.command = ["omarchy-network-band", band]
    settingProc.running = true
  }

  function setDns(provider) {
    if (!provider || settingKind !== "") return
    settingError = ""
    if (provider === "Custom") {
      Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "omarchy-dns Custom"])
      return
    }
    settingKind = "dns"
    pendingSetting = provider
    settingProc.command = ["omarchy-dns", provider]
    settingProc.running = true
  }

  Process {
    id: bandProc
    command: ["omarchy-network-band"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: s.updateBand(text)
    }
  }

  Process {
    id: dnsProc
    command: ["omarchy-dns"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: s.dnsProvider = text.trim() || "DHCP"
    }
  }

  Process {
    id: settingProc
    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        if (s.settingKind === "band") s.bandSelected = s.pendingSetting
        if (s.settingKind === "dns") s.dnsProvider = s.pendingSetting
      } else {
        s.settingError = s.settingKind === "band" ? "Could not change Wi-Fi band" : "Could not change DNS provider"
      }
      s.settingKind = ""
      s.pendingSetting = ""
      s.refreshDetails()
    }
  }
}
