# Naming & Positioning Analysis

**Date:** 2026-08-20
**Data:** `omarchyplugins.com/catalog.json` (694 entries) joined to `api.omarchyplugins.com/v1/stats` on plugin id. Both endpoints returned 200. 36 entries were Omarchy builtins with no listing date — excluded. **Working n = 658 community plugins.**

---

## Recommendation

**Winner: `Omasmash`** (styled with a single capital, matching the marketplace's majority house style).

**Runner-up: `Omasmash`** — the incumbent, and the coherent choice if you weight the parent audience and the safety signal above total reach.

**The data does not discriminate between these two.** It rules some things out, but the choice between Omasmash and Omasmash comes down to a positioning judgement, made explicitly below and labelled as such.

### What the data does and doesn't support

The data supports three useful conclusions and refuses to answer the actual question. It **kills the stated case for the "Oma-" prefix as an engagement lever**: across 78 Oma-prefixed plugins, the prefix has no detectable effect on views (t=+0.8), on view→copy conversion (t=−0.8), or on copies once age, stars, category and preview image are controlled for (β=−0.02, t=−0.1). Oma- plugins have a median of exactly 7 copies — the catalog median. It is common, not effective. The strongest raw correlation in the whole dataset is that **descriptive names outperform coined ones** (+0.47 log-copies, t=+4.4) — but this is almost certainly a *product-type* effect wearing a name's clothing: plugins called "Weather Radar" and "Notification Center" are utilities people were already looking for. The test that isolates it — restricting to the 39 delight/novelty plugins, where product type is held roughly constant — shows the advantage **vanishes** (median 9 copies for descriptive names vs 10 for playful ones). So the headline correlation is not a lever we can pull, because we cannot change what this plugin *is*. What the data does *not* support is any claim that "Baby" or "Smash" will out-perform the other. No cut in this dataset gets near that question, the delight subsample is far too small (n=39) to detect anything but a huge effect, and 82% of the catalog is under a week old, so age-confounding swamps everything. Anyone claiming the numbers pick a name here is over-reading them.

---

## Evidence

### Method

`log1p(views)` and `log1p(copies)` regressed on `log(age)` + `log1p(stars)` + preview-image flag + category dummies, then name-shape features tested on the residuals (permutation tests, 20k iterations) and again as joint regressors. Age normalisation is not optional here: median listing age is **3 days**, and 169 plugins were listed on a single day (2026-08-18). Significance below is uncorrected; with ~14 tests run, treat anything above p≈0.004 as suggestive at best.

Sanity check: the model reproduces the established priors — stars dominate (β=+0.49 on log-copies), preview image is a modest real effect (β=+0.46), and Appearance is the best category (28% of entrants clear 40 copies, vs the 29% prior). The pipeline is measuring the right thing.

### Finding 1 — The "Oma-" prefix is a well-powered null. **This is the strongest finding.**

| cut | n | med views | med copies | conv % | β on log-copies (adjusted) |
|---|---|---|---|---|---|
| Oma-prefixed | 78 | 96 | 7 | 14.6% | −0.02 (t=−0.1) |
| not Oma-prefixed | 580 | 76 | 7 | 16.7% | — |

Nothing. It survives no cut: not views, not conversion, not copies, not within the delight subset. n=78 vs 580 is enough power to have seen a moderate effect, and there isn't one.

Worth noting *which* Oma- names succeed: Omaland (286 copies), OmaConnect (152), OmaClock (111), Omamusic (85), Omaspotify (82), Omado (72), Omalang (49), Omatop (43), Omanote (38). With one exception, the pattern is **Oma + a function word**, not Oma + whimsy. The whimsical ones sit at the bottom (Omatruco 11 copies on 318 views — a 3.5% conversion, the name pulled clicks and the product didn't hold them; Omasweeper 10).

**Implication:** "aligns with the marketplace idiom" is not, by itself, a reason to pick a name. If Oma- earns its place it is for a different reason — see Finding 5.

### Finding 2 — Descriptive names correlate with copies, but it's confounded, and the confound is demonstrable

| feature | β log-views | β log-copies | note |
|---|---|---|---|
| contains a function word | +0.19 (t=+3.1) | **+0.47 (t=+4.4)** | robust to outlier removal |
| all tokens are real English words | +0.12 (t=+1.9) | **+0.38 (t=+3.6)** | independent of the above |
| camelCase | −0.05 (t=−0.6) | −0.20 (t=−1.2) | weak |
| word count | −0.18 (t=−2.5) | −0.16 (t=−1.3) | suggestive |
| character count | +0.03 (t=+2.5) | +0.04 (t=+2.4) | suggestive |

Median copies: 12 for function-word names vs 6 for playful ones; p90 81 vs 33.

**But** — restricting to the 39 delight/novelty plugins (identified by name+description keywords: game, cat, fun, cute, animation, ambience, pixel, doodle, etc.):

| delight plugins only | n | med views | med copies | p90 | max |
|---|---|---|---|---|---|
| descriptive name | 11 | 74 | 9 | 46 | 77 |
| playful name | 28 | 71 | **10** | **68** | **336** |

The effect inverts (weakly, and n is small). The single best delight plugin, and 4th on the entire marketplace, is **Navbar Cat** — a maximally playful name. The correct reading is that the catalog-wide correlation measures *"utilities get installed more than toys"*, not *"descriptive names beat playful names."* For a delight product, it carries no instruction.

Note also the shape of the delight distribution: a *lower* median but a *fatter tail* than the catalog. Given the prior that discovery is off-marketplace and star-driven, a delight plugin's outcome is decided in that tail, not at the median. **Optimise the name for tail outcomes — shareability — not for median performance.**

### Finding 3 — camelCase styling: no signal

The catalog-wide camelCase penalty (−0.38 log-copies, p=0.014 on residuals) does **not** reproduce within Oma- names, where styling can be compared cleanly:

| | n | med views | med copies | mean copies |
|---|---|---|---|---|
| `OmaXxx` (camel) | 20 | 96 | 8 | 20.9 |
| `Omaxxx` (single cap) | 56 | 96 | 7 | 19.7 |

A wash. The catalog-wide camel coefficient was proxying for "coined brand name" generally, not for capitalisation. Single-cap is the majority convention (56 vs 20) — that is a weak conformity argument and nothing more. Pick on taste.

### Finding 4 — Hearts do not over-index for delight: no signal

Tested because it would have been a shareability proxy. It isn't one. Hearts-per-view for delight plugins: 2.68% vs 2.48% for everything else (adjusted t=+0.7). The top hearts-per-view plugins are Screen Time, Vitals, Home Assistant, OmaConnect — all utilities. **Hearts track usefulness, not whimsy.** Hypothesis rejected.

### Finding 5 — Two things the priors don't cover

**a) The lock-screen niche is quietly strong.** Not something the category-level priors surface:

| plugin | copies | views | stars |
|---|---|---|---|
| Lock Screen Explorer | 296 | 792 | 42 |
| Omaland | 286 | 902 | 10 |
| Sandman | 115 | 417 | 13 |
| Media Lock Screen | 85 | 283 | 3 |
| Nova Lock | 32 | 185 | 5 |

Two of the marketplace's top six by copies are lock-screen plugins, both in Appearance. This product *is* a lock screen. **Ship it in Appearance (the best category on both the priors and this data), and put "lock screen" in the description.** That is a firmer recommendation than anything the naming analysis produces.

**b) The niche is completely empty.** Zero plugins in the 658 match `baby|toddler|kid|child|smash|nursery|parent` in name, description, or tags. No incumbent, no crowding, no comparison shopping.

