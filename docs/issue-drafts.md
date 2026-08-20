# Omasmash — GitHub issue drafts

Copy-paste each `###` section into a new issue on `trigz/omarchy-omasmash`.
Body text starts under the `**Body**` line. Titles and labels are suggestions.

Issue numbers referenced in the epic checklist assume these are filed in the
order listed (epic = #1). Fix the numbers after filing.

---

### 1. Epic: Omasmash — a toddler play mode built on the real session lock

**Labels:** `epic`, `tracking`

**Body**

````markdown
## What this is

Omasmash is a toddler-safe "play/lock" plugin for Omarchy. Toggle it on and every
keypress paints a big themed letter or shape with a colour burst and a sound;
mouse clicks splash; drags leave trails. The kid gets a toy, the machine is
untouchable.

Target user: a parent with an 18-month-old who grabs the keyboard and mouse
whenever the parent is at the machine.

## The thesis

The existing prior art (babysmash.io and friends) is browser-based, and **a
browser tab cannot hold the input**. Escape, or the wrong key combo, drops
fullscreen and the damage begins.

Omarchy can do this properly. It ships `omarchy.lock` as a `service`-kind
Quickshell plugin built on `WlSessionLock` — the real `ext-session-lock-v1`
Wayland protocol. That is *compositor-enforced input exclusivity*: while
locked, nothing else on the system receives keyboard or pointer input. No
Escape, no Alt-Tab, no killing the window.

**Smash mode is a lock screen that plays instead of asking for a password.**

The second differentiator is theming: letters are painted in the *active Omarchy
theme's own colours*, read from the theme's full palette, over the active
wallpaper. That ties the toy into Omarchy's core identity in a way a web page
cannot.

## The risk

`ext-session-lock-v1` also means that **if the locking client crashes, the
compositor keeps the screen locked**. That is the security guarantee of the
protocol, and for a toy it is a real risk of locking a parent out of their own
machine. Two live upstream Omarchy (Quattro) bugs are inherited here:

- upstream #6888 — stranded-lock recovery never completes
- upstream #7478 — lock screen crash-loops roughly every 18s after DPMS-off

Nothing pretty gets built until the spike below says the premise holds.

## Phases

1. **Prove the premise** — session-lock spike, in a nested Hyprland. Blocking.
2. **Make it play** — theme/wallpaper integration, play surface, sound.
3. **Make it safe to exit** — unlock UX, watchdog, escape-hatch docs.
4. **Ship it** — convert standalone instance to installed plugin, package,
   publish to the marketplace.

## Architecture (settled)

- **Standalone Quickshell instance during development** (~1s restarts, and a
  crash does not take the user's bar down with it). Convert to an installed
  plugin once the design settles, not before.
- `Theme.qml` — parses `~/.local/state/omarchy/current/theme/colors.toml`
  directly for the theme's full palette (the shell's own `Color` singleton
  only exposes five roles), plus the wallpaper at
  `~/.local/state/omarchy/current/background`.
- `Service.qml` — lock lifecycle, IPC handler, watchdog.
- `PlayView.qml` — the play surface, purely reactive.

## Tasks

- [ ] #2 Spike: prove the `ext-session-lock-v1` premise (**blocking**)
- [ ] #3 Theme + wallpaper integration (`Theme.qml`)
- [ ] #4 Service lifecycle + IPC toggle (`Service.qml`)
- [ ] #5 Play surface: keypress, click and drag visuals (`PlayView.qml`)
- [ ] #6 Sound with a hard volume cap and mute
- [ ] #7 Unlock UX: passphrase, corner gesture, PAM fallback
- [ ] #8 Safety: paint watchdog, escape hatch, honest documentation
- [ ] #9 Package and publish to omarchyplugins.com

## Naming

`Omasmash` follows the distribution's dominant "Oma-" idiom (OmaClock,
OmaConnect, Omaland, Omatop, Omasticky, OmaCapy, Omatruco). Earlier candidates:
Playpen, Keysmash, Doodlelock. Chosen for distribution alignment; not 100%
wedded to it — rename is cheap until the marketplace listing exists.
````

---

### 2. Spike: prove the `ext-session-lock-v1` premise before anything else

**Labels:** `spike`, `priority:critical`, `blocked-by-upstream`, `risk`

**Body**

````markdown
## Why this is first

