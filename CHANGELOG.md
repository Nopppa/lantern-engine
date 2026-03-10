# Changelog

## 0.5.2 - 2026-03-10

Light Lab Readability & Extraction patch:

- extracted Light Lab authored comparison content into `scripts/data/light_lab_layout.gd` so bay/lane/prism/deck content no longer lives as a long inline build block inside `scripts/light_lab_scene.gd`
- extracted generic intensity helpers into `scripts/gameplay/light_query.gd`, establishing a reusable boundary for flashlight cone checks, segment/path exposure checks, and radial light queries beyond the lab
- upgraded Light Lab authored signage to use titled comparison cards plus short behavior hints for brick, wood, wet stone, mirror, glass, prism station, shallow water, deep water, dead/alive blend zone, and the open spawn validation deck
- improved secondary-light readability with clearer response-specific overlay language: transmitted glass continuation now reads as dashed aqua continuation, diffuse spread reads as warm cloud/ring response, flashlight secondary response reads warm, prism secondary response reads cyan, and wet/mirror-style reflected streaks remain clean directional lines
- improved beam-path instrumentation with per-layer `L0/L1/L2...` path labeling, stronger bounce/redirect markers, and metadata for primary vs redirected/secondary path order so testers can follow the logic without reading code
- strengthened water readability: shallow/deep lanes now slow movement much more noticeably, and wet-light response now shows clearer glossy disturbance rather than reading as a perfectly straight unaffected pass
- added hard flashlight occlusion against brick walls and solid tree trunks so no obvious light leaks through blockers; tiny local response remains only at/near the contacted surface
- added solid tree trunks to the Light Lab as movement blockers and beam/light blockers; player movement, beam tracing, and flashlight queries now all respect trunk solidity
- made `F1` a true full overlay toggle for the Light Lab so both top panels disappear for unobstructed testing view and return cleanly on the next press
- slightly widened flashlight/prism restoration influence so alive/dead response reads more naturally without turning into a floodlight
- documented the reusable-vs-lab-only migration boundary in `docs/light_lab_runtime_boundary.md` and updated project docs to point at the extracted/shared light pieces honestly
- updated release metadata for `v0.5.2`

## 0.5.1 - 2026-03-10

Unified Light Response patch:

- unified laser, flashlight, and prism light around a shared response model in `scripts/gameplay/light_response_model.gd`, so all three now resolve against the same reflectivity / diffusion / transmission / absorption material truth instead of flashlight/prism behaving as detached visual-only light
- upgraded `scripts/gameplay/light_surface_resolver.gd` so flashlight and prism light now generate secondary reflected / transmitted / diffused response on authored lab surfaces; mirror, glass, brick, wood, and wet surfaces now show readable differences even without firing only the laser
- added collision-aware movement through `scripts/gameplay/light_lab_collision.gd` and wired it into the Light Lab player, enemies, and Hollow Matriarch movement/pounce targeting so walls behave as real blockers instead of mere arena clamps
- added light-touch water-depth slowdown lanes in the lab using wet-surface metadata plus shallow/deep labels; shallow water only trims movement slightly while deeper water slows more noticeably but still stays readable
- hardened manual spawn/prism placement with blocked-position checks and nearest valid placement fallback so debug objects do not casually appear inside walls
- improved Light Lab debug readability with material coefficient probe text under the cursor, local intensity readout, secondary light/bounce instrumentation, persistent section labels, and live step-speed feedback for water testing
- updated docs and release metadata for the new `v0.5.1` Light Lab baseline

## 0.5.0 - 2026-03-10

Direction-pivot Light Lab patch:

- replaced the old wave-survival arena as the main runtime with a dedicated permanent `Light Lab` scene loaded from `scripts/main.gd -> scenes/light_lab_scene.tscn`
- authored a real lab layout with outer walls, internal routing segments, separate brick / wood / wet / mirror / glass material bays, a prism routing station, dead/alive blend lanes, and an open validation deck for manual spawn testing
- added first-pass modular light-surface data + runtime handling through `scripts/data/light_materials.gd`, `scripts/gameplay/light_surface_resolver.gd`, and `scripts/gameplay/dead_alive_grid.gd`
- upgraded flashlight validation in the lab to use cone falloff with a brighter center, softer edge, and queryable local intensity that now feeds gameplay checks and the dead/alive blend prototype
- implemented readable surface behavior differences: mirror clearly reflects, glass partially transmits (with a weak reflected branch), brick heavily absorbs, wood diffuses softly, wet stone reflects more strongly than brick/wood, and prism routing stays a gameplay-special redirect surface
- removed automatic encounter flow from the primary map; the lab now persists until manually reset and only spawns Moth / Hollow / Hollow Matriarch through debug controls
- added lab debug affordances for cursor material probe, local light intensity probe, beam-hit visualization, enemy HP labels, base alive toggle, and manual prism placement/spawn testing
- kept the old authored wave prototype available in the repo as legacy scaffolding instead of deleting it outright
- validated with headless boot and Windows export; packaged a fresh Windows release artifact for GitHub Releases

