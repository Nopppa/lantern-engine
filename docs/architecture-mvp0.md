# MVP-0 Architecture Notes

## Practical decision

I kept the first playable version in a single primary runtime script (`scripts/run_scene.gd`) on purpose.

### Reason

For MVP-0, the main risk is **not code elegance**. The risk is building a pretty architecture around a mechanic that is not fun.

A compact runtime made it faster to implement and tune:

- movement
- Energy regen/costs
- beam bounce logic
- prism redirection logic
- enemy pressure
- reward flow
- restart loop

## Systems inside `run_scene.gd`

### Player state
- HP / max HP
- Energy / max Energy / regen
- movement and facing
- beam cooldown
- prism node cooldown / duration

### Combat
- line-segment beam tracing to arena bounds
- wall reflection based on bounds hit
- segment vs enemy circle hit checks
- damage and death flags

### Enemies
- Moth: direct chaser / contact damage
- Hollow: intermittent blink ambusher + slower chase pressure

### Progression
- post-encounter reward panel
- three initial upgrades:
  - +1 bounce
  - longer beam
  - focused lens (+damage)

### Encounter loop
- 3 authored encounter steps
- reward after each cleared encounter
- run clear end state
- restart via `R`

## Known technical debt

- rendering uses `_draw()` + ad hoc nodes instead of dedicated scenes for every actor
- no reusable component scripts yet
- no resource/data asset layer yet
- reward and encounter data are inline arrays
- no dedicated combat resolver class yet

## Why that debt is acceptable

Every one of those debts is reversible. The bigger risk would have been shipping no playable proof.
