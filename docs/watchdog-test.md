# Watchdog test — results

**Date:** 2026-08-21
**Verdict: PASSED, after fixing a bug that made the watchdog dead code.**

## What the watchdog is for

While Omasmash is up, the compositor holds a real session lock, and
`ext-session-lock-v1` keeps that lock even if our surface stops working. A
frozen play surface is therefore not a cosmetic failure — it is a locked
screen with nothing behind it. The watchdog exists so that a surface which
has stopped painting releases the lock itself.

Detection is a "canary": a value driven by an animation. Animations only
advance when frames are actually produced, so a frozen canary is truthful
evidence that nothing is drawing. A `Timer` would not be — it keeps ticking
on a surface that renders nothing, and would cheerfully report health while
the user stares at a frozen screen.

## The bug this test found

The watchdog never worked.

`PlayView` lives inside `WlSessionLockSurface`, which the compositor
instantiates per output and only while locked. **Its `id` is not resolvable
from the service's root scope.** The watchdog timer sampled
`playSurface.canary` directly, so every sample threw — silently — and the
watchdog observed nothing. It armed on every lock and disarmed on every
unlock, which is exactly what a working watchdog looks like from outside,
and it would never have fired.

It surfaced only because adding `canaryStalled` to `status()` put the same
bad reference on a path that returns a value: `status` started coming back
empty instead of throwing invisibly.

The fix routes both directions through root properties, which *do* resolve
from inside the lock surface: the surface pushes `canary` up via
`onCanaryChanged`, and takes `stallCanary` back down.

## The test

`omasmash stall` (test-only IPC) halts the canary animation, which is exactly
what a surface that has stopped presenting frames looks like from the
service's side — so this drives the real detection and unlock path.

| t | canary | locked | event |
|---|---|---|---|
| +3s | 11808 (frozen) | true | `test: canary stalled` |
| +6s | 11808 | true | — |
| +9s | 11808 | true | `watchdog: canary frozen (1)` |
| +12s | 11808 | **false** | `unlocked: watchdog` |

The compositor released the lock (`omarchy-hyprland-session-locked` → 1).
About twelve seconds from stall to unlock, consistent with 5s sampling and
two consecutive frozen reads.

## What it does NOT cover

**A wedged QML event loop.** The watchdog runs in the same engine as the
surface it watches, so an infinite loop in JavaScript stops the watchdog
timer along with everything else. It protects against rendering stopping
while the event loop still runs — a scenegraph stall, a surface that is no
longer presented, an animation that dies — and not against the engine
itself locking up.

For that case the escape routes are the ones in the README's RECOVERY
section: the panic chord, IPC unlock from another machine, and the TTY.
There is no way to make a process reliably rescue itself from inside a
thread that has stopped executing.

## Gotcha worth remembering

Hot-reloading the service while it holds an active session lock leaves a
stale surface: the reload takes effect for IPC, but the canary never
propagates. Kill and restart the instance when changing anything inside
`WlSessionLockSurface`, or the thing you are testing is not the code you
just wrote.
