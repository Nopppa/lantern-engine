# RandomGEN Live Handoff

**Purpose:** Living handoff document for follow-up coding agents on `feature/randomgen-exploration-world`.

**Rule:** After any agent timeout or incomplete report, inspect the branch/worktree directly before continuing. Update this file with the verified state, then have the next agent read this file first.

---

## Current Verified State

- **Repo:** `/opt/openclaw/projects/lantern-engine`
- **Branch:** `feature/randomgen-exploration-world`
- **Verified HEAD:** `9f7881b`
- **Verification time:** 2026-03-12 16:24 Europe/Berlin

### Remote/commit status
- Current branch is pushed through commit `9f7881b`.
- There are **no verified uncommitted RandomGEN code changes** at this moment.
- Current untracked files in worktree are unrelated build/editor leftovers:
  - `builds/releases/`
  - `builds/windows/lantern-engine.exe`
  - `builds/windows/lantern-engine.pck`
  - `scripts/main_menu.gd.uid`
  - `scripts/random_gen_placeholder.gd.uid`

---

## Completed Milestones So Far

### Milestone 1
**Commit:** `1c9db0f`
- First practical RandomGEN exploration scaffold added.

### Milestone 2
**Commit:** `188f1e6`
- `scripts/exploration_scene.gd` gained visible rendering/debug shell.
- Player presence/movement added.
- Camera follow added.
- HUD/debug info added.
- Seed reroll hotkeys added.

### Milestone 2.5 / Collision step
**Commit:** `75e0409`
- Exploration runtime now reuses shared `LightLabCollision` helper.
- Player movement resolves against generated blockers instead of free-walking.
- Spawn position is validated with `_find_valid_spawn()`.
- Camera limits are constrained to arena bounds.
- Reroll keeps player node state in sync more cleanly.

### Live handoff workflow
**Commit:** `07d52f7`
- Added this living handoff document.
- Established the verified-state-before-continue workflow for timeout recovery.

### Timeout verification update
**Commit:** `4415cc9`
- Updated this document after verifying a timeout left no code diff.
- Tightened instructions to keep future agents focused and fast.

### Milestone 3 / Minimal shared light runtime boot
**Commit:** `26e811e`
- Exploration scene now boots shared `LightField`.
- Exploration scene now boots `DeadAliveGrid` from generated-world metadata.
- Exploration scene now instantiates and updates `NativeLightPresentation`.
- Minimal exploration flashlight runtime state was added (`_flashlight_on`, `_facing`, minimal flashlight packet source spec).
- Gameplay light field now rebuilds every frame from a small exploration flashlight approximation.
- HUD now reports flashlight state and sampled gameplay-light intensity.

### Milestone 3.5 / Shared flashlight packet reuse
**Commit:** `0ea286f`
- Exploration scene now reuses `FlashlightVisuals.build_render_packet(...)` instead of the earlier ad-hoc local flashlight approximation.
- Shared frontier smoothing state (`_approx_flashlight_frontier`) is now tracked in exploration scene.
- Exploration gameplay-light writing now uses packet segments, zones, and fills with the same general packet-to-field write approach used in Light Lab.
- Mirror/glass/transmit/reflect continuations from the shared packet path now feed exploration gameplay light more truthfully.
- Added small helper passthroughs needed by the shared flashlight packet path.

### Milestone 4 / Exploration pause return path
**Commit:** `1c0f69c`
- Exploration scene now has a minimal in-scene pause state on `Esc`.
- Exploration runtime updates freeze while paused.
- Pause state exposes resume plus return-to-main-menu on `Enter` or `M`.
- This change stayed exploration-local and left Light Lab untouched.

### Milestone 4.5 / Viewport-anchored pause UI
**Commit:** `5a03058`
- Exploration pause UI was moved out of world-space drawing into viewport-anchored overlay UI.
- Pause presentation now behaves more correctly under resolution/fullscreen changes.
- Exploration HUD sizing also became viewport-aware.

### Architecture anchoring docs
**Commit:** `0a2e6ff`
- Added `docs/world-generation-and-persistence-vision.md`.
- Locked RandomGEN toward a deterministic finite procedural world with chunk streaming, persistent chunk modifications, persistent restoration state, and save/load direction.

### Decomposition pass 1 / light runtime extraction
**Commit:** `dfaf4dd`
- Created `scripts/exploration/exploration_light_runtime.gd`.
- Moved exploration-specific light runtime responsibilities out of `scripts/exploration_scene.gd` into the new helper.
- `exploration_scene.gd` now acts more clearly as runtime coordinator/composition root.

### Decomposition pass 2 / overlay UI extraction
**Commit:** `f5a4e31`
- Created `scripts/exploration/exploration_overlay_ui.gd`.
- Moved HUD/status/pause overlay creation, layout, and update logic out of `scripts/exploration_scene.gd`.
- `exploration_scene.gd` now delegates overlay attach/layout/update/show calls to the helper.
- Viewport-aware overlay behavior remains intact and is now more cleanly isolated for future resolution/fullscreen work.

