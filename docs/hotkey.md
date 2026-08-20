# Binding a hotkey

**Nothing in this repo writes to your Hyprland config.** Binding a chord that
locks your session is your decision, so the bind below is documented, not
installed.

## The bind

Add to `~/.config/hypr/bindings.conf` (or wherever your user binds live):

```
bindd = SUPER SHIFT, S, Smash mode, exec, ~/Work/omarchy-omasmash/bin/omasmash-toggle
```

`omasmash-toggle` locks if unlocked and unlocks if locked, so the same chord
gets you both in and out — which matters when the person reaching for the
keyboard is holding a child.

## Choosing a chord

Two constraints pull against each other:

- **Hard enough that a toddler cannot hit it.** They will be pressing keys at
  random with a whole palm. Anything reachable as a single key or a one-modifier
  chord will eventually come up.
- **Easy enough to hit one-handed**, because you will usually be reaching over
  something.

`SUPER+SHIFT+S` is a reasonable middle. Avoid anything Omarchy already binds —
check first:

```bash
hyprctl binds -j | jq -r '.[] | "\(.modmask) \(.key) -> \(.dispatcher) \(.arg)"' | grep -i <your-key>
```

## The one that is not optional

While smash mode is active, Omasmash puts Hyprland into a submap, so **every
other keybind on the system is inert** — including the toggle above. The submap
carries exactly one bind, the panic chord:

```
SUPER + CTRL + ALT + SHIFT + Escape
```

That runs `bin/omasmash-panic`, which restores your keybinds first and unlocks
second. It is deliberately awkward: it is the one chord that must never be
reachable by a palm on the keyboard, and it is the way back if anything else
fails.

See the RECOVERY section of the README for what to do if the process dies
while holding the lock.
