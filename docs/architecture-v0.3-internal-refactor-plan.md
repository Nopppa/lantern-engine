# Lantern Engine v0.3 Internal Refactor Plan

## Purpose

This plan is for **internal decomposition only**.

- no new gameplay features
- no visual rewrite
- no scene-system overhaul
- no "proper engine" detour
- yes to splitting `scripts/run_scene.gd` into smaller, safer units

Target: make the current MVP-0.x runtime easier to maintain while preserving the exact proven game loop.

---

## 1. Why refactor now, not earlier

### Why not earlier
Earlier, the right decision was to keep everything in one file:

- the core mechanic was still unproven
- beam + prism + bounce behavior needed fast tuning
- encounter pacing and reward flow were changing quickly
- readability and UX issues were still product questions, not architecture questions

A compact script reduced iteration cost during MVP-0.

### Why now
Now the project has crossed the point where the single-file approach is actively slowing safe changes:

- `run_scene.gd` is ~700 lines and owns too many responsibilities
- recent fixes landed in tightly coupled areas: beam path budget, run-complete state, help visibility, immortality toggle
- playtests show that small UX/input changes can accidentally affect end-state or discoverability
- the next work is likely stabilization, tuning, and small additions, which benefit from clearer boundaries more than raw prototype speed

### Practical trigger for refactor
Refactor now because the mechanic is proven enough, but the codebase is still small enough to split **without migration pain**.

If postponed further, future content work will pile onto the same file and make each bugfix riskier.

---

## 2. Proposed file split / modules

Keep `RunScene` as the orchestration root, but move logic out of it in passes.

### Recommended target structure

```text
scripts/
  run_scene.gd                        # thin coordinator / wiring

  runtime/
    run_state.gd                      # owned gameplay state container
    run_events.gd                     # optional constants / event names only if needed

  gameplay/
    beam_resolver.gd                  # beam trace, prism redirect, bounce continuation, hit checks
    encounter_controller.gd           # encounter start/advance/clear decisions
    reward_controller.gd              # reward offer + selection + application
    enemy_controller.gd               # enemy update loop, spawn specs, contact damage dispatch

  player/
    player_controller.gd              # movement, facing, action intent gathering
    debug_actions.gd                  # F1/F4/F2/F3 style debug/control toggles

  ui/
    hud_controller.gd                 # top-left and top-right text panels
    reward_panel_controller.gd        # reward panel population and selection visuals
    end_panel_controller.gd           # run complete / death panel content and visibility

  rendering/
    arena_renderer.gd                 # _draw pieces for arena, player, enemies, beam, prism, lighting zones
    lighting_builder.gd               # lit zone generation only

  data/
    encounter_defs.gd                 # current authored encounter arrays
    upgrade_defs.gd                   # current upgrade pool
```

### Important note
Do **not** convert everything into separate scenes yet. For v0.3 internal refactor, plain script extraction is enough.

---

## 3. Responsibility boundaries

### `run_scene.gd`
Owns only:
- node setup and references
- lifecycle hooks (`_ready`, `_process`, `_input`, `_draw`)
- calling the right controller in the right order
- passing shared state to modules

Should not contain detailed combat, reward, or UI string-building logic after the refactor.

### `runtime/run_state.gd`
Owns:
- mutable run data
- player stats
- cooldown timers
- encounter progression flags
- debug flags
- beam segment cache
- lit zone cache
- last-event text

This should be the single source of truth for current run state.

### `gameplay/beam_resolver.gd`
Owns:
- beam cast validation
- total range budgeting
- wall bounce chaining
- prism redirect chaining
- segment vs circle hit tests
- enemy damage along segments
- beam segment output for rendering
- event text related to beam outcomes

Should not own player movement, reward logic, or HUD text.

### `gameplay/enemy_controller.gd`
Owns:
- enemy spawn data -> runtime enemy instance creation
- moth/hollow update behavior
- death timer cleanup
- contact damage requests back to run state / caller

Should not decide encounter advancement or reward presentation.

### `gameplay/encounter_controller.gd`
Owns:
- start encounter
- determine encounter clear
- move to next encounter or mark run complete

Should not build reward UI itself.

