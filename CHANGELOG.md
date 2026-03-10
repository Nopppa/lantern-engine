# Changelog

## 0.3.2 - 2026-03-10

Enemy freeze fix (Playtest 07 follow-up):

- fixed bug where both Moth and Hollow could freeze completely when overlapping the player position
- root cause: `(player_pos - enemy_pos).normalized()` returns `Vector2(0,0)` at zero distance, killing all direction-based movement and blink targeting
- added safe direction fallback (random outward push) when enemy is within 2px of player
- no gameplay/design changes — pure stability fix

## 0.3.1 - 2026-03-10

Disrupted blink transit fix (Playtest 06 follow-up):

- replaced instant teleport during light-disrupted blink with a visible 0.28s linear transit phase
- hollow now moves visibly from start to end position during disrupted blink, flickering/shimmering
- windup phase (0.4s jitter) retained before transit for readability
- transit shows rapid flicker between orange disruption glow and purple ghost afterimage
- faint trail line drawn between start and end positions during transit
- blink distance in light still reduced (40% of normal)
- result: player can read both origin and destination, movement is fast but not instant

## 0.3.0 - 2026-03-10

Blink readability fix (Playtest 05 follow-up):

- hollow blink in flashlight cone now has a visible 0.4s windup/hesitation phase with positional jitter and rapid flicker rings, so the player clearly sees the light disrupting the blink
- disrupted blink distance reduced to 40% of normal (was 45%)
- post-blink shimmer extended to 0.7s (was 0.6s)
- blink cooldown after disrupted blink slightly longer (2.6s vs 2.4s)
- HUD event text shows "Hollow struggling to blink..." during windup
- no new systems, no hard-counter — blink still works, just visibly worse in light

## 0.2.3 - 2026-03-10

Microfix pass for first-launch control reliability:

- handled `F1` help toggle and `F4` immortality toggle directly from raw key events so they still fire reliably even when UI controls own keyboard focus
- opened the full help/legend on first launch so critical controls are discoverable immediately instead of only after a completed run
- kept compact-mode status text explicit about `F1`, `R`, and `F4`, including live immortality ON/OFF state
- updated export/release metadata to `0.2.3`

## 0.2.2 - 2026-03-10

Playtest 03 MVP-safe fix pass:

- replaced the ambiguous 3/3 clear state with an explicit centered end-state panel so the run reads as complete instead of looking stuck or crashed
- made restart practically reachable from any run-over state via both `R` and a clickable `Restart run` button in the end-state panel
- simplified help handling so `F1` directly shows/hides the full legend instead of relying on the older debug visibility toggle behavior
- kept the right-side status panel visible in compact mode and surfaced key actions there so `R` restart and `F4` immortality stay discoverable even when help is collapsed
- fixed Refraction Beam range accounting so the full bounced / redirected path consumes one shared total-range budget instead of resetting per segment
- updated docs and export/release metadata to `0.2.2`

## 0.2.1 - 2026-03-10

Playtest 02 cleanup pass:

- hardened late reward resolution so the same reward cannot be applied twice during end-of-encounter / end-of-run transitions
- fixed reward button wiring to bind stable indices instead of relying on a loop closure in the HUD build
- capped beam range growth to a safe MVP ceiling and deep-copied reward data before assigning button metadata
- collapsed the readability/help legend by default and moved it to a smaller top-right panel so it no longer dominates the play view
- kept the legend available during reward selection and behind `F1` when expanded for debugging
- strengthened beam-path lighting with wider layered glow lines plus sampled light pools along each beam segment so trajectory reads more clearly
- bumped export/release metadata to `0.2.1`

## 0.2.0 - 2026-03-09

Playtest iteration pass:

- shortened Refraction Beam presentation into a quick flash/pulse so shots feel snappier and less like a beam parked on screen
- rebuilt beam path resolution so Prism Node redirect no longer terminates bounce logic; redirected shots can keep bouncing if bounce budget and wall angle allow it
- added explicit dev immortality toggle on `F4` with HUD/status visibility for fast encounter testing
- added lightweight functional lit-zone rendering around player, prism, enemies, and fresh beam paths to make light-space meaningfully legible without introducing a heavy dynamic lighting system
- updated HUD/control copy and docs for the new debug toggle and feel/readability checks
- bumped export/release metadata to `0.2.0`

## 0.1.1 - 2026-03-09

Reward selection usability fix:

- added actual keyboard reward selection in the reward panel
- `1/2/3` now pick the visible reward options directly
- `W/S` and `↑/↓` move the reward highlight
- `E` and `Enter` confirm the highlighted reward
- reward panel text + HUD copy now explain the real input flow
- updated Windows export metadata to `0.1.1`
- cleaned release packaging so `v0.1.1` ships as versioned Windows/Linux archives only
- removed stale `v0.1.0` build artifacts and repacked Windows zip to include only the current `.exe` + `.pck`

## 0.1.0 - 2026-03-09

Initial public MVP-0 mechanic proof:

- created new Godot 4 project
- implemented one-arena top-down prototype loop
- added player movement, HP, Energy regen, restart flow
- implemented Refraction Beam with wall bounce support
- implemented Prism Node redirection / refraction setup interaction
- added Moth and Hollow enemy archetypes
- added reward choice step with three simple upgrades
- added developer testing shortcuts
- documented scope, architecture, controls, milestones, and devlog
