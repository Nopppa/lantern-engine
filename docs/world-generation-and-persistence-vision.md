# Lantern Engine – World Generation and Persistence Vision

## Purpose

This document defines how the game world should be generated, stored, and restored.

The world must feel large and explorable while remaining technically manageable and allowing a clear gameplay progression.

The design goal is **a large procedural world with persistent state**, not an infinite uncontrolled generator.

---

# Core Principle

The world should be **procedurally generated but finite in meaningful gameplay space**.

The player should feel that the world is vast and open, but the game should still provide:

- controlled progression
- meaningful objectives
- a clear endgame

The world should therefore be:

- large procedural world
- chunk streaming
- persistent world state

rather than a truly infinite generator.

---

# World Structure

The world is divided into **chunks / sectors**.

Example conceptual structure:

```text
world
├ chunk_0_0
├ chunk_0_1
├ chunk_1_0
└ chunk_1_1
```

Each chunk contains:

- terrain tiles
- world objects
- environmental sprites
- light restoration state
- spawned structures
- possible encounter locations

Chunks are generated when the player approaches them.

Chunks can be unloaded from memory when far away, but their state must remain saved.

---

# Procedural Generation

The world generation must be **deterministic based on a world seed**.

World generation inputs include:

- world_seed
- biome_noise
- region_rules
- structure_rules

Using the same seed must reproduce the same base terrain layout.

This allows the game to store only changes to the world rather than the entire map.

---

# Persistent World State

The system should store **world changes instead of the entire world**.

Save data should contain:

## World Metadata

- world_seed
- world_version

## Chunk State

For each generated chunk:

- generated flag
- terrain modifications
- restoration state
- destroyed objects
- activated structures

## Light Restoration State

Each tile or region may store a value representing accumulated light energy.

Example concept:

```text
light_energy = 0.0 → dead world
light_energy = 1.0 → fully alive
```

The game must save this value for generated chunks.

---

# World Streaming

Chunks should load and unload dynamically as the player moves.

Conceptual logic:

```text
player moves
→ nearby chunks load or generate
→ distant chunks unload from memory
```

This allows the world to appear large without consuming excessive memory.

Unloaded chunks must retain their saved state.

---

# Player Save Data

The save system must store:

- player_position
- player_stats
- player_build
- inventory
- talents
- unlocked mechanics

When the game loads, the world should reconstruct around the player using:

```text
world_seed + saved chunk states
```

---

# World Progression

The world initially exists in a **dead state**.

The player temporarily restores life using light mechanics.

Permanent restoration occurs through gameplay progression.

Example progression:

```text
explore darkness
→ temporarily restore environment with flashlight
→ defeat area boss
→ activate permanent light artifact
→ region becomes permanently alive
```

Boss artifacts create permanent light sources that maintain restoration in a region.

---

# Finite Progression Area

Although the world generation system may technically support large maps, the gameplay progression should occur within a defined radius from the starting area.

This allows:

- controlled difficulty
- meaningful boss placement
- narrative progression
- a clear endgame objective

Beyond the core progression area, the world may still generate terrain, but it should not contain critical objectives.

---

# Design Goals

The world should feel:

- large
- mysterious
- gradually restored by the player's actions

But the system must remain:

- deterministic
- savable
- memory efficient
- stable across sessions

---

# Key Rule

The game must **never require storing the entire world state**.

Instead it should store:

```text
world_seed + chunk modifications
```

This ensures scalable saves and reliable procedural reconstruction.

---

# Development Priority

Before adding enemies or complex gameplay systems, ensure the following systems function reliably:

1. world seed generation
2. chunk generation
3. chunk save/load
4. player save/load
5. persistent light restoration state
6. dynamic chunk streaming
