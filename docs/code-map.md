# Lantern Engine Code Map

Last updated: 2026-03-10
Current internal state: post `v0.3.5` MVP-0 finish pass

## Purpose

This file tells future contributors and agents where responsibilities currently live after the first internal refactor pass.
Use this before making structural changes so new work lands in the right file instead of drifting back into `scripts/run_scene.gd`.

## Current high-level structure

### Scenes
- `scenes/main.tscn`
  - project entry scene
- `scenes/run_scene.tscn`
  - main gameplay scene used by the MVP runtime

### Main scripts
- `scripts/main.gd`
  - bootstrap / scene entry behavior
- `scripts/run_scene.gd`
  - still the main runtime coordinator
  - still owns the risky gameplay core that has NOT been extracted yet

## Extracted modules

### Data
- `scripts/data/encounter_defs.gd`
  - authored encounter definitions / spawn data
  - source of encounter content that used to live inline in `run_scene.gd`

- `scripts/data/upgrade_defs.gd`
  - reward / upgrade pool definitions
  - source of upgrade data that used to live inline in `run_scene.gd`

### Gameplay
- `scripts/gameplay/reward_controller.gd`
  - reward panel creation
  - reward modal input
  - reward highlight / focus / button state
  - reward selection and upgrade application
  - reward flow progression to next encounter or run-complete state
  - small readability polish for selected-state styling and stat-delta copy

- `scripts/gameplay/sfx_controller.gd`
  - tiny runtime-generated WAV cues for beam fire, hit, kill, reward move, and reward confirm
  - keeps MVP-0 audio polish asset-light and export-safe

- `scripts/gameplay/encounter_controller.gd`
  - encounter completion checks
  - encounter start/reset flow
  - enemy spawn construction from authored encounter data

- `scripts/gameplay/enemy_controller.gd`
  - per-frame enemy runtime updates
  - Moth chase behavior
  - Hollow blink / windup / disrupted transit state progression
  - safe overlap direction fallback and contact damage application

- `scripts/gameplay/beam_resolver.gd`
  - beam cast validation
  - wall-bounce continuation
  - Prism Node redirect chaining
  - shared total-range budgeting along beam segments
  - segment-vs-circle hit checks and enemy damage application

### Player / debug input
- `scripts/player/debug_actions.gd`
  - debug/help/dev input handling
  - F1 help toggle
  - F4 immortality toggle
  - restart input handling
  - dev refill
  - dev spawn / dev reward shortcuts

### UI
- `scripts/ui/hud_text.gd`
  - HUD text formatting helpers
  - extracted text/bar formatting responsibility from `run_scene.gd`

## Intentionally still in run_scene.gd

These responsibilities still remain in the main runtime coordinator:

- player movement + input-driven action intent handling
- lit-zone builder
- `_draw()` rendering path
- top-level runtime glue between world state, combat state, and rendering state

## Rule of thumb for future edits

### Put new changes here first if they belong to:
- reward behavior or reward UI -> `scripts/gameplay/reward_controller.gd`
- help/debug/dev shortcuts -> `scripts/player/debug_actions.gd`
- HUD formatting text -> `scripts/ui/hud_text.gd`
- encounter data -> `scripts/data/encounter_defs.gd`
- reward/upgrade data -> `scripts/data/upgrade_defs.gd`

### Only touch `scripts/run_scene.gd` when the change belongs to:
- player movement / action intent glue
- draw/render core
- top-level runtime orchestration that truly cannot live elsewhere yet

## What not to do yet

- do NOT split beam/combat math casually
- do NOT introduce a large plugin framework yet
- do NOT move rendering and gameplay apart in one giant pass
- do NOT re-inline extracted data back into `run_scene.gd`

## Recommended next structural step

For MVP-0, stop here unless a real regression appears.

When MVP-1 starts, consider:
1. introducing a lightweight shared run-state container or clearer state grouping
2. only after that, splitting lighting/rendering helpers further if the runtime still feels too coupled
3. avoid duplicating combat ownership now that `beam_resolver.gd` and `enemy_controller.gd` hold the core simulation rules

## Validation expectation after structural edits

After any structural refactor, always verify at minimum:
- headless boot succeeds
- Windows export succeeds
- Linux export succeeds
- core playtest behaviors still work
