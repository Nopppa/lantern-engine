# Lantern Engine Code Map

Last updated: 2026-03-10
Current internal state: `v0.5.3` Surface Optics & Navigation Truth patch shipped

## Purpose

This file tells future contributors where the new Light Lab responsibilities now live so the project does not slide back into one giant arena script.

## Scenes

- `scenes/main.tscn`
  - project bootstrap scene
- `scenes/light_lab_scene.tscn`
  - new primary runtime / validation map
- `scenes/run_scene.tscn`
  - legacy wave-survival prototype runtime kept for reference

## Main scripts

- `scripts/main.gd`
  - now boots the Light Lab scene by default
- `scripts/light_lab_scene.gd`
  - top-level coordinator for the permanent validation map
  - owns Light Lab scene assembly, player loop, lab UI, and rendering glue
- `scripts/run_scene.gd`
  - legacy run prototype coordinator
  - kept in repo but de-emphasized

## New Light Lab modules

### Data
- `scripts/data/light_materials.gd`
  - shared authored surface material definitions
  - readable reflectivity / diffusion / transmission / absorption tuning

- `scripts/data/light_lab_layout.gd`
  - Light Lab-only authored comparison layout + signage metadata
  - keeps bay/lane/station labeling out of the scene coordinator

### Gameplay / simulation
- `scripts/gameplay/light_surface_resolver.gd`
  - lab beam routing against authored surfaces
  - shared secondary response generation for flashlight + prism + laser
  - mirror reflection, glass transmission, wet reflection, wood diffusion, brick absorption, prism redirect handling

- `scripts/gameplay/light_response_model.gd`
  - shared source/material response truth for laser / flashlight / prism light
  - normalizes reflectivity / diffusion / transmission / absorption into readable gameplay branches

- `scripts/gameplay/light_query.gd`
  - reusable intensity query helpers for flashlight cone, segment/path exposure, and radial falloff
  - intended to survive beyond the lab into future exploration/runtime light checks

- `scripts/gameplay/light_lab_collision.gd`
  - circle-vs-segment collision helper for Light Lab movement / placement
  - generic enough to survive later rename/extraction beyond the lab
  - keeps player, enemy, boss, and spawn placement out of walls

- `scripts/gameplay/dead_alive_grid.gd`
  - rendering-side dead/alive blend state cache for the floor
  - tracks temporary exposure and base alive/restored zones

- `scripts/gameplay/flashlight_visuals.gd`
  - builds truthful visible flashlight trace segments/zones from the same blocker/material truth used by the lab
  - keeps flashlight rendering alignment work out of `scripts/light_lab_scene.gd`

- `scripts/gameplay/light_lab_navigation.gd`
  - small Light Lab-only waypoint/A* helper for obstacle routing around walls/tree trunks
  - gives enemies basic robust pathing without introducing a heavyweight navigation framework

### Existing reusable modules still used by the lab
- `scripts/gameplay/encounter_controller.gd`
  - reused only for enemy construction helpers during manual debug spawning
- `scripts/gameplay/enemy_controller.gd`
  - reused for per-frame enemy runtime updates in the lab
- `scripts/gameplay/boss_controller.gd`
  - reused for Hollow Matriarch runtime logic during manual debug spawn tests

## Ownership rule going forward

### Put new work here first if it belongs to:
- material definitions -> `scripts/data/light_materials.gd`
- Light Lab authored comparison content/signage -> `scripts/data/light_lab_layout.gd`
- reusable light intensity math -> `scripts/gameplay/light_query.gd`
- beam/surface interaction -> `scripts/gameplay/light_surface_resolver.gd`
- dead/alive blend state -> `scripts/gameplay/dead_alive_grid.gd`
- lab-only debug probes / lab UI glue / validation presentation -> `scripts/light_lab_scene.gd`

### Avoid
- pushing new exploration/light systems back into `scripts/run_scene.gd`
- treating the old wave prototype as the main runtime again
- centralizing future material/light/debug logic into one giant controller
