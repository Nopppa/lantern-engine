# Lantern Engine — MVP-0 Prism Mechanic Proof

Godot 4 prototype for the **first testable Lantern Engine phase**. This repo deliberately ships a tight, playable MVP-0 instead of a broad systems skeleton.

## What is included

- top-down player movement
- one authored test arena
- Energy resource + regen
- one Prism primary skill: **Refraction Beam**
- one placeable setup skill: **Prism Node**
- at least one real bounce/refraction moment:
  - beam can bounce off arena walls
  - beam can refract through Prism Node into a redirected segment
- 2 enemy archetypes:
  - **Moth** chaser
  - **Hollow** ambusher/blinker
- basic hit / death feedback
- one reward/upgrade choice step between encounters with clear mouse + keyboard selection
- restart / retry loop
- dev shortcuts for rapid iteration

## Scope discipline

This is **MVP-0 / mechanic proof**, not MVP-1 and not a vertical slice.

Explicitly *not* implemented yet:

- procedural generation
- save persistence
- multiple schools
- broad content pipeline
- art/audio polish pass
- meta progression
- boss/miniboss
- full data-driven combat authoring

See `docs/mvp0-scope.md` for exact scope boundaries.

## Controls

- `WASD` move
- `LMB` cast Refraction Beam
- `RMB` place Prism Node
- `R` restart run
- reward panel: `1/2/3` direct select, `W/S` or `↑/↓` move, `E`/`Enter` confirm
- mouse click on reward buttons also works
- `F1` toggle debug text
- `F2` refill HP + Energy
- `F3` force reward selection
- `1` spawn Moth
- `2` spawn Hollow

See `docs/run-controls.md` for full testing flows.

## Run locally

### Open in Godot editor

```bash
godot --path /opt/openclaw/projects/lantern_engine
```

### Run from CLI

```bash
godot --path /opt/openclaw/projects/lantern_engine
```

### Headless validation

```bash
godot --headless --path /opt/openclaw/projects/lantern_engine --quit
```

## Build artifacts

Releases are expected to contain the canonical versioned archives:

- `lantern_engine-windows-vX.Y.Z.zip`
- `lantern_engine-linux-vX.Y.Z.tar.gz`

If export templates are missing on the machine, see `docs/devlog.md` for current blocker notes and exact export commands.

## Repo docs

- `docs/vision.md`
- `docs/architecture.md`
- `docs/architecture-mvp0.md`
- `docs/milestones.md`
- `docs/devlog.md`
- `docs/mvp0-scope.md`
- `docs/run-controls.md`
- `CHANGELOG.md`

## Version

See `VERSION`.
