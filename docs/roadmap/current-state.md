# Current State

Last updated: 2026-03-10
Current shipped version target: `v0.4.4`

## Now shipped

- Hollow Matriarch miniboss encounter added as the round-5 finisher
- round 5 now resolves its authored normal enemy pack first, then spawns the miniboss phase from authored encounter data
- Hollow Matriarch runtime now consumes authored boss data from `scripts/data/bosses/hollow_matriarch.json` via `scripts/data/boss_defs.gd`
- shipped Stage-1 minimum viable boss rules from the implementation plan:
  - dark regeneration in shadow
  - regen suppression in flashlight and Prism light
  - `shadow_bolt` darkness projectile with HP and light corrosion
  - `veil_pounce` readable special with Surge interrupt/jam interaction
  - phase split at 50% HP with tighter cadence
- Prism light now participates as anti-darkness light for Hollow behavior and miniboss pressure, not only flashlight
- run still ends cleanly into summary/restart flow after the miniboss dies

## Scope cuts intentionally kept out of this patch

- no `shroud_bloom` yet
- no large boss framework rewrite
- no cutscene layer or broader arena/system overhaul
- no dedicated boss-only HUD panel beyond the in-world/readability cues and encounter-state HUD text

## Immediate next recommendation

- do one focused playtest/review pass on Hollow Matriarch readability and tuning
- especially verify: regen feedback clarity, projectile dissolve readability, Prism-light anti-darkness truth, and Surge interrupt timing on Veil Pounce
- if the fight needs one more escalation after tuning, add a very small `shroud_bloom` implementation as the next isolated patch
