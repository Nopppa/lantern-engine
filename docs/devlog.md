# Devlog

## 2026-03-09

### Objective
Build the **first genuinely testable Lantern Engine phase** in Godot 4 with strict MVP-0 scope.

### Decisions
- chose Godot 4 CLI project creation instead of editor-driven authoring because no live Godot Editor session was connected via OpenClaw plugin
- kept the runtime compact in one script for speed and tuning instead of pretending MVP-0 needs a full production architecture already
- implemented both wall bounce and Prism Node redirection so the prototype contains at least one unmistakable geometry moment
- kept the arena authored and static; no procedural systems
- used simple geometric rendering instead of waiting on asset production

### Scope cuts / non-goals
- no save/profile system
- no meta progression
- no third enemy
- no boss/miniboss
- no content validator yet
- no broad data asset schema yet
- no audio assets yet
- no pixel art production pass

### Observations
- the immediate mechanical identity is already clearer once the beam can bounce off walls instead of only firing straight
- Prism Node redirection is the more interesting part tactically; it creates setup moments rather than only aiming skill checks
- Moth + Hollow is enough variety for MVP-0: one rushes, one repositions and punishes static play

### Blockers / risks
- Godot editor plugin session was unavailable, so editor-side scene inspection/testing had to be replaced with filesystem + CLI work
- architecture is intentionally compact and should be decomposed before large content expansion
- no real art/audio pass yet, so readability testing is mechanically valid but not presentation-complete

### Validation commands
```bash
godot --headless --path /opt/openclaw/projects/lantern_engine --quit
godot --path /opt/openclaw/projects/lantern_engine
godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Windows Desktop" build/windows/lantern_engine.exe
godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Linux/X11" build/linux/lantern_engine.x86_64
```

### Export result
- Windows export succeeded
- Linux export succeeded
- packaged artifacts created under `build/windows/` and `build/linux/`

### Readability / visual pass
- strengthened arena contrast so the playable space reads as a lit stage inside surrounding darkness instead of a flat dark rectangle
- upgraded beam rendering to a warm core + cyan glow with explicit endpoint markers, making bounces and redirect chains easier to parse at a glance
- gave Prism Node a clearer gameplay silhouette with aura rings, crosshair-like guides, and a faint redirect preview so its function reads before the player tests it
- rebuilt the HUD as boxed status panels with bar-style HP/energy readouts, explicit beam/prism readiness, and a tiny readability legend for the prototype language

### Follow-up fix pass: reward selection clarity
- review surfaced the biggest MVP-0 usability issue: the HUD implied keyboard reward selection, but the panel itself only exposed mouse clicks
- fixed this by implementing explicit keyboard support instead of downgrading docs/HUD to mouse-only
- current reward input is now consistent across HUD, panel text, and docs:
  - `1/2/3` direct select
  - `W/S` or `↑/↓` move highlight
  - `E` or `Enter` confirm highlighted option
  - mouse click still works
- chose this over a mouse-only clarification because reward choice is a hard stop in the combat loop and MVP-0 benefits from a fully legible keyboard path

### Release hygiene pass: v0.1.1 packaging cleanup
- cleaned stale `v0.1.0` archives out of `build/` so current exports are unambiguous
- repacked Windows release zip to contain only `lantern_engine.exe` + `lantern_engine.pck`
- created matching Linux archive `build/linux/lantern_engine-linux-v0.1.1.tar.gz` so release assets are version-consistent across platforms
- canonical release artifacts for `v0.1.1` are now:
  - `lantern_engine-windows-v0.1.1.zip`
  - `lantern_engine-linux-v0.1.1.tar.gz`

### Expected follow-up
- tune encounter pacing after first hands-on play session
- split runtime script if team commits to MVP-1
- add actual combat resolver class before content count grows
