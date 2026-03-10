# Hollow Matriarch — Implementation Plan

Purpose: give the programmer a safe, staged path to implement the first Lantern Engine miniboss without scope creep.

Related design source:
- `scripts/data/bosses/hollow_matriarch.json`

## Target outcome

Ship the first miniboss as a focused Lantern Engine boss encounter that:
- heals in darkness
- stops healing in honest light
- fires darkness projectiles that can be dissolved by flashlight/prism light
- has one readable special that Prism Surge can interrupt
- uses the existing three-skill combat kit instead of replacing it

## Scope discipline

Implement in this order. Do not jump ahead unless the earlier stage is already validated.

### Stage 1 — Minimum viable boss
Must-have systems only:

1. boss spawn + boss HP
2. dark regen in shadow
3. regen suppression in flashlight / prism light
4. one projectile attack (`shadow_bolt`)
5. projectile HP + light corrosion
6. one special mobility attack (`veil_pounce`)
7. Surge interrupt / jam interaction
8. clear boss death / run completion handling

If Stage 1 is not stable, do not build Stage 2.

### Stage 2 — Fight readability pass
Only after Stage 1 works:

1. boss telegraphs
2. clearer regen visuals
3. clearer projectile erosion visuals
4. cleaner phase transition signaling
5. optional debug boss HP display if helpful for tuning

### Stage 3 — Optional phase escalation
Only if Stage 1 + 2 feel too thin:

1. add `shroud_bloom`
2. keep it simple
3. cut it immediately if it bloats the fight or delays the release

## Recommended code split

Do not dump miniboss logic into `run_scene.gd`.

Preferred structure:
- boss authored data:
  - `scripts/data/bosses/hollow_matriarch.json`
- future boss skill data if needed:
  - `scripts/data/boss_skills/*.json`
- runtime support:
  - extend existing enemy/boss controller or add a dedicated boss controller
- projectile behavior:
  - isolated enough that projectile HP + light corrosion rules are easy to reason about

## Implementation order in code

### 1. Data ingestion
- load `hollow_matriarch.json`
- prove the runtime can consume boss profile data without hardcoding every value inline

### 2. Boss entity runtime
- create boss spawn path
- HP/state container
- phase tracking
- contact rules if needed

### 3. Light rule integration
- define exactly how flashlight and prism light are tested against the boss
- hook regen suppression first
- keep the light truth consistent with the existing flashlight/prism logic

### 4. Shadow bolt
- projectile entity/state
- projectile HP
- light damage from flashlight/prism light
- clean safe dissolve before impact if light wins

### 5. Veil pounce
- readable windup
- movement/impact handling
- Surge interrupt handling
- do not make it instant or unfair

### 6. End-of-fight integration
- encounter clear
- run summary support if useful
- restart flow

### 7. Optional shroud bloom
- only if needed

## Balance guidelines

### Regen
- should matter enough to punish lazy play
- should not fully erase progress too fast
- player should clearly understand why healing stopped or resumed

### Projectile corrosion
- flashlight should be a real defensive answer
- prism light should feel even more deliberate / positional
- projectiles should not evaporate so fast that the mechanic becomes trivial

### Veil pounce
- should create pressure
- should reward Surge timing
- should not feel like unavoidable teleport damage

## Playtest checklist

When the first boss build exists, test these first:

1. Does the player understand that light stops regen?
2. Can flashlight safely dissolve at least some projectiles before impact?
3. Does prism placement create meaningful safe corridors?
4. Does Surge clearly interrupt the boss special?
5. Is the fight still readable in phase 2?
6. Does the boss feel like Lantern Engine, not a generic action-game miniboss?

## Hard anti-scope-creep rules

Do not add in the first boss pass:
- multiple new enemy types at the same time
- full bullet hell patterns
- complex summon ecosystems
- huge cutscene layer
- totally new lighting framework
- procedural boss generation now

First prove one authored miniboss works.

## Definition of done

The first Hollow Matriarch implementation is done when:
- it spawns and functions from authored boss data
- regen/light rules work reliably
- shadow bolt can be dissolved by light
- veil pounce is interruptible by Surge
- the fight can be completed cleanly
- headless validation passes
- Windows export passes
- docs/version/changelog are updated
- tester artifact is shipped
