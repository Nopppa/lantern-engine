# Milestones

## Done now: v0.6.0 Lighting Overhaul shipped

Delivered in this repo now:

- packet/world-first lighting architecture across both `LightLabScene` and `RunScene`
- shared `LightWorld` / `LightWorldBuilder` path for authored and generated layouts
- direct solver -> `LightRenderPacket` flow as the primary render/query/runtime truth
- removal of legacy visual mirror arrays and old beam compatibility state from the active lighting path
- presentation-only native Godot lighting layer with decorative occluder shadows, explicit masks, and scene parity controls
- seeded generated Light Lab layouts with reroll support and cached static world reuse

## Done now: v0.5.3 Surface Optics & Navigation Truth patch shipped

Delivered in this repo now:

- flashlight visuals now draw traced, blocker-aware, surface-aware branches so visible flashlight behavior matches the lab's actual light truth much more closely than the old fake cone
- glass now reads as pass-through with slight bend + slight loss instead of a straight misleading continuation
- wood now shows broader scatter and less perfectly clean reflection, while wood flooring picks up subtle glow/widening when light travels across it
- wet stone now shows glossy disturbance / partial reflection rather than feeling inert
- flashlight cone widened slightly for clearer readable coverage without losing directionality
- enemies now route around walls/tree trunks with a lightweight waypoint/A* helper instead of walking straight into blockers forever
- `F1` now hides all overlay/debug/help elements needed for a clean unobstructed gameplay/test view

## Done now: v0.5.1 Unified Light Response patch shipped

Delivered in this repo now:

- shared response model now drives laser, flashlight, and prism light against the same material coefficients
- flashlight and prism light now create readable secondary response on lab surfaces instead of staying mostly detached visuals
- player, enemies, and the Hollow Matriarch now respect Light Lab wall collision instead of relying only on arena bounds
- shallow/deep wet test lanes now modulate movement speed for water-depth readability checks
- spawn/prism placement now avoid obviously blocked wall positions where practical
- material/intensity probe, section labels, and secondary beam/bounce instrumentation are clearer for validation

## Done now: v0.5.0 Light Lab pivot shipped

Delivered in this repo now:

- dedicated permanent Light Lab as the new default runtime
- authored outer walls + interior routing/occlusion segments
- authored surface bays for brick, wood, wet stone, mirror, glass, and prism routing
- manual debug spawning for Moth, Hollow, and Hollow Matriarch
- manual Prism placement plus fixed prism routing station
- first-pass modular light material definitions and beam/surface response logic
- flashlight local-intensity query with cone falloff and stronger center / softer edge
- rendering-side dead/alive blend prototype on the lab floor
- debug probes for material-under-cursor, local light intensity, beam hit markers, enemy HP labels, and base alive toggling
- Windows release artifact for the current patch

## Current posture

The project direction is now explicitly:

1. light behavior first
2. permanent validation map first
3. authored world/lab rules before broader exploration/combat expansion
4. modular systems, not a bigger `run_scene.gd`

## Legacy status

The old wave-survival / finite-arena run remains in the repo only as temporary legacy scaffolding.
It is no longer the default runtime, no longer the project center, and no longer the recommended place for new work.

## Recommended next patch

After this Light Lab pivot, the next patch should focus on:

- stronger authored interaction cases inside the lab
- better beam bounce/path visualization polish
- richer material response tuning and clearer comparison signage
- cleaner separation between debug tooling and reusable exploration systems
- deciding which Light Lab systems graduate directly into the future exploration runtime
