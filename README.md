# OmaBaby

A toddler-safe play surface for [Omarchy](https://omarchy.org).

Toggle it on and the keyboard becomes a toy: every keypress paints a big
letter in your active theme's colours, every click splashes, every drag
trails. Meanwhile the machine is untouchable.

> **Status: pre-alpha.** The session-lock premise test has not been signed off
> yet. Do not run this on a machine you care about being able to get back into.
> Read [RECOVERY](#recovery) first — all of it.

## Why this isn't a web page

The existing toddler-smash toys are browser based, and **a browser tab cannot
hold the input.** Escape, or any of a dozen key combos, drops fullscreen and
your toddler is now in your email.

OmaBaby is built on `ext-session-lock-v1`, the Wayland session-lock protocol —
the same mechanism behind Omarchy's real lock screen. Input exclusivity is
enforced by the compositor, not by a focus grab. While it is up, nothing else
on the system receives keyboard or pointer input. No Escape, no Alt-Tab, no
alt-clicking the window away.

So: **OmaBaby is a lock screen that plays instead of asking for a password.**

## Theming

Colours come from your active theme, live. OmaBaby reads
`~/.local/state/omarchy/current/theme/colors.toml` directly rather than going
through the shell's `Color` singleton, because that singleton only exposes
five roles and a play surface wants the whole crayon box. Your wallpaper is
drawn behind the play surface, dimmed, so it still reads as *your* desktop.

Switch themes and it follows — the palette is re-read when
`current/theme.name` changes.

## Unlocking

Three ways out, in order of everyday usefulness:

1. **Type the passphrase** — `omarchy` by default. Seven characters in
   sequence is effectively unreachable by random smashing. Nothing is
   displayed while you type.
2. **Hold the top-left corner** for three seconds. A thin accent-coloured bar
   fills to show progress. Discoverable for an adult, impossible while
   flailing.
3. **Type your real password and press Enter.** There is no visible field —
   keystrokes accumulate invisibly and Enter submits them to PAM. This always
   works, even if you have changed the passphrase and forgotten it.

## This is a child lock, not a security lock

Say it plainly: the passphrase is a *known string*. It stops a toddler. It
does not stop a person with physical access to your machine, and it is not a
substitute for `omarchy.lock`. Do not walk away from an unattended machine
with only OmaBaby up and consider it locked.

## RECOVERY

`ext-session-lock-v1` gives the compositor the last word: **if the locking
client dies while the lock is held, the screen stays locked.** That is the
protocol working as designed — it is what stops someone unlocking your machine
by crashing your lock screen — but for a toy it is a genuine risk of locking
yourself out. Layers of defence, cheapest first:

**1. The paint watchdog (automatic).** The play surface drives a canary from
the render loop. If it stops advancing for two consecutive five-second
samples, the service concludes the surface has stopped painting and releases
the lock itself. This covers a wedged surface — it cannot cover a dead
process.

**2. IPC unlock, from another machine or an SSH session:**

```bash
~/Work/omarchy-omababy/bin/omababy unlock
```

Works whenever the process is alive and answering, including when the screen
is showing nothing useful.

**3. The TTY escape.** If the process is dead and the compositor is still
holding the lock:

```
Ctrl+Alt+F2          # switch to a text console
<log in>
pkill -f omababy     # or: pkill quickshell
Ctrl+Alt+F1          # switch back
```

Omarchy's own stranded-lock handling then applies: a freshly started instance
detects a lock it did not take (via `omarchy-hyprland-session-locked`) and
adopts it, giving you a surface that can accept your PAM password.

**Verify you can get to a TTY on your machine before you run the first lock
test.** That is the floor under everything else here.

### Known upstream issues this inherits

- Omarchy **#6888** — stranded-lock recovery never completes.
- Omarchy **#7478** — lock screen crash-loops roughly every 18s after DPMS-off.

Both are live against the session-lock path OmaBaby is built on, and both are
part of the premise test's acceptance criteria.

## Development

Runs as a standalone Quickshell instance, not an installed plugin — a crash
here cannot take your bar down with it, and restarts take about a second
instead of bouncing the whole shell.

```bash
bin/omababy run       # run it (does NOT lock on its own)
bin/omababy status    # JSON: lock state, theme, watchdog, PAM
bin/omababy lock      # lock
bin/omababy unlock    # release
```

**Run every lock, crash, and `kill -9` test inside the nested compositor**,
where a stranded lock strands a window instead of your machine:

```bash
bin/omababy-nested          # nested Hyprland with OmaBaby inside
bin/omababy-nested --kill   # from the host, if it wedges
```

## Licence

MIT.
