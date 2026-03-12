# Checklist – RandomGEN Exploration World

**Branch:** `feature/randomgen-exploration-world`  
**Purpose:** Build a mergeable generated exploration-world branch that reuses the existing lighting/material/gameplay truth stack.

---

## Scope Guard

- [ ] Keep this branch focused on **generated exploration runtime**
- [ ] Do **not** fork lighting/material logic
- [ ] Keep Light Lab as the authored validation map
- [ ] Avoid giant rewrite behavior
- [ ] Prefer mergeable incremental slices over one massive refactor

---

## Shared Architecture Seams

- [ ] Introduce or formalize a world provider / layout provider seam
- [ ] Introduce or formalize a runtime/world adapter seam where needed
- [ ] Reduce direct `LightLabScene`-shaped assumptions in shared solver/runtime code
- [ ] Keep shared solver inputs minimal and explicit
- [ ] Ensure generated and authored worlds can feed the same shared pipeline

---

## Light / Gameplay Truth Preservation

- [ ] Keep `LightField` as gameplay-light truth
- [ ] Keep render packets as presentation/output boundary
- [ ] Keep gameplay light separate from visible light
- [ ] Ensure gameplay/world influence can still be informed by packet/segment/zone/fill data
- [ ] Do **not** make gameplay depend on rendered pixels

---

## Shared System Reuse

- [ ] Reuse `LightWorld`
- [ ] Reuse `LightWorldBuilder` (extend rather than replace)
- [ ] Reuse material definitions
- [ ] Reuse material response model
- [ ] Reuse light query helpers
- [ ] Reuse beam/material interaction solver path
- [ ] Reuse dead/alive grid logic where applicable
- [ ] Reuse gameplay-light write path into `LightField`

---

## Generated World Data Path

- [ ] Define generated-world layout/config structure
- [ ] Support seed-based generation
- [ ] Generate occluder segments
- [ ] Generate material patches
- [ ] Generate blocker entities (e.g. trunks/obstacles) where appropriate
- [ ] Generate prism emitters/stations where appropriate
- [ ] Generate dead/alive zone metadata
- [ ] Add spawn/navigation metadata
- [ ] Add stable world/layout signature for caching/debugging

---

## Exploration Scene Scaffold

- [ ] Create exploration runtime scene scaffold
- [ ] Add exploration scene script
- [ ] Boot generated world from provider/builder path
- [ ] Initialize LightWorld correctly
- [ ] Initialize LightField correctly
- [ ] Initialize presentation/runtime layers correctly
- [ ] Spawn player in valid generated position

---

## Movement / Collision / Runtime Basics

- [ ] Reuse shared collision logic for generated blockers
- [ ] Verify player movement respects generated walls/obstacles
- [ ] Verify patch/material queries work in generated scene
- [ ] Verify runtime entity refresh path works if prism/player entities are dynamic

---

## Lighting / Material Parity

- [ ] Verify flashlight works in generated world
- [ ] Verify beam works in generated world
- [ ] Verify prism behavior works in generated world
- [ ] Verify mirror reflection matches authored-world behavior
- [ ] Verify glass transmission/refraction matches authored-world behavior
- [ ] Verify opaque surfaces remain correctly blocking
- [ ] Verify visible-light-informed gameplay influence still feels correct
- [ ] Verify restoration/dead-alive behavior uses the same gameplay truth model

---

## Content / Generation Depth (MVP)

- [ ] Generate a modest room/corridor layout or equivalent exploration topology
- [ ] Add enough material variety to exercise the lighting system
- [ ] Add enough emitter/obstacle variety to make exploration useful for testing
- [ ] Keep world size modest enough to preserve acceptable performance
- [ ] Avoid full roguelite scope creep in MVP

---

## Validation / Comparison

- [ ] Add parity checklist for authored vs generated material interactions
- [ ] Test mirror in authored map vs generated world
- [ ] Test glass in authored map vs generated world
- [ ] Test prism interaction in authored map vs generated world
- [ ] Test dead/alive restoration in authored map vs generated world
- [ ] Verify debug probes/inspection remain useful in generated runtime

---

## Performance Safety

- [ ] Preserve current approximation strategy
- [ ] Avoid per-pixel gameplay logic
- [ ] Avoid ray-count explosion
- [ ] Keep generated-world MVP size reasonable
- [ ] Sanity-check LightField update cost in generated world
- [ ] Sanity-check lighting refresh cost in generated world

---

## Documentation

- [ ] Keep branch architecture doc updated if implementation shifts
- [ ] Document generated-world data model once stabilized
- [ ] Document merge strategy / what should land early in main
- [ ] Add short exploration runtime overview when scaffold exists

---

## Git / Merge Hygiene

- [ ] Split merge-friendly shared refactors from branch-local runtime work
- [ ] Rebase frequently onto `main`
- [ ] Avoid long-lived silent divergence in shared files
- [ ] Merge shared seams early when stable
- [ ] Keep PR summaries explicit about what is shared vs exploration-specific

---

## Suggested Commit Sequence

- [ ] `refactor(world): add world provider/runtime seam`
- [ ] `refactor(light): reduce LightLabScene-specific coupling`
- [ ] `refactor(world): extend LightWorld metadata for generated runtime`
- [ ] `feat(worldgen): add generated exploration provider scaffold`
- [ ] `feat(exploration): add exploration scene scaffold`
- [ ] `feat(exploration): boot generated LightWorld through shared pipeline`
- [ ] `feat(worldgen): add blockers/material patches/prism emitters`
- [ ] `test(exploration): add authored-vs-generated parity checks`
- [ ] `docs(worldgen): document exploration runtime usage`

---

## Done Criteria

- [ ] Generated exploration scene boots reliably
- [ ] Player can move in generated world
- [ ] Shared lighting/material behavior matches authored Light Lab behavior closely
- [ ] Gameplay-light vs visible-light separation remains intact
- [ ] Performance remains within acceptable range
- [ ] Branch is still realistically mergeable back into main
