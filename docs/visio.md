# Lantern Engine – Vision and Core Concept

## Overview

Lantern Engine is a top-down exploration roguelike set in a world destroyed by darkness.

The player carries a lantern / flashlight which is the central gameplay mechanic.

The lantern is not only a weapon but also a tool that restores the world and interacts with the environment.

The entire design philosophy of the game revolves around one core theme:

LIGHT VS DARKNESS

Darkness corrupted the world.
Light restores it.

---

# Core Gameplay Loop

1. Player explores a procedurally generated world.
2. The world initially exists mostly in a DEAD state.
3. The player's lantern illuminates the environment.
4. Light slows enemies and weakens darkness creatures.
5. The player fights enemies using light-based tools.
6. The player encounters bosses.
7. Defeating bosses restores parts of the world permanently.
8. The world gradually transitions from DEAD to ALIVE.

---

# World State Concept

The world exists in two main states.

DEAD  
ALIVE

## Dead State

Characteristics:

- grey / desaturated colors
- dead vegetation
- broken structures
- oppressive atmosphere

## Alive State

Characteristics:

- vegetation grows
- colors return
- structures appear restored
- environment feels safer

---

# Temporary Light Restoration

The lantern temporarily restores life visually.

When the beam hits a surface:

- dead tiles blend toward alive tiles
- vegetation briefly appears
- colors return

When the light leaves:

- the tile fades back to dead
- unless the area has been permanently restored

---

# Permanent World Restoration

Permanent restoration occurs through major events.

Examples:

- defeating bosses
- cleansing corruption nodes
- activating restoration points

When a region is restored:

- tiles switch permanently to ALIVE
- environment becomes visually greener
- enemy density may decrease
- exploration becomes safer

---

# Light as Core Gameplay System

Light is used for multiple gameplay functions:

- exploration
- enemy control
- environmental interaction
- puzzle solving
- combat

The player can use:

- flashlight cone
- focused beam / laser
- prisms
- reflective surfaces

---

# Light and Enemy Interaction

Darkness creatures react strongly to light.

Example behaviors:

- movement slowed in light
- teleportation delayed
- special abilities interrupted

Teleport enemies example:

Normal behavior:
instant teleport

In light:
teleport becomes visible phased movement
enemy travels between points instead of instant jump

This gives the player time to react.

---

# Prism Mechanics

Prisms are interactive objects that modify light behavior.

Player actions:

- place prism
- carry prism
- throw prism
- detonate prism

Prisms can:

- redirect beams
- split beams
- amplify beams
- create light bursts

Prism explosions can:

- burn enemies
- apply debuffs
- produce temporary illumination

---

# Boss Design Philosophy

Bosses represent anchors of darkness.

Defeating a boss should:

- permanently restore a region
- visibly transform the environment
- provide emotional progress for the player

Bosses are generated using templates with randomized traits to create variation between runs.

---

# Procedural World Philosophy

The world is continuous and procedurally generated.

Generation layers include:

- biome layout
- terrain layout
- structures and ruins
- interior spaces
- enemy spawn regions
- boss regions

Procedural generation should combine:

designed pieces + procedural placement

not pure random noise.

---

# Core Design Rule

Everything in Lantern Engine must relate to light.

Gameplay systems should revolve around:

- illumination
- reflection
- diffusion
- refraction
- restoration
- growth

Mechanics unrelated to light should be avoided.

---

# Visual Identity

Darkness removes color.

Light restores color.

Dead tiles are desaturated.

Alive tiles are fully colored.

Temporary illumination creates smooth blending between the two states.

---

# Design Goal

Create a game where the player gradually transforms a dead world into a living one using light.