**c) Name-shape distinctiveness is invisible to this dataset.** Engagement stats can only measure names that are *already on the marketplace*, where every name is unique by construction. They cannot measure whether a name is findable on GitHub, X, or Google — which is precisely where the priors say discovery actually happens. This is the gap the collision check below fills, and it turned out to matter more than any regression.

---

## Candidates

Collision-checked against all 694 catalog entries (exact, substring, and fuzzy match at 0.78 similarity), plus a web check on the shortlist. "External" = the wider software world, which matters because discovery is off-marketplace.

| Name | Catalog | External | Audience | Safety signal | Verdict |
|---|---|---|---|---|---|
| **Omasmash / Omasmash** | clear | **clear** | both | weak, fixable | **Winner** |
| **Omasmash** | clear | clear | parents only | strong | **Runner-up** |
| Smash Room | clear | generic (rage-room is a real-world category) | both | medium — "room" implies containment | Strong third |
| Keysmash | clear | **crowded** — keysmash.app, keysmash.dev, KeySmash Studios, several GitHub repos, a Wikipedia entry | both | good — a keysmash is harmless by definition | Killed by crowding |
| Playpen | clear | **collides** — `thestinger/playpen`, a Linux sandbox tool | both (parents strongly) | strongest of any candidate | Killed by collision |
| Baby Smash / Babysmash | clear | **taken** — Scott Hanselman's 2008 app, babysmash.com | parents | strong | Unusable as a name; valuable as a reference |
| Babyarchy | clear | clear | parents only | strong | Cute, narrow, hard to say |
| Omaplaypen | clear | clear | both | strong | Clunky; inherits Playpen's semantic confusion |
| Doodlelock | clear | clear | both | good | Understates the mechanic; "doodle" ≠ smash |
| Scribblelock | clear | clear | both | good | As above |
| Paintlock / Keypaint | clear | clear | both | good | Describes output, not the joy |
| Crayon | clear | spurious only | parents lean | medium | Pretty; says nothing about input capture |
| Tantrum | clear | clear | both | **negative** | Funny, but names the problem not the cure |
| Rage Room | clear | generic | adults only | poor | Gates out parents — the mirror of Omasmash's flaw |
| OmaRage | clear | near-miss vs OmaRazer | adults only | poor | Confusable + single-audience |
| Padded Room | clear | clear | both | strong | Asylum connotation is a liability |
| Bonk / Splat / Squish / Whack | clear | generic words | both | medium | Cute, but opaque — name tells you nothing |
| Smol / Bambino / Crib / Nursery | clear | Crib matches "Windscribe" (spurious) | parents only | strong | Narrow; none describe the mechanic |
| Sandbox / Bubble Wrap | clear | **collide** — sandboxing, Bouncy Castle crypto lib | both | strong | Semantically hijacked in dev circles |
| Confetti / Glitter / Kaboom / Chaos Mode | clear | generic | adults lean | weak | Describe the effect, not the product |
| Big Red Button | clear | generic | both | medium | Long; implies one press, not sustained play |

