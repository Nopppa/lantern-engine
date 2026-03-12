# RandomGEN Layout V2 Notes

This note captures the next intended direction for RandomGEN world generation.

## Core shift

Move away from a simple random arena scatter toward a **graph-based procedural layout**.

## 1. Graph-based layout topology

Instead of placing rooms fully randomly, v2 should use a **node-and-connection** model.

### Node types

- **Spawn node**
  - always calm
  - some light
  - minimal/no blockers
  - safe orientation zone

- **3–7 zone nodes**
  - rooms or exploration regions
  - varying size: small / medium / large

- **Connector nodes**
  - corridors, openings, doorways, transitions
  - ensure reachability between zones

- **Depth / exit node**
  - one node gets status like `Exit` / `Gate`
  - should suggest deeper progression
  - may require a light puzzle or setup to pass

## 2. Material and light-zone logic

The generator should deliberately paint regions with materials that matter to beam/light behavior.

### Suggested zone archetypes

- **Mirror zone**
  - many reflective surfaces
  - tests chained reflection behavior

- **Glass zone**
  - transparent blockers
  - light passes, player does not

- **Wet stone / wood zone**
  - more diffuse / absorptive surfaces
  - dampens or weakly reflects beam
  - useful for mood and soft gating

## 3. Procedural placement of interaction points

Interaction points should not be random clutter. They should be placed according to the node/zone role.

### Placement rules

- **Prisms**
  - corners or room-center placements
  - should split or redirect beam into side paths/corridors

- **Blockers**
  - intentionally placed on routes
  - should create “open this by solving light routing” moments

## V2 generator workflow

### 1. Seed & Graph
Generate nodes and links first.

**Goal:** all rooms/areas remain reachable.

### 2. Room Carving
Turn the abstract graph into physical rooms/corridors/openings.

**Goal:** convert topology into explorable geometry.

### 3. Material Pass
Assign materials to regions/zones.

**Goal:** visual and mechanical variation.

### 4. Puzzle Injection
Place light-relevant interaction points: sources, prisms, blockers, gates.

**Goal:** create localized gameplay intent inside the generated layout.

## Why this matters now

This v2 step is important before larger persistence/streaming work because it teaches how the beam/light systems interact with generated space.

If generation creates only mirrors, the beam may bounce too freely.
If it creates only dull absorptive zones, the game becomes flat.

V2 should be the first pass that finds a useful balance between:
- layout readability
- beam/mechanics readability
- generated exploration interest
- future progression structure

## Scope warning

This note does **not** imply full chunk streaming, save/load, or infinite-world generation yet.
It is a middle step: a stronger procedural layout model inside the current exploration runtime.
