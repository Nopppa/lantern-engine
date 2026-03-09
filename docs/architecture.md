# Architecture Overview

## Current shape

This first implementation favors **playability and speed** over premature framework depth.

### Runtime layers in this repo

- `scenes/main.tscn`
  - minimal bootstrap scene
- `scenes/run_scene.tscn`
  - owns the full playable MVP-0 sandbox
- `scripts/run_scene.gd`
  - currently contains the prototype loop, arena rules, player state, encounter flow, reward handling, and simple enemy logic

## Why this is acceptable right now

The goal was a **testable first milestone today**, not a fully decomposed production runtime.

The code is intentionally compact so the team can quickly answer:

1. is movement good enough?
2. is beam geometry readable?
3. do bounce/refraction moments create delight?
4. do the two enemy archetypes already generate different pressure?

## Expected next refactor boundary

If the prototype is greenlit for MVP-1, split `run_scene.gd` into:

- `scripts/core/game_controller.gd`
- `scripts/combat/combat_resolver.gd`
- `scripts/actors/player_controller.gd`
- `scripts/actors/enemy_controller.gd`
- `scripts/abilities/refraction_beam.gd`
- `scripts/abilities/prism_node.gd`
- `scripts/encounters/encounter_controller.gd`
- `scripts/ui/hud_controller.gd`
- `scripts/ui/reward_controller.gd`

That refactor should happen **after** confirming the core mechanic deserves expansion.