The entire product claim is "a browser tab cannot hold the input, but a
`WlSessionLock` surface can." If that does not hold in practice — or holds so
badly that a crash strands the user out of their session — there is no plugin
worth building. **No visual, audio or packaging work starts until this issue is
closed.**

This spike is throwaway code. The goal is a yes/no answer plus written notes,
not a nice implementation.

## Test method: nested Hyprland containment

Run the whole spike inside a **nested Hyprland instance** so a stranded lock is
contained to a window rather than the real session. A stranded lock in the
nested compositor is closed by killing the nested compositor; a stranded lock in
the real session is a reboot and possibly a lost work session.

Do not run the crash tests against the live session until they pass nested.
Have the TTY escape (`Ctrl+Alt+F2` → login → kill the shell) written down and
tested *before* the first `kill -9`.

## Acceptance criteria

- [ ] A minimal `WlSessionLock` client locks the (nested) session and takes
      keyboard and pointer input exclusively.
- [ ] With the lock up, none of these reach anything underneath: Escape,
      Alt-Tab, the Omarchy keybind prefix, `Ctrl+Alt+Delete`-style combos,
      pointer clicks on windows below.
- [ ] A typed passphrase is received by the lock surface and unlocks it
      cleanly, returning input to the session.
- [ ] `kill -9` of the locking client: document exactly what happens. Expected
      per protocol is that the compositor **stays locked**. Confirm it, and
      confirm whether anything can still recover the session from inside the
      compositor.
- [ ] Stranded-lock recovery: after a `kill -9`, get back into the session by
      (a) restarting a lock client that can unlock, and (b) the TTY escape
      route. Both paths documented with the exact commands used.
- [ ] Behaviour under upstream #6888 (stranded-lock recovery never completes):
      reproduce it or establish that it does not reproduce here. Record the
      Omarchy/Quattro/Hyprland versions tested.
- [ ] Behaviour under upstream #7478 (lock crash-loops ~every 18s after
      DPMS-off): trigger DPMS-off with the lock up and record whether the loop
      occurs, and what state the machine is left in.
- [ ] Verify a paint-watchdog is *possible*: something outside the lock surface
      can observe "the play surface has stopped rendering" and trigger an
      unlock. If it is not possible, say so — that changes the safety design in
      #8.

## Deliverable

A written findings note in `docs/` covering:

