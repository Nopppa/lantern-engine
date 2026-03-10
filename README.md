# Lantern Engine — Light Lab Pivot

Godot 4 prototype now centered on a permanent **Light Lab** instead of treating the old wave-survival arena as the main game direction. `v0.5.0` makes the lab the default runtime so light behavior, authored surfaces, and dead/alive blending become the primary validation loop.

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

## Light Lab content shipped in v0.5.0

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

## Light behavior shipped now

### Surface material first pass

Readable gameplay-first differences are now authored for:

- **Brick** — absorbs heavily
- **Wood** — soft diffusion, limited reflection
- **Wet stone** — noticeably more reflective than brick/wood, slightly rough
- **Mirror** — clear strong reflection
- **Glass** — partial transmission plus a weaker reflected branch
- **Prism** — special gameplay redirect interaction

### Flashlight validation

The flashlight now behaves as a proper gameplay light query in the lab:

- cone-based
- distance falloff
- brighter center / softer edge
- queryable local intensity used by gameplay checks and blend response

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
- `F1` help
- `F2` refill HP + Energy
- `F4` toggle immortality

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

Current project version is `v0.5.0` (see `VERSION`). Local export outputs and release archives are:

- Windows export output: `build/windows/lantern_engine.exe`
- Windows data pack: `build/windows/lantern_engine.pck`
- Windows release archive: `build/windows/lantern_engine-windows-v0.5.0.zip`

Windows builds are the default tester artifacts. Linux builds are not produced unless explicitly requested.

## Repo docs

- `docs/visio.md`
- `docs/ohjeet.md`
- `docs/light_engine.md`
- `docs/milestones.md`
- `docs/roadmap/current-state.md`
- `docs/code-map.md`
- `docs/devlog.md`
- `CHANGELOG.md`
