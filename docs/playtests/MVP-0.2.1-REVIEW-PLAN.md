# MVP-0.2.1 Review Plan

Focused review for the next post-cleanup pass. Goal: confirm the reported fixes are real, readable in play, and not hiding deeper problems.

## 1) Range-upgrade crash: verify it is actually gone
- Reproduce the old path on purpose: reach the same late-level state and take an extra range upgrade again.
- Also try adjacent cases: range upgrade immediately before/after another upgrade, and taking multiple range upgrades across one run.
- Confirm no silent failure replaced the crash: no missing beam, broken targeting, invalid HUD values, soft-lock, or spammed errors in console/log.
- If possible, test both fresh run and continued/high-intensity run so the fix is not only valid in one state.

## 2) Legend / HUD: confirm gameplay stays visible
- During active combat, verify the legend does not cover the player, enemies, pickups, beam endpoint, or bounce interaction points.
- Check at the moments that matter most: movement under pressure, aiming, upgrade choice, and post-hit recovery.
- Confirm the screen can be understood at a glance without needing to read a large overlay.
- If the legend is still needed, it should feel secondary and ignorable during play.

## 3) Beam-path lighting: confirm readability improves, not worsens
- Verify the beam path is easier to track during normal fire, bounce situations, and crowded moments.
- Check that added lighting does not wash out hazards, hide enemy silhouettes, or create misleading "fake" paths.
- Confirm the effect helps answer "where is my beam going right now?" within a quick glance.
- Watch for visual noise: flicker, over-bright bloom, clutter near walls/corners, or confusion when multiple bright elements overlap.

## 4) Bounce-test setup: confirm usefulness without scope creep
- If a dedicated bounce-test setup was added, verify it helps reproduce and inspect reflection behavior quickly.
- Confirm it is lightweight: debug/test aid first, not a new content branch or pseudo-leveling mode.
- It should support review of angles, continuity, and beam readability without introducing new systems that now need their own maintenance.
- If it exists but is slower than using the main arena, call that out.

## Review output expectations
- Record whether each item is: pass, partial, or fail.
- For any fail/partial result, capture exact repro steps and observed symptom.
- Prefer evidence from direct play + console/log behavior over assumption from code intent.