Two near-collisions found in the catalog worth flagging regardless of choice:

- **`ourongxing.omash`** ("omash", a Mihomo proxy selector, 80 views / 0 copies). One letter from `omasmash`. Weak incumbent, but the string proximity is real for install commands and plugin ids. Mitigate by keeping the id as `trigz.omasmash` — author-scoped ids make this a non-issue in practice.
- **`asdfsnlr.omarazer`** ("OmaRazer") — kills OmaRage, not the winner.

Everything else on the list is clear in the catalog.

---

## Reasoning: why Omasmash over Omasmash

**This is a judgement call, not a data finding.** The data does not discriminate. Three arguments decide it:

**1. "Baby" is a hard demographic gate; "Smash" isn't.** A tagline can add the toddler angle to Omasmash — "for your 18-month-old, or for you" costs six words. No tagline can talk a stressed adult with no children into a plugin called Omasmash; they self-select out at the name and never read the description. The asymmetry is the whole argument: one name's weakness is repairable in copy, the other's is not. Since the stress-relief audience is roughly a multiplier on reach, gating it out at the name is the single most expensive thing on the table.

**2. The safety-signalling cost of "Smash" is real but cheap.** It is paid once, in the tagline, and the tagline you already have does it: *"a lock screen that plays instead of asking for a password."* That sentence establishes containment, safety, and the technical differentiator simultaneously. It is a better safety signal than the word "Baby" ever was, because it explains *why* it's safe rather than asserting a vibe. Note too that "smash" here is scoped to the keyboard, and the visual — big letters and colour bursts — reads as expressive, not destructive, within about half a second of the demo GIF.

