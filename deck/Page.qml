import QtQuick
import QtQuick.Controls
import qs.Commons

// Wi-Fi page rendered by Deck and by the standalone popup. Omarchy owns the
// network engines; this file owns presentation, interaction and feedback.
Item {
  id: page

  Translations { id: strings; directory: Qt.resolvedUrl("../i18n") }

  property var state: null
  property var host: null
  property string pwdName: ""
  property bool pwdOpen: false
  property string pwdText: ""
  property string identityText: ""
  property string forgetName: ""
  property string settingsOpen: ""
  implicitHeight: col.implicitHeight
  readonly property bool uiOpen: !host || host.open
  readonly property bool keyboardEditing: pwdOpen

  function syncScanner() { if (state) state.setScanning(uiOpen) }
  onStateChanged: syncScanner()
  onUiOpenChanged: syncScanner()
  Component.onDestruction: if (state) state.setScanning(false)

  function openCredentials(net) {
    pwdName = state ? state.netLabel(net) : ""
    pwdOpen = true
    pwdText = ""
    identityText = ""
    forgetName = ""
  }
  function cancelCredentials() {
    pwdName = ""
    pwdOpen = false
    pwdText = ""
    identityText = ""
  }

  component Caps: Text {
    color: Util.alpha(Color.foreground, 0.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1.5
    textFormat: Text.PlainText
  }

  component Rule: Rectangle {
    width: parent ? parent.width : 0
    height: 1
    color: Util.alpha(Color.foreground, 0.1)
  }

  component Head: Item {
    id: head
    property string glyph: ""
    property string title: ""
    property string value: ""
    property int gap: 0
    width: parent ? parent.width : 0
    height: Style.space(22) + gap

    Item {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Style.space(22)
      Text {
        id: headGlyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(14)
        text: head.glyph
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        textFormat: Text.PlainText
      }
      Text {
        anchors.left: headGlyph.right
        anchors.leftMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
        text: head.title.toUpperCase()
        color: Util.alpha(Color.foreground, 0.45)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1.5
        textFormat: Text.PlainText
      }
      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: head.value
        color: Util.alpha(Color.foreground, 0.45)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        textFormat: Text.PlainText
      }
    }
  }

  component ActionButton: Rectangle {
    id: button
    property string text: ""
    property bool primary: false
    property bool enabled: true
    signal clicked()
    implicitWidth: label.implicitWidth + Style.space(16)
    width: implicitWidth
    height: Style.space(26)
    radius: Style.cornerRadius
    opacity: enabled ? 1 : 0.45
    color: button.primary ? Util.alpha(Color.accent, Style.selectedFillAlpha)
      : (area.containsMouse ? Util.alpha(Color.foreground, Style.hoverFillAlpha) : "transparent")
    border.width: 1
    border.color: button.primary ? Util.alpha(Color.accent, 0.6) : Util.alpha(Color.foreground, 0.25)
    Accessible.name: button.text
    Accessible.role: Accessible.Button
    Accessible.onPressAction: if (button.enabled) button.clicked()
    Text {
      id: label
      anchors.centerIn: parent
      text: button.text
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      textFormat: Text.PlainText
    }
    MouseArea {
      id: area
      anchors.fill: parent
      enabled: button.enabled
      hoverEnabled: true
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: button.clicked()
    }
  }

  component SignalBars: Item {
    id: bars
    property real level: 0
    width: 15
    height: 11
    Repeater {
      model: 4
      Rectangle {
        required property int index
        width: 3
        height: 3 + index * 2.5
        x: index * 4
        y: bars.height - height
        color: (index + 1) <= Math.ceil(bars.level * 4)
          ? Util.alpha(Color.foreground, 0.75) : Util.alpha(Color.foreground, 0.2)
      }
    }
  }

  component NetRow: Item {
    id: row
    property var net: null
    readonly property bool isConnected: net && net.connected
    readonly property string name: page.state ? page.state.netLabel(net) : ""
    readonly property string displayName: page.state ? page.state.displayName(net) : ""
    readonly property bool isBusy: page.state && page.state.actionKind !== "" && page.state.actionName === name
    readonly property bool isFailed: page.state && page.state.failureName === name && page.state.failureReason !== ""
    readonly property bool credentialOpen: page.pwdOpen && page.pwdName === name
    readonly property bool confirmingForget: page.forgetName !== "" && page.forgetName === name
    readonly property string status: {
      if (!page.state || !net) return ""
      if (confirmingForget) return "Forget this saved network?"
      if (isBusy && page.state.actionKind === "connect") return "Connecting…"
      if (isBusy && page.state.actionKind === "disconnect") return "Disconnecting…"
      if (isBusy && page.state.actionKind === "forget") return "Forgetting…"
      if (isFailed) return page.state.failureReason
      if (isConnected && page.state.hasCaptivePortal) return "Sign-in required"
      if (isConnected) return "Connected"
      if (net.known) return "Saved"
      return ""
    }

    width: parent ? parent.width : 0
    height: body.height + (credentialOpen ? credentials.height + Style.space(4) : 0)

    Item {
      id: body
      width: parent.width
      height: Style.space(40)
      Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius
        color: row.isConnected ? Util.alpha(Color.accent, Style.selectedFillAlpha)
          : (hover.containsMouse ? Util.alpha(Color.foreground, Style.hoverFillAlpha) : "transparent")
        border.width: row.isConnected || row.credentialOpen ? 1 : 0
        border.color: Util.alpha(Color.accent, 0.5)
      }
      Text {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(14)
        text: row.isConnected ? "●" : "○"
        color: row.isConnected ? Color.accent : Util.alpha(Color.foreground, 0.45)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        textFormat: Text.PlainText
      }
      Column {
        anchors.left: glyph.right
        anchors.leftMargin: Style.space(8)
        anchors.right: trailing.left
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        Text {
          width: parent.width
          text: row.displayName
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: row.isConnected
          elide: Text.ElideRight
          textFormat: Text.PlainText
        }
        Text {
          width: parent.width
          visible: text !== ""
          text: row.status
          color: row.isFailed || (row.isConnected && page.state && page.state.hasCaptivePortal)
            ? Color.urgent : Util.alpha(Color.foreground, 0.48)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          textFormat: Text.PlainText
        }
      }
      Item {
        id: trailing
        anchors.right: parent.right
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        width: forgetButton.width + lockGlyph.width + bars.width + Style.space(12)
        height: Style.space(26)
        ActionButton {
          id: forgetButton
          anchors.right: lockGlyph.left
          anchors.rightMargin: Style.space(6)
          anchors.verticalCenter: parent.verticalCenter
          visible: page.state && page.state.canForget(row.net)
          enabled: !page.state || !page.state.busy
          text: row.confirmingForget ? "Confirm" : "Forget"
          onClicked: {
            if (row.confirmingForget) {
              page.state.forget(row.net)
              page.forgetName = ""
            } else {
              page.forgetName = row.name
            }
          }
        }
        Text {
          id: lockGlyph
          anchors.right: bars.left
          anchors.rightMargin: Style.space(6)
          anchors.verticalCenter: parent.verticalCenter
          visible: page.state && page.state.needsPassword(row.net)
          text: "󰌾"
          color: Util.alpha(Color.foreground, 0.55)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          textFormat: Text.PlainText
        }
        SignalBars {
          id: bars
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          level: row.net ? Number(row.net.signal || 0) / 100 : 0
        }
      }
      MouseArea {
        id: hover
        anchors.left: parent.left
        anchors.right: trailing.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        hoverEnabled: true
        enabled: !page.state || !page.state.busy
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          if (!page.state || !row.net) return
          if (row.confirmingForget) { page.forgetName = ""; return }
          if (page.state.needsPassword(row.net) || (row.isFailed && row.net.known)) {
            page.openCredentials(row.net)
            Qt.callLater(function() { passwordField.forceActiveFocus() })
            return
          }
          page.cancelCredentials()
          page.forgetName = ""
          page.state.activate(row.net)
        }
      }
    }

    Connections {
      target: page.state ? page.state.networkForName(row.name) : null
      function onConnectionFailed(reason) {
        var ours = page.state && page.state.actionKind === "connect" && page.state.actionName === row.name
        if (page.state && page.state.failAction(row.net, reason) && ours) {
          page.openCredentials(row.net)
          Qt.callLater(function() { passwordField.forceActiveFocus() })
        }
      }
    }

    Column {
      id: credentials
      anchors.top: body.bottom
      anchors.topMargin: Style.space(4)
      width: parent.width
      visible: row.credentialOpen
      spacing: Style.space(5)
      TextField {
        id: identityField
        visible: page.state && page.state.isEnterprise(row.net)
        width: parent.width
        height: Style.space(30)
        enabled: !page.state.busy
        placeholderText: strings.t("wifi.identity")
        text: page.identityText
        onTextChanged: page.identityText = text
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) { page.cancelCredentials(); event.accepted = true }
        }
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        background: Rectangle { color: Util.alpha(Color.foreground, 0.05); border.width: 1; border.color: Util.alpha(Color.foreground, 0.2) }
      }
      Row {
        width: parent.width
        height: Style.space(30)
        spacing: Style.space(6)
        TextField {
          id: passwordField
          width: parent.width - showButton.width - parent.spacing
          height: parent.height
          enabled: !page.state.busy
          placeholderText: page.state && page.state.isEnterprise(row.net) ? "Password" : "Wi-Fi password"
          echoMode: showButton.text === "Show" ? TextInput.Password : TextInput.Normal
          text: page.pwdText
          onTextChanged: page.pwdText = text
          onAccepted: joinButton.clicked()
          Keys.priority: Keys.BeforeItem
          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) { page.cancelCredentials(); event.accepted = true }
          }
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          background: Rectangle { color: Util.alpha(Color.foreground, 0.05); border.width: 1; border.color: Util.alpha(Color.foreground, 0.2) }
        }
        ActionButton {
          id: showButton
          text: strings.t("wifi.show")
          onClicked: text = text === "Show" ? "Hide" : "Show"
        }
      }
      Row {
        width: parent.width
        height: Style.space(28)
        spacing: Style.space(6)
        ActionButton {
          id: joinButton
          primary: true
          enabled: page.pwdText.length > 0 && !page.state.busy
            && (!page.state.isEnterprise(row.net) || page.identityText.length > 0)
          text: row.isBusy ? "Connecting…" : "Join"
          onClicked: {
            if (!enabled) return
            page.state.join(row.net, page.identityText, page.pwdText)
          }
        }
        ActionButton {
          id: cancelButton
          text: strings.t("wifi.cancel")
          enabled: !page.state.busy
          onClicked: page.cancelCredentials()
        }
        Text {
          height: parent.height
          width: parent.width - joinButton.width - cancelButton.width - parent.spacing * 2
          verticalAlignment: Text.AlignVCenter
          visible: row.isFailed
          text: row.status
          color: Color.urgent
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          textFormat: Text.PlainText
        }
      }
    }
  }

  component Switch: Rectangle {
    id: sw
    property bool on: false
    signal toggled()
    width: Style.space(34)
    height: Style.space(18)
    radius: height / 2
    color: on ? Util.alpha(Color.accent, 0.85) : Util.alpha(Color.foreground, 0.2)
    border.width: activeFocus ? 2 : 0
    border.color: Color.foreground
    activeFocusOnTab: true
    Accessible.name: strings.t("wifi.wiFi")
    Accessible.role: Accessible.Switch
    Accessible.checked: on
    Accessible.onPressAction: toggled()
    Keys.onSpacePressed: toggled()
    Keys.onReturnPressed: toggled()
    Rectangle {
      width: Style.space(14)
      height: width
      radius: width / 2
      y: (parent.height - height) / 2
      x: sw.on ? parent.width - width - Style.space(2) : Style.space(2)
      color: "#ffffff"
    }
    MouseArea {
      anchors.fill: parent
      anchors.margins: -Style.space(8)
      cursorShape: Qt.PointingHandCursor
      onClicked: { sw.forceActiveFocus(); sw.toggled() }
    }
  }

  Column {
    id: col
    width: parent.width
    spacing: Style.space(3)

    Item {
      width: parent.width
      height: Style.space(48)
      Text {
        id: heroGlyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(30)
        text: page.state ? page.state.icon : ""
        color: page.state && page.state.active ? Color.accent : Util.alpha(Color.foreground, 0.4)
        font.family: Style.font.family
        font.pixelSize: Style.font.display
        textFormat: Text.PlainText
      }
      Column {
        anchors.left: heroGlyph.right
        anchors.leftMargin: Style.space(10)
        anchors.right: parent.right
        anchors.rightMargin: heroSwitch.visible ? heroSwitch.width + Style.space(8) : 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Text {
          width: parent.width
          text: !page.state ? ""
            : page.state.kind === "ethernet"
              ? page.state.label + (page.state.wiredSpeed !== "" ? " (" + page.state.wiredSpeed + ")" : "")
              : page.state.connected ? page.state.displayName(page.state.connected)
                : (page.state.active ? "Not connected" : "Wi-Fi off")
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
          elide: Text.ElideRight
          textFormat: Text.PlainText
        }
        Caps {
          width: parent.width
          text: page.state && page.state.hasConnection
            ? (page.state.kind === "ethernet" ? strings.t("wifi.connected").toUpperCase()
              : page.state.bandCurrent ? page.state.bandCurrent + " GHz · CONNECTED" : "CONNECTED")
            : (page.state && page.state.active ? "READY" : "DISABLED")
        }
      }
      Switch {
        id: heroSwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: page.state && page.state.canToggle
        enabled: visible
        on: page.state && page.state.wifiOn
        onToggled: if (page.state) page.state.toggle()
      }
    }

    Rectangle {
      visible: page.state && page.state.restricted
      width: parent.width
      height: portalRow.implicitHeight + Style.space(12)
      radius: Style.cornerRadius
      color: Util.alpha(Color.urgent, 0.1)
      border.width: 1
      border.color: Util.alpha(Color.urgent, 0.45)
      Column {
        id: portalRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(5)
        Text {
          width: parent.width
          text: page.state && page.state.hasCaptivePortal ? "This network needs sign-in" : "Internet access is limited"
          color: Color.urgent
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          horizontalAlignment: Text.AlignHCenter
          textFormat: Text.PlainText
        }
        ActionButton {
          visible: page.state && page.state.hasCaptivePortal
          anchors.horizontalCenter: parent.horizontalCenter
          text: strings.t("wifi.signInToNetwork")
          onClicked: page.state.openCaptivePortal()
        }
      }
    }

    Grid {
      id: statsGrid
      visible: page.state && page.state.hasConnection
      width: parent.width
      columns: 2
      columnSpacing: Style.space(12)
      rowSpacing: Style.space(2)
      Repeater {
        model: page.state && page.state.hasConnection ? [
          "IP  " + (page.state.ipAddress || "--"),
          "Gateway  " + (page.state.gateway || "--"),
          "Ping  " + page.state.pingText,
          "Loss  " + page.state.packetLossText,
          "↓  " + page.state.downloadText + "  ·  " + page.state.downloadTotalText,
          "↑  " + page.state.uploadText + "  ·  " + page.state.uploadTotalText
        ] : []
        Text {
          required property var modelData
          width: (statsGrid.width - statsGrid.columnSpacing) / 2
          text: modelData
          color: Util.alpha(Color.foreground, 0.65)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
          textFormat: Text.PlainText
        }
      }
    }

    // Advanced stock settings stay one click away without dominating the page.
    Column {
      width: parent.width
      spacing: Style.space(3)
      visible: page.state && page.state.kind === "wifi" && page.state.hasConnection && page.state.bandAvailable.length > 0
      Head {
        glyph: "󰖩"
        title: "Wi-Fi band"
        value: page.state && page.state.settingKind === "band" ? "Applying…  "
          : ((page.state ? page.state.bandSelected === "auto" ? "Auto" : page.state.bandSelected + " GHz" : "")
          + (page.settingsOpen === "band" ? "  ▴" : "  ▾"))
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: page.settingsOpen = page.settingsOpen === "band" ? "" : "band"
        }
      }
      Row {
        visible: page.settingsOpen === "band"
        spacing: Style.space(6)
        height: Style.space(28)
        Repeater {
          model: ["auto"].concat(page.state ? page.state.bandAvailable : [])
          ActionButton {
            required property var modelData
            primary: page.state && page.state.bandSelected === modelData
            enabled: page.state && page.state.settingKind === ""
            text: modelData === "auto" ? "Auto" : modelData + " GHz"
            onClicked: page.state.setBand(modelData)
          }
        }
      }
    }

    Column {
      width: parent.width
      spacing: Style.space(3)
      visible: page.state && page.state.hasConnection
      Head {
        glyph: "󰇖"
        title: "DNS provider"
        value: page.state && page.state.settingKind === "dns" ? "Applying…  "
          : ((page.state ? page.state.dnsProvider : "") + (page.settingsOpen === "dns" ? "  ▴" : "  ▾"))
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: page.settingsOpen = page.settingsOpen === "dns" ? "" : "dns"
        }
      }
      Row {
        visible: page.settingsOpen === "dns"
        spacing: Style.space(5)
        height: Style.space(28)
        Repeater {
          model: ["DHCP", "Cloudflare", "Google", "Custom"]
          ActionButton {
            required property var modelData
            primary: page.state && page.state.dnsProvider === modelData
            enabled: page.state && page.state.settingKind === ""
            text: modelData
            onClicked: page.state.setDns(modelData)
          }
        }
      }
    }
    Text {
      visible: page.state && page.state.settingError !== ""
      width: parent.width
      text: page.state ? page.state.settingError : ""
      color: Color.urgent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.Wrap
      textFormat: Text.PlainText
    }

    Rule { }

    // A bounded view keeps the card stable as scans arrive. Section headings
    // separate saved networks from new ones, matching Omarchy's grouping.
    Item {
      width: parent.width
      height: page.state && page.state.wifiOn && page.state.canToggle ? Style.space(300) : 0
      visible: page.state && page.state.wifiOn && page.state.canToggle
      ListView {
        id: networkList
        anchors.fill: parent
        clip: true
        model: page.state ? page.state.rows : []
        spacing: Style.space(2)
        boundsBehavior: Flickable.StopAtBounds
        section.property: "known"
        section.criteria: ViewSection.FullString
        section.delegate: Head {
          width: networkList.width
          title: section === "true" ? "Known networks" : "Other networks"
          glyph: "󰖩"
        }
        delegate: NetRow { width: networkList.width; net: modelData }
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
      }
      Column {
        anchors.centerIn: parent
        spacing: Style.space(8)
        visible: page.state && page.state.nets.length === 0
        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: page.state && page.state.scanning ? "Scanning for networks…" : "No networks found"
          color: Util.alpha(Color.foreground, 0.5)
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          textFormat: Text.PlainText
        }
        ActionButton {
          anchors.horizontalCenter: parent.horizontalCenter
          text: strings.t("wifi.scanAgain")
          onClicked: page.state.setScanning(true)
        }
      }
    }

    Rule { }

    Item {
      width: parent.width
      height: Style.space(28)
      ActionButton {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: page.state && page.state.scanning ? "Scanning…" : "Refresh"
        enabled: page.state && page.state.wifiOn && page.state.canToggle && !page.state.scanning
        onClicked: page.state.setScanning(true)
      }
      ActionButton {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: strings.t("wifi.omarchySettings")
        onClicked: {
          var opened = page.host && typeof page.host.openStock === "function"
            ? page.host.openStock("omarchy.network") : false
          if (!opened && page.state)
            page.state.settingError = "The Omarchy network panel is not available on this display"
        }
      }
    }
  }
}
