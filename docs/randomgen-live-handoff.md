# RandomGEN Live Handoff

**Purpose:** Living handoff document for follow-up coding agents on `feature/randomgen-exploration-world`.

**Rule:** After any agent timeout or incomplete report, inspect the branch/worktree directly before continuing. Update this file with the verified state, then have the next agent read this file first.

---

## Current Verified State

- **Repo:** `/opt/openclaw/projects/lantern-engine`
- **Branch:** `feature/randomgen-exploration-world`
- **Verified HEAD:** `dfaf4dd`
- **Verification time:** 2026-03-12 15:35 Europe/Berlin

### Remote/commit status
- Current branch is pushed through commit `dfaf4dd`.
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
- Extracted responsibilities include LightField/DeadAliveGrid/runtime packet state, packet-to-field writing, flashlight/prism light runtime helpers, gameplay-light sampling, and native presentation update delegation.

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
- exploration flashlight now goes through the shared flashlight packet builder path instead of a purely local approximation
- gameplay-light field is now fed from flashlight packet segments / zones / fills using the Light Lab-style packet-to-field write approach
- in-scene pause/menu return path on `Esc`, with resume or return to main menu
- viewport-anchored exploration overlay UI that adapts more safely to resolution/fullscreen changes
- first decomposition pass complete: exploration light runtime now lives in `scripts/exploration/exploration_light_runtime.gd`

Light Lab remains untouched by these branch changes.

---

## What Is Still Missing

### Next likely milestone
Continue incremental decomposition or add the next real gameplay/runtime capability.

### Missing pieces
- no beam/laser integration yet in exploration scene
- exploration now has minimal prism-station shared-light response, but not the fuller authored-world prism/runtime feature set
- pause/menu path exists, but its presentation is still intentionally minimal
- no enemies/runtime gameplay loop yet
- no deeper generated-world variety beyond current scaffold path
- no chunk streaming/save-load implementation yet despite the world-vision doc
- no explicit validation build/report has been attached to this milestone yet

---

## Next Recommended Step

**Best next architectural step:**
Continue the low-risk decomposition plan.

### Recommended next extraction
- `scripts/exploration/exploration_overlay_ui.gd`

Why:
- pause/HUD/layout logic is already a clearly separate responsibility
- it also aligns directly with the new requirement that the real game must adapt to different resolutions and fullscreen
- it keeps `exploration_scene.gd` narrowing toward orchestration only

### Alternative functional step
If feature progress is preferred over structure in the next pass, add one more shared-light parity increment (beam/laser or fuller prism handling) while keeping the new runtime helper boundary intact.

### Constraints
- Do **not** fork lighting/material logic.
- Keep Light Lab intact.
- Keep the change small and architecture-aligned.
- Prefer one focused commit.

---

## Timeout Handling Rule For Future Agents

If the previous agent timed out:
1. Check branch + `git status` yourself.
2. Check for actual diff in `scripts/exploration_scene.gd` and any related files.
3. Update this document with the verified state.
4. Continue only from verified code state, not from speculative summaries.

---

## Notes For Next Agent

Read these first:
- `docs/architecture-randomgen-branch-plan.md`
- `docs/world-generation-and-persistence-vision.md`
- `docs/randomgen-live-handoff.md`
- `scripts/exploration_scene.gd`
- `scripts/exploration/exploration_light_runtime.gd`

Do not trust prior timeout summaries unless they match the verified branch state.
