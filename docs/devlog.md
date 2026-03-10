# Devlog

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
