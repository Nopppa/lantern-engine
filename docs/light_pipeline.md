# Lantern Engine – Light Pipeline

## Purpose

This document defines how the **light system flows through the game engine**.

It explains:

- where light is calculated
- how restoration values are updated
- how visuals are rendered
- how other systems interact with light

The goal is to ensure that all AI agents implement the light system consistently.

---

# Core Systems Involved

The light pipeline connects several modules:

light_engine  
tile_state_system  
vegetation_system  
structure_system  
enemy_system  
rendering_layer  

Each system has a clearly defined role.

---

# Light Flow Overview

The light system operates as a continuous pipeline.

Conceptually:


light sources
↓
light propagation
↓
surface interaction
↓
local light intensity
↓
restoration updates
↓
visual rendering


This flow must remain consistent.

---

# Step 1 – Light Sources

Light sources include:

- player flashlight
- laser beam
- prism reflection
- prism burst
- environmental light sources (optional future)

Each light source produces:


light_origin
light_direction
light_intensity
light_range


These are passed to the **light_engine**.

---

# Step 2 – Light Propagation

The light_engine calculates how light travels.

It resolves:

- beam paths
- reflections
- diffusion
- transmission through surfaces
- intensity falloff

Outputs include:


beam_segments
collision_points
local_light_intensity


This information describes **where light reaches in the world**.

---

# Step 3 – Surface Interaction

When light hits world geometry, surface properties modify it.

Surface types may include:

- stone
- wood
- wet surface
- mirror
- glass
- absorbing material

Surface responses may include:

- reflection
- diffusion
- transmission
- absorption

The result is updated beam data and local light intensity values.

---

# Step 4 – Local Light Intensity Map

After propagation, the system produces local intensity values.

Conceptually:


light_intensity_at_position


Range:


0.0 → complete darkness
1.0 → full illumination


This value drives **restoration behavior**.

---

# Step 5 – Restoration Update

Every restorable world object reads the local light intensity.

Objects track:


restoration_value


Behavior:


if illuminated:
restoration_value increases

if not illuminated:
restoration_value decays


Growth should be faster than decay.

This creates a **lingering life effect**.

---

# Step 6 – Vegetation Growth

When restoration_value passes thresholds, vegetation appears.

Example stages:

0.0 – dead ground  
0.3 – color shift begins  
0.5 – small plants appear  
0.7 – grass grows  
1.0 – full vegetation  

Vegetation growth should animate quickly.

When restoration decreases:

- vegetation fades first
- terrain fades later

---

# Step 7 – Structure Restoration

Structures use the same restoration system.

Dead structures blend toward restored versions.

Example transitions:

- broken windows fade into repaired windows
- cracks disappear
- architectural details return

Structure restoration should be slower than terrain.

This makes buildings feel more substantial.

---

# Step 8 – Rendering Layer

Rendering combines visual layers:

1. base terrain
2. alive/dead blending
3. vegetation sprites
4. structural restoration
5. light effects

Conceptual blend:


final_visual = mix(dead_visual, alive_visual, restoration_value)


Vegetation and small life effects render on top.

---

# Step 9 – Enemy Interaction

Enemies can query local light intensity.

Example behaviors:

- slowed by light
- prevented from teleporting
- damaged by focused light
- projectiles destroyed in strong light

Enemy logic must **read light values**, not compute them.

The light_engine remains the sole owner of light calculations.

---

# Step 10 – Performance Considerations

The pipeline must remain efficient.

Guidelines:

- avoid per-pixel gameplay logic
- prefer tile-based or object-based updates
- offload blending to shaders where possible
- limit vegetation spawning density

Light calculations should remain stable even with multiple beams.

---

# Debug Tools

A debug mode should exist for development.

Debug features may include:

- light intensity visualization
- restoration_value overlay
- beam path display
- vegetation spawn markers

This helps verify correct system behavior.

---

# Design Principle

Light is not just visibility.

Light is the **force that restores the world**.

Every system that reacts to light should reinforce this idea.

Where light touches, life returns.