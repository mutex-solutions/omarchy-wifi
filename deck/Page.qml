import QtQuick
import Quickshell
import qs.Commons

// Wi-Fi page, rendered by Deck and by this plugin's own popup.
//
// Apple's Wi-Fi menu is the reference: the connected network in its own group,
// the rest below it, a lock on secured ones, signal on the right, and a footer
// escape hatch to the full system UI.
Item {
  id: page

  property var state: null
  property var host: null

  property string pwdSsid: ""
  property string pwdText: ""

  implicitHeight: col.implicitHeight

  onStateChanged: if (state) state.setScanning(true)
  Component.onDestruction: if (state) state.setScanning(false)

  component Caps: Text {
    color: Util.alpha(Color.foreground, 0.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1.5
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
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: head.value
        color: Util.alpha(Color.foreground, 0.45)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  // No Row and no anchors: Qt refuses vertical anchors on Row children. Fixed
  // geometry, drawn from the bottom up.
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
          ? Util.alpha(Color.foreground, 0.75)
          : Util.alpha(Color.foreground, 0.2)
      }
    }
  }

  component NetRow: Item {
    id: row
    property var net: null
    property bool isConnected: false

    width: parent ? parent.width : 0
    height: Style.space(30)

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: row.isConnected
        ? Util.alpha(Color.accent, Style.selectedFillAlpha)
        : (hover.containsMouse ? Util.alpha(Color.foreground, Style.hoverFillAlpha) : "transparent")
      border.width: row.isConnected ? 1 : 0
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
    }

    Text {
      anchors.left: glyph.right
      anchors.leftMargin: Style.space(8)
      anchors.right: trailing.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      text: page.state ? page.state.netLabel(row.net) : ""
      color: Color.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: row.isConnected
      elide: Text.ElideRight
    }

    Row {
      id: trailing
      anchors.right: parent.right
      anchors.rightMargin: Style.space(9)
      anchors.verticalCenter: parent.verticalCenter
      height: Style.space(18)
      spacing: Style.space(7)

      SignalBars {
        height: parent.height
        level: page.state && row.net ? page.state.strength(row.net) : 0
      }

      Text {
        height: parent.height
        verticalAlignment: Text.AlignVCenter
        visible: row.net ? !!(row.net.known) : false
        text: "saved"
        color: Util.alpha(Color.foreground, 0.4)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    MouseArea {
      id: hover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (!page.state || !row.net) return
        if (!row.net.connected && page.state.needsPassword(row.net)) {
          page.pwdSsid = String(row.net.ssid || "")
          page.pwdText = ""
          return
        }
        page.state.activate(row.net)
      }
    }
  }

  Column {
    id: col
    width: parent.width
    spacing: Style.space(2)

    // ---- hero ----
    Item {
      width: parent.width
      height: Style.space(44)

      Text {
        id: heroGlyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(30)
        text: "≋"
        color: page.state && page.state.active ? Color.foreground : Util.alpha(Color.foreground, 0.4)
        font.family: Style.font.family
        font.pixelSize: Style.font.display
        horizontalAlignment: Text.AlignHCenter
      }

      Column {
        anchors.left: heroGlyph.right
        anchors.leftMargin: Style.space(10)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
          width: parent.width
          text: page.state && page.state.connected
            ? page.state.netLabel(page.state.connected)
            : (page.state && page.state.active ? "Not connected" : "Wi-Fi off")
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
          elide: Text.ElideRight
        }

        Caps {
          width: parent.width
          text: page.state && page.state.active ? "CONNECTED" : "DISABLED"
        }
      }
    }

    Rule { }

    // ---- connected ----
    Head {
      visible: page.state && page.state.connected
      glyph: "≋"
      title: "Network"
      gap: Style.space(4)
    }

    NetRow {
      visible: page.state && page.state.connected
      net: page.state ? page.state.connected : null
      isConnected: true
    }

    // ---- others ----
    Head {
      visible: page.state && page.state.others.length > 0
      glyph: "≋"
      title: "Other networks"
      value: page.state ? String(page.state.others.length) : ""
      gap: Style.space(6)
    }

    Repeater {
      model: page.state ? page.state.others : []

      delegate: Column {
        required property var modelData
        width: col.width
        spacing: Style.space(3)

        NetRow { net: modelData }

        Row {
          width: parent.width
          height: Style.space(28)
          spacing: Style.space(6)
          visible: page.pwdSsid !== "" && page.pwdSsid === String(modelData.ssid || "")

          Rectangle {
            width: parent.width - joinBtn.width - parent.spacing
            height: parent.height
            radius: Style.cornerRadius
            color: Util.alpha(Color.foreground, Style.normalFillAlpha)
            border.width: 1
            border.color: Util.alpha(Color.foreground, Style.normalBorderAlpha)

            TextInput {
              anchors.fill: parent
              anchors.leftMargin: Style.space(8)
              anchors.rightMargin: Style.space(8)
              verticalAlignment: TextInput.AlignVCenter
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              echoMode: TextInput.Password
              passwordCharacter: "•"
              focus: visible
              onTextChanged: page.pwdText = text
              Keys.onReturnPressed: {
                page.state.join(modelData, page.pwdText)
                page.pwdSsid = ""
              }
            }
          }

          Rectangle {
            id: joinBtn
            width: Style.space(54)
            height: parent.height
            radius: Style.cornerRadius
            color: Util.alpha(Color.accent, Style.selectedFillAlpha)
            border.width: 1
            border.color: Util.alpha(Color.accent, 0.55)

            Text {
              anchors.centerIn: parent
              text: "Join"
              color: Color.foreground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                page.state.join(modelData, page.pwdText)
                page.pwdSsid = ""
              }
            }
          }
        }
      }
    }

    Rule { }

    Text {
      width: parent.width
      height: Style.space(26)
      verticalAlignment: Text.AlignVCenter
      leftPadding: Style.space(8)
      text: "Open Omarchy network settings"
      color: Util.alpha(Color.foreground, 0.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["omarchy-shell", "shell", "summon", "omarchy.network", "{}"])
      }
    }
  }
}
