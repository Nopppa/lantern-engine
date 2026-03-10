# Current State

Last updated: 2026-03-10
Current shipped version target: `v0.5.0`

## Now shipped

- the project now boots directly into a permanent authored **Light Lab** instead of the old auto-wave run
- the lab contains outer walls, internal routing segments, authored brick/wood/wet/mirror/glass/prism test spaces, dead/alive blend lanes, and an open validation deck
- flashlight checks now expose a queryable local light intensity with cone falloff, a stronger center, and softer edge behavior
- first-pass light material definitions now drive readable beam behavior differences across mirror, glass, brick, wood, wet stone, and prism routing
- dead/alive floor response now blends on the rendering side toward ALIVE while illuminated and fades back toward DEAD when light leaves unless the zone has a restored base state
- enemy testing in the lab is manual/debug spawned only; there is no auto encounter flow, no forced completion, and no run ending state in the primary map

## Canon direction status

The project is now concretely aligned to:

- `docs/visio.md`
- `docs/ohjeet.md`
- `docs/light_engine.md`

That direction is no longer just a recommendation in docs; it is now reflected in the shipped main runtime.

## Legacy scaffolding

The older wave-survival arena, encounter chain, reward flow, and run summary are still kept in-repo as temporary legacy scaffolding for reference and fallback testing.
They are no longer the primary design center.

## Immediate next recommendation

Build on the Light Lab by improving:

- material readability/signage and authored comparison cases
- beam-path instrumentation and debug overlays
- light-to-surface tuning for dead/alive restoration semantics
- extraction boundaries so lab systems can migrate cleanly into the eventual exploration runtime
