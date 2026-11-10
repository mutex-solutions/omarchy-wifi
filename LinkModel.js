.pragma library

// Link selection is presentation logic; NetworkManager remains the engine.
// Ethernet wins when both links are up, matching Omarchy's default-route readout.
// The device fallback keeps an OWE transition-mode link up while its named row is
// temporarily absent from a scan.
function linkKind(wiredConnected, wifiRowConnected, wifiDeviceConnected) {
  if (wiredConnected) return "ethernet"
  if (wifiRowConnected || wifiDeviceConnected) return "wifi"
  return "disconnected"
}