## 0.4.4 - 2026-03-10

First Hollow Matriarch miniboss shipping pass:

- added authored boss-data loading through `scripts/data/boss_defs.gd`, so the runtime now consumes `scripts/data/bosses/hollow_matriarch.json` as live input instead of decorative spec data
- extended round 5 into a two-step finisher: the normal mixed pack still spawns first, then the Hollow Matriarch enters only after those enemies are cleared
- shipped the Stage-1 Hollow Matriarch kit from the implementation plan: darkness regeneration, regen suppression in flashlight/Prism light, shadow-bolt pressure with projectile HP and light corrosion, readable Veil Pounce, and a 50% HP cadence escalation
- made Prism light act as anti-darkness light for the miniboss/hollow rules where appropriate, so it can suppress regen and help melt shadow bolts just like the fight spec requires
- made Prism Surge explicitly jam/interrupt the boss special instead of only functioning as generic burst damage
- validated with headless boot and Windows export; packaged a fresh Windows release artifact for GitHub Releases

## 0.4.3 - 2026-03-10

Focused follow-up patch for Prism Surge's debuff identity:

- added **Light Burn** to Prism Surge: enemies caught in the blast are seared for 4.0s, taking 1.5 damage every 0.5s while the existing shove, refund, and special-jam behavior remain intact
- made the debuff readable in moment-to-moment play with a warm luminous burn ring, a live duration arc around afflicted enemies, and hit feedback when each burn tick lands
- kept the implementation in the extracted gameplay/data layer by extending Surge auth/data plus enemy debuff ticking instead of re-growing `run_scene.gd`
- updated only the shipped copy/artifact metadata needed for the new Light Burn behavior
- validated with headless boot and Windows export; packaged a fresh Windows release artifact for GitHub Releases

## 0.4.2 - 2026-03-10

Focused follow-up patch for the first Prism Surge playtest notes:

- fixed Prism Node readiness UI so it now shows `ACTIVE`, a live recharge timer, or `READY` from the same timer/state truth used by placement logic; consuming a node with Surge no longer leaves the HUD lying about readiness
- gave Prism Surge a cleaner identity as a special-jam burst: enemies hit by the blast have their special abilities disabled briefly, and Hollow blinks are interrupted/locked out during that jam window
- kept Surge otherwise compact: the shipped behavior is still burst damage + shove + node consumption, with the new debuff identity replacing the earlier vague feel instead of piling on extra slows / DoTs
- updated skill/help text only where needed to describe the shipped Surge debuff behavior
- validated with headless boot and Windows export; packaged a fresh Windows release artifact for GitHub Releases

## 0.4.1 - 2026-03-10

MVP-1 patch 2 third-skill pass:

- added Prism Surge as the third Prism skill on `Q`, consuming the active Prism Node to release a radial burst that damages and shoves nearby enemies
- kept the new skill inside a cleaner data-driven/runtime split by introducing `scripts/data/skill_defs.gd` for authored skill stats and `scripts/gameplay/skill_controller.gd` for active skill execution instead of re-growing `scripts/run_scene.gd`
- added `Surge Capacitors` to the existing reward pool so the current reward/content structure can deepen the new skill without a parallel bespoke path
- updated HUD/help/control copy just enough to surface the new skill and its live stats cleanly
- extended run summary tracking with Prism Surge casts so the new button shows up in the end report only where it matters
- validated with headless boot and Windows export; packaged a Windows release artifact for GitHub Releases

## 0.4.0 - 2026-03-10

MVP-1 patch 1 finish pass:

