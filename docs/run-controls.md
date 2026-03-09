# Run Controls & Test Commands

## Player controls

- `WASD` move
- `LMB` cast Refraction Beam toward cursor
- `RMB` place Prism Node
- `R` restart run

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
2. choose `+1 Bounce`
3. in encounter 2, intentionally bank the beam twice
4. confirm the extra segment visibly exists

### Retry loop
1. let enemies kill player or press `R`
2. verify run resets to encounter 1
3. verify HP/Energy/upgrades return to baseline

## CLI commands

```bash
godot --headless --path /opt/openclaw/projects/lantern_engine --quit
godot --path /opt/openclaw/projects/lantern_engine
```
