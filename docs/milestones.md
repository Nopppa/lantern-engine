# Milestones

## Done now: MVP-1 patch 5 shipped

Delivered in this repo now:

- simple run summary
- cleaner data-driven content layer for encounters and upgrades
- authored 5-encounter chain
- Prism Node upgrade depth affecting real runtime beam behavior
- third Prism skill: Prism Surge
- Prism Node truth/recharge HUD fix
- Prism Surge special-jam identity
- Prism Surge Light Burn follow-up with readable burn feedback
- first Hollow Matriarch miniboss pass as the round-5 finisher
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

## Current state: MVP-1 patch 5 complete as of v0.4.4

Recently completed:

- Hollow Matriarch miniboss now ships from authored boss JSON through a dedicated boss-data loader/runtime path
- round 5 now resolves in two steps: its regular mixed wave first, then the Hollow Matriarch miniboss phase enters as the finisher
- shipped the minimum viable boss kit from the implementation plan: darkness regen, honest-light suppression, shadow-bolt projectile corrosion, readable Veil Pounce, and a 50% HP escalation
- Prism light now behaves as anti-darkness light for Hollow / miniboss behavior where appropriate instead of only flashlight handling that role
- Prism Surge now cleanly jams the Matriarch's Veil Pounce, reinforcing Beam + Prism Node + Prism Surge as one coherent combat kit
- final encounter completion still resolves directly into the run summary / restart state after the miniboss dies

## Immediate posture: focused miniboss playtest/tuning pass

Do now:

1. distribute the current Windows tester artifact
2. verify that round-5 normal-enemy pacing into the miniboss finisher reads clearly in live play
3. collect feedback specifically on regen readability, shadow-bolt dissolve clarity, prism-light anti-darkness truth, and Surge interrupt timing
4. fix only concrete issues revealed by that miniboss pass

## Recommended next MVP-1 step

- do a narrow Hollow Matriarch polish/tuning patch; only add `shroud_bloom` if the shipped Stage-1 fight clearly needs one extra escalation layer after testing

## After the miniboss: generator experiment

Do not jump straight into full procedural generation. First build a controlled field-generator experiment that answers these questions:

1. does generated geometry still produce good light/occlusion play?
2. does readability survive outside the current authored spaces?
3. do beam, Prism Node, and Prism Surge still feel good in semi-random layouts?
4. does encounter pacing hold up when room structure is less authored?

Treat this as a proof-of-concept milestone, not a full content rewrite.

## After the generator proof: concept-art visual direction pass

Only start a larger art-direction push toward the `concept_art/` material after:

- the three-skill combat kit is stable
- the miniboss exists and is tested
- the generator experiment has clarified whether the game is authored, procedural, or hybrid
- environment scale / occlusion needs are no longer moving wildly

At that point, use the concept art as a visual north star for:
- biome identity
- environmental occlusion language
- player silhouette / animation tone
- Prism Surge / Light Burn VFX polish
- darkness, fog, and scale presentation
