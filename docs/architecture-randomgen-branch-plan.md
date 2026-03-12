# RandomGEN Exploration World – Branch Architecture Plan

> **Partially obsolete for worldgen architecture unless aligned with `TRUTH.md`.** This document may still be useful as branch history and implementation context, but `TRUTH.md` is now the authoritative source for exploration/worldgen architecture. Any conflicting assumptions about generation ownership, layering, or world structure are obsolete.

**Date:** 2026-03-12  
**Status:** Architecture design / pre-implementation  
**Target branch:** `feature/randomgen-exploration-world`

---

## Executive Summary

This document defines a branch plan for building a **RandomGEN exploration world** that can later merge back into `main` cleanly.

The key architectural decision is:

> **Do not fork the lighting/gameplay truth stack.**

Instead, the generated world must reuse the same core systems already used by Light Lab:

- `LightWorld` as world truth for blockers, materials, entities, metadata
- `LightField` as gameplay light truth
- render packets as visual/presentation boundary
- shared material definitions and response model
- shared beam/material interaction solvers

### High-level direction

- Keep **Light Lab** as the authored validation map.
- Build **RandomGEN** as a separate exploration runtime branch.
- Reuse the same shared lighting/material pipeline in both.
- Introduce a cleaner **world provider / runtime adapter seam** so generated worlds do not depend on Light Lab-specific scene assumptions.
- Merge shared refactors early; keep exploration-specific runtime work isolated until ready.

---

## Branch Recommendation

**Recommended branch name:**
- `feature/randomgen-exploration-world`

### Purpose of this branch

- build a true generated exploration runtime
- preserve current performance constraints
- preserve gameplay-light vs visible-light separation
- keep material behavior identical to Light Lab
- stay mergeable back into `main` without a giant rewrite

---

## Current Architecture Readout

The repo is already partially prepared for this direction.

### Shared systems that are already in the right shape

#### `LightWorld`
Already acts as a stable world-truth container for:
- occluder segments
- material patches
- light entities
- metadata

This is the right shared object for authored and generated worlds.

#### `LightField`
Already acts as gameplay-light truth.
This should remain the sole source of truth for gameplay light queries.

#### Render packet boundary
The render packet flow already provides a clean separation between:
- gameplay/light solver truth
- visible presentation output

That separation must remain intact in RandomGEN.

#### Material truth
Material behavior is already centralized through shared data/model files.
Generated worlds should **reuse exactly the same material definitions**.

---

## What is already useful for RandomGEN

The current codebase already contains important seeds for generated-world support:

- `LightWorldBuilder`
- Light Lab world adapter logic
- generated smoke-test hooks inside Light Lab runtime
- dead/alive zone metadata flow
- shared collision/material/light query helpers

This means the project does **not** need a second lighting architecture.
It needs a cleaner runtime seam and a dedicated generated-world runtime.

---

## Main Architectural Problem to Solve

The biggest current coupling is:

> parts of the lighting/gameplay runtime still depend too directly on a **LightLabScene-shaped** context.

That is workable for the current authored validation scene, but it is the wrong long-term contract for a generated exploration runtime.

### What this means in practice

The generated world branch should not try to turn Light Lab into the exploration game.
Instead it should:

1. preserve Light Lab as the validation environment
2. extract the reusable world/runtime contract
3. create a new exploration runtime on top of that contract

---

## Proposed Branch Strategy

Use a **two-lane strategy**.

### Lane A — shared refactors that should merge back early

These are merge-friendly and worth landing in `main` incrementally:

1. world/runtime abstraction seam
2. solver dependency cleanup away from Light Lab-specific assumptions
3. richer `LightWorld` metadata/data shape where needed
4. shared utilities for generated world building and validation

### Lane B — exploration-branch-specific runtime work

These can remain branch-local longer:

1. procedural generation logic
2. exploration scene/runtime
3. room/region graph generation
4. exploration progression/pacing
5. branch-specific UI and placeholder flow

### Why this works

- reduces merge conflicts
- keeps main stable
- allows partial progress to remain useful
- avoids “one huge impossible merge later”

---

## Shared Systems vs Branch-Specific Systems

## Shared systems (must remain single-source)

These should remain shared between Light Lab and RandomGEN:

