import Quickshell
import Quickshell.Wayland
import QtQuick

// Fullscreen visual preview -- the real thing's proportions without the lock.
//
// A layer-shell overlay covering the whole output, so the intro and the play
// surface can be judged at the size they will actually run at. Keyboard focus
// is OnDemand, NOT Exclusive: click in to type, and Escape always quits.
//
// That restraint is deliberate. Exclusive focus here would grab the keyboard
// of the real session with no compositor lock behind it and no watchdog, which
// is a worse failure than anything the lock path can do -- there would be no
// way to type the command to kill it. True input exclusivity belongs to the
// session lock, where it is contained and recoverable. Test that through
// dev-shell.qml in the nested compositor.
ShellRoot {
  PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: theme.background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omasmash-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Theme { id: theme }

    PlayView {
      anchors.fill: parent
      theme: theme
      active: true
      Keys.onEscapePressed: Qt.quit()
    }

    Text {
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      anchors.margins: 18
      text: "preview — Escape to quit"
      color: theme.muted
      font.pixelSize: 13
      opacity: 0.7
    }
  }
}
