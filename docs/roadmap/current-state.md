# Current State

Last updated: 2026-03-11
Current shipped version target: `v0.5.6-alpha` (hybrid lighting architecture Phase 2)

## Now shipped

- the project now boots directly into a permanent authored **Light Lab** instead of the old auto-wave run
- the lab contains outer walls, internal routing segments, authored brick/wood/wet/mirror/glass/prism test spaces, dead/alive blend lanes, shallow/deep water lanes, and an open validation deck
- flashlight checks now expose a queryable local light intensity with cone falloff, a stronger center, softer edge behavior, and secondary surface response on authored materials
- prism light now also participates in the shared material-response model and excites nearby surfaces instead of remaining only an isolated aura concept
- first-pass light material definitions now drive readable response differences across mirror, glass, brick, wood, wet surface, and prism routing from laser / flashlight / prism light together
- dead/alive floor response now blends on the rendering side toward ALIVE while illuminated and fades back toward DEAD when light leaves unless the zone has a restored base state
- player, enemy, and miniboss motion in the lab now respects wall collision rather than only room clamping
- enemy testing in the lab is manual/debug spawned only; there is no auto encounter flow, no forced completion, and no run ending state in the primary map

## Canon direction status

The project is now concretely aligned to:

- `docs/visio.md`
- `docs/ohjeet.md`
- `docs/light_engine.md`

That direction is no longer just a recommendation in docs; it is now reflected in the shipped main runtime.

## Legacy scaffolding

The older wave-survival arena, encounter chain, reward flow, and run summary are still kept in-repo as temporary legacy scaffolding for reference and fallback testing.
They are no longer the primary design center.

## Now improved in v0.5.4

- flashlight presentation now uses a smoothed beam fill driven by fewer guide rays, so it reads as one coherent beam instead of a striped comb
- flashlight/prism secondary response now samples only the strongest nearby material contacts on a budgeted cadence instead of rebuilding everything every frame
- approximation tiers are now explicit: Tier A laser precision, Tier B flashlight guided approximation, Tier C cheap secondary response
- prism scatter and flashlight scatter both now come from the same shared material response contract while remaining cheaper than the laser path
- the lab HUD now shows lightweight approximation/perf counters for Tier B and Tier C work
- reusable-vs-lab-only migration boundary now documents the new approximation module honestly

## Now improved in v0.5.5

- fixed the main visible approximation stability bug: guided flashlight + secondary-light arrays now persist between refreshes instead of being cleared on non-refresh frames
- tightened cadence/sample cost again by lowering Tier B guide-ray count, lowering Tier C sample budget, and stretching both refresh intervals slightly without letting the beam presentation visibly blink
- added deterministic sample ordering and lightweight frontier smoothing in `scripts/gameplay/light_stability.gd` so near-equal material candidates stop swapping frame-to-frame when aim is steady
- clipped reflected/transmitted/scatter spill branches against the next blocker/surface, so brick/tree truth and other solid blockers now stop obvious secondary-light leaks instead of letting lines sail through geometry
- made patch sampling on surface rectangles more source-relative, which keeps prism/flashlight spill anchored to the actually lit side of the surface rather than a detached center-point guess

## Phase 1 Hybrid Lighting Architecture (2026-03-11)

**Introduced durable CPU-solver / GPU-presentation boundary:**
- `scripts/gameplay/light_types.gd` – Shared abstractions: `light_source_spec()`, `light_material_spec()`, `light_render_packet()`
- `scripts/gameplay/light_world.gd` + `light_world_builder.gd` – Light-world data boundary for procedural-generation readiness
- Solver-to-presentation separation: Flashlight/prism/beam now emit **render packets** instead of raw arrays
- `LightFieldPresentation` now has packet-based update methods: `update_flashlight_packet()`, `update_prism_packet()`
- `run_scene.gd` wired to use packets for presentation; gameplay queries adapted
- Material response model now returns normalized `material_spec` alongside response data

