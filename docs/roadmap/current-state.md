# Current State

Last updated: 2026-03-11  
Current shipped version target: `v0.6.0`

## Status

The lighting-overhaul program is complete enough to treat as the current project baseline.

- **Phase 1 — Lock interfaces:** done
- **Phase 2 — Build LightWorld from map data:** done
- **Phase 3 — Render pipeline clean separation:** done
- **Phase 4 — Native Godot helper pass:** done
- **Phase 5 — Randomgen integration:** done

## Locked architectural state

The project now runs on a **packet/world-first** lighting architecture:

- solver/gameplay truth lives in `LightWorld`, shared solver logic, and `LightRenderPacket`
- authored and generated layouts flow through the same `LightWorld` / builder path
- rendering, queries, and runtime consumers now read packet/world data directly instead of scene-owned visual mirror arrays
- native Godot lighting (`CanvasModulate`, `PointLight2D`, `LightOccluder2D`) is presentation-only and does not replace gameplay truth

## What is now true in practice

### Shared world path
- `LightWorldBuilder` constructs shared world data for authored and generated layouts
- `LightLabWorldAdapter` builds through the shared builder/cache path instead of a bespoke scene-only world assembly path
- world metadata carries dead/alive zones and spawn hints through the same path

### Packet-first scenes
- `RunScene` and `LightLabScene` now consume render packets as the sole visual/runtime truth for active light presentation
- legacy visual mirror arrays and `beam_segments` compatibility state were removed from the active lighting path

### Presentation-only native layer
- native additive lights and decorative occluder shadows now sit on top of packet/world truth
- flashlight is the selective native shadow caster
- native masks/layers are explicit and isolated from gameplay evaluation

### Procedural integration
- generated Light Lab layouts can be enabled and rerolled by seed
- generated layouts feed the same lighting/query/presentation pipeline as authored layouts
- static layout-derived world data is cached by signature, while runtime entities can refresh separately

## What remains next

The lighting-overhaul phase chain itself is now closed. The next sensible work modes are:

1. documentation / handoff refresh
2. QA / playability verification
3. build / release checkpoint

Further rendering experiments or larger procedural systems should start as new work, not as unfinished Phase 1–5 carryover.
