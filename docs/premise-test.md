# Premise test — results

**Date:** 2026-08-20
**Verdict: PASSED.** The `ext-session-lock-v1` premise holds. Visual work is
unblocked.

Method: everything below ran inside a nested Hyprland (`bin/omasmash-nested`)
and was driven over IPC from the host. No synthetic input was used, and the
host session was verified unlocked at every step.

| # | Test | Result |
|---|---|---|
| T1 | Service loads, theme parses | PASS — `tokyo-night`, 16 crayons, PAM detected, stranded probe correctly negative |
| T2 | Lock is taken and is real | PASS — `secure=true`; the nested compositor independently reports `LOCK`; host unaffected |
| T3 | IPC unlock releases it | PASS — compositor released, watchdog disarmed |
| T4a | `kill -9` the client while locked | PASS (risk confirmed) — client dead, **screen stays locked**, exactly as the protocol specifies |
| T4b | Fresh instance adopts the stranded lock | PASS — `stranded-lock: adopting` → `secure=true`, live surface, watchdog re-armed |
| T5 | Unlock from the recovered instance | PASS — full round trip, compositor released |

## The finding that matters

`misc:allow_session_lock_restore` **must be true**, and Omarchy sets it
(`/usr/share/omarchy/default/hypr/looknfeel.lua:115`).

The first run of T4b failed, and the failure was worth having. The nested
config did not set the option, so it defaulted to false. With it off:

1. The client dies while locked; the compositor keeps the lock (correct).
2. A new client requests a lock to take over.
3. Hyprland refuses, and the refusal arrives as a **fatal Wayland protocol
   error** — `The Wayland connection experienced a fatal error: Invalid
   argument` — which kills the asking client.
4. No client can ever take over. The session is locked permanently. Only a
   TTY gets you back.

That is a plausible mechanism for upstream **#6888** (*stranded-lock recovery
never completes*), and it is worth checking against that issue before doing
any more work on the recovery path.

Two consequences for Omasmash:

- **The nested harness must mirror the real session's Hyprland options**, or
  it manufactures lockouts the real environment does not have. `nested.conf`
  now sets the option, with a comment explaining why.
- **Any user who has turned that option off has no in-session recovery at
  all.** Detecting it and refusing to lock is a candidate safety feature —
  see the safety issue in `issue-drafts.md`.

## Not yet tested

- **Passphrase and corner-hold unlock.** Both need real typing and pointer
  movement into the nested window. They cannot be driven over IPC and were
  not tested with synthetic input. **These need a manual pass.**
- **The paint watchdog firing for real.** Its arm/disarm transitions were
  observed on every lock and unlock, but a genuinely wedged surface was never
  induced, so the self-unlock path has not executed end to end.
- **Upstream #7478** (lock crash-loop after DPMS-off). DPMS was never driven
  in the nested compositor.
