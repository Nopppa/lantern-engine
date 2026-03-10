# Lantern Engine — MVP-0.2.2 Implementation Contract

Date: 2026-03-10  
Source: Playtest 03 follow-up lock

## Intent

MVP-0.2.2 is a **small corrective iteration** focused on restoring basic end-of-run usability and fixing one confirmed beam-logic bug.

This patch is **not** a feature pass, HUD redesign, or broader progression rebalance. The scope is intentionally tight:
- make the **3/3 end-state readable and recoverable**
- make **legend/help return reliably** so hidden controls are practically usable again
- fix **beam total range budgeting across bounces**

Confirmed good and to be preserved:
- lighting / beam readability is improved versus the prior build
- the current core beam feel should not be regressed by this patch

---

## 1) What we fix now

### A. End-state clarity and restart recovery (P0)
Fix the current **3/3 run-complete state** so it no longer feels broken, stuck, or crash-like.

Implementation target:
- the player must have a **clear, reachable restart path** from the 3/3 state
- the end-state must communicate that the run is complete, not silently strand the player
- if the current state flow hides or suppresses recovery controls, that behavior must be corrected

Design rule:
- solve this with the **smallest clear UX/state correction** that restores recoverability
- do not turn this into a cinematic end screen, meta-progression screen, or full results screen feature

### B. Legend/help visibility recovery (P0)
Fix the legend/help behavior so it can be **reliably shown again** after being hidden or dismissed.

Implementation target:
- legend/help visibility must have a **deterministic, testable toggle/recovery behavior**
- the player must be able to access the help panel again during practical play, including after reaching 3/3
- the panel must expose the control hints needed for restart and immortality discovery

Clarification:
- this is not a full HUD redesign
- this is a **control recovery / discoverability fix**

### C. Restore practical discoverability of immortality toggle (P1)
No new immortality feature work is needed, but its **practical accessibility** must be restored by fixing legend/help recovery and control visibility.

Implementation target:
- if immortality already works mechanically, keep that behavior unchanged
- ensure the player can realistically find/use the control again through the restored help/legend path

### D. Beam total-range budgeting across bounce segments (P0)
Fix beam traversal so **bounces do not reset total beam length**.

Implementation target:
- the beam must consume a **single shared total range budget** from origin through all bounce segments
- each bounce may change direction, but must **not** start a fresh max-range allowance
- the final path length must equal the configured total range, subject to collision/bounce outcomes

Design rule:
- this is a logic fix, not a bounce-system redesign
- preserve current bounce behavior except for the incorrect range reset

---

## 2) What we do **not** do yet

Explicitly out of scope for MVP-0.2.2:
- no new features, upgrades, weapons, or meta systems
- no full HUD/UX overhaul
- no new end screen, score screen, or progression summary system beyond what is minimally required to make restart clear and accessible
- no redesign of immortality mode itself
- no broader bounce-system redesign beyond enforcing one shared total range budget
- no balance pass on beam length, bounce count, damage, or progression unless strictly required to preserve current intended behavior after the logic fix
- no new debug panels or developer tooling unless a tiny helper is strictly needed to validate the fix
- no speculative crash work unrelated to the now-reclassified 3/3 end-state problem

If a change does not directly support **end-state clarity**, **control recovery**, or **range-budget correctness**, defer it.

---

## 3) Acceptance criteria

MVP-0.2.2 is acceptable when all of the following are true:

### End-state / restart
- reaching **3/3** no longer feels functionally stuck or crash-like
- from the 3/3 state, the player can **clearly and successfully restart** without hidden or ambiguous recovery steps
- restart access remains available even if the player previously hid/dismissed the legend/help panel

### Legend/help recovery
- legend/help can be **reliably brought back** after being hidden
- the behavior is consistent enough that a tester can rediscover restart/help-dependent controls without guesswork
- the help path exposes the restart control and the immortality toggle in practice

### Immortality discoverability
- immortality remains available for testing if it already worked before
- the player can find the immortality control again through the restored help/legend flow
- this fix does not require adding a new immortality UX feature beyond restored visibility/discoverability

### Beam range logic
- beam total path length no longer resets at each bounce
- a bounced beam uses one **shared total range budget** from original cast start to final termination
- bounce behavior still works, but the beam cannot exceed intended total range merely by bouncing

### Scope discipline
- the patch stays a **small corrective release** and does not expand into a broader feature or polish wave

---

## 4) Priority order

### P0 — Must ship
1. **Fix 3/3 end-state clarity so restart is clearly reachable**
2. **Fix legend/help recovery so controls can be surfaced again reliably**
3. **Fix beam total-range budgeting across bounces**

### P1 — Should ship in same pass
4. **Verify immortality toggle is practically discoverable again via restored help/control visibility**

### P2 — Only if strictly needed to validate P0/P1
5. **Add minimal validation support** (tiny debug hint, state guard, or repro aid) only if needed to prove the fixes hold

---

## Delivery note

The correct framing for MVP-0.2.2 is:

> **Make the run-complete state recoverable, make hidden controls recoverable, and make bounced beam range obey one real total budget.**

Do not let this iteration expand into new UI, new progression surfaces, or broader gameplay changes.