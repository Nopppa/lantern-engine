# Lantern Engine — Playtest 02 Analysis Frame

Purpose: turn v0.2.0 hands-on feedback into a clear production decision for the next iteration.

Build under test: v0.2.0
Focus areas:
- beam feel
- prism + bounce logic
- immortality toggle as test tool
- lighting / lit-zone readability

## 1) How feedback is classified

Classify every observation into one primary bucket first. Add a secondary bucket only if needed.

### A. Feel / responsiveness
Use when the player is reacting to moment-to-moment handling.

Examples:
- beam feels too slow / too sticky / too weak / too noisy
- fire cadence, pulse duration, hit clarity, impact timing
- aiming, movement, recovery, readability of attack result

Question this bucket answers:
- does the core action feel good enough to repeat for minutes at a time?

### B. System correctness
Use when expected gameplay rules break, behave inconsistently, or are hard to trust.

Examples:
- prism redirect works only sometimes
- bounce chain breaks after prism interaction
- angle logic is surprising in a way that feels buggy, not interesting
- lit zones do not match actual gameplay outcome

Question this bucket answers:
- can the player form stable mental rules and rely on them?

### C. Test friction / debugging support
Use when feedback is blocked by the tester fighting the prototype instead of evaluating it.

Examples:
- immortality toggle missing, unclear, or awkward to use
- reset/retry loop too slow
- cannot isolate prism logic because death or setup cost interrupts testing

Question this bucket answers:
- are we getting valid signal, or is tooling noise contaminating the playtest?

### D. Readability / communication
Use when the system may technically work, but the player cannot read it confidently.

Examples:
- hard to tell where light reaches
- lit vs unlit state is ambiguous
- bounce path is hard to parse visually
- prism result is correct but not legible in motion

Question this bucket answers:
- can the player understand what happened quickly enough to play well?

### E. World interaction potential
Use when feedback points beyond current combat proof and toward light affecting the world.

Examples:
- player wants light to activate, heal, reveal, transform, or restore something
- lighting feels like it should matter beyond damage and visibility
- prototype suggests a stronger environmental rule than currently implemented

Question this bucket answers:
- is the next highest-value proof about the world reacting to light?

### F. Content hunger
Use when the core loop is understood and working, and the tester is mainly asking for more situations.

Examples:
- more arenas, more encounter types, more prism setups
- wants additional enemy variety after current rules already feel solid
- asks for more challenge, progression, or authored scenarios

Question this bucket answers:
- are we ready to scale content instead of refining fundamentals?

## 2) Decision rules for the next step

Pick the next track based on dominant feedback, not on isolated comments.

### Choose FEEL-POLISH next if...
- most issues fall under Feel / responsiveness or Readability
- tester understands the mechanic, but moment-to-moment use is not satisfying yet
- prism+bounce mostly works, but the game still feels mushy, unclear, or low-impact
- debug tooling is sufficient to keep testing efficiently

Typical trigger phrases:
- "works, but doesn’t feel good"
- "hard to read in motion"
- "beam should be snappier / clearer / punchier"

Recommended output of this track:
- beam timing polish
- VFX/SFX/readability adjustments
- lit-zone clarity improvements
- small control/feedback tuning, not new systems

### Choose WORLD-INTERACTION PROOF next if...
- core beam/prism/bounce loop is understandable and reliable enough
- feedback repeatedly points to light needing a stronger purpose beyond attack/readability
- tester starts proposing environmental reactions more than control fixes
- the most exciting opportunity is proving that light changes the world state

Gate before choosing this:
- no major system-correctness bugs in prism+bounce logic
- readability is good enough that a new interaction can be evaluated cleanly

Recommended output of this track:
- one small but undeniable world reaction to light
- e.g. revive/activate/reveal/grow/open, but only one proof at first
- keep scope narrow: one interaction family, one authored test case, one success condition

### Choose CONTENT EXPANSION next if...
- feel is already acceptable for repeated play
- prism+bounce logic is reliable and trusted
- lighting readability is clear enough that confusion is no longer a dominant complaint
- tester mostly wants more situations, combinations, challenge, or variety

Gate before choosing this:
- no blocking correctness bug in core interaction chain
- no major request for beam-feel repair
- no major test-friction complaint preventing valid playtest signal

Recommended output of this track:
- more rooms / encounters / authored prism puzzles
- extra enemy or obstacle variants
- broader scenario coverage using already-proven rules

## 3) Suggested priority order

Default priority for Playtest 02 analysis:

1. **System correctness first**
   - If prism+bounce trust is broken, do not move to new content or broader world systems.
   - Rule: unreliable rules invalidate downstream feedback.

2. **Readability + feel second**
   - If the system works but is hard to read or lacks punch, polish before expansion.
   - Rule: the player must be able to parse and enjoy the core loop.

3. **Test friction third**
   - Keep immortality toggle and related debug aids good enough to accelerate iteration.
   - Rule: cheap test loops increase signal quality, but they do not replace fixing the core.

4. **World-interaction proof fourth**
   - Move here once core beam/prism/bounce is reliable and readable.
   - Rule: prove one meaningful world reaction before building lots of content around it.

5. **Content expansion last**
   - Only after the team can answer: "why is this mechanic fun and what does light do in this world?"
   - Rule: do not scale uncertainty.

## Quick scoring shortcut

After the playtest, score each bucket:
- 0 = no issue / no demand
- 1 = minor note
- 2 = recurring concern or clear opportunity
- 3 = dominant finding / blocks next phase

Then use this readout:
- If **System correctness** is 3 -> next step = **feel-polish/correctness pass**, not expansion
- Else if **Feel** + **Readability** combined >= 4 -> next step = **feel-polish**
- Else if **World interaction potential** >= 2 and correctness/readability are stable -> next step = **world-interaction proof**
- Else if **Content hunger** is the highest score and all core buckets are <= 1 -> next step = **content expansion**
- If **Test friction** is 2-3, add debug/tooling fixes into the next build regardless of main track

## Recommended default interpretation bias

For v0.2.0, bias decisions in this order unless Playtest 02 strongly disproves it:
1. stabilize prism+bounce trust
2. improve beam and lighting readability/feel
3. preserve/improve immortality toggle for fast testing
4. prove one small world interaction with light
5. only then expand content breadth

## Output template for the actual Playtest 02 write-up

- Raw feedback
- Interpreted findings by bucket
- Bucket scores (0-3)
- Dominant risk
- Dominant opportunity
- Decision: feel-polish / world-interaction proof / content expansion
- Immediate next-build actions (max 5)
- Explicitly postponed items
