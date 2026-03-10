# Lantern Engine Code Map

Last updated: 2026-03-10
Current internal state: `v0.5.0` Light Lab pivot shipped

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
  - first-pass authored surface material definitions
  - readable reflectivity / diffusion / transmission / absorption tuning

### Gameplay / simulation
- `scripts/gameplay/light_surface_resolver.gd`
  - lab beam routing against authored surfaces
  - mirror reflection, glass transmission, wet reflection, wood diffusion, brick absorption, prism redirect handling

- `scripts/gameplay/dead_alive_grid.gd`
  - rendering-side dead/alive blend state cache for the floor
  - tracks temporary exposure and base alive/restored zones

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
- beam/surface interaction -> `scripts/gameplay/light_surface_resolver.gd`
- dead/alive blend state -> `scripts/gameplay/dead_alive_grid.gd`
- lab content / debug probes / lab UI glue -> `scripts/light_lab_scene.gd`

### Avoid
- pushing new exploration/light systems back into `scripts/run_scene.gd`
- treating the old wave prototype as the main runtime again
- centralizing future material/light/debug logic into one giant controller
