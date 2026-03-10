# Milestones

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
