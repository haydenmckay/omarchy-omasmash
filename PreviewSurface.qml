import QtQuick
import "Match.js" as Match

// PlayView wired for the dev previews.
//
// There is no Service here and nothing to unlock, but the hint has to fill in
// or the previews cannot show the one interaction worth looking at. Scoring
// goes through the same Match.js the service uses, so what you see here is
// what the real unlock will do.
PlayView {
  id: surface

  property string buffer: ""
  signal completed()

  // Self-driving mode, for capturing stills and the demo GIF.
  //
  // It calls the surface's own burst/splash functions directly rather than
  // synthesising input at the compositor. That is not a shortcut: injecting
  // keystrokes into a live session collides with whatever the person at the
  // keyboard is actually doing. This drives the same code path a real key
  // press drives, so the capture is honest.
  property bool demo: false

  active: true
  matchProgress: Match.progress(buffer, passphrase)

  onKeyTyped: function(text) {
    buffer = (buffer + text).slice(-64)
    if (matchProgress >= passphrase.length) {
      completed()
      buffer = ""
    }
  }

  onSubmitRequested: buffer = ""
  onEscapePressed: Qt.quit()
  onCornerHeld: completed()

  Timer {
    // Held off until the warp lands, so the intro is never fighting the demo.
    running: surface.demo && !surface.introPlaying
    interval: 230
    repeat: true

    readonly property string alphabet: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    onTriggered: {
      var w = surface.width
      var h = surface.height
      if (Math.random() < 0.22) {
        surface.splash(w * (0.15 + Math.random() * 0.7),
                       h * (0.2 + Math.random() * 0.6))
        return
      }
      surface.burst(alphabet.charAt(Math.floor(Math.random() * alphabet.length)),
                    w * (0.12 + Math.random() * 0.76),
                    h * (0.14 + Math.random() * 0.68))
    }
  }
}
