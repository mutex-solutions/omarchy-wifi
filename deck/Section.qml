import QtQuick
import qs.Commons

// Deck adapter. The full tile uses its extra width for live link details; the
// half and compact tiles keep Deck's standard body.
Item {
  id: s

  readonly property var state: stateLoader.item

  readonly property bool active: state ? state.active : false
  readonly property bool canToggle: state ? state.canToggle : false
  readonly property string label: state ? state.label : ""
  readonly property string detail: state ? state.detail : ""
  readonly property string icon: state ? state.icon : ""

  function toggle() {
    if (state) state.toggle()
  }

  readonly property Component tileFull: fullTile

  Component {
    id: fullTile

    Item {
      id: full
      signal holdStarted()
      signal holdEnded()
      signal pageRequested(string sectionId)

      readonly property var st: s.state
      readonly property bool wired: st && st.kind === "ethernet"
      readonly property string title: st && st.connected ? st.displayName(st.connected)
        : st ? st.label : ""
      readonly property string mainDetail: {
        if (!st) return ""
        if (wired) {
          var link = st.wiredSpeed !== "" ? st.wiredSpeed : "Connected"
          return st.ipAddress !== "" ? link + " · " + st.ipAddress : link
        }
        if (st.connected) {
          var band = st.bandCurrent !== "" ? st.bandCurrent + " GHz" : ""
          var signal = st.signalStrength > 0 ? st.signalStrength + "%" : ""
          return band !== "" && signal !== "" ? band + " · " + signal
            : band !== "" ? band : signal !== "" ? signal : "Connected"
        }
        return st.wifiOn ? "Not connected" : "Wi-Fi off"
      }
      readonly property string rightTop: {
        if (!st || !st.hasConnection) return ""
        return "↓ " + st.downloadText
      }
      readonly property string rightBottom: {
        if (!st || !st.hasConnection) return ""
        return st.pingText
      }

      property bool detailsAcquired: false
      function acquireDetails() {
        if (detailsAcquired || !st) return
        detailsAcquired = true
        st.setFullTileDetails(true)
      }
      Component.onCompleted: acquireDetails()
      onStChanged: acquireDetails()
      Component.onDestruction: {
        if (detailsAcquired && st) st.setFullTileDetails(false)
      }

      // The full tile opens the page on a tap or a hold; the small tiles retain
      // the radio-toggle click. No global IPC: the host stays on this screen.
      MouseArea {
        id: pageArea
        anchors.fill: parent
        property bool held: false
        cursorShape: Qt.PointingHandCursor
        onPressed: {
          held = false
          pageHold.restart()
          full.holdStarted()
        }
        onReleased: {
          pageHold.stop()
          full.holdEnded()
          if (!held) full.pageRequested("")
        }
        onCanceled: {
          pageHold.stop()
          full.holdEnded()
        }
        Timer {
          id: pageHold
          interval: 450
          onTriggered: {
            pageArea.held = true
            full.holdEnded()
            full.pageRequested("")
          }
        }
      }

      Item {
        id: glyph
        anchors.left: parent.left
        anchors.leftMargin: Style.space(12)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Style.space(28)
        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: full.st ? full.st.icon : ""
          color: full.st && full.st.active ? Color.accent : Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.display
        }
      }

      Column {
        anchors.left: glyph.right
        anchors.leftMargin: Style.space(8)
        anchors.right: details.visible ? details.left : parent.right
        anchors.rightMargin: Style.space(8)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: full.title
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          text: full.mainDetail
          color: Util.alpha(Color.foreground, 0.6)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }

      Column {
        id: details
        visible: full.st && full.st.hasConnection
        anchors.right: parent.right
        anchors.rightMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(96)
        spacing: Style.space(2)
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignRight
          textFormat: Text.PlainText
          text: full.rightTop
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
          font.bold: true
          elide: Text.ElideRight
        }
        Text {
          width: parent.width
          horizontalAlignment: Text.AlignRight
          textFormat: Text.PlainText
          text: full.rightBottom
          color: Util.alpha(Color.foreground, 0.5)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }

  Loader {
    id: stateLoader
    source: "../State.qml"
  }
}