**Preserved behavior:**
- Laser compatibility intact
- Existing material response logic (reflectivity, diffusion, transmission) unchanged
- Current gameplay light queries adapted to use packets instead of raw arrays

**Not yet migrated:**
- Light Lab scene still uses legacy array-based flow (deferred to Phase 2)
- Full randomgen pipeline (LightWorld scaffold exists but not yet consumed by map generation)
- Complete retirement of CPU-visible beam artifacts (packets coexist with legacy arrays for now)

**Documentation:** See `docs/architecture-hybrid-lighting-phase1.md`

## Phase 2 Hybrid Lighting Architecture (2026-03-11)

**Strengthened LightWorld / LightWorldBuilder integration:**
- Added practical query methods to `LightWorld`: `entity_list()`, `find_patch_at()`, `all_blockers()`
- Enhanced `from_run_scene()` to emit arena boundary segments and normalized material patches
- Enhanced `from_light_lab_scene()` to normalize all patches with `material_spec` using shared contracts
- Both scenes now emit **concrete LightWorld data** suitable for shared solver/presentation

**Light Lab migrated to packet-based flow:**
- Added `secondary_render_packet`, `flashlight_render_packet`, `prism_render_packet` variables
- Introduced source spec builders: `_flashlight_source_spec()`, `_prism_source_spec()`
- Introduced packet builders: `_build_visual_render_packet()`, `_build_combined_prism_render_packet()`, `_build_secondary_render_packet()`
- Migrated `_surface_patch_at()` to use `light_world.find_patch_at()` first
- Migrated `_visibility_between()` to use `light_world.all_blockers()` for unified iteration
- Migrated `_material_under_cursor()` to use LightWorld queries and respect `material_spec`
- LightWorld now refreshed on scene state changes (`_build_light_lab()`, `_restart_lab()`)

**Reduced legacy special-case wiring:**
- Patch spatial lookups now flow through LightWorld contract when available
- Blocker queries unified via `all_blockers()` instead of parallel segment/trunk iteration
- Material metadata normalized via `material_spec` instead of direct dictionary lookups

**Preserved for collision/layout:**
- Raw `surface_segments`, `prism_stations`, `tree_trunks` arrays still exist (used by LightLabCollision)
- FlashlightVisuals still returns raw dictionaries (not yet packet-native)
- Solvers (BeamResolver, LightSurfaceResolver) still accept scene arrays (packet-native solver deferred)

**Documentation:** See `docs/architecture-hybrid-lighting-phase2.md`

## Phase 2 follow-up integration (2026-03-11)

**More Light Lab consumers now use shared contracts directly:**
- Light-intensity queries now consume `flashlight_render_packet`, `prism_render_packet`, and `secondary_render_packet` via shared packet helpers instead of iterating scene-local arrays separately
- Lit-zone construction now reads packet segments/zones for flashlight, prism, and secondary light
- Flashlight/prism/secondary draw helpers now consume packet `fills` / `zones` / `segments` instead of bespoke local arrays
- Cursor material lookup, patch rendering, sign rendering, occluder rendering, and tree/prism entity rendering now prefer LightWorld-backed helpers

**New Light Lab helper boundary:**
- `_packet_segments()` / `_packet_zones()` / `_packet_fills()`
- `_packet_intensity_at()`
- `_light_world_patches()` / `_light_world_occluders()` / `_light_world_tree_entities()` / `_light_world_prism_entities()`

**What this reduced:**
- Fewer direct reads from `flashlight_visual_*`, `prism_visual_*`, and `secondary_light_*` arrays in query/draw consumers
- Fewer direct reads from `surface_patches`, `surface_segments`, `tree_trunks`, and `prism_stations` outside layout/collision/solver production code

**Still intentionally raw-array based for now:**
- LightSurfaceResolver and FlashlightVisuals internal production paths
- LightLabCollision motion/blocking helpers
- Prism-station production loop inside the approximation refresh pass


