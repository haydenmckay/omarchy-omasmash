import QtQuick
import Quickshell
import Quickshell.Io

// Live view of the active Omarchy theme, for the play surface.
//
// The shell's own `qs.Commons` Color singleton only surfaces five roles
// (foreground/background/accent/urgent/muted) because that is all a bar needs.
// A play surface wants the whole crayon box, so this parses theme/colors.toml
// directly and exposes every colour the theme ships.
//
// Color.qml deliberately sets watchChanges:false and takes theme swaps over
// shell IPC instead. A standalone instance gets no such IPC, so this watches
// `theme.name` -- the file the theme switcher rewrites last -- and re-reads
// the palette from the freshly repointed symlink when it changes.
QtObject {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: home + "/.local/state"
  readonly property string currentPath: stateHome + "/omarchy/current"
  readonly property string themePath: currentPath + "/theme"

  property string name: ""
  property string mode: "dark"

  property color background: "#1a1b26"
  property color foreground: "#a9b1d6"
  property color accent: "#7aa2f7"
  property color muted: "#414868"

  // Every non-background, non-neutral colour the theme defines, in file order.
  // This is what letters and splashes are painted with.
  property var crayons: ["#f7768e", "#e0af68", "#9ece6a", "#7aa2f7", "#ad8ee6"]

  // Resolved (readlink -f) path to the active wallpaper. Empty until probed.
  property string backgroundImage: ""
  // Bumped on every resolve so Image consumers can bust their cache when the
  // symlink is repointed at a file the loader has already seen.
  property int backgroundVersion: 0

  signal reloaded()

  function crayon(i) {
    var list = root.crayons
    if (!list || list.length === 0) return root.accent
    var n = Math.floor(i)
    return list[((n % list.length) + list.length) % list.length]
  }

  function randomCrayon() {
    return crayon(Math.floor(Math.random() * 1000))
  }

  // Keys that describe the canvas rather than the paint. Excluded from crayons
  // so letters never come out background-on-background and vanish.
  readonly property var structuralKeys: ({
    "background": true, "dark_background": true, "darker_background": true,
    "lighter_background": true, "selection": true, "muted": true,
    "dark_foreground": true, "mode": true
  })

  function parseColors(raw) {
    var text = String(raw || "")
    if (!text) return

    var picked = []
    var seen = ({})
    var lines = text.split("\n")

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].replace(/^\s+|\s+$/g, "")
      if (!line || line.charAt(0) === "#") continue

      var kv = line.match(/^([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{3,8}|[A-Za-z]+)["']?\s*(#.*)?$/)
      if (!kv) continue

      var key = kv[1]
      var value = kv[2]

      if (key === "mode") { root.mode = value; continue }
      if (key === "background") { root.background = value; continue }
      if (key === "foreground") { root.foreground = value; continue }
      if (key === "accent") { root.accent = value; continue }
      if (key === "muted") { root.muted = value; continue }

      if (root.structuralKeys[key]) continue
      if (value.charAt(0) !== "#") continue
      // Themes ship `blue` and `bright_blue` as near-twins; dedupe so one hue
      // does not get twice the odds of being drawn.
      if (seen[value.toLowerCase()]) continue

      seen[value.toLowerCase()] = true
      picked.push(value)
    }

    // A theme with an unusually sparse colors.toml still has to paint. Fall
    // back to the roles we always have rather than shipping an empty box.
    if (picked.length < 3) picked = [root.accent, root.foreground, root.accent]

    root.crayons = picked
    root.reloaded()
  }

  property Process resolveBackgroundProc: Process {
    command: ["readlink", "-f", root.currentPath + "/background"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var next = String(text || "").trim()
        if (next.length === 0) return
        root.backgroundImage = next
        root.backgroundVersion += 1
      }
    }
  }

  function refresh() {
    if (!resolveBackgroundProc.running) resolveBackgroundProc.running = true
    colorsFile.reload()
  }

  property FileView colorsFile: FileView {
    id: colorsFile
    path: root.themePath + "/colors.toml"
    watchChanges: true
    printErrors: false
    onLoaded: root.parseColors(text())
    onFileChanged: reload()
  }

  // The theme switcher rewrites this after repointing the symlinks, so it is
  // the reliable "a new theme has fully landed" edge.
  property FileView themeNameFile: FileView {
    path: root.currentPath + "/theme.name"
    watchChanges: true
    printErrors: false
    onLoaded: {
      root.name = String(text() || "").trim()
      root.refresh()
    }
    onFileChanged: reload()
  }

  Component.onCompleted: refresh()
}
