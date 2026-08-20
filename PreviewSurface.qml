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
}