- `LightWorld`
- `LightWorldBuilder` (or a generalized builder layer)
- `LightField`
- material definitions
- material response model
- light query helpers
- beam/material interaction solvers
- gameplay-light write path from packets/segments/zones/fills into `LightField`
- dead/alive grid logic
- collision/query helpers where not lab-specific

## Branch-specific systems

These belong to the RandomGEN branch/runtime:

- procedural world generation
- room/corridor/region layout generation
- biome/theming logic
- generated placement rules for obstacles/material patches/prism emitters
- exploration scene/controller
- generated-world specific progression and content pacing

## Light Lab-specific systems that should stay local

These should remain authored-map specific:

- lab signage / authored comparison content
- validation-map-specific overlays
- lab-specific teaching/debug presentation
- authored room layout source data

---

## Proposed Abstractions / Interfaces

## 1. World layout/provider seam

A dedicated provider abstraction is warranted.

### Goal
Allow scenes to ask for a world from either:
- authored validation layout
- generated exploration layout

without changing the lighting/material/gameplay stack.

### Suggested shape

```gdscript
class_name WorldLayoutProvider

func build_static_layout(seed: int, options: Dictionary = {}) -> Dictionary
func build_light_world(layout: Dictionary, arena_rect: Rect2, options: Dictionary = {}) -> LightWorld
func metadata() -> Dictionary
func spawn_hint() -> Vector2
```

### Likely implementations

- `AuthoredLightLabProvider`
- `GeneratedExplorationProvider`

This avoids forcing Light Lab adapter code to become the permanent abstraction.

---

## 2. Runtime/world adapter seam

Separate **static world data** from **runtime entity refresh**.

### Suggested shape

```gdscript
class_name WorldRuntimeAdapter

func static_world() -> LightWorld
func runtime_entities() -> Array
func collision_space() -> Dictionary
func patch_at(pos: Vector2) -> Dictionary
func dead_alive_zones() -> Array
```

### Why

Current solver/runtime code still expects a scene-like object with helper methods.
This adapter seam is cleaner and easier to share across scenes.

---

## 3. Light solver context

The shared solver path should move toward a smaller context object/dictionary instead of depending directly on a `LightLabScene`-shaped host.

### Suggested responsibility bundle

```gdscript
{
  "world": LightWorld,
  "visibility_fn": Callable,
  "player_pos": Vector2,
  "facing": Vector2,
  "beam_offset": float,
  "current_prism_radius": float,
  "prism_energized_fn": Callable,
  "damage_segment_fn": Callable
}
```

### Benefit

This keeps the solver:
- reusable
- scene-agnostic
- easier to test against authored and generated worlds alike

---

## Data Model for Generated World

Generated worlds should still compile into the same `LightWorld` structure.

### Generated world should describe at least

- occluder segments
- material patches
- tree/obstacle circles or entities
- prism emitters/stations
- dead/alive zones
- navigation / spawn metadata
- region / room metadata

### Suggested metadata additions

Useful exploration metadata might include:

- `spawn_hint`
- `room_defs`
- `corridor_defs`
- `poi_defs`
- `dead_alive_zones`
- `layout_signature`
- `region_seed`
- `world_type`

### Important rule

Generated data should still resolve into the same material IDs and the same shared material-response rules.

---

## Scene / Gameplay Integration Plan

## New runtime scene

Create a new scene instead of stretching Light Lab into exploration runtime.

**Recommended new scene:**
- `scenes/exploration_scene.tscn`
- `scripts/exploration_scene.gd`

### Responsibilities of the new scene

- request or generate a world from generated-world provider
- initialize `LightWorld`
- initialize `LightField`
- run shared gameplay-light and visual-light pipelines
- host player/exploration logic
- remain parallel to Light Lab, not embedded inside it

### Responsibilities Light Lab should retain

- validation of material/light behavior
- authored comparison environment
- smoke-test/debug aid for lighting correctness

---

## Lighting / Material Consistency Plan

The generated world must follow the same rules as the authored one.

### Non-negotiables

- gameplay light stays separate from visible light
- gameplay logic never depends on rendered pixels
- visible light may inform gameplay through shared packet/field logic, not screen reads
- mirror/glass/material behavior must stay identical across worlds
- restoration behavior must remain gradual and field-based

### Practical consistency rule

If a material interaction works one way in Light Lab, it must work the same way in RandomGEN because:
- same material definitions
- same response model
- same solver path
- same gameplay LightField write path

No duplicate material logic should exist in the RandomGEN branch.

---

## Validation Strategy Across Both Worlds

