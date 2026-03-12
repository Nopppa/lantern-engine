# Boss Data Format (Draft)

Goal: make bosses authorable as structured data so future miniboss/boss work can move toward reusable generation and composition.

## Recommended split

### 1. Boss profile file
One file per boss, e.g.:
- `scripts/data/bosses/hollow_matriarch.json`

Contains:
- identity / fantasy / role
- base stats
- phase structure
- light interaction rules
- list of skill ids or embedded skill definitions
- telegraphing notes
- implementation notes

### 2. Boss skill files (future-friendly)
Recommended next standard once more than one boss exists:
- `scripts/data/boss_skills/<skill_id>.json`

Contains only the skill's reusable authored behavior:
- type
- cooldown
- damage
- projectile data
- light counters
- telegraph rules
- phase tags / usage tags

### 3. Boss assembly layer
A boss can later be assembled from:
- one profile
- N skill definitions
- optional modifier package

That allows future experiments like:
- authored bosses
- semi-randomized miniboss packages
- biome-specific boss variants

## Suggested schema outline

```json
{
  "id": "boss_id",
  "display_name": "Boss Name",
  "role": "miniboss",
  "fantasy": "short fantasy sentence",
  "core_rules": {
    "hp": 0,
    "base_move_speed": 0,
    "phase_thresholds": [0.5],
    "dark_regen": { ... },
    "light_interaction": { ... }
  },
  "skills": [
    { ... }
  ],
  "phases": [
    { ... }
  ],
  "telegraphing": { ... },
  "implementation_notes": { ... }
}
```

## Authoring rules

1. Keep combat fantasy explicit.
2. Every boss should define:
   - what light stops
   - what light weakens
   - what Surge interrupts
3. Projectile bosses should define whether projectiles can be destroyed by light.
4. Phase-2 escalations should be clearly separable from the MVP version.
5. Keep one `minimum_viable_boss` block so implementation can cut scope cleanly.

## Why this format helps

- easier for a coder to implement from one file
- easier to review design intent without reading code
- easier to build future random boss assembly from structured components
- easier to keep boss skills separate from boss body stats and phase logic
