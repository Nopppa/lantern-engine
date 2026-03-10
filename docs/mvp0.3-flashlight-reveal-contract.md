# MVP-0.3 Flashlight Reveal Contract

## Purpose

MVP-0.3 is a **strict mechanic proof** for one new combat-reading tool: a player-controlled flashlight that trades energy for information and control.

This proof exists to answer only these questions:

1. does a continuously draining flashlight create a meaningful moment-to-moment tradeoff against other energy use?
2. does reveal-light make stealth/blink enemies more readable and tactically distinct?
3. can the game communicate that "light exposes and weakens blink behavior" without needing a large content/system branch?

If those answers are yes, the mechanic is worth carrying forward. If not, it should stay cheap to remove or redesign.

---

## 1) Scope for this proof

Included in MVP-0.3:

- one **toggleable flashlight** owned by the player
- flashlight drains **energy continuously while active**
- flashlight **does not deal damage**
- flashlight reveals enemies that are otherwise hidden, invisible, or blink-phased
- at least one existing enemy type gains a **flashlight-sensitive blink behavior**
- being inside the beam/light cone causes the blink enemy to become **more trackable and less evasive**
- clear player-facing feedback for:
  - flashlight on/off state
  - energy drain while active
  - enemy being revealed by light
  - enemy blink being weakened by light
- minimal tuning pass so the mechanic can be felt in a short authored encounter
- documentation update and acceptance validation for the proof

Preferred implementation shape:

- use the current authored arena / authored encounter model
- keep the system local and practical; avoid a broad stealth framework
- implement reveal using simple state checks and readable visuals rather than expensive lighting simulation

---

## 2) Explicit non-goals / what we do NOT do yet

Not included in MVP-0.3:

- no real shadow casting or physically accurate light/visibility system
- no damage-over-time, stun, burn, or other offensive flashlight effects
- no broad stealth roster or multiple reveal-reactive enemy families
- no battery pickup economy, recharge stations, or inventory layer
- no new progression tree or permanent upgrades tied to flashlight
- no cone-shape polish pass with shaders if a simple gameplay volume proves the idea
- no enemy perception rewrite, suspicion meters, or full AI state machine expansion
- no level design pass built around darkness as a full game pillar
- no balance promise for late-game or production content
- no commitment yet to keep flashlight as a permanent feature if the proof is weak

This is a **proof of tactical readability and energy tradeoff**, not a full stealth/combat feature branch.

---

## 3) Recommended blink-enemy behavior in flashlight

The blink enemy should gain a simple, readable rule set:

### Baseline outside flashlight

- enemy can enter its normal blink/invisible behavior
- while blinking, its position is hard to track or briefly absent
- it retains its current threat identity as a repositioning/evasion enemy

### Inside flashlight

When the enemy is inside the active flashlight area:

- it becomes **visibly revealed** even during blink-related hidden states
- its blink is **weakened**, not disabled outright
- preferred weakening behavior:
  - reduce blink travel distance noticeably
  - add a brief visible shimmer/ghosted silhouette during or immediately before blink
  - optionally add a short recovery window after blink where the enemy stays visible

### Recommended concrete proof behavior

Use the following as the default proof implementation:

- flashlight contact applies a temporary **"revealed"** status that refreshes while in light
- while revealed:
  - blink distance is reduced to roughly **40-60%** of normal
  - enemy renders with a visible flicker/shimmer silhouette even if it would normally hide
  - enemy cannot chain blink as cleanly as outside light; if needed, add a tiny post-blink visible linger

### Why this is the right proof behavior

This keeps the enemy threatening while making the player feel they are **controlling chaos with light**, not merely turning the enemy off. That is the interesting part of the mechanic.

Hard-disable behavior would answer less. We want to test whether partial suppression creates a better tactical loop than a binary counter.

---

## 4) Role of the energy tradeoff

The flashlight only matters if it competes with something valuable.

Its design role in MVP-0.3:

