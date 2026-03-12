# Main Menu Mode Select – Branch Architecture Plan

**Date:** 2026-03-12  
**Status:** Architecture design / pre-implementation  
**Target branch:** `feature/main-menu-mode-select`

---

## Executive Summary

This document defines a clean, mergeable branch plan for adding a **main menu** to Lantern Engine so the player can choose which mode to launch:

- **Light Lab**
- **Random Gen** (placeholder for now)

The goal is to add a stable bootstrap/navigation seam **without disturbing the current lighting work**.

### Core approach

- Keep `main.tscn` as the permanent application bootstrap scene.
- Turn `scripts/main.gd` into a small **screen router / scene host**.
- Add a dedicated **Main Menu** scene.
- Add a tiny **Random Gen placeholder** scene.
- Keep **Light Lab unchanged as the real playable mode**.

This is intentionally a **small shell-layer branch**, not a gameplay or lighting branch.

---

## Current Boot Flow

Current startup path in the repo:

1. `project.godot`
   - `run/main_scene="res://scenes/main.tscn"`
2. `scenes/main.tscn`
   - root bootstrap scene
3. `scripts/main.gd`
   - immediately instantiates `res://scenes/light_lab_scene.tscn`
   - adds it as a child

### Result today

- App boots directly into **Light Lab**
- There is **no menu**
- There is **no central mode-selection layer**
- There is **no explicit runtime routing abstraction** yet

---

## Branch Goal

Add a branch-local shell flow like this:

```text
project.godot
  -> main.tscn
    -> Main Menu
       -> Light Lab
       -> Random Gen (placeholder)
```

This branch should:

- be easy to merge back into `main`
- not interfere with lighting iteration
- not require changes inside Light Lab internals
- provide a stable entry seam for future RandomGEN runtime work

---

## Recommended Branch Name

**Recommended:**
- `feature/main-menu-mode-select`

Alternatives:
- `feature/menu-lightlab-randomgen`
- `feature/bootstrap-main-menu`

---

## Scene / File Plan

### Files to add

- `scenes/main_menu.tscn`
- `scripts/main_menu.gd`
- `scenes/random_gen_placeholder.tscn`
- `scripts/random_gen_placeholder.gd`

### Files to modify

- `scripts/main.gd`

### Files to leave untouched if possible

- `scripts/light_lab_scene.gd`
- `scripts/gameplay/*`
- lighting / material / LightField / LightWorld systems
- `scripts/run_scene.gd` (unless deliberately exposed later as debug/legacy mode)

---

## Recommended Bootstrap Design

### Keep `main.tscn` as the root host

`main.tscn` should remain the app entrypoint and own exactly **one active child screen** at a time.

That child can be:

- Main Menu
- Light Lab scene
- Random Gen placeholder scene

### Why this is the cleanest seam

- avoids scene-change churn in `project.godot`
- keeps app boot stable
- lets later modes plug in cleanly
- localizes branching risk to bootstrap/navigation only
- minimizes conflicts with current gameplay work

---

## Recommended `main.gd` Responsibility

`main.gd` should become a tiny router/host.

### Responsibilities

- instantiate one child scene at a time
- free previous child when switching
- provide simple methods like:
  - `show_main_menu()`
  - `start_light_lab()`
  - `start_random_gen_placeholder()`

### Example responsibility model

```gdscript
Main
  owns current_screen
  can swap between scenes
```

### Important

Do **not** put game logic here.
`main.gd` should stay shell-level only.

---

## Menu Flow Design

### Minimal first-pass menu

Main Menu should contain:

- Title: `Lantern Engine`
- Button: `Light Lab`
- Button: `Random Gen`
- Optional small label under Random Gen: `Placeholder`

### Flow

- Selecting **Light Lab** loads current `light_lab_scene.tscn`
- Selecting **Random Gen** loads placeholder scene

### UX recommendation for v1

Keep it extremely small:

- clickable buttons
- no animation required
- no persistence required
- no advanced settings screen required

---

## Placeholder Random Gen Scene Design

The placeholder should be intentionally simple but useful.

### Required contents

- Title: `Random Gen`
- Status text: `Placeholder branch entry point`
- Short note that procedural runtime is not implemented yet
- `Back to Menu` button

### Optional small extras

If desired, the placeholder may also show:

- placeholder seed text (`Seed: TODO`)
- one fake `Generate` button that only updates text/logs intent

