import QtQuick

// The play surface. Purely reactive: it renders and reports, it never decides
// whether the session is locked. Every colour on screen comes from the user's
// active Omarchy theme -- that is the deliberate difference from babysmash.io,
// which can only ever look like babysmash.io.
FocusScope {
  id: root

  property Theme theme
  property bool active: false
  property int cornerHoldMs: 3000
  property int cornerSize: 96

  // Maximum live sprites. A toddler generates input far faster than an adult,
  // and unbounded creation is how a toy turns into a wedged surface -- which
  // in a session lock means a locked-out parent.
  property int maxSprites: 48
  property int spriteCount: 0

  signal keyTyped(string text)
  signal submitRequested()
  signal cornerHeld()

  // Render-loop canary for the service watchdog. An animation only advances
  // when frames are actually being produced, so this freezing is a truthful
  // signal that the surface has stopped painting -- unlike a Timer, which
  // keeps ticking on a surface that renders nothing.
  property real canary: 0
  NumberAnimation on canary {
    from: 0; to: 100000
    duration: 200000
    loops: Animation.Infinite
    running: true
  }

  function fileUrl(path, version) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + version
  }

  function spawn(component, props) {
    if (spriteCount >= maxSprites) return null
    var obj = component.createObject(playfield, props)
    if (obj) spriteCount += 1
    return obj
  }

  function retire(obj) {
    spriteCount = Math.max(0, spriteCount - 1)
    obj.destroy()
  }

  function burst(text, x, y) {
    spawn(glyphComponent, {
      "label": text,
      "x": x, "y": y,
      "tint": theme.randomCrayon(),
      "spin": (Math.random() * 40) - 20
    })
    spawn(ringComponent, {
      "cx": x, "cy": y,
      "tint": theme.randomCrayon(),
      "maxRadius": 140 + Math.random() * 120
    })
  }

  function splash(x, y) {
    spawn(ringComponent, { "cx": x, "cy": y, "tint": theme.randomCrayon(), "maxRadius": 220 })
    var petals = 6
    for (var i = 0; i < petals; i++) {
      var angle = (Math.PI * 2 * i) / petals + Math.random()
      var dist = 70 + Math.random() * 110
      spawn(dotComponent, {
        "x": x, "y": y,
        "targetX": x + Math.cos(angle) * dist,
        "targetY": y + Math.sin(angle) * dist,
        "tint": theme.randomCrayon()
      })
    }
  }

  onActiveChanged: if (active) forceActiveFocus()

  // ---- backdrop ------------------------------------------------------
  Rectangle {
    anchors.fill: parent
    color: root.theme ? root.theme.background : "#1a1b26"
  }

  // The user's own wallpaper, dimmed. Keeping it -- rather than a flat colour
  // -- is what makes this read as *their* desktop at play rather than a
  // generic kids app that has taken the machine over.
  Image {
    id: wallpaper
    anchors.fill: parent
    source: root.theme ? root.fileUrl(root.theme.backgroundImage, root.theme.backgroundVersion) : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    visible: status === Image.Ready
    opacity: 0.35
  }

  // Scrim in the theme's own background colour, so glyphs stay legible over
  // whatever the wallpaper happens to be doing underneath them.
  Rectangle {
    anchors.fill: parent
    color: root.theme ? root.theme.background : "#1a1b26"
    opacity: 0.45
  }

  Item {
    id: playfield
    anchors.fill: parent
  }

  // ---- input ---------------------------------------------------------
  Item {
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (!root.active) return
      event.accepted = true

      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        root.submitRequested()
        return
      }

      var label = event.text
      // Control characters and modifier-only presses have no glyph. Still
      // reward them with a splash so every key does *something* -- an
      // unresponsive key is the one a toddler hits forty more times.
      if (!label || label.length === 0 || label.charCodeAt(0) < 32) {
        if (event.isAutoRepeat) return
        root.splash(playfield.width * (0.2 + Math.random() * 0.6),
                    playfield.height * (0.2 + Math.random() * 0.6))
        return
      }

      root.keyTyped(label)
      root.burst(label.toUpperCase(),
                 playfield.width * (0.12 + Math.random() * 0.76),
                 playfield.height * (0.14 + Math.random() * 0.68))
    }
  }

  MouseArea {
    id: pointer
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    property real lastTrailX: -1
    property real lastTrailY: -1

    onPressed: function(mouse) { root.splash(mouse.x, mouse.y) }

    onPositionChanged: function(mouse) {
      cornerWatch.update(mouse.x, mouse.y)
      if (!pressed) return
      if (lastTrailX >= 0 && Math.abs(mouse.x - lastTrailX) + Math.abs(mouse.y - lastTrailY) < 26) return
      lastTrailX = mouse.x
      lastTrailY = mouse.y
      root.spawn(dotComponent, {
        "x": mouse.x, "y": mouse.y,
        "targetX": mouse.x, "targetY": mouse.y + 40,
        "tint": root.theme.randomCrayon()
      })
    }

    onReleased: { lastTrailX = -1; lastTrailY = -1 }
    onExited: cornerWatch.reset()
  }

  // ---- corner-hold unlock --------------------------------------------
  // Deliberately silent and unlabelled: an adult who knows can find it, a
  // toddler flailing cannot hold a 96px corner still for three seconds.
  QtObject {
    id: cornerWatch
    property bool inCorner: false
    property real progress: 0

    function reset() { inCorner = false; progress = 0; cornerTimer.stop() }

    function update(x, y) {
      if (!root.active) return
      var near = (x <= root.cornerSize && y <= root.cornerSize)
      if (near === inCorner) return
      inCorner = near
      if (near) { progress = 0; cornerTimer.restart() } else { progress = 0; cornerTimer.stop() }
    }
  }

  Timer {
    id: cornerTimer
    interval: 50
    repeat: true
    onTriggered: {
      cornerWatch.progress += interval / root.cornerHoldMs
      if (cornerWatch.progress >= 1) {
        cornerWatch.reset()
        root.cornerHeld()
      }
    }
  }

  Rectangle {
    x: 0; y: 0
    width: root.cornerSize; height: 4
    color: root.theme ? root.theme.accent : "#7aa2f7"
    opacity: cornerWatch.inCorner ? 0.85 : 0
    scale: 1
    transformOrigin: Item.Left
    Behavior on opacity { NumberAnimation { duration: 150 } }

    Rectangle {
      anchors.left: parent.left
      height: parent.height
      width: parent.width * Math.min(1, cornerWatch.progress)
      color: parent.color
    }
  }

  // ---- sprites -------------------------------------------------------
  Component {
    id: glyphComponent
    Text {
      id: glyph
      property string label: ""
      property color tint: "white"
      property real spin: 0

      text: label
      color: tint
      font.pixelSize: 220
      font.bold: true
      transformOrigin: Item.Center
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter

      scale: 0
      opacity: 0

      ParallelAnimation {
        running: true
        SequentialAnimation {
          NumberAnimation { target: glyph; property: "scale"; from: 0; to: 1.15; duration: 220; easing.type: Easing.OutBack }
          NumberAnimation { target: glyph; property: "scale"; to: 1.0; duration: 140 }
          PauseAnimation { duration: 700 }
          NumberAnimation { target: glyph; property: "scale"; to: 1.4; duration: 500; easing.type: Easing.InQuad }
        }
        SequentialAnimation {
          NumberAnimation { target: glyph; property: "opacity"; from: 0; to: 1; duration: 180 }
          PauseAnimation { duration: 880 }
          NumberAnimation { target: glyph; property: "opacity"; to: 0; duration: 500 }
        }
        NumberAnimation { target: glyph; property: "rotation"; from: 0; to: glyph.spin; duration: 1560 }

        onFinished: root.retire(glyph)
      }
    }
  }

  Component {
    id: ringComponent
    Rectangle {
      id: ring
      property real cx: 0
      property real cy: 0
      property color tint: "white"
      property real maxRadius: 160
      property real radius_: 0

      x: cx - radius_
      y: cy - radius_
      width: radius_ * 2
      height: radius_ * 2
      radius: radius_
      color: "transparent"
      border.color: tint
      border.width: 6
      opacity: 0.9

      ParallelAnimation {
        running: true
        NumberAnimation { target: ring; property: "radius_"; from: 0; to: ring.maxRadius; duration: 700; easing.type: Easing.OutCubic }
        NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: 700 }
        onFinished: root.retire(ring)
      }
    }
  }

  Component {
    id: dotComponent
    Rectangle {
      id: dot
      property real targetX: 0
      property real targetY: 0
      property color tint: "white"

      width: 26; height: 26
      radius: 13
      color: tint

      ParallelAnimation {
        running: true
        NumberAnimation { target: dot; property: "x"; to: dot.targetX; duration: 620; easing.type: Easing.OutCubic }
        NumberAnimation { target: dot; property: "y"; to: dot.targetY; duration: 620; easing.type: Easing.OutCubic }
        NumberAnimation { target: dot; property: "opacity"; from: 1; to: 0; duration: 620 }
        NumberAnimation { target: dot; property: "scale"; from: 1.2; to: 0.3; duration: 620 }
        onFinished: root.retire(dot)
      }
    }
  }
}
