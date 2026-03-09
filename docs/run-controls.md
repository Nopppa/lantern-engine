# Run Controls & Test Commands

## Player controls

- `WASD` move
- `LMB` cast Refraction Beam toward cursor
- `RMB` place Prism Node
- `R` restart run
- reward panel: `1/2/3` direct select, `W/S` or `↑/↓` move highlight, `E`/`Enter` confirm
- mouse click on a reward button also selects it

## Debug / dev controls

- `F1` toggle debug info
- `F2` refill HP + Energy
- `F3` open reward selection immediately
- `1` spawn one Moth near enemy side
- `2` spawn one Hollow near enemy side

## Recommended test flows

### Core feel
1. start run
2. kite Moths around arena edges
3. bounce beam off wall into a pursuer
4. confirm readability of beam continuation

### Prism setup moment
1. place Prism Node near center-right of arena
2. stand lower-left of node
3. aim beam through node toward top/right pressure lane
4. confirm redirected segment appears and can hit enemies behind the original firing line

### Reward verification
1. clear encounter 1
2. verify reward panel shows keyboard hint text
3. press `1`, `2`, or `3` to take a reward immediately, or use `W/S` / `↑/↓` then `E` or `Enter`
4. confirm the panel closes and the next encounter begins
5. if you picked `+1 Bounce`, intentionally bank the beam twice in encounter 2 and confirm the extra segment visibly exists

### Retry loop
1. let enemies kill player or press `R`
2. verify run resets to encounter 1
3. verify HP/Energy/upgrades return to baseline

## CLI commands

```bash
godot --headless --path /opt/openclaw/projects/lantern_engine --quit
godot --path /opt/openclaw/projects/lantern_engine
```
