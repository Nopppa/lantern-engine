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

## Current state: MVP-0 complete as of v0.3.5

Recently completed:

- flashlight reveal mechanic added for Hollow pressure/readability
- disrupted blink readability improved with visible windup + transit
- shared enemy freeze bug fixed in v0.3.2
- first low-risk internal refactor pass completed around data, reward flow, debug input, and HUD helpers
- second structural pass completed in v0.3.3 around beam resolution and encounter orchestration
- tester-visible debug regressions fixed in v0.3.4 (`F2` refill and `F3` reward trigger)
- enemy runtime update/state handling extracted in v0.3.4 to `scripts/gameplay/enemy_controller.gd`
- final v0.3.5 polish tightened reward readability and added lightweight hit-flash / synthesized audio feedback without expanding scope
- MVP-0 is now considered effectively complete for tester handoff unless a new serious regression appears

## Immediate posture: ship + only fix real regressions

Do now:

1. distribute the current Windows tester artifact
2. treat new work as bugfix-only unless a tester finds a concrete MVP-0 blocker
3. keep persistent playtest notes if any regressions or clarity gaps appear

## Next milestone: MVP-1

Only proceed if the core beam/refraction loop feels strong.

Then add:

- Prism Node upgrade depth
- one third Prism skill
- one miniboss
- 4–5 encounter chain
- simple run summary
- cleaner data-driven content layer