### `gameplay/reward_controller.gd`
Owns:
- selecting current reward options
- input-level reward selection state
- applying upgrade effects to run state

Should not own the panel nodes themselves.

### `player/player_controller.gd`
Owns:
- movement vector
- facing updates
- mouse/world targeting intent
- action intent detection for beam/prism

Should return intent/results, not directly mutate UI.

### `player/debug_actions.gd`
Owns:
- help toggle
- immortality toggle
- quick refill
- dev reward/dev spawn input handling if kept

Reason: recent playtests show debug/help/input behavior is a real failure cluster and deserves isolation.

### `ui/hud_controller.gd`
Owns:
- main HUD text
- status/help text
- discoverability messaging
- immortal/help state visibility

Should not change gameplay state except perhaps focus/selection handoff.

### `ui/reward_panel_controller.gd`
Owns:
- reward button text
- selected highlight state
- panel visibility
- focus behavior

### `ui/end_panel_controller.gd`
Owns:
- end panel text
- run complete vs death copy
- restart button hookup state

### `rendering/lighting_builder.gd`
Owns:
- `lit_zones` construction from player, beam, prism, and enemies

### `rendering/arena_renderer.gd`
Owns:
- all drawing code currently packed into `_draw()`
- only consumes state and cached geometry
- no gameplay mutation

### `data/encounter_defs.gd` and `data/upgrade_defs.gd`
Owns:
- inline arrays moved out of the main runtime file

This is low-risk extraction and makes tuning safer.

---

## 4. Safest split order

Do this in **stabilization-first order**, not by theoretical purity.

### Pass 1 — Extract static data and simple helpers
Extract first:
- `UPGRADE_POOL` -> `data/upgrade_defs.gd`
- `encounters` -> `data/encounter_defs.gd`
- `_bar()` helper
- UI text formatting helpers if any

Why first:
- almost no behavior risk
- immediately reduces clutter in `run_scene.gd`
- makes later modules less noisy

### Pass 2 — Isolate help/debug/input handling
Extract:
- `_input()` key handling for `F1` / `F4`
- quick refill / restart / debug reward/spawn handling
- help state + immortal toggle helpers

Why second:
- this is the currently proven fragile area from playtests
- isolating it reduces accidental breakage during later gameplay extraction

### Pass 3 — Separate reward flow from encounter flow
Extract:
- `_show_rewards`
- `_handle_reward_input`
- `_update_reward_button_states`
- `_select_reward`

Why before combat split:
- reward flow is UI-heavy and self-contained
- it is easier to verify than beam math
- it removes one major state branch from `_process()`

### Pass 4 — Separate encounter orchestration
Extract:
- `_check_encounter_complete`
- `_start_encounter`
- encounter progression / run-complete transition

Why here:
- once rewards are out, encounter logic becomes cleaner
- clarifies who decides when the run advances or ends

### Pass 5 — Extract beam/combat resolver
Extract:
- `_cast_refraction_beam`
- `_beam_to_bounds`
- `_reflect_if_wall`
- `_segment_circle_hit`
- `_damage_enemies_along_segment`
- `_redirected_prism_direction`

Why after the simpler passes:
- this is the most behavior-sensitive and most likely to regress
- recent bugfixes prove this code must be moved carefully, last among core systems

### Pass 6 — Extract enemy update logic
Extract:
- `_update_enemies`
- `_spawn_enemy`
- enemy cleanup behaviors
- contact damage request path

### Pass 7 — Extract rendering and lighting cache builders
Extract:
- `_build_lit_zones`
- `_draw`

Why last:
- drawing code is large but mostly cosmetic
- gameplay correctness matters more than renderer neatness
- moving render code too early makes debugging logic harder

---

## 5. What should NOT be refactored yet

Do not spend v0.3 time on these yet:

### No ECS/component architecture
Too heavy for the current game size.

### No resource-driven content pipeline
The encounter and upgrade data can move to dedicated script files, but do not build a full authoring pipeline yet.

### No scene-per-actor conversion
Moth, Hollow, Prism Node, beam FX, and player do not yet need their own production scene stack.

### No signal-heavy event bus
Direct calls are still fine at this size. Introducing a generic event system now would add indirection without real payoff.

