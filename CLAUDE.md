# CLAUDE.md — Omasmash

Toddler-safe play surface for Omarchy. **A lock screen that plays instead of
asking for a password.** Read `README.md` first; read `docs/issue-drafts.md`
for the planned work breakdown.

## The one thing that matters

This is built on `ext-session-lock-v1`. The compositor enforces input
exclusivity, and **it keeps the screen locked if the client dies.** Every
design decision follows from that. Before touching the lock path:

- Test in the nested compositor (`bin/omasmash-nested`), never the real
  session. A stranded lock in there strands a window.
- Confirm the TTY escape works on this machine first (`README.md` → RECOVERY).
- Never remove the paint watchdog in `Service.qml` without a replacement.

## Layout

| File | Role |
|---|---|
| `Service.qml` | Lock lifecycle, unlock paths, watchdog, IPC. Owns all state. |
| `PlayView.qml` | The play surface. Purely reactive — renders and reports, decides nothing. |
| `Theme.qml` | Live palette + wallpaper from the active Omarchy theme. |
| `dev-shell.qml` | Standalone harness. Must stay at the project root. |
| `dev/nested.conf` | Nested Hyprland config for lock testing. |
| `bin/omasmash` | Control CLI (`run`/`lock`/`unlock`/`status`). |

## Gotchas already paid for

- **`dev-shell.qml` lives at the repo root, not `dev/`.** Quickshell refuses
  QML module paths outside the config folder, so `import ".."` from `dev/`
  fails with "Service is not a type".
- **`Theme.qml` parses `colors.toml` itself.** The shell's `qs.Commons` Color
  singleton only exposes five roles; a play surface needs every colour. It
  also sets `watchChanges: false` and takes theme swaps over shell IPC, which
  a standalone instance never receives — hence watching `theme.name`.
- **Cache-bust the wallpaper** with `?v=<version>`, or `Image` will not reload
  when the symlink is repointed at a file it has already seen.
- **Cap live sprites.** A toddler generates input faster than an adult;
  unbounded sprite creation wedges the surface, and a wedged surface in a
  session lock means a locked-out parent.
- **`misc:allow_session_lock_restore` must be true for recovery to work.**
  Omarchy sets it; the nested harness must too. With it off, a client trying
  to adopt a stranded lock is killed by a fatal Wayland protocol error and the
  session is locked forever. Any nested test config must mirror the real
  session's Hyprland options or it manufactures lockouts that do not exist.
- **The watchdog canary is animation-driven, not timer-driven.** Animations
  only advance when frames are produced, so a frozen canary truthfully means
  "not painting". A Timer keeps ticking on a surface that renders nothing.

## Development loop

```bash
bin/omasmash run        # standalone; does not lock on its own
bin/omasmash status     # JSON state
qmllint *.qml          # must stay clean
```

Standalone by choice, per `~/.claude/skills/omarchy-plugin-dev/`: an installed
plugin shares the shell's long-running process, so a crash takes the bar with
it. Convert to an installed plugin once the lock design has settled.