### Recommendation

For first merge-safe pass, keep it to:

- title
- one explanatory label
- one back button

---

## Navigation Strategy

### First implementation

Use **local child swapping in `main.gd`**, not global `change_scene_to_file()` routing.

Why:

- keeps all mode-switching inside one bootstrap layer
- easier to debug
- simpler merge
- easier to add temporary placeholders

### Back navigation

#### Required in v1
- Placeholder scene should support **Back to Menu**

#### Optional later
- Light Lab may later gain:
  - `Esc to Menu`
  - or a small return button

This should be milestone 2 or 3, not mandatory for initial branch landing.

---

## Shared vs Branch-Specific Ownership

### Shared / long-term reusable

- `main.tscn`
- `scripts/main.gd` as bootstrap router
- scene-path constants / mode launch helpers

### Branch-specific to this feature

- `main_menu.tscn`
- `main_menu.gd`
- `random_gen_placeholder.tscn`
- `random_gen_placeholder.gd`

### Explicitly not part of this branch

- real RandomGEN world runtime
- lighting refactors
- Light Lab gameplay changes
- material system changes

This branch is a **shell and entry-flow branch only**.

---

## Merge Strategy Back to Main

### Recommended merge shape

This branch should stay small enough to merge as one clean PR.

### Safe merge order

1. Add `main.gd` router support
2. Add Main Menu scene
3. Add Random Gen placeholder scene
4. Wire buttons
5. Optional: README/docs note

### Why this is low risk

- no lighting core changes
- no material changes
- no LightField/LightWorld changes
- Light Lab remains the real mode and loads as before, only through one extra shell hop

---

## Smallest Safe Implementation Milestones

### Milestone 1 — Router seam only

- refactor `main.gd` into a scene host
- can still launch Light Lab immediately by default during development

### Milestone 2 — Main Menu scene

- boot into `main_menu.tscn`
- button to launch Light Lab

### Milestone 3 — Random Gen placeholder

- add placeholder scene
- add back-to-menu flow

### Milestone 4 — Optional return from Light Lab

- later add `Esc to Menu` or a UI exit action if desired
- only if it doesn’t fight current debug keybinds

### Recommended merge point

Merge after **Milestone 3**.

---

## Risks and Edge Cases

### 1. Dirty worktree / concurrent lighting work

**Risk:** menu branch accidentally mixes in unrelated lighting changes  
**Mitigation:** branch from clean `main` only

### 2. Input/keybinding conflicts

**Risk:** menu uses keys already heavily used by Light Lab  
**Mitigation:** keep v1 mouse-first, minimal keyboard bindings

### 3. Scene lifecycle leaks

**Risk:** old child scenes remain alive after swap  
**Mitigation:** centralize swapping in `main.gd` and free previous child explicitly

### 4. Future menu growth turns bootstrap into junk drawer

**Risk:** `main.gd` becomes overloaded  
**Mitigation:** keep `main.gd` strictly as router, push UI logic into `main_menu.gd`

### 5. Random Gen placeholder gains too much fake logic

**Risk:** placeholder becomes accidental proto-runtime  
**Mitigation:** keep it intentionally tiny and clearly marked placeholder-only

---

## Recommended First Code Shape

### `scripts/main.gd`
Should expose methods roughly like:

- `show_main_menu()`
- `start_light_lab()`
- `start_random_gen_placeholder()`
- `_swap_screen(scene_path: String)`

### `scripts/main_menu.gd`
Should:

- own menu button logic
- call upward into parent router
- stay purely UI-level

### `scripts/random_gen_placeholder.gd`
Should:

- display placeholder info
- provide back button to menu

---

## Suggested Commit Sequence

1. `refactor(bootstrap): turn main.gd into screen host`
2. `feat(menu): add main menu scene`
3. `feat(menu): wire Light Lab launch from menu`
4. `feat(menu): add random gen placeholder scene`
5. `feat(menu): add placeholder back-to-menu flow`
6. `docs(menu): document mode selection bootstrap`

---

## Final Recommendation

Implement this as a **small dedicated branch** that only changes the app shell:

- keep Light Lab intact
- do not mix with lighting fixes
- use Main Menu as the stable future launch seam
- treat Random Gen as a placeholder target for now

This gives the project a clean top-level structure now, while preparing it for a real generated-world runtime later.

---

**Recommended next step after branch creation:**
Implement Milestones 1–3 only, then merge.
