# Lantern Engine – Light Restoration System

## Purpose

This document defines the **Light Restoration System**, one of the core gameplay mechanics of Lantern Engine.

Light does not merely illuminate the world.

Light **restores life to a dead world**.

This system affects:

- terrain
- vegetation
- structures
- environmental details

The restoration effect is **temporary while illuminated** and fades gradually when light is removed.

This creates the feeling that the player is **bringing life back to the world with light**.

---

# Core Concept

The world exists visually in two states:

DEAD  
ALIVE

Dead represents a corrupted world consumed by darkness.

Alive represents the restored natural state of the world.

Light reveals and temporarily restores the **alive state**.

---

# Visual Restoration Model

Each restorable object contains two visual representations.

- dead_visual
- alive_visual

These visuals share the same:

- position
- scale
- sprite layout
- collision shape

The final visual is calculated by blending between the two states.

Conceptual formula:


final_visual = mix(dead_visual, alive_visual, restoration_value)


Where:

- restoration_value = 0.0 → fully dead
- restoration_value = 1.0 → fully alive

---

# Restoration Value

Each object maintains a dynamic value:


restoration_value


This value is influenced by **light exposure**.

When illuminated:

- restoration_value increases quickly

When light leaves:

- restoration_value decreases slowly

Conceptual behavior:


if illuminated:
restoration_value += growth_rate * light_intensity

if not illuminated:
restoration_value -= decay_rate


The decay rate should be **slower than the growth rate**.

This creates a lingering effect where life briefly remains after light passes.

---

# Multi-Layer Restoration

Restoration should occur in layers rather than a simple texture switch.

## Layer 1 – Base Terrain Shift

Dead terrain gradually changes color.

Examples:

- brown soil shifts toward green
- desaturated textures gain saturation
- brightness increases slightly

This layer affects the largest visible area.

---

## Layer 2 – Vegetation Growth

When restoration_value crosses a threshold, vegetation begins to appear.

Examples:

- grass
- small plants
- flowers
- leaves

Vegetation should **grow quickly**, not pop instantly.

Suggested behavior:

- growth animation or scale-up effect
- slightly randomized placement
- quick but visible growth

When light fades:

- vegetation fades or shrinks first
- terrain color fades more slowly

---

## Layer 3 – Structural Restoration

Structures such as buildings should visually restore when illuminated.

Examples:

- broken windows fade into restored windows
- cracks diminish
- details reappear
- walls regain color and structure

The effect should feel like the **true structure is emerging from the shadows**.

This is implemented using the same blending model.

Example progression:

1. grey ruin
2. subtle color return
3. structural edges sharpen
4. restored architectural features appear

---

# Restoration Response Speeds

Different object types should respond differently to light.

Suggested values:

| Object Type | Growth Speed | Decay Speed |
|-------------|-------------|-------------|
Ground | fast | medium |
Vegetation | fast | fast-medium |
Trees | medium | medium |
Structures | slower | slow |

This creates a layered and natural restoration effect.

---

# Light Exposure Model

Objects receive a **light intensity value** from the light engine.

Example inputs:

- flashlight cone intensity
- laser reflection spill
- prism burst light
- ambient light effects

Conceptual range:


light_intensity ∈ [0.0, 1.0]


Higher intensity accelerates restoration.

Lower intensity produces weaker effects.

---

# Restoration Thresholds

Optional thresholds can control visual events.

Example:


0.0 – 0.2
minor color shift

0.2 – 0.5
terrain visibly restored

0.5 – 0.8
vegetation begins appearing

0.8 – 1.0
full alive state


These thresholds allow progressive restoration.

---

# Fade-Out Behavior

When illumination stops:

- vegetation fades first
- terrain color fades later
- structures fade slowest

This creates a **memory effect** where the world briefly remembers life.

Example order of decay:

1. flowers disappear
2. grass fades
3. terrain returns to brown
4. structures darken again

---

# Performance Considerations

Avoid per-pixel gameplay logic.

Preferred approaches:

- shader-based blending
- sprite overlay systems
- lightweight vegetation spawning

The restoration effect should remain **cheap enough to run continuously**.

---

# Gameplay Impact

The restoration system supports several gameplay functions:

- visual reward for exploration
- environmental storytelling
- guidance for player navigation
- enemy weakness to light
- puzzle mechanics

The player should feel that their light **pushes back the darkness**.

---

# Visual Design Goal

The effect should evoke the following feeling:

A dead world slowly waking up wherever the player's light touches.

Grass grows.

Leaves appear.

Ruins remember their former shape.

But when the light leaves, the darkness begins reclaiming it.

---

# Implementation Principle

The system must feel:

- organic
- responsive
- visually readable
- emotionally satisfying

Avoid binary switching.

Always prefer **smooth transitions and layered restoration**.

---

# Final Design Goal

The player should experience the world as something fragile but recoverable.

Wherever light reaches, **life briefly returns**.