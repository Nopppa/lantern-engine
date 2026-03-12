# Lantern Engine – Light Engine Technical Specification

## Purpose

This document defines the technical and gameplay-oriented behavior of light in Lantern Engine.

The goal is **not** to build physically perfect real-world optics.
The goal is to build a **consistent, readable, and satisfying gameplay light system**.

The light system is one of the most important foundations of Lantern Engine.
All major gameplay systems depend on it.

---

# Design Principles

## Principle 1 – Consistency over realism

A surface does not need to behave exactly like in real-world physics.
It must behave:

* consistently
* predictably
* readably
* in a way that feels logical to the player

If the player learns that a material reflects, diffuses, absorbs, or transmits light in a specific way, that rule should remain stable.

---

## Principle 2 – Flashlight and laser are different systems

There are two distinct light systems in the game.

### Flashlight Cone

Used for:

* illumination
* enemy debuffing
* temporary world restoration
* atmosphere

### Laser / Focused Beam

Used for:

* precise combat
* beam routing
* prism interaction
* tactical setups
* puzzle-like interactions

These two systems may share infrastructure but should not behave identically.

---

## Principle 3 – Readability is mandatory

The player must visually understand:

* where light is strongest
* where it weakens
* which surfaces reflect
* which surfaces absorb
* which surfaces diffuse
* which surfaces transmit
* how prisms modify light

If a rule exists but cannot be understood from visuals, the rule is not working well enough.

---

# Light System Architecture

## Recommended separation

The light engine should be divided into the following systems:

1. **Light Source System**
2. **Ray / Beam Casting System**
3. **Surface Response System**
4. **Light Intensity / Falloff System**
5. **Visual Blend System**
6. **Gameplay Effect Application System**
7. **Debug / Visualization System**

---

# 1. Light Source System

Each light-emitting object should be represented by a source definition.

## Common source properties

Suggested fields:

* source_type
* origin_position
* direction
* range
* base_intensity
* beam_angle
* max_bounces
* color
* falloff_curve
* source_mode

## Source types

### Flashlight Source

* cone-shaped emission
* short to medium range
* smooth falloff
* wide gameplay influence

### Laser Source

* narrow beam
* long range
* precise pathing
* reflection / refraction capable

### Prism Burst / Explosion Source

* radial or multi-directional temporary light
* short lifetime
* optional status effect payload

### Ambient Restoration Pulse

* region-based pulse used when bosses die or regions are restored

---

# 2. Ray / Beam Casting System

## Flashlight Cone

The flashlight should be evaluated as a directional cone with intensity falloff.

Suggested logic:

* determine angle from source forward vector to target point
* determine distance from source
* if inside cone and within range, calculate intensity

Suggested conceptual formula:

light_intensity = angle_factor * distance_factor * source_intensity

Where:

* angle_factor is strongest in the center of the cone
* distance_factor decreases toward max range

This allows:

* bright center
* soft edges
* natural fading near the end of the beam

---

## Laser Beam

Laser beam should use precise ray / segment logic.

Suggested behavior:

1. cast beam from source position in direction vector
2. detect first collision
3. query material response on hit surface
4. determine:

   * reflected component
   * diffused component
   * transmitted component
   * absorbed component
5. continue beam if reflected or transmitted energy remains
6. stop when intensity falls below threshold or bounce limit reached

---

## Bounce Handling

Laser beam should support a configurable bounce count.

Suggested fields:

* max_bounces
* min_intensity_threshold
* intensity_loss_per_interaction

Recommended initial limits:

* default max bounces: 3 to 6
* stop beam if intensity < minimum readable threshold

This prevents infinite or noisy beam chains.

---

# 3. Surface Response System

Each surface must define how it responds to incoming light.

## Core material properties

Each material should define:

* reflectivity
* diffusion
* transmission
* absorption
* optional tint
* optional roughness
* optional restoration_affinity

### reflectivity

How much light is redirected as a directional reflection.

### diffusion

How much light spreads outward in a softer scattered way.

### transmission

How much light passes through the surface.

### absorption

How much light energy is lost.

### tint

Optional color shift to outgoing light.

### roughness

Optional value affecting reflection sharpness vs softness.

### restoration_affinity

How strongly the surface contributes to alive-state visual restoration when illuminated.

Important rule:

