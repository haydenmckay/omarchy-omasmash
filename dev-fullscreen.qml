import Quickshell
import Quickshell.Wayland
import QtQuick

// Fullscreen visual preview -- the real thing's proportions without the lock.
//
// Keyboard focus is OnDemand, NOT Exclusive: click in to type, Escape quits.
// That restraint is deliberate. Exclusive focus here would grab the real
// session's keyboard with no compositor lock behind it and no watchdog, which
// is a worse failure than anything the lock path can produce -- there would be
// no way to type the command to kill it. True input exclusivity belongs to the
// session lock, where it is contained and recoverable; test that through
// dev-shell.qml in the nested compositor.
ShellRoot {
  PanelWindow {
    anchors { top: true; bottom: true; left: true; right: true }
    color: theme.background
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omasmash-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Theme { id: theme }

    PreviewSurface {
      anchors.fill: parent
      theme: theme
      // Nothing to unlock, so completing the passphrase just leaves. It is
      // still the honest test: if the hint filled and this fired, the real
      // unlock would have fired too.
      onCompleted: Qt.quit()
    }

    Text {
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      anchors.margins: 18
      text: "preview — type the passphrase, or Escape, to quit"
      color: theme.foreground
      opacity: 0.6
      font.pixelSize: 13
    }
  }
}