### Decomposition pass 3 / player controller extraction
**Commit:** `a045e50`
- Created `scripts/exploration/exploration_player_controller.gd`.
- Moved movement input, facing update from mouse, collision-resolved motion, arena clamping, and spawn validation out of `scripts/exploration_scene.gd`.
- `exploration_scene.gd` now delegates spawn resolution and per-frame player stepping to the controller helper.

### Feature step / exploration beam runtime
**Commit:** `80a0b13`
- Added beam/laser runtime state to `scripts/exploration/exploration_light_runtime.gd`.
- Exploration now reuses shared beam/laser solving and native beam presentation flow.
- Beam packet energy is now written into the gameplay light field.
- Prism energizing can now respond to beam energy as well as flashlight energy.
- Added minimal exploration-side beam trigger/testing hook in `scripts/exploration_scene.gd` plus HUD/status reporting for beam readiness/activity.

### Generator milestone / Layout v2
**Commit:** `9f7881b`
- `scripts/world/generated_exploration_provider.gd` now builds a deterministic graph-based procedural layout instead of reusing the old generated light-lab arena scatter.
- Layout now includes:
  - calm spawn node
  - 3–7 themed zone nodes
  - corridor/connector links
  - one progression/exit-style node deeper in the map
- Material-zone logic now deliberately creates mirror / glass / wet / wood flavored regions.
- Prism stations, blockers, and route geometry are placed with more purpose according to zone theme.
- Provider now emits richer metadata (`layout_nodes`, `layout_links`, `zone_summaries`, progression node ids, graph depth) while still compiling into the same `LightWorld`/shared material pipeline.
- `docs/randomgen-layout-v2-notes.md` added to anchor the design intent.
- `scripts/exploration_scene.gd` scene label/HUD copy updated to reflect layout-v2 exploration goals.

---

## What Is Working Now

In `feature/randomgen-exploration-world`, the exploration shell currently has:

- generated `LightWorld`
- visible debug/exploration rendering
- player movement
- camera follow
- HUD/debug info
- reroll controls
- blocker collision via shared collision helper
- safer spawn handling
- shared `LightField` boot
- `DeadAliveGrid` boot/update
- native light presentation boot/update
- flashlight toggle (`F`) and aim direction from mouse for exploration runtime
- exploration flashlight goes through the shared flashlight packet builder path
- gameplay-light field is fed from flashlight packet segments / zones / fills using the Light Lab-style packet-to-field write approach
- in-scene pause/menu return path on `Esc`, with resume or return to main menu
- viewport-anchored exploration overlay UI that adapts more safely to resolution/fullscreen changes
- beam/laser runtime in exploration:
  - beam can be triggered for testing from exploration input
  - beam uses shared solver/presentation path
  - beam writes energy into gameplay light field
  - beam can energize prism stations
- graph-based layout v2 generation:
  - calmer spawn region
  - multiple distinct zones
  - linked corridor structure
  - deeper progression/exit node
  - themed material regions
  - purposeful prism/blocker placement
- decomposition passes completed for:
  - light runtime
  - overlay/HUD/pause UI
  - player controller / movement / spawn handling

Light Lab remains untouched by these branch changes.

---

## What Is Still Missing

### Next likely milestone
Use the new v2 world layout to deepen gameplay meaning rather than only layout shape.

### Missing pieces
- layout v2 exists, but still needs practical play-feel tuning and validation inside exploration runtime
- progression gate/exit is represented structurally, but not yet backed by a fuller gameplay rule or unlock loop
- prism behavior in exploration still trails the fuller authored-world aspirations
- no enemies/runtime gameplay loop yet
- no chunk streaming/save-load implementation yet despite the world-vision doc
- no explicit packaged validation build/report has been attached to this milestone beyond headless boot checks

---

## Next Recommended Step

### Recommended feature direction
The next step should build gameplay meaning on top of layout v2, not add more structure for its own sake.

Best candidates:
1. make the progression/exit node mechanically meaningful (light gate, artifact, or unlock rule), or
2. strengthen prism/light-puzzle behavior inside the new generated zones so the v2 map is more than just a better-shaped space.

### Constraints
- Do **not** fork lighting/material logic.
- Keep Light Lab intact.
- Keep the change architecture-aligned.
- Prefer one focused feature step next.

---

## Timeout Handling Rule For Future Agents

If the previous agent timed out:
1. Check branch + `git status` yourself.
2. Check for actual diff in the expected files.
3. Update this document with the verified state.
4. Continue only from verified code state, not from speculative summaries.

---

## Notes For Next Agent

Read these first:
- `docs/architecture-randomgen-branch-plan.md`
- `docs/world-generation-and-persistence-vision.md`
- `docs/randomgen-layout-v2-notes.md`
- `docs/randomgen-live-handoff.md`
- `scripts/world/generated_exploration_provider.gd`
- `scripts/exploration_scene.gd`
- `scripts/exploration/exploration_light_runtime.gd`

Do not trust prior timeout summaries unless they match the verified branch state.