**3. Distinctiveness, which the regressions cannot see.** Finding 1 says the Oma- prefix buys no engagement lift, and that is true — but it isn't the reason to keep it. Discovery happens on X, Reddit, Discord, and GitHub (established prior), where a name has to be searchable and ownable. This is exactly where the two best-sounding alternatives died: **Keysmash** is a Wikipedia-entry English term with several existing apps on it, and **Playpen** is already a Linux sandboxing tool — a semantically adjacent collision that would actively confuse the safety story with a developer audience. "Omasmash" returns nothing. The prefix's value is namespace, not lift, and that value is invisible to engagement data because every marketplace name is unique by construction.

The counter-argument, stated fairly: "Smash" is the only candidate whose *first* connotation is destructive, and this plugin's entire premise is that nothing gets destroyed. If you believe the parent audience is the one that actually converts — that a stressed adult will smile at the GIF and not install, while a parent with a keyboard-grabbing toddler has a real problem and will — then Omasmash is correct and the reach multiplier is a mirage. That is a legitimate read. It is not one this data can settle.

**On styling:** Finding 3 says `Omasmash` vs `Omasmash` is a wash. Single-cap matches the majority house style (Omaland, Omamusic, Omashot, Omado, Omatop). Use `Omasmash`; it is also marginally further from `omash`.

**Migration cost is near zero.** The plugin is unlisted; this is a rename of `manifest.json`, the repo, and the docs before first publish.

---

## Positioning

**One-line pitch:**
> **Omasmash — a lock screen that plays instead of asking for a password.**

Sub-line: *Every key paints a giant letter in your theme colours. Clicks splash, drags trail, and your machine is untouchable until you type the password.*

**Angles, in priority order:**

1. **The toddler angle (the origin story).** "My 18-month-old grabs the keyboard every time I sit down." Concrete, true, and the story people repeat. Lead the README with it. Explicitly reference **BabySmash** — Scott Hanselman's 2008 Windows app is well known to exactly this audience and does the legitimising work for free. Then land the differentiator: BabySmash blocks Alt-Tab and the Windows key on a best-effort basis from inside a normal app; Omasmash is built on `ext-session-lock-v1`, so input exclusivity is **enforced by the compositor**. It is not a fullscreen window pretending to be a lock. Browser-based prior art can't do this at all — Escape drops fullscreen.

2. **The stress-relief angle (the reach multiplier).** "Just need to smash a keyboard for thirty seconds?" This is where the tech thesis quietly does double duty and it's worth saying out loud: *without real input capture you're not destressing, you're typing `asdfghjkl` into Slack.* That line is the funniest and most shareable thing in the pitch, and it converts the safety story into a punchline instead of a disclaimer.

3. **The Omarchy-native angle (why it belongs here).** Colours come live from the user's active Omarchy theme. It looks like *their* desktop, not a generic kids' app. Cheap to say, and it's the reason this is an Omarchy plugin rather than a binary.

**Listing mechanics (from the data, not judgement):**
- Category: **Appearance** — best category for a new entrant on both the priors and this data (28% clear 40 copies), and the lock-screen niche lives there.
- Put "lock screen" in the description. Two of the top six plugins by copies are lock screens.
- Ship a preview image (modest but real effect, β=+0.46 on log-copies).
- Keep the description short — longer descriptions are slightly negative, and there is no other listing-metadata lever worth pulling.
- Everything else rides on GitHub stars and off-marketplace sharing. **The GIF is the product's marketing, not the listing.**

**The demo GIF** — under 6 seconds, and it must show the *lock*, because that's the part nobody expects:

1. (0–1s) A normal, recognisable Omarchy desktop with real work on screen — terminal, editor.
2. (1–3s) Toggle on. Hands mash the keyboard: giant letters bloom in the desktop's own accent colours, clicks splash, a drag leaves a trail. Loud, fast, obviously fun.
3. (3–5s) **The money shot.** Press Escape. Press Super. Press Alt-Tab. Press Ctrl-Alt-F2. *Nothing happens.* Overlay the keys as they're pressed so the viewer sees the attempts fail. This is the entire differentiator and it takes two seconds.
4. (5–6s) Type the password; the desktop returns exactly as it was, work untouched.

A toddler's hands in step 2 make it a better GIF than adult hands, and cost nothing on the adult angle — the caption carries that. If the GIF only shows pretty letters, it reads as babysmash.io and the technical thesis is invisible.
