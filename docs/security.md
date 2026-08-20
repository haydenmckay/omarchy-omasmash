# Why keypresses paint a random glyph

**Omasmash never paints the character you typed.** Press `k` and you get some
other letter, or a dinosaur. This is a security decision, and it is the reason
the password fallback is safe to advertise at all.

## The problem

Omasmash accepts your real account password as an unlock route. There is no
visible field: keystrokes accumulate in a buffer and Enter submits them to PAM.
That is a good property — it means you are never locked out of your own machine
by a forgotten passphrase, and it needs no UI a toddler could get stuck in.

But the surface's whole job is to paint every keypress in letters roughly
220 pixels tall.

Put those together and the everyday recovery route becomes the most effective
shoulder-surfing attack imaginable: your password, rendered one character at a
time, at the largest size the display supports, on a screen that is by
definition visible to whoever is in the room. Worse, the audience for this
plugin is people who are *not alone* — that is the entire premise.

## The fix

The glyph shown does not have to be the key that was pressed.

Nothing about the toy depends on that correspondence. The delight is the burst,
the colour and the motion; a toddler is not checking that `k` produced a K, and
an adult smashing out their frustration cares even less. So the surface draws a
random letter — or, sometimes, an emoji — and the leak closes completely.

Both properties now hold at once:

- Your password still works as an unlock route.
- Nothing you type is ever displayed.

## The cost, stated honestly

Key-accurate letters have real value for an older child learning their
alphabet — press A, see A. That is a genuine use case and this trade gives it
up by default.

`revealTypedKeys: true` on the play surface turns correspondence back on. It is
opt-in rather than a setting to flip casually: turning it on means anyone who
types a password into that machine's lock screen displays it. Use it on a
machine where that will never happen.

## Why not just remove the password route instead

Considered and rejected. `ext-session-lock-v1` hands the compositor the last
word — if the locking client dies the screen stays locked — so the number of
independent ways back into your own machine is a safety property, not a
convenience. Removing one to protect a cosmetic detail is the wrong trade.
Randomising the glyph keeps every route and costs nothing.

See the RECOVERY section of the README for the full set of ways back in.