reflectivity + diffusion + transmission + absorption should approximately sum to 1.0

---

# Recommended Initial Material Classes

## Brick

Role:

* mostly absorbent
* slightly diffusive
* not mirror-like

Suggested behavior:

* beam loses most energy
* small amount of ambient spread remains

Example values:

* reflectivity: 0.05
* diffusion: 0.20
* transmission: 0.00
* absorption: 0.75

---

## Wood

Role:

* organic diffuse surface
* slightly softer than brick

Suggested behavior:

* light spreads gently
* no strong reflection

Example values:

* reflectivity: 0.10
* diffusion: 0.35
* transmission: 0.00
* absorption: 0.55

---

## Wet Surface / Wet Stone

Role:

* partially glossy
* partially diffuse

Suggested behavior:

* beam partially reflects
* some spread remains

Example values:

* reflectivity: 0.45
* diffusion: 0.20
* transmission: 0.00
* absorption: 0.35

---

## Mirror

Role:

* highly controlled directional reflection
* tactical / puzzle surface

Suggested behavior:

* beam reflects strongly and clearly
* almost no diffusion

Example values:

* reflectivity: 0.95
* diffusion: 0.00
* transmission: 0.00
* absorption: 0.05

---

## Glass

Role:

* transmissive surface
* partially reflective

Suggested behavior:

* beam passes through partially
* slight reflection may remain

Example values:

* reflectivity: 0.15
* diffusion: 0.05
* transmission: 0.70
* absorption: 0.10

---

## Prism

Role:

* special gameplay surface
* splits, redirects, or transforms beams

Behavior is not purely based on material coefficients.
Prism should use explicit gameplay rules.

Prism behaviors may include:

* beam redirection
* beam splitting
* beam amplification
* status burst on detonation

---

# 4. Reflection, Diffusion, and Transmission Rules

## Reflection

Used mainly by:

* mirrors
* glossy surfaces
* wet surfaces
* some metallic surfaces later

Mirror reflection should be precise.

Suggested conceptual formula:

reflection_vector = reflect(incoming_vector, surface_normal)

For rough/glossy surfaces:

* reflected direction may include controlled spread based on roughness

---

## Diffusion

Diffusion means the light does not continue as a clean beam.
Instead, it spreads into a localized area.

Gameplay purpose:

* surfaces do not feel like black holes
* flashlight illumination feels natural
* some materials softly spread light into the environment

Diffusion does not need physically heavy simulation.
Use a simplified local spread model.

Suggested implementation options:

1. radial splash of reduced intensity near hit point
2. small cone spread around reflection direction
3. local illumination mask around impact point

For Lantern Engine, readability is more important than perfect optics.

---

## Transmission

Used mainly by:

* glass
* future magical barriers / crystals if needed

Transmission means some light continues through the surface.

Suggested behavior:

* outgoing beam continues in similar direction
* intensity reduced by transmission coefficient
* optional slight angular distortion depending on surface type

---

# 5. Intensity and Falloff System

All light should weaken over distance and interactions.

## Flashlight falloff

Flashlight should weaken based on:

* distance from source
* angular distance from beam center
* optional obstruction / material influence

Suggested conceptual factors:

* center of beam = highest intensity
* edges = lower intensity
* far end of beam = lower intensity

This is critical for alive/dead blending.

---

## Laser falloff

Laser should lose power through:

* travel distance
* material interactions
* beam splitting
* prism events
* bounce count

Suggested model:

current_intensity = previous_intensity * transmission_or_reflection_factor * distance_decay

Laser should not stay equally strong forever.

---

# 6. Dead / Alive Visual Blend System

One of the main gameplay fantasies of Lantern Engine is that light restores life.

This should be implemented using smooth visual blending.

## Asset rule

For each important tile / asset there may be:

* dead version
* alive version

These should share:

* same dimensions
* same origin / pivot
* same world position

---

## Blend rule

When illuminated:

final_visual = mix(dead_visual, alive_visual, illumination_value)

Where:

* 0.0 = fully dead
* 1.0 = fully alive
* 0.5 = half-blended

This should apply to:

* ground
* trees
* environmental props
* structures where feasible

---

## Temporary restoration

Flashlight creates temporary life.

Meaning:

