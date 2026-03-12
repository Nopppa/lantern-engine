# Exploration World Generation – Biome Architecture Guidelines

> **Partially obsolete unless aligned with `TRUTH.md`.** This document may still contain useful biome-direction ideas, but `TRUTH.md` now defines the non-negotiable worldgen architecture. Any conflicting assumptions about layering, ownership, or build/runtime structure are obsolete.

## Purpose

This document defines the **new architectural direction for exploration world generation**.  
It replaces the previous **material-themed layout system** with a **biome-driven world model**.

The goal is to move the exploration mode away from **technical test arenas** and toward **believable places** that still support the light engine and puzzle mechanics.

This document is authoritative for all agents working on:

- world generation
- exploration runtime
- layout providers
- exploration scene rendering
- gameplay environment design

Lighting logic, physics, and Light Lab remain **unchanged**.

---

# Core Design Principle

Exploration worlds are no longer defined by **materials**.

They are defined by **biomes**.

Materials are still used internally for the **light engine**, but they no longer define the identity of an area.

Old model:


mirror zone
glass zone
wet zone
wood zone


New model:


forest
→ meadow
→ street
→ housing
→ industrial


This shift is critical to make the world feel like **a place rather than a laboratory**.

---

# World Generation Architecture

The generation pipeline remains the same.


GeneratedExplorationProvider
↓
LightWorldBuilder
↓
LightWorld
↓
ExplorationScene runtime


### Important rule

The **ExplorationScene never constructs world data directly**.

All world data must come from:


GeneratedExplorationProvider


---

# Layout Model

Exploration worlds use a **graph-based layout**.


spawn
│
├─ zone
│
├─ zone
│
├─ zone
│
└─ progression (exit)


Each node represents a **biome zone**.

Each link represents a **corridor route** between zones.

---

# Biome Types

Current biome set:


forest
meadow
street
housing
industrial


These represent **environment identity**, not materials.

Each biome controls:

- geometry decoration
- obstacle placement
- vegetation / structures
- material distribution
- prism placement style

Example mapping:

| Biome | Materials Used |
|------|------|
| forest | wet, wood |
| meadow | wood, wet |
| street | brick, wet |
| housing | brick, wood, glass |
| industrial | brick, glass, mirror |

Materials are **implementation details**, not gameplay identity.

---

# Biome Responsibilities

Biome decorators are responsible for generating:


patches
segments
tree_trunks
prism_stations
dead_alive_cells


These must remain compatible with the **LightWorld pipeline**.

Biome decorators must **never modify LightWorldBuilder behavior**.

---

# Light Engine Compatibility

The lighting system continues to rely on:


occluder_segments
material_patches
light_entities
dead_alive_cells


These must still follow the existing structure used by:


LightWorldBuilder
ExplorationLightRuntime
NativeLightPresentation


Exploration mode **must not alter lighting architecture**.

---

# GeneratedExplorationProvider Rules

The provider is responsible for:

1. generating the world graph
2. assigning biome types
3. placing zones
4. decorating zones
5. compiling the layout dictionary

Required output keys:


segments
patches
prism_stations
tree_trunks
dead_alive_cells
layout_nodes
layout_links
zone_summaries
spawn_hint
generated_seed


---

# Layout Metadata

Exploration worlds expose metadata for debugging and visualization.

Example metadata:


layout_nodes
layout_links
zone_summaries
graph_depth
spawn_node_id
progression_node_id
generated_seed


Agents must preserve this metadata when modifying world generation.

---

# ExplorationScene Responsibilities

The scene runtime must:

- load world from provider
- initialize runtime systems
- render debug geometry
- render biome zones
- render material patches
- render occluders
- render entities
- render player

It **must not**:

- generate world geometry
- modify LightWorld data
- introduce new lighting rules

---

# Rendering Guidelines

Rendering exists for **debugging and readability**, not final art.

ExplorationScene may render:

### biome tint overlays

Example:


forest → green tint
meadow → light green
street → grey
housing → brown
industrial → steel blue


These overlays are **visualization only**.

They do not affect gameplay.

---

# Player and Runtime Systems

The exploration runtime is composed of:


ExplorationPlayerController
ExplorationLightRuntime
NativeLightPresentation
ExplorationOverlayUi


These systems must remain **loosely coupled**.

The scene orchestrates them but does not implement their logic.

---

# World Seed Behavior

Exploration worlds are deterministic.


seed → identical world


Changing the seed produces a new biome layout.


R → next seed
T → random seed


The seed must always be stored in metadata.

---

# Spawn Philosophy

The spawn location must always be:

- calm
- readable
- safe
- visually distinct

Typical spawn biome:


meadow


Spawn areas may contain:


soft occluders
guide prism
low obstacle density


---

# Exit / Progression Zone

The final node in the graph is a **progression zone**.

It should:

- visually feel different
- contain stronger gating geometry
- guide the player toward the exit

Example mechanics:


glass gate
mirror redirect
prism alignment


---

# Agent Design Constraints

Agents modifying exploration code must obey the following:

### Do not modify


LightWorldBuilder
Light Lab
lighting physics
material semantics


### Only modify


GeneratedExplorationProvider
biome decorators
ExplorationScene visualization


---

# Future Expansion

Possible biome additions:


ruins
suburbs
canal
harbor
rail yard
graveyard
cathedral district


These should be implemented as **biome decorators**, not new world systems.

---

# Summary

The exploration world now follows this model:


Biome World
↓
Graph Layout
↓
Zone Decoration
↓
Material Distribution
↓
LightWorld
↓
ExplorationScene


This architecture keeps the **light engine stable** while allowing the world to feel **alive and believable**.

Agents should prioritize:


clarity
determinism
world readability
biome identity


over material experimentation.
