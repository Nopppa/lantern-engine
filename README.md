# Lantern Engine — MVP-1 Patch 1

Godot 4 prototype advancing beyond the MVP-0 mechanic proof into a small but complete authored run. `v0.4.0` ships the first MVP-1 patch with a simple run summary, a cleaner data-driven content layer, a full 5-encounter authored chain, and Prism Node upgrade depth — without adding the out-of-scope third Prism skill or miniboss.

## What is included

- top-down player movement
- one authored test arena
- Energy resource + regen
- one Prism primary skill: **Refraction Beam**
- one placeable setup skill: **Prism Node**
- beam wall-bounce support plus Prism redirect chaining
- 2 enemy archetypes:
  - **Moth** chaser
  - **Hollow** ambusher/blinker
- authored 5-encounter run chain
- reward/upgrade choice step between encounters with clear mouse + keyboard selection
- Prism upgrade depth that now affects redirect damage, redirect catch radius, redirect bend angle, and post-redirect bounce continuation
- simple end-of-run summary populated from runtime events
- cleaner data-driven encounter + upgrade authoring split out of the main scene script
- restart / retry loop
- dev shortcuts for rapid iteration, including immortality toggle
- short pulse-style Refraction Beam presentation instead of a long-held laser trace
- lightweight functional lit-zone readability pass around player, prism, targets, and fresh beam path

## Scope discipline

This is a **small MVP-1 patch**, not a vertical slice and not a content explosion.

Explicitly *not* implemented yet:

- third Prism skill
- miniboss
- procedural generation
- save persistence
- multiple schools
- broad content validator pipeline
- meta progression
- full production art/audio pass

See `docs/milestones.md` for current milestone posture.

## Controls

- `WASD` move
- `LMB` cast Refraction Beam
- `RMB` place Prism Node
- `R` restart run
- reward panel: `1/2/3` direct select, `W/S` or `↑/↓` move, `E`/`Enter` confirm
- mouse click on reward buttons also works
- `F1` show/hide the full help legend (shown by default on first launch; compact event/status panel stays visible after collapsing)
- `F2` refill HP + Energy
- `F3` force reward selection
- `F4` toggle immortality for testing
- `1` spawn Moth
- `2` spawn Hollow

See `docs/run-controls.md` for full control notes and `docs/playtests/PLAYTEST-02-CHECKLIST.md` for the focused tester checklist that triggered the v0.2.1 cleanup pass.

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

Current project version is `v0.4.0` (see `VERSION`). Local export outputs and release archives are:

- Windows export output: `build/windows/lantern_engine.exe`
- Windows data pack: `build/windows/lantern_engine.pck`
- Windows release archive: `build/windows/lantern_engine-windows-v0.4.0.zip`

Windows builds are the default tester artifacts. Linux builds are not produced unless explicitly requested.

Godot export presets point to the unarchived executable under `build/windows/`; the versioned `.zip` file is the canonical release artifact to hand to testers.

If export templates are missing on the machine, see `docs/devlog.md` for current blocker notes and exact export commands.

## Repo docs

- `docs/vision.md`
- `docs/architecture.md`
- `docs/architecture-mvp0.md`
- `docs/architecture-v0.3-internal-refactor-plan.md`
- `docs/code-map.md`
- `docs/milestones.md`
- `docs/devlog.md`
- `docs/mvp0-scope.md`
- `docs/run-controls.md`
- `CHANGELOG.md`

## Version

See `VERSION`.
