# Milestones

## Done now: MVP-1 patch 2 shipped

Delivered in this repo now:

- simple run summary
- cleaner data-driven content layer for encounters and upgrades
- authored 5-encounter chain
- Prism Node upgrade depth affecting real runtime beam behavior
- third Prism skill: Prism Surge
- Windows release artifact for the current patch

## Previous milestone: MVP-0 first playable

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

## Current state: MVP-1 patch 2 complete as of v0.4.1

Recently completed:

- simple run summary is now populated from real runtime events instead of scaffolding only
- encounter and upgrade authoring now live cleanly in dedicated data files and are used by runtime flow
- the run now uses an authored 5-encounter chain end-to-end
- Prism Node upgrades now change redirect damage, catch radius, bend angle, and post-redirect bounce continuation in actual beam resolution
- Prism Surge adds a third combat skill that consumes the active node for radial burst damage and displacement
- final encounter completion now resolves directly into the run summary / restart state

## Immediate posture: playtest this authored run with Prism Surge

Do now:

1. distribute the current Windows tester artifact
2. verify that the 5-encounter pacing lands well in real hands
3. collect feedback specifically on Prism Surge timing/value, Prism upgrade depth, and run-summary usefulness
4. fix only concrete issues revealed by that playtest pass

## Recommended next MVP-1 step

- add the next scoped combat-content layer carefully: the miniboss, using the now-complete three-skill runtime as the baseline combat kit