## Immediate next recommendation

**Phase 3 (when ready for deeper solver migration):**

- Migrate BeamResolver + LightSurfaceResolver to accept `LightWorld` as primary input instead of raw scene arrays
- Introduce first procedural test map that populates `LightWorld` from generation logic
- Push more GPU light field rendering (reduce CPU-visible polygon drawing in `_draw()`)
- Consider caching per-source candidate surface sets during movement for perf if testers report lab heaviness


## Producer / solver boundary follow-up (2026-03-11)

**Producer-side migration completed:**
- `FlashlightVisuals` now exposes source-option builders (`flashlight_source_options()`, `prism_source_options()`) and a packet-native producer entry point: `build_render_packet()`
- Light Lab now requests flashlight/prism render packets directly from `FlashlightVisuals` instead of first building local visual dictionaries and only then wrapping them into packets
- secondary light packet creation now also keeps debug/perf metadata attached to the packet boundary

**Solver boundary movement completed:**
- `LightSurfaceResolver` now has LightWorld-backed access helpers for occluders, patches, trees, and prism entities
- secondary-light source enumeration now reads prism emitters through shared world/entity helpers
- surface sampling and closest-hit queries now use LightWorld-backed occluder/patch/entity access first, with scene arrays effectively acting as adapter fallback

**Procedural-readiness improved:**
- producer and solver code now have clearer internal seams where a generated `LightWorld` can be supplied without rewriting every consumer first
- scene-local arrays are less central in producer/query flow and more confined to fallback/layout/collision roles


## Light Lab adapter-layer follow-up (2026-03-11)

**Adapter seam introduced:**
- added `scripts/gameplay/light_lab_world_adapter.gd`
- authored Light Lab layout is now translated in one place into:
  - legacy runtime arrays (`surface_segments`, `surface_patches`, `prism_stations`, `tree_trunks`)
  - a populated `LightWorld`

**What moved out of Light Lab:**
- direct authored-layout copying loops were removed from `_build_light_lab()`
- prism-station production in the approximation refresh now iterates shared prism entities instead of scene-owned `prism_stations`
- collision entry points now go through tiny adapter helpers (`_collision_surface_segments()`, `_collision_tree_trunks()`) instead of hardwiring scene fields at each call site

**Boundary effect:**
- Light Lab is more clearly an orchestrator that asks an adapter for world/runtime data
- raw-array production loops now live mainly in the adapter seam rather than the scene coordinator itself
- this makes future procedural input easier because authored-layout translation has one obvious replacement point


## Collision/world-space seam + generated injection hook (2026-03-11)

**Legacy runtime-array dependency reduced further:**
- `LightLabCollision` now exposes `resolve_circle_motion_in_space()` and `is_circle_blocked_in_space()` that operate on collision-space dictionaries instead of raw segment/circle arrays at call sites
- `LightLabScene` collision/spawn entry points now pass `_collision_space()` rather than handing `surface_segments` / `tree_trunks` directly to collision helpers
- `LightWorld` now exposes `collision_space()` and `prism_emitters()` so shared world data can feed collision and producer/solver helper code more directly

**Producer/helper state moved outward:**
- prism emitter lookup now comes from `LightWorld.prism_emitters()` when world data is present
- collision-space composition now comes from `LightWorld.collision_space()` instead of being reassembled repeatedly at scene call sites

**Generated-LightWorld injection point introduced:**
- `LightLabScene` now supports `generated_light_world_override`
- `_inject_generated_light_world(world)` and `_clear_generated_light_world_override()` provide the first explicit hook for feeding a generated/shared `LightWorld` into the lab without rewriting the whole scene stack
- `_build_light_lab()` now respects this override, making a first procedural test path credible

## Generated-world smoke test + deeper collision-space cleanup (2026-03-11)

