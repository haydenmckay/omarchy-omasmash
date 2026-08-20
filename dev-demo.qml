import Quickshell
import Quickshell.Wayland
import QtQuick

// Capture harness: the play surface driving itself, fullscreen.
//
// Fullscreen rather than a window because Hyprland tiles windows to whatever
// the operator's layout happens to be, which makes captured assets depend on
// the desktop they were shot on. An output-sized overlay is the same shape
// every time, and it is the shape the plugin actually runs at.
//
// OnDemand keyboard focus and Escape-to-quit, same as the other previews --
// nothing here should be able to trap the session. Not part of the plugin.
ShellRoot {
  PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: theme.background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omasmash-demo"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Theme { id: theme }

    // Brief hold so the recorder catches the warp from its first frame --
    // quickshell's startup alone is enough to eat the whole flight otherwise.
    // Kept short on purpose: this overlay covers the operator's screen while
    // it runs, and a longer gate just looks like the thing has hung.
    //
    // Referenced as `win.started`, not bare `started`: Quickshell reparents a
    // PanelWindow's children into an internal content item, so the scope chain
    // never reaches the window's own properties. Bare references resolve to
    // nothing and fail at runtime with "started is not defined" -- which is
    // silent in qmllint and shows up only as a surface that does nothing.
    property bool started: false

    Timer {
      interval: 1200
      running: true
      repeat: false
      onTriggered: win.started = true
    }

    PreviewSurface {
      anchors.fill: parent
      theme: theme
      active: win.started
      demo: win.started
      onCompleted: Qt.quit()
    }
  }
}
