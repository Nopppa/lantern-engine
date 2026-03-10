# Lantern Engine — Light Lab Pivot

Godot 4 prototype now centered on a permanent **Light Lab** instead of treating the old wave-survival arena as the main game direction. `v0.5.4` keeps the lab as default runtime and shifts the light presentation toward cheaper approximation tiers while preserving material/obstacle truth.

## Current primary runtime

The project now boots straight into the **Light Lab**:

- permanent authored lab map
- no auto-wave flow
- no forced encounter completion state
- manual debug spawning for validation
- surface/material response testing first
- flashlight + beam readability first
- dead/alive blend prototyping first

The older wave-survival run still exists in the repo as temporary legacy scaffolding (`scenes/run_scene.tscn`, `scripts/run_scene.gd`, encounter data, reward flow), but it is no longer the primary target or default scene flow.

## Light Lab content shipped in v0.5.4

- surrounding outer walls
- several internal wall segments for routing / occlusion tests
- authored material bays for:
  - brick
  - wood
  - wet stone / wet surface
  - mirror
  - glass
  - prism routing station
- dead/alive blend test zones
- open validation deck for manual spawn tests
- manual Prism Node placement plus fixed prism station routing
- authored in-world signage cards + one-line hints for every comparison bay/lane/station/deck
- layered beam path labels and clearer bounce / redirect / secondary-light overlays for faster testing

## Light behavior shipped now

### Surface material first pass

Readable gameplay-first differences are now authored for:

- **Brick** — absorbs heavily
- **Wood** — soft diffusion, limited reflection
- **Wet stone** — noticeably more reflective than brick/wood, slightly rough
- **Mirror** — clear strong reflection
- **Glass** — partial transmission plus a weaker reflected branch
- **Prism** — special gameplay redirect interaction

### Unified light/material response

Laser, flashlight, and prism light now all participate in one shared material-response architecture:

- one shared material truth: reflectivity / diffusion / transmission / absorption
- laser still remains the most precise branch-casting source
- flashlight now drives soft surface reactions instead of only drawing a cone
- prism light now also excites nearby authored surfaces instead of behaving like a detached aura only
- mirror / glass / brick / wood / wet surfaces now produce visibly different secondary response from all meaningful light sources

### Flashlight validation

The flashlight now behaves as a proper gameplay light query in the lab and its rendered trace matches that truth much more closely:

- cone-based with a slightly wider 34° half-angle
- distance falloff with brighter center / softer edge
- player-facing flashlight now renders as a unified smoothed beam fill driven by a smaller set of guide rays
- guide rays still preserve blocker/material truth, but no longer dominate the image as comb-like stripes
- hard visible blocking on brick walls and tree trunks
- visible reflected / scattered / transmitted flashlight branches on nearby surfaces
- glass pass-through now shows slight bend + intensity loss
- wood now shows broader scatter instead of a too-clean reflection
- wet stone now shows glossy disturbance / partial reflection
- wood floor lanes now pick up subtle widened glow when light travels across them
- queryable local intensity still drives gameplay checks and blend response
- approximation work now refreshes on a short budgeted cadence instead of rebuilding every surface response every frame

### Dead/alive blend prototype

The lab floor now uses a temporary rendering-side dead/alive blend grid:

- illuminated cells blend toward **ALIVE**
- cells fade back toward **DEAD** when light leaves
- authored base-alive zones remain restored
- no destructive pixel rewriting

## Controls

### Core

- `WASD` move
- `LMB` cast validation beam
- `RMB` place Prism Node
- `Q` trigger Prism Surge from active node
- `F` toggle flashlight
- `R` reset lab
- `F1` hide/show all overlays
- `F2` refill HP + Energy
- `F4` toggle immortality

Movement notes:

- walls are now solid for player / enemies / miniboss movement in the Light Lab
- tree trunks are now also solid blockers in the validation space
- shallow water lane now causes a clearly noticeable slowdown
- deep water lane now causes a much heavier slowdown for immediate comparison

### Manual debug spawn / probes

- `1` spawn Moth at cursor
- `2` spawn Hollow at cursor
- `3` spawn Hollow Matriarch at cursor
- `4` place Prism Node at cursor
- `5` toggle cursor material/intensity probe
- `6` toggle beam-hit debug markers
- `7` toggle enemy HP labels
- `8` toggle dead/alive base-state setup

## Run locally

### Open in Godot editor

```bash
godot --path /opt/openclaw/projects/lantern_engine
```

### Headless validation

```bash
godot --headless --path /opt/openclaw/projects/lantern_engine --quit
```

## Build artifacts

Current project version is `v0.5.4` (see `VERSION`). Local export outputs and release archives are:

- Windows export output: `build/windows/lantern_engine.exe`
- Windows data pack: `build/windows/lantern_engine.pck`
- Windows release archive: `build/windows/lantern_engine-windows-v0.5.4.zip`

Windows builds are the default tester artifacts. Linux builds are not produced unless explicitly requested.

## Repo docs

- `docs/visio.md`
- `docs/ohjeet.md`
- `docs/light_engine.md`
- `docs/milestones.md`
- `docs/roadmap/current-state.md`
- `docs/code-map.md`
- `docs/devlog.md`
- `docs/light_lab_runtime_boundary.md`
- `CHANGELOG.md`
