# Devlog

## 2026-03-10 — v0.5.2 Light Lab Readability & Extraction patch

This patch keeps the project pointed at the Light Lab, but makes the lab faster to read and easier to graduate from later.

What changed:
- extracted authored Light Lab bay/lane/station content into `scripts/data/light_lab_layout.gd`
- extracted reusable light intensity math into `scripts/gameplay/light_query.gd`
- upgraded each comparison space with stronger authored signage and short behavior hints
- differentiated secondary-light overlays so reflection / transmission / diffusion / prism-emitted response are easier to tell apart
- added path-layer labels and stronger bounce/redirect markers so beam logic reads as a layered trace instead of a loose glow sketch
- tightened truth/readability from testing feedback: brick walls now occlude flashlight properly, solid tree trunks now block movement/beam/flashlight, water slowdown is much more noticeable, wet-light response is less visually dead/straight, and `F1` now hides both top debug panels for a clean view
- slightly widened restoration influence so the alive floor response reads more naturally around the active light sources
- documented the migration boundary in `docs/light_lab_runtime_boundary.md`

Validation:
```bash
/opt/openclaw/bin/godot --headless --path /opt/openclaw/projects/lantern_engine --quit
/opt/openclaw/bin/godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Windows Desktop" build/windows/lantern_engine.exe
```

Validation result:
- headless boot passed locally during implementation; Windows export result is tracked in the release/build step for `v0.5.2`

Recommended next step:
- split scene-agnostic trace/query inputs farther out of `light_surface_resolver.gd` only when the first exploration runtime consumer actually exists

## 2026-03-10 — v0.5.1 Unified Light Response patch

This patch hardens the Light Lab into a more credible systems testbed instead of leaving flashlight/prism light half-detached from the world.

What changed:
- added `scripts/gameplay/light_response_model.gd` so laser, flashlight, and prism light now resolve against the same material-response truth
- extended `scripts/gameplay/light_surface_resolver.gd` so flashlight/prism light now generate readable secondary reflect/diffuse/transmit response on authored surfaces
- added `scripts/gameplay/light_lab_collision.gd` and wired it into player/enemy/boss movement plus practical spawn placement checks
- added shallow/deep wet lanes and movement slowdown feedback for water-depth readability testing
- upgraded debug readability with richer cursor probe text, live step-speed readout, section labels, and clearer secondary light markers

Validation:
```bash
/opt/openclaw/bin/godot --headless --path /opt/openclaw/projects/lantern_engine --quit
/opt/openclaw/bin/godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Windows Desktop" build/windows/lantern_engine.exe
```

Validation result:
- see build/release workflow for the final command results for `v0.5.1`

Recommended next step:
- decide whether the shared response model should become the basis for future exploration/runtime lighting queries beyond the lab

## 2026-03-10 — v0.5.0 Light Lab Direction Pivot

This patch deliberately changed the project center of gravity.
The old wave-survival arena is no longer the shipped main runtime; the project now boots into a permanent authored Light Lab built to validate light behavior first.

What changed:
- added `scenes/light_lab_scene.tscn` + `scripts/light_lab_scene.gd` as the new primary map/runtime
- switched `scripts/main.gd` so the Light Lab loads by default instead of `scenes/run_scene.tscn`
- authored a permanent lab layout with outer walls, multiple internal routing segments, surface bays for brick/wood/wet/mirror/glass, a prism routing station, dead/alive blend lanes, and an open spawn-validation deck
- added `scripts/data/light_materials.gd` for first-pass readable material tuning
- added `scripts/gameplay/light_surface_resolver.gd` so beam/surface behavior lives outside the old arena coordinator
- added `scripts/gameplay/dead_alive_grid.gd` for rendering-side dead/alive blend state instead of gameplay-side tile rewriting
- reused the existing enemy + boss runtime modules only as manual debug-spawn helpers; there is no auto encounter loop in the Light Lab
- added lab debug affordances: manual enemy spawning, material-under-cursor readout, local intensity probe, beam-hit markers, HP overlays, and base-alive toggling

Validation:
```bash
/opt/openclaw/bin/godot --headless --path /opt/openclaw/projects/lantern_engine --quit
/opt/openclaw/bin/godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Windows Desktop" build/windows/lantern_engine.exe
```

Validation result:
- headless boot passed
- Windows export pending at the time this note was written in-file; see final build step in release workflow

Recommended next step:
- keep building the Light Lab as the truth source for future exploration-light mechanics instead of widening the old wave prototype again
