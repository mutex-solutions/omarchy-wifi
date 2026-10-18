import QtQuick

// Deck adapter: the five members Deck reads, forwarded to the shared State.
Item {
  id: s

  readonly property var state: stateLoader.item

  readonly property bool active: state ? state.active : false
  readonly property string label: state ? state.label : ""
  readonly property string detail: state ? state.detail : ""
  readonly property string icon: state ? state.icon : ""

  function toggle() {
    if (state) state.toggle()
  }

  Loader {
    id: stateLoader
    source: "../State.qml"
  }
}
