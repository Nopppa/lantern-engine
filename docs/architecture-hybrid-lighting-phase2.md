# Hybrid Lighting Architecture – Phase 2 Integration

**Date:** 2026-03-11  
**Version:** Phase 2 implementation  
**Status:** Implemented, validated  
**Builds on:** Phase 1 foundation (commit 090b11c)

---

## Purpose

Phase 2 strengthens the hybrid lighting architecture foundation by:

1. **Making LightWorld practical** – Added query/helper methods so scenes can use it instead of raw arrays
2. **Moving Light Lab onto shared contracts** – Lab now emits real LightWorld data and uses render packets
3. **Reducing legacy special-case wiring** – Patch lookups, blocker queries, and visibility checks now flow through LightWorld when available

This is **not a full solver unification**. This is a **targeted integration pass** that pushes more data flow through the shared Phase 1 contracts.

---

## What Was Added

### 1. LightWorld Query Methods (`light_world.gd`)

Added practical helper methods to make LightWorld usable by scene logic:

- **`entity_list(kind: String = "") -> Array`** – Returns all entities or filtered by kind (e.g., "prism_node", "tree_trunk")
- **`find_patch_at(pos: Vector2) -> Dictionary`** – Spatial lookup for material patches at a position
- **`all_blockers() -> Array`** – Returns unified blocker list (segments + circle entities like tree trunks)

**Intent:**
- Scenes can now query LightWorld instead of maintaining parallel raw arrays
- Future procedural maps can populate LightWorld and instantly support these queries

---

### 2. LightWorldBuilder Strengthened (`light_world_builder.gd`)

**Enhanced `from_run_scene()`:**
- Now emits arena boundary segments (not just empty arrays)
- Populates material patches with normalized `material_spec` data
- Includes player anchor entity for future spatial queries
- Metadata flag: `"shared_boundary_ready": true`

**Enhanced `from_light_lab_scene()`:**
- Normalizes all surface patches with `material_spec` using `LightTypes.light_material_spec()`
- Tree trunk entities include material spec
- Preserves all occluder segments and entities from layout

**Intent:**
- Both scenes now emit **concrete LightWorld data** suitable for shared solver/presentation use
- Material metadata flows through one contract instead of scene-specific lookups

---

### 3. Light Lab Scene Integration (`light_lab_scene.gd`)

**Added packet-based data flow:**
- `secondary_render_packet` – wraps secondary light segments/zones
- `flashlight_render_packet` – built via `_build_visual_render_packet()` helper
- `prism_render_packet` – built via `_build_combined_prism_render_packet()` helper

**Added source spec builders:**
- `_flashlight_source_spec()` – returns normalized LightTypes source spec
- `_prism_source_spec(origin, direction)` – returns normalized prism source spec
- `_build_secondary_render_packet(secondary)` – wraps solver output in packet format

**Migrated to LightWorld queries:**
- `_surface_patch_at()` – now uses `light_world.find_patch_at()` first
- `_visibility_between()` – now uses `light_world.all_blockers()` for unified blocker iteration
- `_material_under_cursor()` – uses `light_world.find_patch_at()` and respects `material_spec`

**LightWorld refresh on scene state changes:**
- `_build_light_lab()` – rebuilds `light_world` after layout changes
- `_restart_lab()` – rebuilds `light_world` on reset

**Intent:**
- Light Lab now flows data through the same contracts as `run_scene.gd`
- Presentation layer can consume packets consistently across scenes
- Scene-specific logic reduced; shared contracts handle more

---

## What Remains Legacy

**Still coexist for now:**
- Raw `surface_segments`, `prism_stations`, `tree_trunks` arrays in Light Lab (used by layout/collision helpers)
- FlashlightVisuals still returns raw dictionaries (not yet packet-native)
- LightSurfaceResolver still operates on scene arrays (packet-native solver deferred to Phase 3+)
- `beam_segments` array still maintained alongside `beam_render_packet` in `run_scene.gd`

**Why:**
- Collision/layout systems still expect raw arrays
- Full solver migration would touch too many systems at once
- Phase 2 focuses on **data boundary migration**, not solver rewrite

---

## Validation Performed

- **Parse validation:** All modified scripts (`light_world.gd`, `light_world_builder.gd`, `light_lab_scene.gd`, `run_scene.gd`) pass Godot 4.6 headless parse checks
- **Inheritance check:** Removed duplicate const declarations from `light_lab_scene.gd` (inherits from `RunScene`)
- **Contract compliance:** Packet structures use `LightTypes.light_render_packet()` consistently
- **Material spec flow:** Both scenes emit normalized `material_spec` data in patches/entities

**Not validated in this pass:**
- Full runtime playtest (no Linux build per constraints)
- Performance impact (integration is additive, not a hot-path change)
- GPU light field presentation updates (deferred to separate pass)

---

## Architectural Progress

**After Phase 2:**
- LightWorld is now a **practical query interface**, not just a scaffold
- Both `run_scene` and `light_lab_scene` emit **real shared boundaries**
- Light Lab data flow uses **packets + LightWorld contracts** instead of only raw scene arrays
- Material metadata flows through one normalized `material_spec` contract

**Closer to target pipeline:**
```
seed/layout -> LightWorld -> solver -> render packets -> presentation
```

**Current state:**
- LightWorld ✅ populated by both scenes
- Solver 🟡 still operates on scene arrays (BeamResolver/LightSurfaceResolver)
- Render packets ✅ used by presentation layer
- Presentation 🟡 consumes packets but doesn't yet push to GPU light fields everywhere

---

## Next Recommended Phase

**Phase 3 (future):**
- Migrate BeamResolver + LightSurfaceResolver to accept LightWorld as primary input
- Retire raw array parameters from solver entry points
- Introduce first procedural test map that populates LightWorld from generation logic
- Push more GPU light field rendering (reduce CPU-visible polygon drawing)

---

## Commit Intent

This pass establishes:
- **LightWorld as a practical contract** (query methods, unified blocker interface)
- **Light Lab on shared data flow** (packets, LightWorld queries, material spec normalization)
- **Reduced scene-specific special cases** (patch lookups, blocker iteration, visibility checks)

**Not a breaking change.** Legacy arrays still exist for collision/layout helpers. This is an **integration pass** that moves more logic onto the Phase 1 foundation.
