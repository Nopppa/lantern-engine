# Lantern Engine – Scene-First Migration Plan

**Date:** 2026-03-12  
**Status:** Authoritative architecture reference – supersedes prior scene-first notes  
**Applies to:** All feature work from this date forward  
**Worldgen truth source:** `TRUTH.md` is the controlling source for world generation architecture. Any worldgen guidance here must be interpreted through `TRUTH.md`, and conflicting older material is obsolete.  

---

## 0. Why This Document Exists

Lantern Engine has been confirmed to need a migration from a **script-first** architecture (41 scripts, 4 stub scenes) toward a **scene-first** architecture that matches Godot 4's core design philosophy. This document locks in the rules, structure, and phasing, with explicit constraints from the project owner baked in.

Read this before touching any scene or script work.

---

## 1. Core Rules

These rules are non-negotiable. Follow them for all new work and apply them incrementally to existing code.

### 1.1 Scene-First Default

> **If it is visible, instantiable, or editor-meaningful → it must be a scene.**

Scenes are required for:
- Gameplay entities (player, enemies, interactables)
- World objects (trees, houses, roads, prisms, light beams)
- UI elements (HUD, menus, overlays, reward panels)
- Level/world roots (mode scenes, exploration scene)
- Reusable components (flashlight, health bar, collision shapes)

### 1.2 Script/System Exceptions

Scripts remain scripts when they are:
- Pure data definitions (resource `.gd` files, JSON-adjacent)
- Stateless utility/helper functions
- Autoload managers (global singletons)
- Solver/generation/calculation logic with no visual footprint
- One-time bootstrap logic with no spatial presence

### 1.3 No Stub Scenes

**Do not create a bare host scene and defer content.** Every scene must represent its intended content at the time of creation — even if that content starts minimal and grows incrementally. A scene exists to convey structure, hierarchy, and composition. A node with nothing in it is not a scene; it is a script wearing a hat.

This rule is **most critical for the Exploration World** (see Section 6).

### 1.4 Composition Over Script Spawning

Build hierarchies in the editor, not in `_ready()`. If code is creating nodes manually, that is a smell — extract those nodes into child scenes and instance them. Scripts should orchestrate, not construct.

### 1.5 Single Responsibility

Each scene has one clear purpose. If a scene's root script exceeds ~300 lines, it is probably doing too much. Split responsibilities into component scenes.

---

## 2. Target Folder Structure

```
res://
├── scenes/
│   ├── main/
│   │   ├── main.tscn                        # Entry + scene routing
│   │   ├── main.gd                          # Minimal bootstrap
│   │   └── main_menu.tscn                   # Menu UI
│   │
│   ├── gameplay/
│   │   ├── run_scene.tscn                   # Run mode root (composed)
│   │   ├── run_scene.gd                     # Orchestrator (~150 lines)
│   │   ├── light_lab_scene.tscn             # Light Lab root (composed)
│   │   ├── light_lab_scene.gd               # Orchestrator (~200 lines)
│   │   └── exploration_scene.tscn           # Exploration World root
│   │       ├── (see Section 6)
│   │
│   ├── player/
│   │   ├── player.tscn                      # Player entity
│   │   ├── player.gd
│   │   └── flashlight/
│   │       ├── flashlight.tscn              # Flashlight component
│   │       └── flashlight.gd
│   │
│   ├── enemies/
│   │   ├── moth/
│   │   │   ├── moth_enemy.tscn
│   │   │   └── moth_enemy.gd
│   │   └── hollow/
│   │       ├── hollow_enemy.tscn
│   │       └── hollow_enemy.gd
│   │
│   ├── world/
│   │   ├── exploration/                     # Exploration-world building blocks
│   │   │   ├── terrain/
│   │   │   │   ├── meadow_ground.tscn       # Open grass/field ground tile
│   │   │   │   ├── forest_floor.tscn        # Forest understory ground
│   │   │   │   └── road_section.tscn        # Dirt/stone road segment
│   │   │   ├── vegetation/
│   │   │   │   ├── tree_broadleaf.tscn      # Standard tree (occluder)
│   │   │   │   ├── tree_conifer.tscn
│   │   │   │   ├── shrub.tscn
│   │   │   │   └── tall_grass_patch.tscn
│   │   │   ├── structures/
│   │   │   │   ├── house_small.tscn         # Simple rural house
│   │   │   │   ├── house_large.tscn
│   │   │   │   ├── barn.tscn
│   │   │   │   ├── stone_wall_section.tscn  # Field boundary walls
│   │   │   │   └── fence_section.tscn
│   │   │   └── landmarks/
│   │   │       ├── well.tscn
│   │   │       ├── signpost.tscn
│   │   │       └── campfire.tscn
│   │   └── shared/
│   │       ├── prism_station.tscn           # Prism/light source station
│   │       └── light_beam.tscn             # Beam visual effect
│   │
│   ├── gameplay_objects/
│   │   └── (prism, beams, interactables)
│   │
│   └── ui/
│       ├── hud/
│       │   ├── game_hud.tscn
│       │   ├── health_bar.tscn
│       │   └── energy_bar.tscn
│       ├── pause_menu/
│       │   └── pause_menu.tscn
│       ├── reward_panel/
│       │   └── reward_panel.tscn
│       └── exploration_overlay/
│           └── exploration_overlay.tscn
│
├── scripts/
│   ├── autoload/                            # Global singletons
│   │   ├── game_manager.gd
│   │   ├── sfx_manager.gd
│   │   └── light_manager.gd
│   │
│   ├── data/                                # Data-only (unchanged)
│   │   ├── boss_defs.gd
│   │   ├── encounter_defs.gd
│   │   ├── skill_defs.gd
│   │   └── upgrade_defs.gd
│   │
│   ├── systems/                             # Gameplay systems (stateless)
│   │   ├── beam_resolver.gd
│   │   ├── light_query.gd
│   │   └── reward_system.gd
│   │
│   ├── light_engine/                        # Lighting pipeline (unchanged)
│   │   ├── light_world.gd
│   │   ├── light_field.gd
│   │   ├── light_types.gd
│   │   ├── light_world_builder.gd
│   │   ├── light_approximation.gd
│   │   ├── light_surface_resolver.gd
│   │   └── native_light_presentation.gd
│   │
│   └── world/                               # World generation (unchanged)
│       ├── world_layout_provider.gd
│       └── generated_exploration_provider.gd
│
└── data/                                    # Non-code assets, JSON, resources
    ├── bosses/
    └── ...
```

