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

## Current state: MVP-0.3.4 stabilization + enemy/runtime extraction completed

Recently completed:

- flashlight reveal mechanic added for Hollow pressure/readability
- disrupted blink readability improved with visible windup + transit
- shared enemy freeze bug fixed in v0.3.2
- first low-risk internal refactor pass completed around data, reward flow, debug input, and HUD helpers
- second structural pass completed in v0.3.3 around beam resolution and encounter orchestration
- tester-visible debug regressions fixed in v0.3.4 (`F2` refill and `F3` reward trigger)
- enemy runtime update/state handling extracted in v0.3.4 to `scripts/gameplay/enemy_controller.gd`

## Next sensible milestone: MVP-0.x safety cleanup + feel verification

Recommended next steps:

1. group shared mutable run state more cleanly to reduce flag sprawl
2. keep playtesting enemy pacing after the controller split; adjust only if fresh evidence shows drift
3. keep playtesting beam readability after the safety pass; current beam resolver ownership is now in the right place
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
