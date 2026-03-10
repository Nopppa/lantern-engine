# MVP-0.3 Flashlight Reveal — Implementation Report

**Date:** 2026-03-10
**Status:** ✅ Implemented and built

## What was implemented

### 1. Toggleable Flashlight (F key)
- Player presses **F** to toggle flashlight on/off
- Flashlight projects a visible **cone/arc** (28° half-angle, 260px range) in the player's facing direction
- Cone follows mouse aim in real-time
- Visual: warm yellow translucent cone with edge lines and arc

### 2. Continuous Energy Drain
- Flashlight drains **14 energy/sec** while active
- Auto-disables when energy hits 0
- Competes with beam cost (25 energy per shot) — creates real tradeoff
- At max energy (100), continuous uptime ~7 seconds — supports short tactical bursts

### 3. No Damage
- Flashlight deals zero damage — purely informational/tactical tool

### 4. Hollow Blink-Enemy Reveal Behavior
- **Outside flashlight:** Hollow blinks normally (teleports ~140px behind player with ±80px randomness)
- **Inside flashlight cone:**
  - Blink distance reduced to **~45% of normal** (63px vs 140px)
  - Random scatter halved (±40px instead of ±80px)
  - Post-blink **shimmer timer** (0.6s visible linger with pulsing golden aura)
  - Enemy marked as `revealed_by_light` — renders with animated golden shimmer ring
- Effect is **partial suppression**, not hard-disable — hollows remain threats

### 5. Visual Feedback
- **Cone rendering:** warm yellow polygon with edge lines and arc outline
- **Reveal shimmer:** pulsing golden aura + ring on revealed hollows (sin-wave animation)
- **HUD:** Flashlight ON/OFF status with drain rate shown
- **Event log:** Clear messages for flashlight toggle, energy depletion, weakened blink

### 6. Flashlight-Focused Encounter
- Added **Encounter 4:** 3 hollows — designed to showcase flashlight value
- All-hollow encounter makes flashlight the obvious tactical choice

## Files Modified

| File | Change |
|------|--------|
| `scripts/run_scene.gd` | Flashlight state, cone logic, reveal check, hollow blink weakening, cone drawing, shimmer rendering, HUD update |
| `scripts/data/encounter_defs.gd` | Added encounter 4 (3× hollow) |
| `project.godot` | Added `toggle_flashlight` input action (F key) |
| `docs/mvp0.3-flashlight-reveal-implementation.md` | This file |

## Build

- **Location:** `build/linux/lantern_engine-linux-v0.3.0.tar.gz`
- **Headless import:** ✅ Clean (no errors)
- **Export:** ✅ Successful (Linux/X11 debug)

## How It Works In Practice

1. Player enters encounter with hollows
2. Hollows blink/teleport aggressively — hard to track
3. Player presses F — flashlight cone appears
4. Any hollow inside the cone gets golden shimmer + weakened blink
5. Player can now track and beam the hollow more reliably
6. Energy drains steadily — player must decide when to conserve
7. Letting flashlight run too long = no energy for beam shots

## Intentionally Deferred

- No shadow casting / physical light simulation
- No flashlight damage/stun/burn effects
- No battery pickups or recharge economy
- No moth flashlight sensitivity (only hollows react)
- No shader-based cone (uses simple polygon drawing)
- No enemy perception/suspicion system
- No progression/upgrade integration for flashlight
- No darkness-as-pillar level design