- convert energy into **information** and **safer enemy handling**
- force the player to choose between:
  - keeping light on to expose/control a blink enemy
  - saving energy for other active tools and survival decisions
- create tension where the correct play is sometimes:
  - light briefly to reveal and stabilize the enemy
  - switch off to conserve energy
  - re-engage only when the enemy becomes hard to read again

Energy tradeoff target for the proof:

- flashlight should be affordable enough to use deliberately
- but expensive enough that leaving it on carelessly feels wrong
- player should notice the drain in one encounter without instantly feeling punished for testing the mechanic

Recommended tuning direction:

- start with a drain rate that makes continuous use possible only for a limited window
- prefer a drain profile that supports **short controlled bursts** over permanent uptime
- if the choice is unclear, increase drain before adding complexity

Success condition for the tradeoff:

- players can clearly feel that flashlight use has value
- players can also clearly feel that careless uptime has a cost

---

## 5) Acceptance criteria

MVP-0.3 is accepted when all of the following are true in a playable build:

1. player can toggle flashlight on and off reliably during play
2. active flashlight drains energy continuously and visibly
3. flashlight itself deals no damage and does not directly kill enemies
4. at least one blink/invisible enemy becomes visibly revealed when in flashlight
5. the revealed blink enemy remains a threat, but its blink/reposition behavior is clearly weaker in light than outside it
6. the weakening is readable without opening debug tools; a tester can describe the difference by play alone
7. the player can run out of practical flashlight uptime if they overuse it
8. there is at least one authored encounter where using the flashlight is meaningfully better than ignoring it
9. there is at least one moment where leaving the flashlight on too long creates an energy cost the player notices
10. the implementation does not require a large architecture rewrite to ship this proof

### Simple playtest statement

A tester should be able to say:

> "The flashlight costs energy, does not hurt enemies, exposes the blink enemy, and makes that enemy easier to track and punish while the light is on."

If that statement is not true from direct play, the proof is not done.

---

## 6) Practical implementation order for a small team / solo dev

Keep the order narrow and testable.

### Step 1 — Player flashlight skeleton

- add flashlight input + on/off state
- add simple gameplay area/cone in front of player
- add HUD/state feedback for active flashlight
- add continuous energy drain while active

Goal: verify the flashlight can be switched on, pointed, and paid for.

### Step 2 — Reveal hook only

- add a minimal enemy flag/state for `revealed_by_light`
- make hidden/blink enemy visibly render when lit
- do not tune blink weakening yet

Goal: prove reveal readability before touching enemy behavior.

### Step 3 — Blink weakening

- reduce blink distance while revealed
- add shimmer / ghost / post-blink visible linger so the weakening reads onscreen
- keep the rule simple and local to the blink enemy

Goal: prove that light changes the matchup, not just the visuals.

### Step 4 — Encounter tuning

- place or adjust one authored encounter to showcase the mechanic
- tune drain rate and reveal duration
- tune blink reduction until the effect is obvious but not trivializing

Goal: make the proof legible in under a few minutes of play.

### Step 5 — Validation and cleanup

- verify acceptance criteria in a fresh run
- document the mechanic and known limitations
- stop once the proof is readable; do not expand into a broader stealth branch

Goal: leave behind a clean, testable checkpoint rather than an overgrown half-system.

---

## Implementation guardrails

During MVP-0.3, prefer:

- simple overlap/cone checks over advanced light simulation
- one enemy proof over many enemy integrations
- explicit readable visuals over subtle realism
- short tuning loops over architecture ambition

Avoid:

- solving darkness for the whole game
- introducing system depth that only matters after content scale-up
- adding secondary flashlight mechanics just because the base proof works

---

## Exit condition

At the end of MVP-0.3, the team should be able to decide one of three things quickly:

1. **keep and expand** — flashlight reveal adds real tactical identity
2. **keep but simplify** — reveal is good, but blink weakening or energy tuning needs less complexity
3. **cut or replace** — the mechanic adds cost without enough gameplay value

That decision should come from this proof, not from a larger speculative feature plan.