---

## 3. What Stays Script / System / Data-Only

The following are **explicitly not scenes** and must remain as scripts or data:

| Category | Examples | Reason |
|---|---|---|
| Lighting pipeline | `LightWorld`, `LightField`, `LightWorldBuilder`, `LightApproximation`, solvers | Pure computation, no visual footprint |
| World generation | `GeneratedExplorationProvider`, `WorldLayoutProvider`, layout algorithms | Data output, not spatial |
| Material definitions | `MaterialResponse`, material type enums, patch defs | Data-only |
| Beam/light solvers | `BeamResolver`, `LightQuery`, `LightSurfaceResolver` | Stateless computation |
| Data definitions | `boss_defs.gd`, `encounter_defs.gd`, skill/upgrade JSON | Pure data |
| Autoload managers | `SfxManager`, `GameManager`, `LightManager` | Global singleton pattern |

**Rule:** If you can run it as a unit test with no scene tree, it stays a script.

---

## 4. RandomGEN Contract

### 4.1 Responsibility Boundary

RandomGEN (the `GeneratedExplorationProvider` + `WorldLayoutProvider` + `LightWorldBuilder` pipeline) is a **data producer**. Its contract:

**Inputs:**
- Seed (`int`)
- World configuration (size, zone count, density parameters, theme hints)
- Arena rect (`Rect2`)

**Outputs:**
- `LightWorld` — the gameplay-light truth structure
- `layout` — a Dictionary describing:
  - Occluder segments (walls, structure outlines, tree trunks)
  - Material patches (ground type, zone type)
  - Prism station positions and initial state
  - Entity spawn points (player start, enemy zones)
  - Navigation metadata (road graph, open field zones)
  - Zone metadata (meadow / forest / settlement / road tags)
  - World signature (seed + config hash, for caching/debugging)

**Does NOT produce:**
- Visual nodes
- Scene instances
- Any Godot Node

### 4.2 Consumer Contract (ExplorationScene)

`exploration_scene.gd` (the runtime adapter) consumes RandomGEN output and:
1. Calls `LightWorldBuilder.build_light_world(layout, arena_rect, options)` → gets `LightWorld`
2. Initializes `LightField` from `LightWorld`
3. Reads layout entity list and instances appropriate **scene files** (e.g. `tree_broadleaf.tscn`, `house_small.tscn`, `prism_station.tscn`)
4. Places player at layout-specified spawn point
5. Registers generated occluders with the lighting pipeline
6. Hands off to the shared lighting/gameplay runtime

### 4.3 Compatibility Guarantees

- RandomGEN scripts (`generated_exploration_provider.gd`, `world_layout_provider.gd`) are **not modified** during the scene-first migration
- `LightWorldBuilder` is **not modified** during migration
- Same seed must produce same layout before and after any scene-first refactor
- Scene-first migration only changes what `ExplorationScene` does with the layout output — not how layout is generated

### 4.4 Extension Points

