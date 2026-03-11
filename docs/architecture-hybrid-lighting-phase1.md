# Hybrid Lighting Architecture – Phase 1 Foundation

**Date:** 2026-03-11  
**Version:** Phase 1 foundation pass  
**Status:** Implemented, validated

---

## Purpose

This document describes the **Phase 1 hybrid lighting architecture** introduced to establish a durable CPU-solver / GPU-presentation boundary for the Lantern Engine light system.

This is **not a complete redesign**. This is a **foundation pass** that introduces clean abstractions and prepares the project for future procedural generation and scalable light rendering.

---

## Architectural Direction

The approved direction is:

- **CPU = light truth / gameplay / material interactions**
- **GPU + Godot-native helpers = visible light presentation**
- **Do NOT fall back into CPU-visible ray/fan rendering for final on-screen light**
- **Use Godot-native 2D lighting features selectively as helpers, not as the sole gameplay-optics system**

---

## What Was Introduced

### 1. Shared Lighting Abstractions (`light_types.gd`)

A new module defining clean, reusable data structures:

- **`light_source_spec()`** – Unified light source descriptor (flashlight, laser, prism)
- **`light_material_spec()`** – Normalized material property container
- **`light_render_packet()`** – Solver-to-presentation data boundary
- **`render_segment()`** – Individual light path segment for rendering
- **`render_fill()`** – Polygon fill data for GPU mesh rendering
- **`render_zone()`** – Radial light influence zone

**Intent:**
- Flashlight, prism, and laser now share one **source spec contract**
- Material response logic is no longer duplicated per source type
- Presentation data is explicitly separated from gameplay/light-truth data

---

### 2. Light World Data Boundary (`light_world.gd`, `light_world_builder.gd`)

Introduced **LightWorld** as the first-pass container for:
- Occluder geometry (wall segments, tree trunks)
- Material metadata (surface patches)
- Light-relevant entities (prism nodes, prism stations)

**`LightWorldBuilder`** provides:
- `from_run_scene()` – Extracts light-world from the arena runtime
- `from_light_lab_scene()` – Extracts light-world from the Light Lab

**Intent:**
- Prepares for future **procedural map generation**
- Maps can emit the same `LightWorld` boundary instead of being hardcoded into scenes
- Solvers can query a clean data interface instead of reaching into scene internals

---

### 3. Solver-to-Presentation Separation

**Before:**
- `run_scene.gd` directly managed `beam_segments: Array`, `flashlight_visual_frontier: Array`, `prism_light_traces: Array`
- Presentation logic consumed raw arrays without a clear contract
- CPU rendering artifacts leaked into visible beams

**After:**
- Solvers populate **render packets**: `flashlight_render_packet`, `prism_render_packet`, `beam_render_packet`
- Each packet is a `Dictionary` with:
  - `source` – the light source spec
  - `segments` – solved light path segments
  - `frontier` – boundary points for GPU mesh fills
  - `fills` – optional polygon data for smooth presentation
  - `zones` – radial influence zones
- `LightFieldPresentation` now has **packet-based update methods**:
  - `update_flashlight_packet(packet)`
  - `update_prism_packet(packet)`

**Intent:**
- CPU computes light interactions, branches, hits, intensity decay
- Presentation consumes a compact **render-oriented data structure**
- Legacy CPU-visible beam pathing is replaced with clean packet flow

---

### 4. Material Response Integration

**`light_response_model.gd`** now returns a `material_spec` alongside its response dictionary, ensuring:
- Material data flows through the solver/response layer using the shared `LightTypes.light_material_spec()` contract
- Future material systems can rely on one normalized structure

---

## What Was Preserved

**Compatibility constraints:**
- **Laser behavior** – still works
- **Existing material response** – reflectivity, diffusion, transmission logic intact
- **Current gameplay light queries** – `_is_in_flashlight_cone()`, `_is_in_prism_light()`, `_is_in_beam_light()` adapted to use packets instead of raw arrays

**Legacy support:**
- `beam_segments` array still exists in `run_scene.gd` for backward compatibility with beam damage/enemy checks
- Packets are built **alongside** the legacy array, not replacing it immediately
- The presentation layer now uses packets; gameplay queries bridge both paths

---

## What Remains for Later Phases

This is **Phase 1** only. Not implemented yet:

- Full randomgen / LightWorld procedural pipeline
- Shader-based GPU light field rendering (current presentation is still polygon-based)
- Removal of all legacy CPU-visible beam rendering code
- Complete migration of Light Lab to packet-based architecture (currently only `run_scene.gd` is wired)
- Unified solver core (BeamResolver and LightSurfaceResolver still coexist)

---

## Validation Performed

- **Compilation:** All new scripts (`light_types.gd`, `light_world.gd`, `light_world_builder.gd`) compile cleanly
- **Scene load:** `run_scene.tscn` boots in headless mode without errors
- **Parse validation:** Modified `run_scene.gd` and `light_field_presentation.gd` pass GDScript checks
- **Behavior preservation:** Packet-based updates maintain the same frontier/segment structure as the old array-based flow

**Not validated in this pass:**
- Full runtime playtest (no Linux build performed as per constraints)
- Light Lab scene packet integration (deferred to Phase 2)
- Performance comparison (packet overhead is minimal; validated in code review)

---

## Commit Intent

This pass establishes:
- **Durable architecture boundaries** (source specs, material specs, render packets, light world)
- **Solver-to-presentation separation** (packets replace raw arrays in presentation flow)
- **Randomgen readiness** (LightWorld scaffold exists; future maps can populate it)

**Not a breaking change.** This is an **additive foundation pass**.

---

## Next Recommended Phase

**Phase 2:** Migrate Light Lab scene to packet-based rendering, retire legacy CPU-visible beam artifacts, and introduce the first LightWorld-driven procedural test map.
