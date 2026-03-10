# Current State

Last updated: 2026-03-10
Current shipped version target: `v0.5.3`

## Now shipped

- the project now boots directly into a permanent authored **Light Lab** instead of the old auto-wave run
- the lab contains outer walls, internal routing segments, authored brick/wood/wet/mirror/glass/prism test spaces, dead/alive blend lanes, shallow/deep water lanes, and an open validation deck
- flashlight checks now expose a queryable local light intensity with cone falloff, a stronger center, softer edge behavior, and secondary surface response on authored materials
- prism light now also participates in the shared material-response model and excites nearby surfaces instead of remaining only an isolated aura concept
- first-pass light material definitions now drive readable response differences across mirror, glass, brick, wood, wet surface, and prism routing from laser / flashlight / prism light together
- dead/alive floor response now blends on the rendering side toward ALIVE while illuminated and fades back toward DEAD when light leaves unless the zone has a restored base state
- player, enemy, and miniboss motion in the lab now respects wall collision rather than only room clamping
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

## Now improved in v0.5.3

- flashlight rendering now follows blocker/material truth much more closely with visible traced rays, visible blocking, visible reflection, and visible glass pass-through bend instead of relying on a misleading simple cone
- glass / wood / wet / wood-floor interactions now read more honestly in the visible light language
- flashlight cone widened slightly to support readability without turning into a floodlight
- enemies now use lightweight obstacle routing around walls/tree trunks when a path exists
- `F1` now genuinely hides help/legend/debug overlays for a clean validation view
- reusable-vs-lab-only migration boundary now also documents the new flashlight-visual and navigation helpers honestly

## Immediate next recommendation

Do a narrow runtime-light consolidation pass:

- separate scene-agnostic trace/query inputs from `light_surface_resolver.gd`
- keep Light Lab debug presentation as a consumer of those outputs
- begin proving the same reusable light query pieces in the first small exploration-room prototype later, not yet in a full exploration system
