import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "Match.js" as Match

// Omasmash -- a lock screen that plays instead of asking for a password.
//
// The whole product rests on one property: ext-session-lock-v1 is
// compositor-enforced input exclusivity. While locked, nothing else on the
// system sees keyboard or pointer input. That is what a browser tab can never
// offer, and it is why a toddler cannot escape this the way they escape
// babysmash.io.
//
// The same property is the danger. If this client dies while locked, the
// compositor KEEPS the screen locked -- that is the security guarantee working
// as designed, and for a toy it is a real risk of locking a parent out of
// their own machine. Everything in the SAFETY section below exists for that.
Item {
  id: root

  // Set by the shell when running as an installed plugin; unused standalone.
  property var shell: null
  property string omarchyPath: ""

  readonly property string home: Quickshell.env("HOME")
  readonly property string userName: Quickshell.env("USER") || Quickshell.env("LOGNAME")

  property Theme theme: Theme {}

  // ---- configuration -------------------------------------------------
  // Seven characters in sequence is effectively unreachable by random
  // smashing, which is the entire threat model.
  property string passphrase: "omarchy"
  // Holding still in a small corner for three continuous seconds is
  // discoverable for an adult and near-impossible while flailing.
  property int cornerHoldMs: 3000
  property int cornerSize: 96

  // ---- state ---------------------------------------------------------
  property bool lockRequested: false
  property bool pendingSessionLock: false
  property bool passwordPamConfigured: false
  property bool authenticatingPassword: false
  property string pendingPassword: ""
  property int failedAttempts: 0
  property string lastEvent: "init"
  property string lastEventAt: ""
  property bool strandedLock: false
  property bool strandedLockResolved: false
  property bool hotkeysBlocked: false

  // The play surface lives inside WlSessionLockSurface, which the compositor
  // instantiates per output only while locked. Its `id` is NOT resolvable from
  // this scope -- referencing it here throws, silently, at runtime.
  //
  // That is not a style point. The watchdog timer used to sample
  // `playSurface.canary` directly, so every sample threw and the watchdog
  // never observed anything: the one safety net covering a wedged surface was
  // dead code that looked alive, and only trying to prove it worked found it.
  //
  // So the surface pushes its canary up here, and takes the stall flag back
  // down. Both directions cross the boundary through root properties, which do
  // resolve from inside the lock surface.
  property real surfaceCanary: -1
  property bool stallRequested: false

  // Rolling window of recent keystrokes. Never displayed, never logged.
  property string keyBuffer: ""
  // How many leading characters of the passphrase the user currently has
  // typed, for the on-screen hint. Recomputed from the buffer rather than
  // counted up, so a wrong key falls back to the longest still-valid prefix
  // instead of resetting to zero -- typing "omom" leaves you two in, not out.
  property int matchProgress: 0

  // Deliberately does NOT include sessionLock.secure. `secure` latches true
  // once the compositor has confirmed the lock and does not clear on unlock,
  // so folding it in here made `locked` sticky: isLocked reported true after a
  // clean unlock and the next lock() was refused as "already-locked". It stays
  // in status() as a diagnostic, but it is not a lock indicator.
  readonly property bool locked: lockRequested || sessionLock.locked

  signal unlockedByPassphrase()
  signal unlockedByCorner()
  signal unlockedByWatchdog()

  function logEvent(event) {
    lastEvent = event
    lastEventAt = new Date().toISOString()
    console.log("omasmash " + lastEventAt + " " + event)
  }

  function realScreenCount() {
    var screens = Quickshell.screens || []
    var count = 0
    for (var i = 0; i < screens.length; i++) {
      var s = screens[i]
      if (s && s.name && s.width > 0 && s.height > 0) count += 1
    }
    return count
  }

  // ---- lock lifecycle ------------------------------------------------
  // Outputs are frequently not settled at the moment a lock is asked for, and
  // locking with no real screen strands the session. Both timers below exist
  // to wait that out rather than lock blind -- the same shape omarchy.lock
  // arrived at, and for the same reason.
  function beginLock() {
    if (locked) return false

    keyBuffer = ""
    matchProgress = 0
    failedAttempts = 0
    stallRequested = false
    surfaceCanary = -1
    lockRequested = true
    logEvent("lock-requested")
    theme.refresh()
    queueSessionLock()
    watchdog.arm()
    blockHotkeys()
    return true
  }

  function queueSessionLock() {
    pendingSessionLock = true
    stabilizeTimer.restart()
    if (!pendingLockTimer.running) pendingLockTimer.start()
  }

  function requestSessionLock() {
    if (!lockRequested || sessionLock.locked || sessionLock.secure) return
    if (stabilizeTimer.running) return

    if (realScreenCount() === 0) {
      if (lastEvent !== "lock-pending: no-real-screen") logEvent("lock-pending: no-real-screen")
      pendingSessionLock = true
      if (!pendingLockTimer.running) pendingLockTimer.start()
      return
    }

    pendingSessionLock = false
    pendingLockTimer.stop()
    sessionLock.locked = true
  }

  function finishUnlock(reason) {
    if (!locked && !lockRequested) return

    lockRequested = false
    pendingSessionLock = false
    stabilizeTimer.stop()
    pendingLockTimer.stop()
    watchdog.disarm()
    releaseHotkeys()
    keyBuffer = ""
    matchProgress = 0
    pendingPassword = ""
    authenticatingPassword = false
    if (passwordPam.active) passwordPam.abort()
    sessionLock.locked = false
    logEvent("unlocked: " + reason)
  }

  // ---- unlock paths --------------------------------------------------
  // Three ways out, deliberately. The passphrase is the everyday one, the
  // corner hold is the one you can find when you have forgotten the
  // passphrase, and PAM is the one that always works.
  function handleKey(text) {
    if (!lockRequested) return
    if (!text || text.length === 0) return

    keyBuffer = (keyBuffer + text).slice(-64)
    matchProgress = computeMatch()

    if (passphrase.length > 0 && matchProgress >= passphrase.length) {
      unlockedByPassphrase()
      finishUnlock("passphrase")
    }
  }

  // Case-insensitive: a parent reaching over a toddler should not be defeated
  // by caps lock. The buffer itself stays raw, because PAM needs it verbatim.
  function computeMatch() {
    return Match.progress(keyBuffer, passphrase)
  }

  // Enter submits whatever has accumulated to PAM. This gives a real password
  // fallback with no visible field at all: type your password, press Enter.
  // A toddler hitting Enter just fails harmlessly and the buffer resets.
  function submitBufferToPam() {
    if (!lockRequested || authenticatingPassword) return

    var candidate = keyBuffer
    keyBuffer = ""
    matchProgress = 0
    if (candidate.length === 0 || !passwordPamConfigured) return

    pendingPassword = candidate
    authenticatingPassword = true
    if (!passwordPam.start()) {
      authenticatingPassword = false
      pendingPassword = ""
      failedAttempts += 1
      return
    }
    Qt.callLater(respondToPasswordPrompt)
  }

  function respondToPasswordPrompt() {
    if (!authenticatingPassword || !passwordPam.active || !passwordPam.responseRequired) return
    passwordPam.respond(pendingPassword)
  }

  function cornerHoldCompleted() {
    if (!lockRequested) return
    unlockedByCorner()
    finishUnlock("corner-hold")
  }

  // ---- compositor hotkeys --------------------------------------------
  // ext-session-lock stops input reaching other *clients*, but Hyprland
  // handles its own keybinds before delivery, so SUPER+Q and friends still
  // fire while locked. A toddler can close windows through a lock screen.
  //
  // A submap fixes it: while one is active only its own binds resolve, so an
  // almost-empty submap makes all ~234 system binds inert. It must contain at
  // least one bind to register at all -- an empty submap silently does not
  // exist -- and that one bind is spent on the panic chord, because a process
  // that dies holding the submap leaves a desktop with no shortcuts.
  //
  // Note the two different "reset"s below: `keyword submap reset` closes the
  // definition block, `dispatch submap reset` returns to the default map.
  // Resolved from this file's own location, so it is correct whether the
  // plugin was installed by `omarchy plugin add` into
  // ~/.config/omarchy/plugins/<id>/ or is running from a dev checkout. It was
  // previously hardcoded to the author's ~/Work path, which meant the panic
  // chord -- the one keyboard route back when the submap has made every other
  // bind inert -- pointed at a file that does not exist on anybody else's
  // machine. That is the single worst thing in this plugin to get wrong.
  readonly property string pluginDir: {
    var dir = Qt.resolvedUrl(".").toString()
    if (dir.indexOf("file://") === 0) dir = dir.substring(7)
    return decodeURIComponent(dir.replace(/\/$/, ""))
  }
  readonly property string panicScript: pluginDir + "/bin/omasmash-panic"
  readonly property string panicBind: "SUPER CTRL ALT SHIFT, Escape, exec, " + panicScript

  // `hyprctl keyword bind` appends, so re-registering on every lock grows the
  // submap without bound. Register once per process, then just switch into it.
  property bool submapRegistered: false

  function blockHotkeys() {
    if (hotkeysBlocked) return
    if (!submapRegistered) {
      submapEnter.running = true
      submapRegistered = true
    } else {
      submapActivate.running = true
    }
    hotkeysBlocked = true
    logEvent("hotkeys-blocked")
  }

  function releaseHotkeys() {
    if (!submapReset.running) submapReset.running = true
    if (hotkeysBlocked) logEvent("hotkeys-released")
    hotkeysBlocked = false
  }

  Process {
    id: submapEnter
    command: ["bash", "-c",
      "hyprctl keyword submap omasmash; " +
      "hyprctl keyword bind '" + root.panicBind + "'; " +
      "hyprctl keyword submap reset; " +
      "hyprctl dispatch submap omasmash"]
  }

  Process {
    id: submapActivate
    command: ["hyprctl", "dispatch", "submap", "omasmash"]
  }

  Process {
    id: submapReset
    command: ["hyprctl", "dispatch", "submap", "reset"]
  }

  // ---- SAFETY --------------------------------------------------------
  // If the play surface stops rendering, the toy has become a wall. The
  // canary is driven by the render loop, so a wedged or non-painting surface
  // freezes it even when this Item's own timers still tick. Two consecutive
  // frozen samples and we let go of the lock ourselves.
  QtObject {
    id: watchdog

    property bool armed: false
    property real lastSample: -1
    property int frozenSamples: 0

    function arm() { armed = true; lastSample = -1; frozenSamples = 0; watchdogTimer.restart() }
    function disarm() { armed = false; watchdogTimer.stop() }

    function sample(value) {
      if (!armed || !root.lockRequested) return

      if (lastSample >= 0 && Math.abs(value - lastSample) < 0.0001) {
        frozenSamples += 1
        root.logEvent("watchdog: canary frozen (" + frozenSamples + ")")
        if (frozenSamples >= 2) {
          root.logEvent("watchdog: self-unlocking, surface not painting")
          root.unlockedByWatchdog()
          root.finishUnlock("watchdog")
          return
        }
      } else {
        frozenSamples = 0
      }
      lastSample = value
    }
  }

  Timer {
    id: watchdogTimer
    interval: 5000
    repeat: true
    running: watchdog.armed
    onTriggered: watchdog.sample(root.surfaceCanary)
  }

  // A lock present before we ever asked for one is an orphan behind the
  // compositor's failsafe -- ext-session-lock outlives its client, and a fresh
  // start carries no lock over. Adopting it is the only way to give the user
  // a way back in. Exit code 2 means "cannot tell yet", so keep asking.
  function checkStrandedLock() {
    if (strandedLockResolved || strandedProc.running) return
    if (locked || lockRequested) { strandedLockResolved = true; return }
    strandedProc.running = true
  }

  function recoverStrandedLock() {
    if (!strandedLock || locked) return
    strandedLock = false
    logEvent("stranded-lock: adopting")
    beginLock()
  }

  // ---- session lock --------------------------------------------------
  WlSessionLock {
    id: sessionLock
    locked: false

    onSecureStateChanged: {
      root.logEvent("secure=" + secure)
      if (secure) {
        root.pendingSessionLock = false
        stabilizeTimer.stop()
        pendingLockTimer.stop()
      }
    }

    onLockStateChanged: {
      root.logEvent("session-locked=" + locked)
      if (locked) {
        root.pendingSessionLock = false
        stabilizeTimer.stop()
        pendingLockTimer.stop()
      }
      if (!locked && root.lockRequested) root.finishUnlock("compositor-released")
    }

    WlSessionLockSurface {
      color: root.theme.background

      PlayView {
        id: playSurface
        anchors.fill: parent
        theme: root.theme
        active: root.lockRequested
        cornerHoldMs: root.cornerHoldMs
        cornerSize: root.cornerSize
        passphrase: root.passphrase
        matchProgress: root.matchProgress
        stallCanary: root.stallRequested

        onCanaryChanged: root.surfaceCanary = canary

        onKeyTyped: function(text) { root.handleKey(text) }
        onSubmitRequested: root.submitBufferToPam()
        onCornerHeld: root.cornerHoldCompleted()
      }
    }
  }

  PamContext {
    id: passwordPam
    config: "omarchy-lock-password"
    user: root.userName

    onResponseRequiredChanged: root.respondToPasswordPrompt()
    onPamMessage: root.respondToPasswordPrompt()

    onCompleted: function(result) {
      root.authenticatingPassword = false
      root.pendingPassword = ""
      if (!root.lockRequested) return
      if (result === PamResult.Success) {
        root.finishUnlock("pam")
      } else {
        root.failedAttempts += 1
        root.logEvent("pam-failed (" + root.failedAttempts + ")")
      }
    }

    onError: function(error) {
      root.authenticatingPassword = false
      root.pendingPassword = ""
      root.failedAttempts += 1
    }
  }

  FileView {
    path: "/etc/pam.d/omarchy-lock-password"
    watchChanges: true
    printErrors: false
    onLoaded: root.passwordPamConfigured = true
    onLoadFailed: root.passwordPamConfigured = false
    onFileChanged: reload()
  }

  Process {
    id: strandedProc
    command: ["bash", "-c", "omarchy-hyprland-session-locked"]
    onExited: function(exitCode) {
      if (exitCode === 2) return
      root.strandedLockResolved = true
      root.strandedLock = exitCode === 0 && !root.locked && !root.lockRequested
      root.recoverStrandedLock()
    }
  }

  Timer {
    id: stabilizeTimer
    interval: 500
    repeat: false
    onTriggered: root.requestSessionLock()
  }

  Timer {
    id: pendingLockTimer
    interval: 100
    repeat: true
    onTriggered: root.requestSessionLock()
  }

  Timer {
    id: strandedRetryTimer
    interval: 500
    repeat: true
    readonly property int budget: 20
    property int remaining: 20
    running: !root.strandedLockResolved && remaining > 0
    function rearm() { if (!root.strandedLockResolved) remaining = budget }
    onTriggered: {
      remaining -= 1
      root.checkStrandedLock()
    }
  }

  Connections {
    target: Quickshell
    function onScreensChanged() {
      root.requestSessionLock()
      strandedRetryTimer.rearm()
      root.checkStrandedLock()
    }
  }

  Component.onCompleted: {
    // A crash while the submap was held leaves the desktop keybind-less, and
    // nothing else on the system will put it back. Clearing it unconditionally
    // on startup costs nothing when it was never set.
    releaseHotkeys()
    checkStrandedLock()
  }

  IpcHandler {
    target: "omasmash"

    function lock(): string {
      if (root.locked) return "already-locked"
      return root.beginLock() ? "ok" : "failed"
    }

    // The escape hatch that does not need a TTY. Documented in the README.
    function unlock(): string {
      if (!root.locked) return "not-locked"
      root.finishUnlock("ipc")
      return "ok"
    }

    function isLocked(): string {
      return root.locked ? "true" : "false"
    }

    // Test-only: freeze the render-loop canary so the watchdog sees a surface
    // that has stopped painting. The lock should release itself within about
    // ten seconds. This is how the watchdog gets proven; without it the one
    // safety net that covers a wedged surface is an untested claim.
    function stall(): string {
      if (!root.locked) return "not-locked"
      root.stallRequested = true
      root.logEvent("test: canary stalled")
      return "ok"
    }

    function status(): string {
      return JSON.stringify({
        locked: root.locked,
        requested: root.lockRequested,
        pending: root.pendingSessionLock,
        sessionLocked: sessionLock.locked,
        secure: sessionLock.secure,
        realScreens: root.realScreenCount(),
        passwordPam: root.passwordPamConfigured,
        strandedLock: root.strandedLock,
        watchdogArmed: watchdog.armed,
        canaryStalled: root.stallRequested,
        surfaceCanary: root.surfaceCanary,
        hotkeysBlocked: root.hotkeysBlocked,
        matchProgress: root.matchProgress,
        theme: root.theme.name,
        pluginDir: root.pluginDir,
        crayons: root.theme.crayons.length,
        failedAttempts: root.failedAttempts,
        lastEvent: root.lastEvent,
        lastEventAt: root.lastEventAt
      })
    }
  }
}
