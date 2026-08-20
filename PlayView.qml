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

  // Mirrored from the service for the unlock hint. The hint shows how far in
  // you are, never what you have typed.
  property string passphrase: "omarchy"
  property int matchProgress: 0

  // Whether a keypress paints the character that was actually typed.
  //
  // Off by default, and that is a security decision rather than a style one.
  // The PAM fallback means a user may type their real password into this
  // surface -- and painting each character 220px tall is the most effective
  // shoulder-surfing attack imaginable. The burst is the delight here, not the
  // letter's identity, so a random glyph costs the toy nothing and closes the
  // leak completely. Turn it on only for a machine where nobody will ever type
  // a password into it.
  property bool revealTypedKeys: false
  readonly property string glyphPool: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

  function glyphFor(text) {
    if (revealTypedKeys) return text.toUpperCase()
    return glyphPool.charAt(Math.floor(Math.random() * glyphPool.length))
  }

  // Warp-in: the camera flies forward through a field of letters that are
  // themselves standing still. That distinction is the whole effect -- glyphs
  // do not travel outward from a point, they hold a fixed spot in space and
  // the perspective divide sweeps them off the edges as you close on them.
  //
  // Depth is a real projection: screen offset and scale are both focal/z, so
  // a constant camera speed produces the 1/z rush by itself. Nothing is eased
  // to fake acceleration.
  property bool introPlaying: false
  property int introGlyphs: 190
  property int introMs: 4600

  // Camera position along z. Everything else is derived from it.
  property real camZ: 0
  // Depth of the slab of letters. Glyphs wrap through it modulo this, so the
  // corridor is endless for free -- no spawning, no destroying, no churn.
  property real introSpan: 1800
  property real introNear: 80
  property real introFocal: 700
  property real introSpread: 720
  property real introMinRadius: 45

  // Maximum live sprites. A toddler generates input far faster than an adult,
  // and unbounded creation is how a toy turns into a wedged surface -- which
  // in a session lock means a locked-out parent.
  property int maxSprites: 48
  property int spriteCount: 0

  signal keyTyped(string text)
  signal submitRequested()
  signal cornerHeld()
  // Escape is always consumed -- nothing on a lock screen should act on it --
  // but it is reported so the dev previews, which are ordinary windows and do
  // need a way out, can quit on it.
  signal escapePressed()

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

  onActiveChanged: {
    if (active) {
      forceActiveFocus()
      // Deferred by one turn: when `active` is set as an initial binding it
      // can fire before `theme` has been assigned, and the intro needs the
      // palette. callLater runs after the surrounding assignments settle.
      Qt.callLater(playIntro)
    } else {
      introPlaying = false
    }
  }

  // Letters rushing past the camera. Each glyph accelerates outward from the
  // centre on its own heading, growing as it passes -- the depth cue is the
  // squared progress, which is what makes it read as travel rather than a
  // spread. Cheap: they are plain Texts destroyed on completion, and they are
  // deliberately kept out of the sprite budget so a warp can never starve the
  // toy that follows it.
  function playIntro() {
    if (!active || !theme) return
    camZ = 0
    introPlaying = true
    cameraAnim.restart()
  }

  // Impact. The flight ends by hitting something rather than parking: a flash,
  // two shockwaves and a spray of debris thrown out through the lens.
  //
  // Burst pieces live in their own layer and are exempt from the sprite cap.
  // They are bounded by construction -- a fixed count, each destroyed when its
  // animation ends -- so they cannot starve the toy the way uncapped keypress
  // sprites could.
  function playBurst() {
    if (!theme) return

    flash.fire()

    for (var r = 0; r < 3; r++) {
      burstRingComponent.createObject(burstField, {
        "tint": theme.randomCrayon(),
        "maxRadius": Math.max(width, height) * (0.55 + r * 0.28),
        "span": 620 + r * 220,
        "delay": r * 90,
        "thickness": 10 - r * 3
      })
    }

    var alphabet = passphrase.toUpperCase() + "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for (var i = 0; i < 34; i++) {
      var ang = (Math.PI * 2 * i) / 34 + Math.random() * 0.35
      burstGlyphComponent.createObject(burstField, {
        "label": alphabet.charAt(Math.floor(Math.random() * alphabet.length)),
        "tint": theme.randomCrayon(),
        "angle": ang,
        "distance": Math.max(width, height) * (0.35 + Math.random() * 0.55),
        "spin": (Math.random() * 720) - 360,
        "span": 700 + Math.floor(Math.random() * 450)
      })
    }
  }

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

  // Camera dolly: creeps at first, then piles on speed the whole way and
  // punches straight into the play surface at full tilt. Easing.InCubic is
  // the acceleration; the 1/z projection multiplies it, so the last second
  // covers more ground than the first three combined.
  //
  // It deliberately does not ease out. Arriving at speed and cutting is the
  // point -- decelerating to a stop reads as a screensaver, not an entrance.
  NumberAnimation {
    id: cameraAnim
    target: root
    property: "camZ"
    from: 0
    to: root.introSpan * 4.2
    duration: root.introMs
    easing.type: Easing.InCubic
    onFinished: {
      root.introPlaying = false
      root.playBurst()
    }
  }

  Item {
    id: introField
    anchors.fill: parent
    visible: root.introPlaying
    // Lift the whole field out at the end so the last few glyphs do not
    // simply vanish when the animation stops.
    opacity: root.introPlaying ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 320 } }

    Repeater {
      model: root.introPlaying ? root.introGlyphs : 0

      Text {
        id: star

        property real wx: 0
        property real wy: 0
        property real wz: 0

        // Fixed world position, chosen once. A minimum radius keeps glyphs off
        // the dead centre of the screen, where a projected point never moves
        // and the illusion collapses.
        Component.onCompleted: {
          var alphabet = root.passphrase.toUpperCase() + "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
          var ang = Math.random() * Math.PI * 2
          var rad = root.introMinRadius + Math.random() * root.introSpread
          wx = Math.cos(ang) * rad
          wy = Math.sin(ang) * rad
          wz = Math.random() * root.introSpan
          text = alphabet.charAt(Math.floor(Math.random() * alphabet.length))
          color = root.theme.randomCrayon()
        }

        // Wrapping depth: as the camera advances this falls towards `near`,
        // then rolls back to the far plane, so the same 190 objects supply an
        // endless corridor. Named `dz` rather than `z` -- Item.z is FINAL and
        // shadowing it fails to load the whole component.
        readonly property real dz: {
          var d = star.wz - root.camZ
          var s = root.introSpan
          return root.introNear + ((d % s) + s) % s
        }
        readonly property real k: root.introFocal / dz
        // 0 at the camera, 1 at the far plane.
        readonly property real depth01: (dz - root.introNear) / root.introSpan

        font.pixelSize: 40
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        x: introField.width / 2 - width / 2 + wx * k
        y: introField.height / 2 - height / 2 + wy * k
        scale: k

        // Fade in out of the far haze, blow out as it sweeps past the lens.
        opacity: depth01 < 0.07
                 ? depth01 / 0.07
                 : (depth01 > 0.90 ? (1 - depth01) / 0.10 : 1)
      }
    }
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

      if (event.key === Qt.Key_Escape) {
        root.escapePressed()
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
      root.burst(root.glyphFor(label),
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
      // Sized to comfortably contain the visible affordance -- pointing at
      // the thing that says "hold here" has to be what triggers it.
      var near = (x >= width - Math.max(root.cornerSize, cornerHint.width + 36)
                  && y <= Math.max(root.cornerSize, cornerHint.height + 36))
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

  // Corner-hold affordance, top right.
  //
  // It used to be invisible until the pointer was already inside the hot
  // corner, which meant the only people who could find it were people who had
  // read the source. An unlock route nobody can discover is not an unlock
  // route. It sits there quietly, and fills as you hold.
  Rectangle {
    id: cornerHint
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: 18
    width: cornerLabel.implicitWidth + 28
    height: cornerLabel.implicitHeight + 20
    radius: 10
    color: root.theme ? root.theme.background : "#1a1b26"
    opacity: (root.active && !root.introPlaying) ? (cornerWatch.inCorner ? 0.95 : 0.62) : 0
    border.width: 1
    border.color: root.theme ? root.theme.accent : "#7aa2f7"
    Behavior on opacity { NumberAnimation { duration: 200 } }

    Text {
      id: cornerLabel
      anchors.centerIn: parent
      text: cornerWatch.inCorner ? "keep holding…" : "or hold here"
      color: root.theme ? root.theme.foreground : "#a9b1d6"
      opacity: 0.85
      font.pixelSize: 13
      font.letterSpacing: 1
    }

    // Fills left to right as the hold completes, same gauge language as the
    // passphrase below the word on the other side of the screen.
    Rectangle {
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      anchors.leftMargin: 1
      anchors.bottomMargin: 1
      height: 3
      radius: 1.5
      width: (parent.width - 2) * Math.min(1, cornerWatch.progress)
      color: root.theme ? root.theme.accent : "#7aa2f7"
    }
  }

  Item {
    id: burstField
    anchors.fill: parent
  }

  // Full-frame flash at the moment of impact.
  //
  // Short, bright, and deliberately not opaque. The first version peaked at
  // 0.85 in `foreground`, which on a dark theme is a mid-tone -- so instead of
  // a punch it laid a coloured veil over the frame for half a second and
  // desaturated the whole impact. A flash should be over before you can name
  // its colour: hit fast, peak below half, get out.
  Rectangle {
    id: flash
    anchors.fill: parent
    color: root.theme ? root.theme.flash : "#ffffff"
    opacity: 0

    function fire() { flashAnim.restart() }

    SequentialAnimation {
      id: flashAnim
      NumberAnimation { target: flash; property: "opacity"; from: 0; to: 0.45; duration: 40 }
      NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 190; easing.type: Easing.OutCubic }
    }
  }

  // ---- unlock hint ---------------------------------------------------
  // Deliberately obvious. The threat model is a toddler, not a stranger --
  // there is nothing to gain by hiding the passphrase, and a parent holding a
  // squirming child should not have to remember anything. Fills in as you go,
  // hangman style.
  // Backing plate. `muted` is not reliably legible -- in plenty of themes it
  // sits a few percent off the background -- and the hint has to survive both
  // an arbitrary wallpaper behind it and whatever palette the user is running.
  // A plate in the theme's own background colour guarantees the contrast that
  // foreground-on-background is defined to have.
  Rectangle {
    anchors.fill: hint
    anchors.margins: -18
    radius: 14
    color: root.theme ? root.theme.background : "#1a1b26"
    opacity: hint.opacity * 0.72
    border.width: 1
    border.color: root.theme ? root.theme.accent : "#7aa2f7"
    z: hint.z - 1
    visible: hint.opacity > 0
  }

  Column {
    id: hint
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: 42
    anchors.topMargin: 38
    spacing: 10
    opacity: (root.active && !root.introPlaying) ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 450 } }

    Text {
      text: "type to unlock"
      color: root.theme ? root.theme.foreground : "#a9b1d6"
      opacity: 0.75
      font.pixelSize: 15
      font.letterSpacing: 2
    }

    // The word fills like a gauge rather than lighting letter by letter: one
    // dim copy of the passphrase, with a bright copy clipped to the progress
    // fraction laid exactly on top. Both are the same Text with the same
    // metrics, so the bright glyphs land pixel-for-pixel on the dim ones and
    // the boundary can fall mid-letter -- which is what makes it read as
    // filling up instead of stepping.
    Item {
      width: passLabel.implicitWidth
      height: passLabel.implicitHeight

      readonly property real fraction: root.passphrase.length > 0
                                       ? Math.min(1, root.matchProgress / root.passphrase.length)
                                       : 0

      Text {
        id: passLabel
        text: root.passphrase.toUpperCase()
        font.pixelSize: 34
        font.bold: true
        font.letterSpacing: 8
        color: root.theme ? root.theme.foreground : "#a9b1d6"
        opacity: 0.32
      }

      Item {
        height: parent.height
        width: parent.width * parent.fraction
        clip: true
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Text {
          text: passLabel.text
          font: passLabel.font
          color: root.theme ? root.theme.accent : "#7aa2f7"
        }
      }
    }

    // Matching gauge under the word.
    Item {
      width: passLabel.implicitWidth
      height: 3

      Rectangle {
        anchors.fill: parent
        radius: 1.5
        color: root.theme ? root.theme.foreground : "#a9b1d6"
        opacity: 0.22
      }

      Rectangle {
        height: parent.height
        radius: 1.5
        width: parent.width * (root.passphrase.length > 0
                               ? Math.min(1, root.matchProgress / root.passphrase.length)
                               : 0)
        color: root.theme ? root.theme.accent : "#7aa2f7"
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
      }
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
    id: burstRingComponent
    Rectangle {
      id: bring
      property color tint: "white"
      property real maxRadius: 400
      property int span: 700
      property int delay: 0
      property real thickness: 8
      property real radius_: 0

      x: burstField.width / 2 - radius_
      y: burstField.height / 2 - radius_
      width: radius_ * 2
      height: radius_ * 2
      radius: radius_
      color: "transparent"
      border.color: tint
      border.width: thickness
      opacity: 0

      SequentialAnimation {
        running: true
        PauseAnimation { duration: bring.delay }
        ParallelAnimation {
          NumberAnimation { target: bring; property: "radius_"; from: 0; to: bring.maxRadius; duration: bring.span; easing.type: Easing.OutQuad }
          NumberAnimation { target: bring; property: "opacity"; from: 0.95; to: 0; duration: bring.span }
        }
        onFinished: bring.destroy()
      }
    }
  }

  Component {
    id: burstGlyphComponent
    Text {
      id: shard
      property string label: ""
      property color tint: "white"
      property real angle: 0
      property real distance: 400
      property real spin: 0
      property int span: 800
      property real progress: 0

      text: label
      color: tint
      font.pixelSize: 72
      font.bold: true
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter

      x: burstField.width / 2 - width / 2 + Math.cos(angle) * distance * progress
      y: burstField.height / 2 - height / 2 + Math.sin(angle) * distance * progress
      rotation: spin * progress
      scale: 0.35 + progress * 1.5
      opacity: 1 - (progress * progress)

      NumberAnimation on progress {
        from: 0; to: 1
        duration: shard.span
        easing.type: Easing.OutCubic
        onFinished: shard.destroy()
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
