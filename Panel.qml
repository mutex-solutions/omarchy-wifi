import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Ui
import qs.Commons

// Standalone bar widget. Click opens the panel; the same page Deck renders is
// shown inside it.
Panel {
  id: root

  Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  moduleName: "mutex-solutions.wifi"
  ipcTarget: "mutex-solutions.wifi"

  readonly property var state: stateLoader.item

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Loader {
    id: stateLoader
    source: "State.qml"
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.state ? root.state.icon : ""
    active: root.state ? root.state.active : false
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(Math.min(content.implicitHeight, Style.space(520)), Style.space(600))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onActivateRequested: root.close()
    }

    // Long network lists must scroll; a Column alone would overflow and clip.
    ScrollView {
      id: scroll
      anchors.fill: parent
      clip: true
      ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
      ScrollBar.vertical.policy: content.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

      Column {
        id: content
        width: scroll.availableWidth
        spacing: Style.space(10)

        Item {
          width: parent.width
          height: Style.space(24)

          Text {
            id: headerGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "≋"
            color: Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.title
          }

          Text {
            anchors.left: headerGlyph.right
            anchors.leftMargin: Style.space(8)
            anchors.verticalCenter: parent.verticalCenter
            text: root.state ? root.state.label : strings.t("wifi.wiFi")
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Rectangle {
            visible: root.state && root.state.canToggle
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(34)
            height: Style.space(18)
            radius: height / 2
            color: root.state && root.state.wifiOn
              ? Util.alpha(Color.accent, 0.85)
              : Util.alpha(Color.foreground, 0.2)

            Rectangle {
              width: Style.space(14)
              height: width
              radius: width / 2
              y: (parent.height - height) / 2
              x: root.state && root.state.wifiOn ? parent.width - width - Style.space(2) : Style.space(2)
              color: "#ffffff"
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: if (root.state) root.state.toggle()
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: Util.alpha(Color.foreground, 0.12)
        }

        // Loaded only while the popup is open: the page turns the Wi-Fi scanner
        // on when it initialises, and a scanner should not run for a closed panel.
        Loader {
          id: pageLoader
          width: parent.width
          active: root.opened
          source: "deck/Page.qml"
          onLoaded: if (item) {
            item.state = root.state
            item.host = root.pageHost
          }
        }
      }
    }
  }

  function luaString(value) {
    return '"' + String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"'
  }

  Process {
    id: stockFocusProc
    property string requestedId: ""
    onExited: function(code) {
      var id = requestedId
      requestedId = ""
      if (code !== 0 || id === "") return
      root.close()
      Quickshell.execDetached(["omarchy-shell", "shell", "summon", id, "{}"])
    }
  }

  function openStockOnScreen(id) {
    if (!panel.screen || stockFocusProc.running) return false
    stockFocusProc.requestedId = String(id || "")
    stockFocusProc.command = ["hyprctl", "eval",
      "hl.dispatch(hl.dsp.focus({ monitor = " + luaString(panel.screen.name) + " }))"]
    stockFocusProc.running = true
    return true
  }

  readonly property QtObject pageHost: QtObject {
    readonly property bool open: root.opened
    function close() { root.close() }
    function notify(text) { console.log("wifi:", String(text)) }
    function openStock(id) { return root.openStockOnScreen(id) }
  }

  onStateChanged: if (pageLoader.item) pageLoader.item.state = root.state

  // The device only lists networks while its scanner is enabled, so scanning
  // is tied to the popup being open.
  onOpenedChanged: {
    if (root.state)
      root.state.setScanning(root.opened)
  }
}
