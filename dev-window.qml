import Quickshell
import QtQuick

// Windowed visual iteration harness -- no session lock, no nested compositor.
//
// The lock path is proven (docs/premise-test.md) and does not need re-proving
// every time a colour changes. Anything touching the lock lifecycle still has
// to go through dev-shell.qml in the nested compositor; this harness can tell
// you nothing about that.
ShellRoot {
  FloatingWindow {
    title: "Omasmash — preview"
    implicitWidth: 1280
    implicitHeight: 800
    color: theme.background

    Theme { id: theme }

    PreviewSurface {
      anchors.fill: parent
      theme: theme
      // Completing the passphrase ends the preview, the same way it ends the
      // lock. Leaving the window open after a successful unlock would be the
      // one thing the preview must not teach.
      onCompleted: Qt.quit()
    }
  }
}
