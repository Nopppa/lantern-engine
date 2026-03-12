# Lantern Engine – Agent Instructions

This document summarizes the current development focus and next priorities.

The current development phase should focus heavily on LIGHT BEHAVIOR SYSTEMS.

The lantern and light interactions are the most important gameplay mechanic in the game.

New combat features should not be prioritized before the light system behaves correctly.

---

# Current Development State

The project currently has:

- basic player movement
- ranged combat
- projectile system
- enemy logic
- first miniboss prototype
- boss prototype
- lantern debuff mechanic
- laser beam
- beam reflection prototype
- prism placement and explosion
- wave-based enemy spawning (temporary system)

The game currently runs in a simple square test arena.

---

# Immediate Development Focus

Development should now focus on validating the LIGHT SYSTEM.

This includes:

- light interaction with surfaces
- beam reflection
- beam diffusion
- beam absorption
- beam transmission
- visual blending between DEAD and ALIVE tiles

This phase is called:

LIGHT BEHAVIOR VALIDATION PHASE

---

# Surface Material System

Each surface type should define how it interacts with light.

Recommended properties:

reflectivity  
diffusion  
transmission  
absorption  

Example material definitions:

## Brick

- reflectivity: very low
- diffusion: low
- transmission: none
- absorption: high

Behavior:
light mostly dies on the surface but spreads slightly around it.

---

## Wood

- reflectivity: low
- diffusion: medium
- transmission: none
- absorption: medium

Behavior:
light spreads softly around the surface.

---

## Wet Surface

- reflectivity: medium
- diffusion: medium
- transmission: none
- absorption: medium-low

Behavior:
partially reflective and partially diffuse.

---

## Mirror

- reflectivity: very high
- diffusion: almost zero
- transmission: none
- absorption: very low

Behavior:
beam reflects clearly.

Used for puzzles and combat manipulation.

---

## Glass

- reflectivity: low-medium
- diffusion: low
- transmission: high
- absorption: low

Behavior:
beam partially passes through and partially reflects.

---

# Light Behavior Systems

Two light systems exist.

## Flashlight Cone

Purpose:

- illuminate environment
- debuff enemies
- reveal alive state of world

Flashlight light should have:

- soft diffusion
- gradual intensity falloff
- visible illumination gradient

Flashlight should not behave exactly like the laser beam.

---

## Laser Beam

Purpose:

- combat
- puzzles
- prism interaction

Laser beam should be:

- precise
- readable
- deterministic

Reflection and refraction rules should be consistent.

---

# Dead / Alive Tile Blending

Each tile has two visual versions:

dead version  
alive version

When illuminated:

visual blending occurs.

Formula concept:

final_visual = mix(dead_tile, alive_tile, light_intensity)

Light intensity determines the blending ratio.

Center of beam:
mostly alive.

Edge of beam:
mostly dead.

This creates smooth visual transitions instead of hard edges.

---

# Development Tools Requirement

Before continuing major feature work, developer testing tools should be implemented.

Required debug tools:

- spawn enemy anywhere
- spawn miniboss
- spawn prism
- toggle surface types
- toggle dead/alive tiles
- visualize light intensity
- display material type of surface

These tools accelerate testing and debugging.

---

# Next Patch Goal

Next patch should focus entirely on validating the LIGHT SYSTEM.

Patch name suggestion:

LIGHT_SURFACE_TEST_PATCH

Patch contents:

1. create a dedicated test room
2. implement all main surface types
3. enable flashlight testing
4. enable laser testing
5. display reflection behavior
6. show diffusion behavior
7. test prism interaction
8. test dead/alive blending
9. implement debug spawn tools

The test room should contain:

- brick wall
- wooden surface
- wet reflective surface
- mirror surface
- glass surface
- prism object

Acceptance criteria:

- each surface behaves consistently
- flashlight illumination looks natural
- laser reflections are readable
- mirror reflections are precise
- glass transmission works
- dead/alive blending looks smooth

---

# Development Rule

Do not add new gameplay systems until light interaction behaves correctly.

Light behavior is the foundation of Lantern Engine.

All other gameplay systems depend on it.