To keep generated and authored behavior aligned, both runtimes should share validation habits.

### Recommended validation checks

- flashlight on mirror behaves the same in both worlds
- flashlight on glass behaves the same in both worlds
- prism emission/energizing works the same in both worlds
- dead/alive restoration still uses same gameplay truth
- collision/material patches queried the same way in both worlds
- visible-light-informed gameplay influence still uses shared packet/field logic

### Recommended long-term debug capability

Support equivalent probes in both scenes for:
- material under cursor
- gameplay light intensity at point
- beam hit / response markers
- dead/alive mask state

---

## Migration / Merge Plan Back to Main

### Recommended merge sequence

#### Phase 1 — shared seams
Merge early:

1. world provider / runtime adapter interfaces
2. solver dependency cleanup
3. additive `LightWorld` metadata/schema improvements
4. shared generated-world helper utilities

#### Phase 2 — generated world builder path
Merge when stable:

5. generated layout/provider logic
6. `LightWorldBuilder` extensions for exploration world

#### Phase 3 — exploration runtime
Merge later:

7. new exploration scene
8. generated exploration gameplay loop
9. optional main-menu integration or mode routing

### Why this order is correct

It keeps shared infrastructure useful even before exploration mode is feature-complete.

---

## Risks and Mitigations

### Risk 1 — lighting logic gets duplicated

**Bad outcome:** Light Lab and RandomGEN drift apart  
**Mitigation:** single shared material/solver/LightField pipeline only

### Risk 2 — generated runtime depends too much on Light Lab scene methods

**Bad outcome:** branch becomes unmergeable spaghetti  
**Mitigation:** introduce adapter/context seams early

### Risk 3 — scope explodes into full game rewrite

**Bad outcome:** branch stalls and never lands  
**Mitigation:** focus on exploration-runtime skeleton first, not full game design

### Risk 4 — merge conflicts in shared world builder/runtime files

**Bad outcome:** painful late merge  
**Mitigation:** rebase often, merge shared refactors early and in small commits

### Risk 5 — performance regressions in bigger generated worlds

**Bad outcome:** acceptable Light Lab performance does not translate  
**Mitigation:** keep generated-world MVP modest in size and preserve current approximation strategy

---

## Recommended First Implementation Milestones

## Milestone 1 — Shared seam extraction

- introduce world provider/runtime adapter seam
- reduce direct Light Lab runtime coupling in solver inputs
- keep behavior unchanged

## Milestone 2 — Generated world data path

- create generated layout/provider that resolves into `LightWorld`
- keep it simple and inspectable
- support blockers/material patches/prism emitters/dead-alive metadata

## Milestone 3 — Exploration scene shell

- create new exploration runtime scene
- load generated world
- support movement/collision/basic light/runtime boot

## Milestone 4 — Lighting/material parity

- verify mirror/glass/material interactions behave the same as in Light Lab
- verify restoration and gameplay light queries behave consistently

## Milestone 5 — Exploration usefulness

- add enough structure that the generated runtime is worth testing and exploring
- keep future progression/content work separate from lighting architecture work

---

## Suggested Commit Sequence Strategy

A practical commit train for this branch:

1. `refactor(world): add world provider/runtime adapter seam`
2. `refactor(light): reduce LightLabScene-specific solver coupling`
3. `refactor(world): extend LightWorld metadata for generated runtime`
4. `feat(worldgen): add generated exploration provider scaffold`
5. `feat(exploration): add exploration scene scaffold`
6. `feat(exploration): boot generated LightWorld through shared pipeline`
7. `feat(worldgen): add generated blockers/material patches/prism emitters`
8. `test(exploration): add parity/debug validation for authored vs generated worlds`
9. `docs(worldgen): document exploration branch architecture`

---

## Final Recommendation

Build RandomGEN as a **parallel exploration runtime branch**, not as a mutation of Light Lab.

The correct long-term structure is:

- **Light Lab** = authored validation map
- **RandomGEN** = generated exploration runtime
- **Shared core** = LightWorld + LightField + packet/render/material/solver stack

That gives the project:

- clean mergeability
- consistent material behavior
- preserved lighting architecture
- a proper path toward exploration gameplay without destabilizing the current validated lighting pipeline

---

**Recommended next step:**
Create the branch from clean `main`, land the doc first, then start with the shared runtime/world seam before implementing the exploration scene itself.