**Generated-world hook is now exercised:**
- `LightWorldBuilder.build_light_lab_smoke_test()` now creates a tiny generated `LightWorld` with its own occluders, patches, trunks, and a prism station
- `LightLabScene` can toggle that override at runtime with `9`, giving a real smoke-test path for the generated-world seam instead of leaving the hook unused

**Collision/helper cleanup moved farther toward world-space access:**
- `LightLabNavigation` now path-checks through a collision-space dictionary rather than raw segment/circle arrays
- `EnemyController` movement and clear-position probing now use `_collision_space()` / `resolve_circle_motion_in_space()` / `is_circle_blocked_in_space()` when available
- `BossController` movement and pounce target resolution now use the same collision-space seam, reducing direct dependence on `surface_segments`

**Legacy mirror state reduced in practice:**
- scene-owned arrays still exist as compatibility fallback, but more runtime consumers now prefer world/collision adapter helpers first
- this further narrows the set of systems that care whether the lab was authored from layout arrays or injected from a generated `LightWorld`

## Dead/alive world metadata seam + stronger generated runtime path (2026-03-11)

**Dead/alive dependency decoupled from authored layout first:**
- `LightWorld` now exposes a tiny metadata-array accessor for array-like metadata payloads
- authored `LightLabWorldAdapter` now copies `dead_alive_cells` into `LightWorld.metadata.dead_alive_zones`
- `LightLabScene` now builds `dead_alive_cells` from world metadata first and only falls back to authored layout data when no world-provided zones exist

**Generated path is more end-to-end than before:**
- generated smoke-test worlds now include their own `dead_alive_zones`
- generated smoke-test worlds also carry a `spawn_hint`, and Light Lab spawn validation now prefers that hint while the generated override is active
- this means the generated path now drives not just collision/render/material/entity queries, but also floor alive/dead state and one small runtime spawn behavior

**Additional scene-array leakage reduced:**
- `LightSurfaceResolver` now prefers scene-provided world helper methods (`_light_world_occluders()`, `_light_world_patches()`, `_light_world_tree_entities()`, `_light_world_prism_entities()`) before touching raw fallback arrays
- this keeps the solver/helper side more aligned with the shared world/adapter seam without forcing a broad rewrite

## Laser packet-path consolidation on authored validation field (2026-03-11)

**Shared interface movement (Phase 1):**
- `LightSurfaceResolver.cast_beam()` now emits a proper `beam_render_packet` with shared source metadata instead of leaving laser output only in ad-hoc scene state
- the packet records laser segments, zones, and debug metadata through the same `LightTypes.light_render_packet(...)` contract already used by flashlight/prism/secondary paths

**Render/presentation separation moved forward on the current field (Phase 3):**
- `LightLabScene` light-intensity queries now read laser contribution from `beam_render_packet`
- beam lit-zone generation and beam-layer UI reporting now read packet segments/zones instead of direct `beam_segments`
- pulse expiry/restart paths now reset `beam_render_packet`, keeping packet lifecycle aligned with the authored validation map runtime

**Boundary effect:**
- the current test field still preserves existing visible behavior, but laser is less special-case than before
- legacy `beam_segments` still exist for compatibility and beam damage/debug flow, but packet consumption is now the primary render/intensity path inside Light Lab

## Laser packet-state cleanup pass (2026-03-11)

**More laser legacy dependency reduced:**
- beam-active checks now prefer packet state through `_beam_packet_active()` instead of using raw `beam_segments` directly
- approximation invalidation state now tracks packet segment count / packet-active state rather than reading `beam_segments` as the source of truth
- duplicate laser packet reset in Light Lab restart flow was removed

**Phase 3 cleanup effect:**
- pulse expiry, packet lifetime, and approximation refresh triggers now line up more closely around `beam_render_packet`
- the scene is doing a little less unnecessary mirroring between solver output and legacy beam state

**Phase 2 direction kept aligned:**
- laser packets now also record `world_type` from the current `LightWorld` when available, reinforcing the shared solver → packet → world-backed runtime direction on the authored field