1. Does compositor-enforced input exclusivity hold? (the go/no-go)
2. Exact recovery procedure for a stranded lock, verified by doing it.
3. Whether #6888 / #7478 reproduce, with versions.
4. Whether the paint-watchdog approach is viable.
5. Any constraint the findings put on the unlock design (#7) or the safety
   design (#8).

## Notes

- If the answer is "the premise holds but recovery is unreliable", that is not
  automatically a no-go — it moves weight onto #8 (watchdog + escape hatch) and
  onto the README being blunt about the risk.
- If the answer is "the premise does not hold", close the epic or re-scope
  Omasmash to a non-lock fullscreen overlay and be honest in the README that it
  is only marginally better than the browser toys.
````

---

### 3. Theme and wallpaper integration (`Theme.qml`)

**Labels:** `enhancement`, `appearance`

**Body**

````markdown
## Context

The deliberate differentiator over babysmash.io is that letters and splashes are
painted in the **active Omarchy theme's own colours**, over the active
wallpaper. The shell's own `Color` singleton only exposes five roles
(foreground/background/accent/urgent/muted) because that is all a bar needs; a
play surface wants the whole crayon box.

`Theme.qml` exists in the repo root as a first pass. It parses
`~/.local/state/omarchy/current/theme/colors.toml` directly, exposes every
non-structural colour as a `crayons` array, and resolves the wallpaper via
`readlink -f` on `~/.local/state/omarchy/current/background`. It watches
`current/theme.name` — the file the theme switcher rewrites last — as the
"a new theme has fully landed" edge, because a standalone Quickshell instance
gets no theme-swap IPC.

This issue is about hardening that pass and proving it across the shipped theme
set.

## Acceptance criteria

- [ ] Palette parses correctly for **every theme shipped with Omarchy**, not
      just the default. Record any theme whose `colors.toml` shape breaks the
      parser.
- [ ] Structural colours (backgrounds, selection, muted) stay excluded from
      `crayons`, so a letter is never painted background-on-background.
- [ ] Near-duplicate hues (`blue` vs `bright_blue`) stay deduped so one hue does
      not get double odds.
- [ ] Sparse-palette fallback verified: a theme with fewer than three usable
      colours still paints something legible.
- [ ] Light-mode themes are legible, not just dark ones — check contrast of
      `crayons` against both the wallpaper and the theme background.
- [ ] Live theme switch while the play surface is up: colours and wallpaper
      update without a restart, and without flicker or a blank frame.
- [ ] Wallpaper change (same theme) is picked up — the `backgroundVersion`
      cache-bust actually busts the `Image` cache when the symlink is repointed
      at a previously-seen file.
- [ ] Missing/unreadable `colors.toml` or `background` degrades to defaults
      rather than crashing. **Crashing here strands the lock** — see #8.

## Notes

- Any parse path that can throw must be defensive: this code runs inside the
  locking client, and an exception is a stranded session.
- Undecided: whether letters get a contrast-guaranteeing outline/shadow, or
  whether crayon selection filters by contrast against the wallpaper at
  runtime. Pick one after seeing it against real wallpapers.
````

---

### 4. Service lifecycle and IPC toggle (`Service.qml`)

**Labels:** `enhancement`, `core`

**Body**

````markdown
## Context

`Service.qml` owns the lock lifecycle: raising the `WlSessionLock`, holding the
play surface, handling the unlock request, and running the watchdog (#8). It is
the only component that talks to the session-lock protocol.

Depends on #2 — the lifecycle can only be written once the spike has established
what actually happens on crash and recovery.

## Acceptance criteria

- [ ] A single documented entry point turns smash mode on. During standalone dev
      this can be a script in `bin/`; once installed as a plugin it should be an
      `omarchy-shell` IPC command so it can be bound to a key.
- [ ] Lock raises reliably from a cold start and from an already-running shell.
- [ ] Play surface appears on **every** connected output, not just the focused
      one — a second monitor left showing the desktop defeats the point.
- [ ] Monitor hotplug while locked does not crash the client and does not leave
      an unlocked output.
- [ ] Unlock tears down cleanly: input returns to the session, no leftover
      surfaces, no leaked processes (audio in particular, see #6).
- [ ] Toggling on → off → on repeatedly is stable (no accumulating state, no
      growing memory).
- [ ] Idle/DPMS interaction is explicitly decided and tested, given upstream
      #7478. Options: inhibit idle while smash mode is active, or handle
      DPMS-off/on cleanly. **Undecided — decide with the #2 findings in hand.**
- [ ] The service never starts a second Quickshell process from inside an
      installed plugin.

## Notes

- Interaction with the real `omarchy.lock`: what happens if the session lock
  fires (idle timeout, manual lock) while smash mode is up is **undecided**.
  Nesting two session locks is likely not possible; simplest defensible answer
  is that smash mode inhibits the idle lock while active. Confirm in #2.
````

---

### 5. Play surface: keypress, click and drag visuals (`PlayView.qml`)

**Labels:** `enhancement`, `appearance`

**Body**

````markdown
## Context

The toy itself. `PlayView.qml` is purely reactive: it renders what it is told
and owns no lifecycle state. Every keypress paints a big letter or shape with a
colour burst; mouse clicks splash; drags leave trails. Colours come from
`Theme.qml` (#3); sounds from #6.

## Acceptance criteria

- [ ] Letter and digit keys paint that character, large, in a random theme
      crayon, at a random position, over the wallpaper.
- [ ] Non-character keys (modifiers, function keys, media keys) paint a shape
      rather than nothing — a keypress that does nothing reads as "broken" to a
      toddler.
- [ ] Mouse clicks paint a splash at the pointer.
- [ ] Drags leave a trail that decays.
- [ ] Shapes fade/expire so the surface does not accumulate into mush; a
      sustained key-smash (many events/second, keys held down with autorepeat)
      stays at a smooth frame rate and bounded memory.
- [ ] Hard cap on live shapes, with oldest-first eviction.
- [ ] Rendering keeps up on a low-spec machine and on a HiDPI multi-monitor
      setup.
- [ ] Nothing in this component can throw on unexpected input — an exception in
      the play surface strands the lock.
- [ ] Keys used by the unlock mechanism (#7) still paint normally, so the
      passphrase is not discoverable by watching which keys behave oddly.

## Notes

- Undecided: whether shapes are drawn with QML `Text`/`Shape` items or a
  `Canvas`/scene-graph approach. Pick based on what holds frame rate under a
  sustained smash test, not on elegance.
- Undecided: whether letters are lowercase, uppercase, or match the key.
- Deliberately out of scope for v1: word/phonics modes, drawing persistence,
  saving the "artwork".
````

---

### 6. Sound with a hard volume cap and mute

**Labels:** `enhancement`, `safety`

**Body**

````markdown
## Context

Every keypress and click gets a sound. Two constraints dominate: it is played
next to a small child's ears, and it plays from a locked session the user may
not be able to reach the volume keys of.

## Acceptance criteria

- [ ] Keypresses and clicks play a short sound.
- [ ] **Hard volume cap** applied in-app: Omasmash's own output cannot exceed a
      configured ceiling regardless of the system volume level. The cap is a
      code-level clamp, not just a default setting.
- [ ] Mute is available and reachable *while locked*, without unlocking — a
      dedicated key or gesture, documented in the README.
- [ ] Mute state persists across toggles of smash mode.
- [ ] A rapid smash does not stack into a wall of overlapping audio: cap
      concurrent voices and/or rate-limit triggers.
- [ ] Omasmash's audio does not permanently change the system/session volume, and
      restores anything it touched on unlock.
- [ ] Missing audio device, or a device that disappears mid-session, degrades to
      silence and **never** crashes the locking client.
- [ ] No leaked audio processes after unlock (see #4).
- [ ] Sound assets are licensed for redistribution and the licence is recorded
      in the repo. Required for marketplace publication (#9).

## Notes

- Undecided: playback mechanism (Quickshell/Qt multimedia vs. shelling out to a
  player). Shelling out per keypress is likely too slow and leaks processes;
  prefer in-process, but measure.
- Undecided: whether sound defaults to on or off on first run. Defaulting to
  *off* with a README line is the safer choice for a plugin someone tries at
  their desk.
````

---

### 7. Unlock UX: passphrase, corner gesture, PAM fallback

**Labels:** `enhancement`, `ux`, `needs-decision`

**Body**

````markdown
## Context

The exit path. It has to be effectively unreachable by a toddler smashing keys
and grabbing the mouse, and trivially reachable by the parent standing right
there. **This design is not settled** — this issue is where it gets settled.

Depends on #2 (what the lock surface can actually receive) and constrains #8.

## Candidate mechanisms

1. **Typed passphrase** — `omarchy` by default, configurable. Seven characters
   in sequence is effectively unreachable by random smashing.
2. **Corner gesture** — hold the pointer in a corner for N seconds, or hit four
   corners in order. Useful when the parent has one hand on the mouse.
3. **PAM password** — the user's real password, always available as a fallback.

Passphrase and PAM should both exist. Whether the corner gesture ships in v1,
and which of the two corner variants, is **undecided**.

## Acceptance criteria

- [ ] Passphrase unlock works, matched as a sequence with a sensible reset (e.g.
      the buffer clears after a short idle gap so partial matches do not
      accumulate across a smash session).
- [ ] Passphrase is configurable, and the config path is documented.
- [ ] A random-smash simulation (thousands of synthetic keypresses) does not
      unlock. Run it against the *nested* compositor, not the live desktop.
- [ ] PAM password fallback authenticates against the real user account and
      unlocks.
- [ ] Failed PAM attempts do not lock the account out or leave the surface in a
      broken state.
- [ ] Corner gesture (if shipped): tuned so that a toddler dragging the mouse
      around does not trigger it — measure, do not guess.
- [ ] Unlock feedback is minimal and non-obvious: no visible passphrase progress
      indicator that teaches a watching child, but enough feedback that the
      parent knows a failed attempt failed.
- [ ] Typing the passphrase or the PAM password never leaks characters to
      anything underneath the lock.
- [ ] Every unlock path is documented in the README, including what to do if all
      of them fail (see #8).

## Notes

- **The README must be honest that this is a child lock, not a security lock.**
  A known, default passphrase protects against a toddler, not against a person
  with physical access. Users must never confuse Omasmash with the session lock.
  Tracked in #8, restated here because it constrains how this is described in
  the UI.
````

---

### 8. Safety: paint watchdog, escape hatch, and honest documentation

**Labels:** `safety`, `documentation`, `priority:high`

**Body**

````markdown
## Context

Because Omasmash is built on `ext-session-lock-v1`, a crash of the locking client
leaves the compositor **locked**. This issue covers every mitigation for that,
plus the documentation that makes the risk legible to a user before they install
a toy on their work machine.

Depends on #2 for what is actually achievable.

## Acceptance criteria

### Paint watchdog

- [ ] Something outside the play surface observes whether the surface is still
      rendering, and self-unlocks if it stops for longer than a threshold.
- [ ] The watchdog itself cannot be the thing that crashes: it is simple, has no
      dependency on theme parsing, audio, or the play surface's internals.
- [ ] Threshold is long enough not to fire during a legitimate stall (DPMS,
      monitor hotplug, heavy load) and short enough to be useful. Value chosen
      from measurement, not guessed.
- [ ] Watchdog behaviour verified by deliberately hanging and by `kill -9`-ing
      the render path in the nested compositor.

### Escape hatch

- [ ] TTY escape route documented and **verified by actually doing it**:
      `Ctrl+Alt+F2` → login → kill the shell. Exact commands in the README.
- [ ] SSH-from-another-machine recovery documented as a second route.
- [ ] Recovery instructions live somewhere reachable *when the screen is
      locked* — i.e. in the GitHub README, not only in a local file behind the
      lock.

### Documentation

- [ ] README states plainly: **this is a child lock, not a security lock.** A
      known passphrase protects against a toddler, not against a person with
      physical access.
- [ ] README states plainly that a crash of the client can leave the session
      locked, that this is the Wayland protocol's designed behaviour and not a
      bug in Omasmash, and how to recover.
- [ ] Upstream #6888 and #7478 are linked with the versions they were observed
      on, and what Omasmash does about them.
- [ ] "Try it in a nested Hyprland first" is the recommended first run in the
      README, with the command.
- [ ] Per omarchyplugins.com publishing requirements, every external dependency,
      setup step, privilege boundary, service and installer is documented — PAM
      access in particular needs to be spelled out and justified (#9).

## Notes

- Undecided: whether a maximum session duration auto-unlock is worth adding
  (e.g. self-unlock after N minutes regardless). Cheap insurance, but it is also
  a way for the toy to quit mid-play. Decide after #2.
````

---

### 9. Package and publish to omarchyplugins.com

**Labels:** `packaging`, `release`

**Body**

````markdown
## Context

Convert the standalone Quickshell dev instance into an installed plugin and get
it listed. Last phase — the standalone instance stays until the design has
settled, because an installed plugin shares the shell's single long-running
process and a crash takes the user's bar down with it.

There are zero kids/baby/toddler plugins in the marketplace catalog, and
Appearance is the strongest category for new entrants. The binding growth
constraint is off-marketplace attention, not listing metadata — **a GIF of a
toddler smashing keys is the marketing.**

## Acceptance criteria

- [ ] `manifest.json` **in the repo root** (a nested layout fails
      `omarchy plugin add <url>` outright), with: `schemaVersion`, `id`, `name`,
      `version` (semver, ≤64 chars), `author`, `license`, `description`,
      `kinds`, `entryPoints`.
- [ ] Plugin ID migrated from the dev ID `trigz.omasmash` to
      `io.github.trigz.omasmash`. Must not start with `omarchy.*`.
- [ ] Public repo with README and a licence file.
- [ ] Validated against a **fresh clone**, not the working checkout:
      ```bash
      git clone <repo-url> /tmp/omasmash-check && omarchy plugin validate /tmp/omasmash-check
      ```
- [ ] Install *and* removal are clean: nothing left behind, and deleting the
      plugin folder does not break the shell.
- [ ] Shell-restart survival, disable/re-enable, and IPC toggle all tested.
- [ ] Every external dependency, privilege boundary and service documented —
      PAM in particular (#8).
- [ ] Sound asset licences recorded (#6).
- [ ] `preview.png` (optional but worth having).
- [ ] **Demo GIF** of a real toddler smashing keys, in the README, above the
      fold. This is the single highest-leverage asset in the project.
- [ ] Submitted with repository link, category and tags. Category: Appearance
      unless something better fits at submission time.

## Notes

- The marketplace validates listings, not plugin security; plugins run
  unsandboxed. PAM handling and anything that shells out has to be justified in
  our own docs because nothing downstream will catch it.
- Final name check before the ID is claimed: `Omasmash` is chosen for alignment
  with the "Oma-" idiom but is not locked in. Renaming after a listing exists is
  expensive; renaming before it is free.
````