* dead areas visually move toward alive state when illuminated
* when light leaves, they fade back unless permanently restored

This supports the fantasy that the lantern reveals what the world could become.

---

## Permanent restoration

Major progression events set a base alive state.

Examples:

* boss defeated
* corruption node destroyed
* beacon activated

Recommended model:

* tile_state_base = DEAD or ALIVE
* tile_light_exposure = 0.0 to 1.0
* final_blend = combine(base_state, current_light_exposure)

This allows both:

* temporary restoration from light
* permanent restoration from progression

---

# 7. Gameplay Effects Driven by Light

Light is not only visual.
It also drives gameplay effects.

## Enemy debuffing

Enemies in light may experience:

* movement slow
* delayed teleportation
* ability interruption
* exposure to damage amplification
* special weakness triggers

Suggested implementation:

* enemies query current local light intensity
* thresholds decide effect strength

Example:

* low light = minor slow
* medium light = strong slow
* high light = ability disruption

---

## Teleport enemy behavior

Special rule example:

Normal:

* instant teleport

In sufficient light:

* teleport becomes phased visible movement
* enemy travels from origin to destination over time
* still faster than walking but no longer instant

This is a major part of the combat identity and must feel readable.

---

## Projectile interaction

Boss or enemy projectiles may be weakened or destroyed by sufficient light exposure.

This should be handled using light thresholds and projectile tags.

---

# 8. Prism Behavior Specification

Prisms are special gameplay objects and should not behave like normal surfaces.

## Prism actions

Player can:

* place prism
* carry prism
* throw prism
* detonate prism

## Prism incoming beam behavior

Depending on prism mode or talent state, incoming beam may:

* redirect
* split into multiple beams
* refract at set angles
* amplify status payloads

## Example talent interaction

Talent: beam splitter

Behavior:

* beam that hits prism splits into multiple outgoing beams instead of single redirected beam

## Prism detonation

Prism explosion may:

* create area light burst
* burn enemies
* apply debuffs
* create temporary local alive blend spike

---

# 9. Rendering Recommendations

## Recommended approach

Prefer:

* shader-based blending
* tile-level blending
* sprite-level mask blending

Avoid implementing pixel replacement logic directly in gameplay code.

Reason:

* cleaner architecture
* better performance
* easier iteration
* smoother gradients
* easier debugging

The game concept of mixing dead/alive visuals based on beam coverage is correct.
The implementation should happen primarily in rendering systems, not by manually rewriting texture pixels every frame in core gameplay logic.

---

# 10. Debug Tools Requirement

A debug layer is mandatory for developing the light system.

Required debug functions:

* spawn enemy anywhere
* spawn miniboss
* spawn prism
* place surface samples
* toggle material type
* toggle dead/alive base state
* visualize flashlight cone
* visualize laser path
* show bounce count
* show current material hit
* show local light intensity at cursor or target
* show tile blend value

Without these tools iteration speed will collapse.

---

# 11. Suggested Immediate Test Map

Build a dedicated light laboratory map.

This should not be a full procedural zone yet.
It should be a controlled test environment.

## Contents

* one brick wall section
* one wood section
* one wet surface section
* one mirror section
* one glass section
* one prism station
* one enemy sample zone
* one teleport enemy sample zone
* dead/alive ground patch testing zone

## Goals

* validate readability
* validate consistency
* validate visual feel
* validate enemy interactions
* validate dead/alive blending

---

# 12. Acceptance Criteria for Light System Milestone

The current milestone is successful when:

1. flashlight looks natural and readable
2. laser path is deterministic and understandable
3. mirrors reflect cleanly
4. glass transmits partially and predictably
5. brick and wood absorb/diffuse differently in a noticeable way
6. wet surfaces feel visually distinct from dry surfaces
7. enemies react to light consistently
8. teleport enemy delay in light is clear
9. dead/alive blend works smoothly
10. debug tools make testing fast

---

# 13. Final Priority Rule

Do not prioritize new combat systems or content expansion before the light system is correct.

The light engine is the foundation of Lantern Engine.

If the light behavior feels correct:

* combat will feel better
* restoration will feel better
* visuals will feel better
* procedural world will feel more believable

If the light behavior feels wrong:

* the entire game fantasy weakens

Therefore the current top priority is:

**make light behavior coherent, readable, and satisfying first**.