New world entity types can be added to RandomGEN output by:
1. Adding a new entity type tag to the layout Dictionary (e.g. `"well"`, `"barn"`)
2. Creating a corresponding scene file in `scenes/world/exploration/`
3. Adding a mapping entry in `exploration_scene.gd`'s entity instantiation table

No changes to the solver, LightWorld, or LightField are required for new entity types unless they affect occlusion (in which case they register occluder segments normally).

---

## 5. Exploration World Constraint – Natural Inhabited World

### 5.1 What the Exploration World Is

The Lantern Engine exploration world is a **natural, human-inhabited landscape**. Think:

- Open meadows with tall grass
- Cultivated fields and crop rows
- Patches of deciduous and coniferous forest
- Dirt roads and stone paths connecting areas
- Farmhouses, barns, cottages
- Villages and small towns
- Stone walls and wooden fences marking field boundaries
- Wells, signposts, campsites, ruins
- Rivers, ponds, clearings

This world **feels lived-in and traversable**, not engineered or underground.

### 5.2 What the Exploration World Is NOT

The exploration world must **never** be designed or implemented as:

- A corridor dungeon
- A cave labyrinth or cave system
- A tile-based maze with narrow passages
- A procedural grid of rooms connected by hallways
- An enclosed underground space
- A "cave crawler" in any sense

If a layout algorithm, scene, or asset implies dungeon/cave aesthetics, it is wrong for this mode. Fix it.

### 5.3 No Stub Exploration Scenes

**This constraint is binding:** When work begins on `exploration_scene.tscn`, it must be a **real, substantive scene** from the first commit — not a placeholder. This means:

- The scene root should reflect actual world composition structure
- At least the ground/terrain layer must be represented with real scene nodes
- World object placement (trees, roads, structures) must have real scene instances, even if the set is small
- No "TODO: add content here" nodes

Incremental growth is fine. Incremental *emptiness* is not.

### 5.4 World Zones (for RandomGEN and Scene Design)

The layout system should be able to tag zones with these types, and scene selection should respect them:

| Zone Tag | Ground | Vegetation | Structures | Roads |
|---|---|---|---|---|
| `meadow` | Open grass | Scattered shrubs | None | Rare paths |
| `field` | Cultivated soil | Crop rows | Fence sections | Field tracks |
| `forest` | Forest floor | Dense trees, shrubs | None / ruins | None |
| `settlement` | Packed earth, stone | Garden plants | Houses, barns, wells | Stone/dirt roads |
| `road` | Road surface | Verge grass | Signposts, fences | Main road |

---

## 6. Exploration Scene – Target Composition

When `exploration_scene.tscn` is built, its node hierarchy must reflect real world structure:

```
ExplorationScene (Node2D)
├── World (Node2D)                   # Scene-based world content root
│   ├── TerrainLayer (Node2D)        # Ground tiles (meadow, forest, road)
│   ├── VegetationLayer (Node2D)     # Trees, shrubs (occluders)
│   ├── StructureLayer (Node2D)      # Houses, barns, walls, fences
│   ├── ProceduralEntities (Node2D)  # Runtime-spawned instances from layout
│   └── PrismStations (Node2D)       # Prism station instances
│
├── Player (Node2D)                  # scene instance: player.tscn
│   └── Flashlight                   # scene instance: flashlight.tscn
│
├── Enemies (Node2D)                 # Runtime-spawned enemy instances
│
├── LightRuntime (Node2D)            # LightField + NativeLightPresentation
│
└── UI (CanvasLayer)                 # scene instance: exploration_overlay.tscn
```

The `World/ProceduralEntities` container is populated at runtime by `exploration_scene.gd` from the RandomGEN layout. Static/authored world content (background terrain, ambient structures) can live in the scene directly.

---

## 7. Migration Phases

### Phase 0 – Rules Adoption (Immediate)

**Goal:** No new script-only entities or stub scenes after this date.  
**Actions:**
- All new gameplay entities created as scenes from the start
- Any new world objects (trees, houses, prisms) → scene files in `scenes/world/`
- This document is the authority; update it when rules need to evolve

**Checklist:**
- [x] Publish `docs/scene-first-migration-plan.md`
- [ ] Team/collaborators read and acknowledge this document
- [ ] No new script-spawned entity nodes added without a corresponding scene file

### Phase 1 – Foundation Scenes (Weeks 1–2)

**Goal:** Core entity scenes that unblock all subsequent work.

**Deliverables:**
- `scenes/player/player.tscn` — player entity with collision, camera anchor
- `scenes/player/flashlight/flashlight.tscn` — flashlight component
- `scenes/ui/hud/game_hud.tscn` — HUD with health/energy bars in editor
- `scenes/world/shared/prism_station.tscn` — prism station with shape and label

