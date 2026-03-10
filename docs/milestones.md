# Milestones

## Done now: MVP-0 first playable

Delivered in this repo:

- project skeleton
- main bootstrap scene
- one test arena
- player movement
- Energy resource
- Refraction Beam
- wall bounce support
- Prism Node refraction/redirection support
- Moth enemy
- Hollow enemy
- reward choice
- restart/retry
- documentation pass

## Current state: MVP-0.3 combat/runtime decomposition in progress

Recently completed:

- flashlight reveal mechanic added for Hollow pressure/readability
- disrupted blink readability improved with visible windup + transit
- shared enemy freeze bug fixed in v0.3.2
- first low-risk internal refactor pass completed around data, reward flow, debug input, and HUD helpers
- second structural pass completed in v0.3.3 around beam resolution and encounter orchestration

## Next sensible milestone: MVP-0 enemy/runtime state extraction

Recommended next steps:

1. extract enemy runtime update/state handling from `run_scene.gd`
2. group shared mutable run state more cleanly to reduce flag sprawl
3. retest enemy pacing and beam readability after the structural pass
4. tighten reward/UI readability only if new playtests still expose friction
5. add lightweight hit-flash/audio polish after runtime structure is safer
6. keep documenting playtest findings in persistent files

## After validation: MVP-1

Only proceed if the core beam/refraction loop feels strong.

Then add:

- Prism Node upgrade depth
- one third Prism skill
- one miniboss
- 4–5 encounter chain
- simple run summary
- cleaner data-driven content layer
