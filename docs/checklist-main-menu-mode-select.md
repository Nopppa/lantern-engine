# Checklist – Main Menu Mode Select

**Branch:** `feature/main-menu-mode-select`  
**Purpose:** Add a clean bootstrap main menu that lets the player launch either Light Lab or a Random Gen placeholder.

---

## Scope Guard

- [ ] Keep this branch focused on **bootstrap/menu flow only**
- [ ] Do **not** mix in lighting/material/runtime refactors
- [ ] Do **not** redesign Light Lab internals in this branch
- [ ] Keep Random Gen as **placeholder only** for now

---

## Bootstrap / Routing

- [ ] Refactor `scripts/main.gd` into a small screen host / router
- [ ] Add a `current_screen` ownership pattern in the bootstrap layer
- [ ] Add helper methods such as:
  - [ ] `show_main_menu()`
  - [ ] `start_light_lab()`
  - [ ] `start_random_gen_placeholder()`
- [ ] Ensure scene swapping frees the previous child correctly
- [ ] Keep `main.tscn` as the permanent entry scene

---

## Main Menu Scene

- [ ] Create `scenes/main_menu.tscn`
- [ ] Create `scripts/main_menu.gd`
- [ ] Add title text: `Lantern Engine`
- [ ] Add `Light Lab` button
- [ ] Add `Random Gen` button
- [ ] Add optional placeholder subtitle/label for Random Gen
- [ ] Keep the first pass simple and readable (no fancy animation required)

---

## Launch Wiring

- [ ] Wire `Light Lab` selection to `res://scenes/light_lab_scene.tscn`
- [ ] Verify Light Lab launches through the router instead of direct bootstrap instantiation
- [ ] Wire `Random Gen` selection to placeholder scene
- [ ] Verify only one active child screen exists at a time

---

## Random Gen Placeholder Scene

- [ ] Create `scenes/random_gen_placeholder.tscn`
- [ ] Create `scripts/random_gen_placeholder.gd`
- [ ] Add title text: `Random Gen`
- [ ] Add placeholder description text
- [ ] Add `Back to Menu` button
- [ ] Keep the scene intentionally tiny and obviously placeholder-only

---

## Navigation / UX

- [ ] Verify boot → Main Menu works reliably
- [ ] Verify Main Menu → Light Lab works reliably
- [ ] Verify Main Menu → Random Gen placeholder works reliably
- [ ] Verify Random Gen placeholder → Main Menu works reliably
- [ ] Decide whether Light Lab gets a return-to-menu path now or later
- [ ] If not adding Light Lab return yet, document that clearly

---

## Input / Conflict Safety

- [ ] Avoid stealing Light Lab debug keybinds for the menu branch
- [ ] Keep v1 menu primarily mouse-driven unless keyboard navigation is trivial
- [ ] Check that menu input does not leak into spawned gameplay scenes

---

## Validation

- [ ] Run Godot headless check
- [ ] Launch and verify startup flow manually
- [ ] Confirm no Light Lab startup regressions
- [ ] Confirm `main.gd` router does not duplicate scenes or leak instances
- [ ] Confirm placeholder scene is stable and returns correctly

---

## Documentation

- [ ] Update architecture doc if implementation shape changes
- [ ] Add brief note to README or docs if boot flow changes are user-visible
- [ ] Record final menu flow in a short branch summary

---

## Git / Merge Hygiene

- [ ] Keep commits small and scoped to shell/menu flow
- [ ] Avoid unrelated formatting churn
- [ ] Rebase onto `main` before final merge if needed
- [ ] Prepare clean PR summary focused on bootstrap/menu changes only

---

## Suggested Commit Sequence

- [ ] `refactor(bootstrap): turn main.gd into screen host`
- [ ] `feat(menu): add main menu scene`
- [ ] `feat(menu): wire Light Lab launch`
- [ ] `feat(menu): add random gen placeholder scene`
- [ ] `feat(menu): add back-to-menu flow`
- [ ] `docs(menu): document mode selection flow`

---

## Done Criteria

- [ ] Game boots to a main menu
- [ ] Player can choose Light Lab
- [ ] Player can choose Random Gen placeholder
- [ ] Placeholder can return to menu
- [ ] Light Lab still works as before once launched
- [ ] Branch remains isolated from lighting-system work
