# Current State

Last updated: 2026-03-11
Current shipped version target: `v0.5.6-alpha` (hybrid lighting architecture Phase 1)

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

## Immediate next recommendation

Do one more narrow extraction/perf pass only if testers still find the lab heavy:

- split generic blocker-query helpers farther out of `light_surface_resolver.gd`
- cache per-source candidate surface sets for short windows during movement
- keep Light Lab debug presentation as a thin consumer instead of adding more special-case fixes into the scene coordinator
