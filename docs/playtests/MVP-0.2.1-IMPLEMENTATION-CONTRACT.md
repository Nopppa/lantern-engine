# Lantern Engine — MVP-0.2.1 Implementation Contract

Date: 2026-03-10  
Source: Playtest 02 follow-up lock

## Intent

MVP-0.2.1 is a **small stability + readability cleanup pass** before any wider scope expansion.

This is **not** a new milestone branch, feature wave, or content push. The goal is to make the current combat loop safer to play and easier to read, while preserving the gains already confirmed in Playtest 02.

Confirmed good and therefore to be preserved:
- beam pulse / weapon feel is now good
- prism + bounce behavior works in normal use
- immortality toggle works for testing

---

## 1) What we fix now

### A. Critical stability fix: late reward crash on additional range upgrade
Fix the crash that occurs when the player takes an **additional range upgrade** during a late-game / end-of-run reward state.

Clarification:
- the suspected cause is **not** extra bounce selection
- the immediate target is the **range-upgrade reward path** and any upgrade-cap / stat-application edge case around it

Expected implementation focus:
- reproduce the crash reliably
- guard the reward application path against invalid state, out-of-bounds upgrade application, or duplicated late reward resolution
- ensure the run continues normally after taking the range upgrade

### B. Readability cleanup: legend/HUD obstruction
Reduce how much the current legend/instruction panel covers active gameplay space.

Acceptable solutions include one lightweight pass such as:
- smaller default footprint
- moved to a less intrusive position
- collapsed by default
- shown only in non-critical states / debug contexts

Goal:
- keep essential information available
- stop the legend from dominating the play area during normal play

### C. Lighting readability pass: beam path should illuminate more
Increase the visible lighting contribution of the **beam path itself**, not just pooled impact/target lighting.

Scope rule:
- this is a **readability/feel pass**, not a new lighting system
- keep it lightweight and compatible with the current MVP combat loop

Goal:
- the player should more clearly read the beam trajectory through light emission along the beam path

---

## 2) What we do **not** do yet

Explicitly out of scope for MVP-0.2.1:
- no new weapons, schools, or major combat mechanics
- no new enemy/content expansion push
- no “light changes the world” systemic feature set yet
- no environmental growth/restoration mechanics
- no large HUD redesign beyond removing the current obstruction problem
- no bounce-system redesign if current prism+bounce behavior remains stable
- no broad progression rebalance pass unless needed to safely fix the crash
- no separate test arena / bounce corridor unless required for reproducing or verifying the crash cheaply

If a change does not directly support **stability**, **readability**, or a minimal validation step for those two goals, it should be deferred.

---

## 3) Acceptance criteria

MVP-0.2.1 is acceptable when all of the following are true:

### Stability
- selecting an additional **range** upgrade in the problematic late reward scenario no longer crashes the game
- repeated reward selection / late-run upgrade flow completes without softlock or broken player state
- existing confirmed-good behavior remains intact:
  - beam still feels like a short satisfying pulse
  - prism + bounce still works in normal gameplay
  - immortality toggle still works

### Readability / HUD
- legend/help panel no longer meaningfully blocks the main gameplay view during normal play
- core HUD information remains accessible after the cleanup

### Lighting / Feel
- beam path is visibly more readable because it now emits more noticeable light along its travel path
- the result improves moment-to-moment legibility without overwhelming the scene or regressing performance/clarity

### Scope discipline
- the patch remains a **small cleanup iteration**, not a disguised feature expansion

---

## 4) Priority order

### P0 — Must ship
1. **Fix late reward crash on additional range upgrade**

### P1 — Should ship in same pass
2. **Reduce / relocate / collapse the intrusive legend**
3. **Strengthen beam-path illumination for readability**

### P2 — Only if needed to validate P0/P1
4. **Add minimal debug/repro support** for verifying the crash or beam readability, but only if the existing scene/setup is insufficient

---

## Delivery note

The correct framing for MVP-0.2.1 is:

> **Stabilize the current fun version, remove the most obvious screen clutter, and make the beam read better.**

Do not let this iteration expand into new systems just because the current build is finally starting to feel good.