- completed the first authored MVP-1 run as a 5-encounter chain using encounter data from `scripts/data/encounter_defs.gd` instead of inline scene-script content
- completed the cleaner data-driven content layer by keeping encounter definitions and upgrade definitions in dedicated data files and tightening reward-pool filtering/fallback around encounter tags and already-taken upgrades
- completed Prism Node upgrade depth at runtime: Prism upgrades now affect redirect damage, redirect catch radius, redirect bend angle, and post-redirect bounce continuation instead of existing only as partial scaffolding
- completed the simple run summary as a real runtime-fed report, with encounter progression, chosen upgrades, beam casts, prism placements, prism redirects, damage dealt/taken, and per-enemy kill counts populated from gameplay events
- fixed final-encounter flow so the run ends cleanly into the summary instead of incorrectly trying to open another reward step after the last authored encounter
- validated with headless boot and Windows export; packaged a Windows release artifact for GitHub Releases

## 0.3.5 - 2026-03-10

Final MVP-0 polish / finish pass:

- tightened reward readability with a larger reward panel, clearer selected-state styling, direct beam-stat context while paused, and short delta-focused reward text so testers can parse the upgrade impact faster
- added lightweight impact polish: beam hits now spawn short radial hit flashes at the contact point, with a larger confirmation pop on kills
- added tiny synthesized runtime SFX for beam fire, hit, kill, reward navigation, and reward confirm without introducing external asset pipeline overhead
- documented the finish-pass validation note and marked MVP-0 as effectively complete pending normal tester confirmation on the packaged Windows artifact
- validated with headless boot and Windows export

## 0.3.4 - 2026-03-10

Regression fix + enemy runtime extraction pass:

- fixed tester-visible dev shortcut regressions where `F2` refill and `F3` reward trigger could appear to do nothing because they were only polled in `_process` and could be swallowed by UI focus
- handled `F2` and `F3` directly from raw key input, matching the earlier reliability fix approach used for `F1` / `F4`
- made dev refill revive out of the run-over/end-panel state so testers can resume immediately instead of seeing a refilled but still locked run
- made forced reward open from run-over state and reordered `_process()` so reward modal handling wins before the run-over early return
- extracted enemy runtime update / state handling out of `scripts/run_scene.gd` into new `scripts/gameplay/enemy_controller.gd`
- kept `scripts/gameplay/beam_resolver.gd` as the single beam/combat path authority; `run_scene.gd` now coordinates beam, encounter, reward, and enemy modules instead of re-owning those details
- validated with headless boot and Windows export

## 0.3.3 - 2026-03-10

Combat/runtime decomposition pass:

- extracted beam path / bounce / prism redirect / beam-hit logic into `scripts/gameplay/beam_resolver.gd`
- extracted encounter start / completion / enemy spawn orchestration into `scripts/gameplay/encounter_controller.gd`
- reduced `scripts/run_scene.gd` to a thinner runtime coordinator for these systems
- updated roadmap + code map docs to reflect the new internal structure and next recommended step
- no intended gameplay/design changes; structure-first maintenance pass

## 0.3.2 - 2026-03-10

Enemy freeze fix (Playtest 07 follow-up):

- fixed bug where both Moth and Hollow could freeze completely when overlapping the player position
- root cause: `(player_pos - enemy_pos).normalized()` returns `Vector2(0,0)` at zero distance, killing all direction-based movement and blink targeting
- added safe direction fallback (random outward push) when enemy is within 2px of player
- no gameplay/design changes — pure stability fix

## 0.3.1 - 2026-03-10

Disrupted blink transit fix (Playtest 06 follow-up):

- replaced instant teleport during light-disrupted blink with a visible 0.28s linear transit phase
- hollow now moves visibly from start to end position during transit, flickering/shimmering
- windup phase (0.4s jitter) retained before transit for readability
- transit shows rapid flicker between orange disruption glow and purple ghost afterimage
- faint trail line drawn between start and end positions during transit
- blink distance in light still reduced (40% of normal)
- blink cooldown after disrupted blink slightly longer (2.6s vs 2.4s)
- result: player can read both origin and destination, movement is fast but not instant

## 0.3.0 - 2026-03-10

Blink readability fix (Playtest 05 follow-up):

- hollow blink in flashlight cone now has a visible 0.4s windup/hesitation phase with positional jitter and rapid flicker rings, so the player clearly sees the light disrupting the blink
- disrupted blink distance reduced to 40% of normal (was 45%)
- post-blink shimmer extended to 0.7s (was 0.6s)
- blink cooldown after disrupted blink slightly longer (2.6s vs 2.4s)
- HUD event text shows "Hollow struggling to blink..." during windup
- no new systems, no hard-counter — blink still works, just visibly worse

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