**Strategy:**
- Build scenes in parallel with existing scripts
- Switch gameplay modes to use scene-based player once validated
- Keep old script spawn paths active until scene version is confirmed stable

**Validation:**
- Light Lab playable with scene-based player
- No lighting pipeline regressions
- Same visual output as before

### Phase 1E – Earliest Exploration Implications

**Goal:** Ensure exploration direction is established correctly before it grows further.

This sub-phase runs in parallel with Phase 1 and focuses only on establishing the correct *shape* of the exploration world, even if content is minimal.

**Deliverables:**
- `scenes/world/exploration/terrain/meadow_ground.tscn` — basic open ground
- `scenes/world/exploration/vegetation/tree_broadleaf.tscn` — broadleaf tree (occluder capable)
- `scenes/world/exploration/structures/house_small.tscn` — minimal rural house
- `scenes/world/exploration/terrain/road_section.tscn` — dirt road segment
- `exploration_scene.tscn` scaffold with correct composition (World / Player / LightRuntime / UI nodes)

**Constraints enforced here:**
- Scene content must feel like a natural world, not a dungeon
- No corridor-shaped terrain or cave-style occlusion arrangements
- At least two zone types (meadow + settlement or meadow + forest) must be representable before Phase 2 begins

**Validation:**
- `exploration_scene.tscn` opens in Godot editor and shows a real world composition
- Tree occluder registers correctly with the lighting pipeline
- Player can spawn and move in an open meadow area

### Phase 2 – Gameplay Entities (Weeks 3–4)

**Goal:** All gameplay objects become scene instances.

**Deliverables:**
- `scenes/enemies/moth/moth_enemy.tscn`
- `scenes/enemies/hollow/hollow_enemy.tscn`
- `scenes/world/shared/light_beam.tscn`
- Additional exploration world building blocks (forest floor, barn, fence, stone wall)

**Strategy:**
- One entity type at a time
- Keep `EncounterController` working with both script and scene enemies during transition
- Feature-flag toggle for scene vs. script spawning if needed

### Phase 3 – UI Scenes (Week 5)

**Goal:** All UI is scene-based, none procedurally constructed.

**Deliverables:**
- `scenes/ui/pause_menu/pause_menu.tscn`
- `scenes/ui/reward_panel/reward_panel.tscn`
- `scenes/ui/exploration_overlay/exploration_overlay.tscn`
- All modes updated to instance these UI scenes

### Phase 4 – Orchestrator Refactor (Week 6)

**Goal:** Mode scene scripts become thin orchestrators, not god objects.

**Deliverables:**
- `light_lab_scene.gd` reduced from 1258 lines → ~300 lines
- `run_scene.gd` reduced from 771 lines → ~200 lines
- `exploration_scene.gd` ← real scene composition, not a stub
- All three mode `.tscn` files show full node hierarchy in editor

### Phase 5 – Autoloads & Cleanup (Week 7)

**Goal:** Formalize global systems, remove circular dependencies.

**Deliverables:**
- `scripts/autoload/sfx_manager.gd` (migrated from `SfxController`)
- `scripts/autoload/light_manager.gd`
- `project.godot` autoload registrations updated
- Redundant script spawn paths removed

---

## 8. Risks and Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Breaking lighting pipeline | High | Never touch `scripts/light_engine/`. Pipeline is data-driven and scene-agnostic. |
| RandomGEN incompatibility | High | Data contract preserved (see Section 4). Scene migration only changes the consumer side. |
| Exploration drifting toward dungeon/cave aesthetics | High | All exploration scenes reviewed against Section 5 before merge. |
| Stub exploration scene being committed | High | Phase 1E is mandatory — real content at first commit. |
| Performance regression from scene instancing | Medium | Profile before/after. Pool frequently-spawned scenes. |
| Merge conflicts in `.tscn` files | Medium | Small focused scenes, use `%NodeName` unique references. |

---

## 9. Reference: What Changed from Previous Docs

This document supersedes and consolidates:
- `docs/architecture-scene-first-refactor-plan.md` — previous scene-first notes (still valid as background)
- Inline world-direction notes scattered across various docs

**Key additions / changes in this document:**
1. Explicit natural-world constraint for exploration (Section 5) — not in prior docs
2. No-stub enforcement (Section 1.3 and 5.3)
3. Phase 1E (exploration implications) — new phase to prevent exploration from drifting
4. RandomGEN contract formalized as a section (Section 4)
5. Exploration scene target composition specified (Section 6)
6. World zone tags defined for RandomGEN ↔ scene mapping

---

## 10. Document Maintenance

This document is a living reference. Update it when:
- A new scene category is established
- RandomGEN contract changes
- Phase timelines shift
- New world zone types are added

Keep it in `docs/scene-first-migration-plan.md`. Reference it in PRs that touch scene architecture.

---

*End of document.*
