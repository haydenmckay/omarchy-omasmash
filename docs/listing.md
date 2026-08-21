# Marketplace listing copy

Written by hand. The catalog is full of descriptions that read like a summary
of the repo, because that is what they are — and a summary of the repo tells
someone what the code does, not why they would want it.

## Description (the one in `manifest.json`)

> Beautiful, theme-aware keyboard smash with a real lock screen underneath.
> Hand the keyboard to a toddler and they can't reach your agents — and neither
> can you, on the tenth "fix it, and don't make any mistakes."

187 characters, doing four jobs.

**"Beautiful, theme-aware"** is the differentiator over every browser-based
smash toy, and it is the honest one: the surface is painted from the user's own
palette and wallpaper.

**"with a real lock screen underneath"** is the product in six words — it names
the guarantee *and* puts "lock screen" where the search index will find it.
Lock screens are two of this marketplace's top six listings, so that phrase is
worth its space twice over.

**"Hand the keyboard to a toddler … and neither can you"** names both audiences
in one parallel instead of the flabby "for toddlers and adults alike". The turn
does real work: the adult benefit is not just stress relief, it is being
stopped from typing something you will regret.

An earlier draft opened the clause with "little fingers", which was more
elegant and worse. **"toddler" is the word people actually search**, and it was
then absent from the listing text entirely — living only in the desktop entry's
keywords, where the marketplace index never sees it. Say the word.

**The closing quote** is the shareable part, aimed at people already running
agents — which on this marketplace is everyone.

### Rejected

- *"for toddlers and adults alike"* — states the two audiences instead of
  demonstrating them, and "alike" is filler.
- Leading with the toddler — halves the audience in the first four words, which
  is the exact mistake the name change was made to avoid.
- Anything longer. Description length correlates slightly *negatively* with
  installs, and the real growth constraint is GitHub stars and off-marketplace
  attention, not listing metadata.

## The password route is fine to mention

An earlier draft of this file said to keep the PAM fallback out of the listing,
because advertising "accepts your account password" invited people to type
their password into a surface that painted every keystroke 220px tall.

That is fixed at the source: the glyph shown is never the key pressed
(`docs/security.md`). The route is now genuinely safe in front of an audience,
so it can be described as what it is — you are never locked out of your own
machine.

## Category

**Appearance.** It is genuinely a lock screen, and lock screens do well here —
Lock Screen Explorer (296 copies) and Omaland (286) are both top-six, both in
Appearance. Appearance is also the strongest category for a new entrant at ~28%
of recent listings clearing 40 copies, against 0% in Developer Tools.

Put "lock screen" in the description text where the search index will see it.

## Preview image

`preview.png` is a frame from the warp intro. The loading sequence is the most
distinctive thing here and the one that survives being shrunk to a card.

## The shareable assets

Two, doing different jobs:

- `docs/media/omasmash-demo.gif` — the warp intro and the play surface. The
  hook.
- `docs/media/omasmash-themes.gif` — four themes switched live, mid-play. The
  **argument**. Every browser-based smash toy looks like itself; this one looks
  like the viewer's own desktop, and no amount of description does that as
  quickly as watching the palette change under the letters.

A GIF of an actual toddler smashing keys would beat both, and is worth shooting
when the opportunity presents itself.
