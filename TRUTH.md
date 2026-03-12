# TRUTH.md

**Lantern Engine — World Generation Architecture Truth**

This file is the non-negotiable architecture truth for world generation and exploration-world structure.

If any older note, roadmap, architecture doc, or implementation idea conflicts with this file, that older material is **obsolete**.

---

## 1. Exploration World Truth

The exploration world is **not**:
- a corridor dungeon
- a cave labyrinth
- a room-and-hallway procedural map
- a narrow maze-like traversal space

The exploration world **is**:
- a natural inhabited world
- meadows
- fields
- forests
- roads and paths
- houses
- villages, towns, and city edges
- landmarks in a human-settled landscape

Any exploration/worldgen architecture that assumes dungeon-first or corridor-first layout is obsolete for Lantern Engine exploration mode.

---

## 2. Core Worldgen Architecture Truth

Do **not** build a single `world.gd` god script that generates everything directly into runtime.

World generation must be split into three layers:

### A. World Plan
An abstract plan of the world.

Examples:
- biome map
- region cells
- road paths
- settlement sites
- landmark sites
- vegetation zones
- prop sites
- influence fields / macro maps

### B. World Build
A builder turns the plan into actual Godot world content.

Examples:
- TileMaps / TileMap layers
- instanced scenes
- chunk content
- placed landmarks / props / structures

### C. World Runtime
The finished world runs as a normal Godot world.

Examples:
- player traversal
- lighting runtime
- enemy runtime
- interaction logic
- gameplay state changes

**Canonical rule:**
> First generate the world as a plan, then build the Godot world from that plan, then run it as gameplay.

---

## 3. Responsibility Boundaries

### Data
`data/` defines what can be generated.

Examples:
- biome profiles
- landmark profiles
- settlement profiles
- generation profiles
- tileset configuration

### Generators
Generators decide where and why things appear.

Examples:
- macro map generation
- biome assignment
- road network generation
- settlement placement
- landmark placement
- vegetation/detail placement

Generators write to a **WorldPlan**-style structure.

### Builders
Builders turn the plan into Godot content.

Examples:
- terrain TileMap building
- road layer building
- scene instancing for houses, bridges, wells, churches, ruins, tree clusters
- chunk assembly

### Runtime
Runtime operates on the built world.

Examples:
- player and enemy logic
- light field / beam runtime
- interactables
- dynamic state changes

### Debug
Debug layers must visibly explain why the generated world looks the way it does.

Examples:
- biome overlays
- road graph overlays
- settlement influence overlays
- landmark placement explanation
- chunk boundary overlays

Debug is not optional. A worldgen system without debug visibility is incomplete.

---

## 4. Scene-First Rule for World Content

Visible, instantiable, editor-meaningful world things should usually be scenes.

### Good candidates for scene instancing
- churches
- bridges
- houses
- barns
- wells
- graveyards
- cabins
- tree clusters
- rock clusters
- field props
- signposts
- fence segments
- major landmarks

### Good candidates for TileMap / layered terrain
- base ground
- biome surface treatment
- roads/path surfaces
- fields
- swamp surface

### Good candidates for pure plan/data only
- moisture map
- height map
- traversability map
- region graph
- influence fields
- placement candidate lists
- intermediate generation results

Do not turn everything into nodes. Do not leave visible world structure as invisible script-only runtime if it should be a scene.

---

## 5. Required World Root Shape

The procedural world should converge toward a structure like:

```text
WorldRoot
├── WorldGenerator
├── Terrain
├── Roads
├── Regions
├── Settlements
├── Landmarks
├── Vegetation
├── Props
├── GameplayObjects
└── DebugOverlay
```

This may later be chunked, but the separation of concerns must remain.

---

## 6. Chunking Truth

Chunking is allowed and expected as the world grows, but chunking does not replace the plan/build/runtime separation.

Preferred long-term pattern:

```text
WorldChunk
├── TerrainChunk
├── RoadChunk
├── VegetationChunk
├── PropChunk
├── LandmarkChunk
└── DebugChunkOverlay
```

Early versions may build a smaller world without full streaming, but architecture must not block chunking.

---

## 7. Obsolescence Rule

The following kinds of documents or ideas are obsolete if they conflict with this truth:
- corridor-first exploration generation notes
- dungeon/cave exploration assumptions
- room-and-hallway world structure proposals
- single-script world generation plans that skip the World Plan layer
- any design that hides worldgen reasoning instead of exposing debug layers

If a legacy doc still contains useful local detail, it may remain as background reference only — but its conflicting worldgen architecture is obsolete.

---

## 8. Enforcement

From this point onward:
- new worldgen architecture must follow this file
- conflicting docs should be marked obsolete
- new implementation work should explicitly state whether it belongs to Plan, Build, Runtime, or Debug

If unsure, default to:
1. plan first
2. build second
3. runtime third
4. debug visible throughout