### No save/load or meta progression infrastructure
Out of scope for internal cleanup.

### No lighting-system rewrite
Keep the current cheap 2D draw-based lighting/readability method unless a concrete gameplay need forces change.

### No broad naming/style churn
Avoid cosmetic renames that create noisy diffs while behavior is being stabilized.

---

## 6. Risks and regression avoidance

### Main risks
1. **Beam math regressions**
   - total range budgeting breaks again
   - bounce continuity breaks
   - prism redirect no longer chains correctly

2. **Input discoverability regressions**
   - `F1` and `F4` break again during extraction
   - restart/help behavior diverges between live run and end panel

3. **State ownership confusion**
   - both `RunScene` and a controller mutate the same flags
   - reward/run-over/encounter-active become inconsistent

4. **Rendering becoming coupled to hidden logic**
   - `_draw()` accidentally depends on module internals instead of stable state

### Rules to avoid regressions

#### Rule A — Keep one source of truth
All mutable gameplay state should live in a single shared state object or clearly grouped `RunScene` fields during transition.

#### Rule B — Extract behavior without redesigning it
First move code mostly as-is. Improve structure first, behavior second.

#### Rule C — Preserve current public flow
During refactor, the runtime order should stay recognizable:

1. read inputs
2. early exits (`restart`, `run_over`, reward modal)
3. update timers/state
4. player actions
5. enemy updates
6. encounter checks
7. UI update
8. draw from cached state

#### Rule D — Validate after every pass
After each pass, do a short manual smoke test for:
- movement
- beam fire
- prism placement
- bounce path length
- reward selection with keyboard and mouse
- `F1` help toggle
- `F4` immortality toggle
- run complete -> restart

#### Rule E — Prefer adapter phase over big-bang cutover
It is fine if `run_scene.gd` temporarily calls helper modules with old-style dictionaries/arrays first. Full cleanup can happen after behavior is stable.

### Suggested regression checklist
Use this checklist after each extracted pass:

- game boots to run scene
- HUD visible on first launch
- `F1` toggles help reliably before and after clearing encounters
- `F4` toggles immortality and HUD reflects state
- beam respects one shared total range across all bounces
- prism redirect still continues pathing
- reward panel accepts `1/2/3`, `W/S`, `Enter/E`, and mouse click
- clearing 3/3 shows clear end state
- `R` restart works during run and after run complete

---

## 7. Recommended minimum first refactor pass

If only one pass is funded right now, do this:

## Minimum Pass = Input/Reward split, leave beam math where it is

### Scope
Extract only:
- `debug_actions.gd`
- `reward_controller.gd`
- `reward_panel_controller.gd`
- `data/upgrade_defs.gd`
- `data/encounter_defs.gd`

Keep in `run_scene.gd` for now:
- beam logic
- enemy logic
- lighting builder
- full draw code

### Why this is the best first pass
- directly targets the most recently broken area: help/input/discoverability
- removes the modal reward branch that currently complicates `_process()`
- reduces `run_scene.gd` size meaningfully without touching the riskiest beam path code yet
- gives immediate maintenance value with low chance of combat regression

### Expected outcome of the minimum pass
After this pass, `run_scene.gd` should mostly read like:
- setup scene
- delegate debug/input
- delegate reward modal flow
- run core gameplay loop
- update HUD
- draw

That is enough to make the next pass (encounter or beam extraction) much safer.

---

## Recommended implementation sequence summary

1. move upgrade and encounter data out of file
2. isolate debug/help/input handling
3. isolate reward flow + reward panel presentation
4. isolate encounter progression
5. extract beam resolver
6. extract enemy controller
7. extract lighting builder and renderer last

---

## Bottom-line recommendation

Do **not** attempt a full production architecture rewrite.

Do a **small, staged internal split** with the first milestone focused on:
- debug/help input reliability
- reward flow isolation
- data extraction out of `run_scene.gd`

Then, only after those are stable, move the beam/combat resolver.

That gives Lantern Engine the best tradeoff for a solo dev / small team:
- lower bug risk
- cleaner ownership
- no lost momentum
- no fake-engineering detour
