# Light Lab Runtime Boundary

Last updated: 2026-03-10  
Target version: `v0.5.3`

## Purpose

This note draws a hard line between:

- **reusable light/runtime logic** that should survive into the future exploration build
- **Light Lab authored content + debug presentation** that should stay lab-only unless explicitly generalized later

The point of `v0.5.2` is not to build exploration early.
It is to make migration honest and cheap when exploration runtime work begins.

## Reusable now

### `scripts/data/light_materials.gd`
**Status:** reusable now

This file is now the shared authored material truth for light response.
It should remain the single place for gameplay-facing coefficients such as:

- reflectivity
- diffusion
- transmission
- absorption
- roughness
- restoration affinity
- optional water metadata that materially affects traversal/readability

This is future-runtime-safe because it contains authored truth, not lab scene assumptions.

### `scripts/gameplay/light_response_model.gd`
**Status:** reusable now

This is the response contract between:

- source profile (`laser`, `flashlight`, `prism`)
- material definition
- outgoing readable gameplay branches

It is appropriate to graduate directly into future exploration runtime because it is not tied to the Light Lab map layout.

### `scripts/gameplay/light_query.gd`
**Status:** reusable now

New in `v0.5.2`.
This extracts generic point/segment/radial intensity queries out of `light_lab_scene.gd` so the math is no longer trapped inside the lab scene.

Reusable helpers now include:

- flashlight cone intensity query
- line/segment proximity intensity query
- radial falloff query

These are generic enough to support future exploration light checks, enemy exposure checks, restoration checks, and local debug probes.

### `scripts/gameplay/light_surface_resolver.gd`
**Status:** partly reusable now

Reusable pieces:

- secondary response generation against material truth
- branch metadata for reflection / transmission / diffusion readability
- beam path layering metadata (`layer`, `bounce_index`, `kind`)
- material-aware hit labeling and response routing

Not yet fully reusable:

- direct dependence on Light Lab scene-owned arrays like `surface_segments`, `surface_patches`, and `prism_stations`
- direct write-back into lab-owned debug arrays and temporary render-side overlays

Recommended next extraction step later:
- split the scene-agnostic tracing/query portion from the lab wiring layer
- keep the tracing core reusable, keep the lab assembly as an adapter

### `scripts/gameplay/light_lab_collision.gd`
**Status:** reusable with rename later

The helper itself is generic enough to survive beyond the lab.
The only thing lab-specific about it right now is the filename and current calling context.

Recommended later move:
- rename to a more general collision/query helper once exploration runtime starts consuming it outside the lab

### `scripts/gameplay/dead_alive_grid.gd`
**Status:** reusable prototype

The dead/alive blend cache is not exploration-ready in presentation terms, but the underlying idea is reusable:

- base alive state
- temporary light exposure
- smooth blend response over time

This should remain a prototype foundation, not final world-restoration architecture.

## Lab-only for now

### `scripts/data/light_lab_layout.gd`
**Status:** lab-only authored content

This is intentionally the authored test-map layout:

- comparison bays
- lane labeling
- prism station placement
- validation deck signage

It exists to stop `light_lab_scene.gd` from owning all authored content directly.
It should not be treated as exploration runtime content.

### `scripts/gameplay/flashlight_visuals.gd`
**Status:** partly reusable now

Reusable pieces:

- visible flashlight trace assembly from blocker/material truth
- pass-through / reflect / scatter branch presentation inputs
- extra local visual readability for wood/wet/glass interactions

Lab-only parts right now:

- direct dependence on the Light Lab scene contract/arrays
- current tuning language for the validation deck and signage expectations

### `scripts/gameplay/light_lab_navigation.gd`
**Status:** Light Lab-only for now

This is intentionally a small obstacle-routing helper for enemies in the authored validation space.
It solves wall/tree truth without pretending a full future-runtime navigation architecture already exists.

### `scripts/light_lab_scene.gd`
**Status:** lab coordinator only

This scene should continue owning:

- Light Lab presentation
- authored signage
- debug overlays
- manual spawn controls
- cursor probes
- validation-only render language

It should not become the future exploration runtime root.

## Migration rule going forward

When future exploration runtime starts:

1. keep `light_materials.gd` as shared truth
2. keep `light_response_model.gd` as shared response contract
3. consume `light_query.gd` directly for intensity/exposure checks
4. split generic tracing/query pieces further out of `light_surface_resolver.gd` only when exploration actually needs them
5. leave Light Lab signage/debug presentation in the lab unless a debug tool is explicitly promoted

## Honest non-extractions

These pieces are **not** extracted yet on purpose:

- Light Lab authored comparison map content
- Light Lab signage rendering
- debug-only bounce/path marker drawing
- cursor probe presentation strings

Reason:
These are valuable for validation, but generalizing them now would be premature architecture work.

Additional note from the `v0.5.2` refinement pass:
- tree trunks are currently authored as Light Lab validation blockers owned by `scripts/data/light_lab_layout.gd`
- the underlying blocker handling in `light_lab_collision.gd`, `light_query.gd`, and `light_surface_resolver.gd` is reusable logic
- the specific tree placement/content is still lab-only authored validation data

## Recommended next patch after `v0.5.2`

A sensible next patch would be a **runtime-light query consolidation pass**:

- separate generic trace inputs/outputs from the Light Lab scene object contract
- make secondary-light generation consume explicit query structs instead of the whole lab scene
- keep Light Lab overlays as a thin consumer of those outputs

That would move one more layer toward exploration readiness without pretending exploration content exists already.
