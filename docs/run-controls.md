# Run Controls & Test Commands

## Player controls

- `WASD` move
- `LMB` cast Refraction Beam toward cursor
- `RMB` place Prism Node
- `Q` trigger Prism Surge from the active Prism Node (consumes the node, damages and shoves nearby enemies, and jams enemy special abilities briefly)
- `R` restart run
- reward panel: `1/2/3` direct select, `W/S` or `↑/↓` move highlight, `E`/`Enter` confirm
- mouse click on a reward button also selects it

## Debug / dev controls

- `F1` show/hide the full help legend; the run now starts with the full legend visible once so the critical controls are discoverable immediately
- `F2` refill HP + Energy
- `F3` open reward selection immediately
- `F4` toggle immortality on/off
- `1` spawn one Moth near enemy side
- `2` spawn one Hollow near enemy side

## Recommended test flows

### Core feel
1. start run
2. kite Moths around arena edges
3. bounce beam off wall into a pursuer
4. confirm the shot reads like a brief flash/pulse rather than a long-held laser
5. confirm readability of beam continuation

### Prism setup moment
1. place Prism Node near center-right of arena
2. stand lower-left of node
3. aim beam through node toward top/right pressure lane
4. confirm redirected segment appears and can hit enemies behind the original firing line
5. if you have bounce upgrades or wall angle, confirm the redirected beam can still bounce from walls after the node redirect

### Prism Surge check
1. place Prism Node near a pack of enemies
2. press `Q`
3. confirm the node collapses into a cyan burst ring
4. confirm nearby enemies take damage, get shoved away from the node, have special abilities jammed briefly, and the node is consumed
5. specifically hit a Hollow during windup or before its next blink and confirm the blink is interrupted / delayed during the jam window
6. if `Surge Capacitors` appears, take it and confirm the larger blast / shorter cooldown are noticeable

### Reward verification
1. clear encounter 1
2. verify reward panel shows keyboard hint text
3. press `1`, `2`, or `3` to take a reward immediately, or use `W/S` / `↑/↓` then `E` or `Enter`
4. confirm the panel closes and the next encounter begins
5. if you picked `+1 Bounce`, intentionally bank the beam twice in encounter 2 and confirm the extra segment visibly exists

### Retry loop
1. let enemies kill player or clear 3/3, then confirm a centered end-state panel appears immediately
2. verify the panel clearly says the run ended / completed and offers both `R` and a clickable restart button
3. restart via `R`
4. verify run resets to encounter 1
5. verify HP/Energy/upgrades return to baseline

## Current playtest focus

For the current `v0.4.2` patch-3 build, testers should pay extra attention to:

- Prism Surge value: does `Q` create a real tactical decision now that it also jams enemy specials?
- node tension: does consuming the Prism Node for an AOE burst create interesting timing choices versus keeping it for beam redirects?
- reward readability: does `Surge Capacitors` read clearly when it appears in the reward pool?
- baseline safety: do `F2`, `F3`, `F1`, `F4`, `Q`, and `R` all behave reliably in the shipped build, including Prism HUD readiness after consuming a node?

Use the relevant playtest notes under `docs/playtests/` when capturing observations.

## CLI commands

```bash
godot --headless --path /opt/openclaw/projects/lantern_engine --quit
godot --path /opt/openclaw/projects/lantern_engine
godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Windows Desktop" build/windows/lantern_engine.exe
godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Linux/X11" build/linux/lantern_engine.x86_64
```

## Export outputs and canonical tester artifacts

Raw Godot export outputs land here:

- `build/windows/lantern_engine.exe`
- `build/windows/lantern_engine.pck`
- `build/linux/lantern_engine.x86_64`
- `build/linux/lantern_engine.pck`

For the current version, the canonical packaged artifact to distribute is:

- `build/windows/lantern_engine-windows-v0.4.2.zip`
