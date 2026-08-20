import Quickshell
import QtQuick

// Visual iteration harness -- a plain desktop window, no session lock, no
// nested compositor.
//
// The lock path is proven (docs/premise-test.md) and does not need re-proving
// every time a colour changes. Designing the play surface through a session
// lock means a nested Hyprland, an IPC round trip and a real lock for every
// tweak; here it is just a window you can close. Anything touching the lock
// lifecycle still has to be tested through dev-shell.qml in the nested
// compositor -- this harness cannot tell you anything about that.
ShellRoot {
  FloatingWindow {
    title: "Omasmash — preview"
    implicitWidth: 1280
    implicitHeight: 800
    color: theme.background

    Theme { id: theme }

    PlayView {
      anchors.fill: parent
      theme: theme
      active: true

      // No lock to release, so unlocking is meaningless here. Report instead,
      // so the passphrase and corner paths can still be exercised by eye.
      onKeyTyped: function(text) { progress.bump() }
      onCornerHeld: progress.note("corner-hold fired")
      onSubmitRequested: progress.note("Enter -> PAM submit")
    }

    QtObject {
      id: progress
      function bump() {}
      function note(what) { console.log("omasmash preview: " + what) }
    }
  }
}
