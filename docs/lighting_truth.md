# Lighting Truth

This document defines the non-negotiable architectural and gameplay rules for Lantern Engine's lighting system.

If an implementation idea conflicts with these rules, the implementation must change.

## 1. Core idea

Light restores life to the world.

Darkness represents decay.
Light represents restoration.

Gameplay systems must preserve this relationship.

## 2. Gameplay light vs visual light

These must remain separate.

### Gameplay light
Used for:
- world restoration
- plants and environmental reactions
- enemies and gameplay logic
- puzzle interactions

Gameplay light lives in the **LightField** and related world/gameplay data.

### Visual light
Used for:
- ambient visibility
- glow / bloom / highlight presentation
- atmosphere
- decorative native Godot lighting

Visual light must never become gameplay truth.

Ambient light is visual-only.

## 3. Restoration behavior

World restoration must be gradual, not binary.

Rules:
- flashlight center restores more than beam edge
- stronger light restores faster
- weaker light restores more slowly
- darkness causes slow decay

Do not flatten lighting into simple on/off world state behavior.

## 4. Persistent restoration

Persistent world progress must be stored as data, not faked with permanent visual light.

Preferred model shape:

```text
life_charge += current_light * revive_rate
life_charge -= decay_rate
life_charge = max(life_charge, persistent_floor)
```

Use persistent world-state data such as `persistent_floor` rather than fake always-on gameplay light.

## 5. Shared light interaction rules

Objects should interact with light through shared material/world properties.

Typical properties include:
- opacity
- transmission
- reflection
- emission
- shadow casting

Avoid object-specific hacks unless a behavior is explicitly intended as a special-case effect.

## 6. Rendering is not gameplay

Rendered pixels, sprites, glows, and decorative effects are not gameplay truth.

Gameplay logic must read from:
- `LightField`
- `LightWorld`
- shared gameplay/world data

not from presentation output.

## 7. Performance philosophy

Gameplay lighting must remain efficient.

Preferred methods:
- low-resolution `LightField`
- cached updates
- shared material/world rules
- write-once, read-many gameplay-light flow

Avoid:
- heavy packet scanning in gameplay queries
- per-pixel gameplay lighting logic
- large numbers of temporary gameplay light objects
- regressions from `LightField` back to render-packet hot-path scans

Visual rendering may be richer than gameplay logic, but gameplay-light truth must stay cheap and stable.

## 8. World data model

The world should have one source of truth.

Objects define:
- geometry
- material/light properties
- gameplay tags

Lighting, gameplay logic, and presentation derive behavior from that shared data model.

## 9. Current architecture contract

The intended architecture is:

```text
LightSource
-> Solver
-> LightRenderPacket --------> Presentation
-> LightField ---------------> Gameplay sampling / restoration / logic
```

And for world structure:

```text
Authored or Generated Layout
-> LightWorld / LightWorldBuilder
-> Shared solver + gameplay + presentation flow
```

## 10. Contributor rule

Before changing lighting behavior or architecture:
1. preserve gameplay-light vs visual-light separation
2. preserve gradual restoration behavior
3. preserve `LightField` as gameplay-light truth
4. preserve `LightRenderPacket` as presentation/render truth
5. preserve authored/generated compatibility through shared world paths

If a shortcut breaks those rules, do not take it.
