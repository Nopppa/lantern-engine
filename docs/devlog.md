# Devlog

## 2026-03-10 — v0.3.1 Disrupted Blink Transit

Playtest 06 feedback: windup + teleport still didn't sell the fantasy. Player knows something is happening but the blink destination appears instantly. Fix: replaced the teleport with a short visible linear transit (0.28s). Hollow now moves visibly between start and end, flickering rapidly as light disrupts the blink. Still much faster than walking (~5x speed), but readable. Windup retained. Trail line shows path during transit.

## 2026-03-10 — v0.3.0 Blink Readability Fix

Playtest 05 feedback: hollow blink in flashlight felt instant/unreadable. Player couldn't see the light disrupting the blink.

Fix: added 0.4s pre-blink windup phase when hollow is in flashlight cone. During windup the enemy jitters in place and gets rapid orange/yellow flicker rings. After windup, blink executes at reduced distance with post-blink shimmer. Blink still works — it's just visibly worse, which is the whole point.

Files touched: `scripts/run_scene.gd`, `CHANGELOG.md`, `VERSION`

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

### Playtest iteration pass: v0.2.0
- changed beam presentation from a long-lived trace to a short pulse window (`0.15s`) so each shot lands more like a flash than a sustained laser
- reworked beam resolution loop so Prism Node redirect is now just another path transformation, not the end of the simulation; bounce continuation survives the redirect
- added explicit dev immortality toggle on `F4` because fast combat tuning without death friction is worth the tiny debug surface area
- added lightweight lit-zone rendering using layered circles on the 2D canvas instead of real lighting nodes/shaders; this keeps the effect cheap and readable in the current prototype scope

### Documentation prep pass: Playtest 02
- aligned README and `docs/run-controls.md` with the current `v0.2.0` build instead of leaving release artifact names as generic placeholders
- documented both raw export outputs and canonical packaged tester artifacts so local build paths vs distributable archives are not conflated
- added `docs/playtests/PLAYTEST-02-CHECKLIST.md` as the focused tester sheet for beam feel, Prism Node bounce continuity, immortality toggle usefulness, and lighting readability
- noted one remaining repo hygiene inconsistency: old `v0.1.1` archives still exist beside `v0.2.0` archives in `build/`, so docs now identify `v0.2.0` as the current canonical handoff

### Expected follow-up
- tune encounter pacing after first hands-on play session now that beam cadence is punchier
- decide whether lit zones should gain gameplay rules later (enemy stealth, safe routes, buffs) or stay presentation-only for MVP-0
- split runtime script if team commits to MVP-1
- add actual combat resolver class before content count grows

## 2026-03-10

### Internal refactor pass 1: low-risk decomposition
- reduced `scripts/run_scene.gd` responsibility without touching the riskiest beam/combat path math yet
- moved authored encounter data into `scripts/data/encounter_defs.gd`
- moved upgrade/reward data into `scripts/data/upgrade_defs.gd`
- extracted debug/help/dev-input handling into `scripts/player/debug_actions.gd`
- extracted reward panel construction and reward input/selection/application flow into `scripts/gameplay/reward_controller.gd`
- extracted HUD bar text helper into `scripts/ui/hud_text.gd`

### What stayed in `run_scene.gd` on purpose
- beam casting, prism redirect, bounce continuation, and range budgeting
- enemy spawning/update behavior
- encounter completion/start orchestration
- lit-zone cache building and `_draw()` rendering

### Why this pass stopped here
- target was safer ownership cleanup, not gameplay redesign
- recent bug history says reward/debug/input was a better first split target than beam math movement
- keeping combat geometry local preserves current proven behavior while making the next refactor pass easier

### Validation
```bash
godot --headless --path /opt/openclaw/projects/lantern_engine --quit
godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Windows Desktop" build/windows/lantern_engine.exe
godot --headless --path /opt/openclaw/projects/lantern_engine --export-release "Linux/X11" build/linux/lantern_engine.x86_64
```

### Validation result
- headless boot passed after fixing one missing preload in `reward_controller.gd`
- export validation pending / to be run after documentation update

---

## 2026-03-10 — v0.3.2 Enemy Freeze Bugfix

**Context:** Playtest 07 reported both Moth and Hollow freezing completely in place before being killed.

**Root cause:** `(player_pos - enemy_pos).normalized()` returns `Vector2(0,0)` when enemy overlaps the player. This zeroed out all movement (Moth chase, Hollow slow-walk) and blink targeting (`dir.rotated(PI) * distance` = zero), trapping the enemy at player position indefinitely.

**Fix:** Added a 2px distance threshold check before normalizing. When enemy is within threshold, a random direction is used instead, pushing the enemy outward so normal movement resumes next frame.

**Files touched:** `scripts/run_scene.gd` (4 lines added in `_update_enemies`), `VERSION`, `CHANGELOG.md`, `docs/devlog.md`

**Not a side-effect of:** reward state, run state, input handling, flashlight/blink design, or debug actions. All those paths are gated separately and don't affect the `dir` calculation.
