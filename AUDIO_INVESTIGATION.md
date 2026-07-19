# Siren Audio Investigation Log

## Overview

Investigation into why the Ivory Car Pack's `say3D`-based siren system produces smooth audio on Ivory vehicles but exhibits gaps, glitches, and sound accumulation when applied to the Means Emergency Vehicle Pack.

---

## Part 1: The Gap Problem (exterior audio)

### Root Cause: `#particlesource` single-sound limit

The Arma 3 engine imposes a strict constraint on `#particlesource` entities: **every `say3D` call on the same `#particlesource` object instantly cancels any currently playing sound**. This is engine-level behavior, not configurable.

Ivory's original code uses a single `#particlesource` dummy attached to the car at `[0,0,0]`. The SQF loop calls `say3D`, waits exactly `_sirenTime`, then calls `say3D` again. On a clean scheduler, the gap between "sound ends" and "next `say3D` fires" is ~1 frame (~16ms at 60fps) — barely perceptible.

On Mean vehicles, the `init` handler loads background scripts (`lightbar.sqf`, `Flashers.sqf`, `radar.sqf`) that run continuous `while` loops with frequent `sleep` calls. These consume scheduler time, introducing **2-4 frames of jitter (33-66ms at 30fps)**. The gap becomes clearly audible.

### Solution: Dual-dummy `#particlesource`

Two `#particlesource` dummies (A and B) alternate. Each dummy fires once every `2 × (sirenTime - offset)` seconds. Since each sound is `sirenTime` seconds long, no single dummy ever receives a new `say3D` while its previous sound is still playing. This avoids cancellation.

The overlap offset compensates for scheduler jitter:
- Dummy B fires `_sirenTime - offset` after dummy A
- If offset > jitter, B starts before A ends → seamless
- If offset < jitter, B starts after A ends → gap

### .wav Duration Verification

The actual Ivory siren `.wss` files were decoded to `.wav` and measured. All hardcoded `_sirenTime` values match exactly:

| Sound | Hardcoded `_sirenTime` | Actual `.wav` duration | Match |
|---|---|---|---|
| Wail | 20.742s | 20.742s | ✅ |
| Yelp | 5.038s | 5.038s | ✅ |
| Priority | 9.862s | 9.862s | ✅ |
| HiLo | 10.211s | 10.211s | ✅ |
| Airhorn | 9.932s | 9.932s | ✅ |

File duration mismatch is ruled out. The gap is purely scheduler jitter.

### Waveform Correlation Analysis

To determine if overlap causes audible phase conflict, tail-vs-head correlation was measured at various overlaps. Correlation = 1 means identical waveform (perfect overlap), -1 means opposite (cancellation), 0 means uncorrelated.

| Tone | 0.02s | 0.05s | 0.08s | 0.15s | 0.20s | 0.30s |
|---|---|---|---|---|---|---|
| Wail | -0.88 | -0.22 | -0.19 | -0.02 | -0.17 | -0.06 |
| Yelp | 0.56 | -0.10 | -0.02 | 0.01 | 0.00 | -0.02 |
| Priority | -0.17 | 0.01 | -0.09 | -0.14 | 0.09 | 0.07 |
| HiLo | -0.01 | 0.03 | 0.01 | 0.06 | 0.05 | -0.08 |

**Finding**: At any overlap ≥ 0.05s, all four tones are uncorrelated (near zero). Phase conflict from overlap is not a concern. The only exception is Wail at 0.02s (strongly out of phase).

### Final Overlap Values (empirically tuned)

| Siren | Duration | Overlap | Fire interval | Notes |
|---|---|---|---|---|
| 1 — Wail | 20.742s | **0.35s** | every 20.392s | Longest cycle, most jitter exposure |
| 2 — Yelp | 5.038s | **0.15s** | every 4.888s | Short cycle, minimal jitter |
| 3 — Priority | 9.862s | **0.15s** | every 9.712s | Medium cycle |
| 4 — HiLo | 10.211s | **0.25s** | every 9.961s | Quieter tail (RMS=0.13), needs more margin |

Wail at 0.35s was needed because `sleep 0.05` at 30fps actually takes ~66ms (2 frames) per check, and `say3D` startup latency adds unknown overhead. The effective overlap was much less than 0.20s.

### SQF `sleep` Granularity

`sleep 0.05` in SQF has frame-level granularity. At 30fps (33ms per frame):
- `sleep 0.05` actually sleeps ~66ms (2 frames minimum)
- The `waitUntil` check fires every ~66ms, not every 50ms
- Worst case: condition becomes true 1ms after a check → next check is 66ms later → 66ms added jitter
- Plus 1-2 frames of scheduler reschedule delay (33-66ms) from Mean background scripts

Total worst-case delay: ~100-130ms from the `sleep` mechanism alone, plus unknown `say3D` startup latency.

### Stationary vs Moving Gap Difference

The gap is more audible when the vehicle is **stationary** (engine off/idle) vs **driving**. Two likely factors:

1. **Audio masking**: Engine and road noise fills the brief gap when driving. Stationary, the siren is the only audio source so any silence stands out.

2. **Scheduler behavior**: When driving, the game engine runs at full rate (physics, audio active). When stationary idle, the engine may consolidate or de-prioritize scheduler ticks, making `sleep` wake-ups less consistent.

---

## Part 2: The Interior Audio Problem

### Problem

Players inside Mean vehicles (1st person / interior view) cannot hear the siren from the `#particlesource` dummy. It is audible from 3rd person and outside the vehicle.

### Root Cause: `attenuationEffectType = "CarAttenuation"`

The Mean vehicle base classes define:
```cpp
attenuationEffectType = "CarAttenuation";  // line 197 in each vehicle config
```

This tells Arma's audio engine to apply **car sound dampening** to all external sound sources when the listener is inside the vehicle cabin. The `#particlesource` dummy is treated as an external sound source, regardless of being attached at `[0,0,0]` — so it gets muffled to near-silence inside.

**Ivory vehicles do NOT set this property**, which is why the same `#particlesource` approach works for interior audio on Ivory but not on Mean.

The property is set on all 6 Mean base classes:

| Class | File |
|---|---|
| `M_CVPIbase` | `MeansCars/2011_CVPI/config.cpp:197` |
| `M_Charger12base` | `MeansCars/2012_Charger/config.cpp:197` |
| `M_Tahoebase` | `MeansCars/2015_Tahoe/config.cpp:197` |
| `M_Ambulancebase` | `MeansCars/Ambulance/config.cpp:197` |
| `M_FPISbase` | `MeansCars/Ford_Torus/config.cpp:197` |
| `M_Silveradobase` | `MeansCars/Silverado/config.cpp:197` |

### Attempted Fix: Config Override (FAILED)

Attempted to override `attenuationEffectType` on all 6 Mean base classes via `CfgVehicles` in our patch `config.cpp`. All three Arma 3 config syntaxes were tried:

1. **Inherit**: `class M_CVPIbase: M_CVPIbase { attenuationEffectType = "DefaultAttenuation"; };`
   - Error: `"inherit class 'M_CVPIbase' does not exist"`
   - MakePBO cannot resolve the parent class from the `requiredAddons` chain

2. **Forward declaration + inherit**:
   ```
   class M_CVPIbase;
   class M_CVPIbase: M_CVPIbase { attenuationEffectType = "DefaultAttenuation"; };
   ```
   - Error: `"duplicated token or class"`
   - MakePBO treats the forward declaration as a class definition, then sees the inheritance as a duplicate

3. **Bare redefinition**: `class M_CVPIbase { attenuationEffectType = "DefaultAttenuation"; }`
   - Builds, but **corrupts the class at runtime** — loses the `: CRFT_Car_Base` inheritance chain, vehicle disappears from editor

**All config override approaches are impossible with MakePBO.** There is no SQF script command to change `attenuationEffectType` at runtime.

### Attempted Fix: `_car say3D` (FAILED)

Playing the siren directly on the vehicle object bypasses `CarAttenuation` because the sound source IS the vehicle itself. However, `_car say3D` cannot be cancelled — each call plays to completion. On every loop iteration, a new call stacks on top of the previous. After several tone switches, multiple different siren sounds play simultaneously inside the car with no way to stop them.

### Attempted Fix: `player/crew say3D` (FAILED)

Playing `say3D` on each vehicle occupant so the sound originates from inside the cabin. Same inability to cancel — sound accumulates with each loop iteration and mode switch.

### Solution: `playSound` for Driver Interiors

```sqf
_dummy say3D [_siren, 300];                              // exterior — dual-dummy, cancellable
if (driver _car == player) then { playSound [_siren, 1.0]; };  // interior — 2D, no accumulation
```

`playSound` is a 2D command — it ignores 3D positioning and `CarAttenuation`. It plays at full volume regardless of listener position. Critically, calling `playSound` again **replaces** the previous call (no accumulation). Limited to the driver only for simplicity.

---

## Current Architecture Summary

### `fn_sirens.sqf` — final state

| Component | Mechanism | Cancellable | Accumulation |
|---|---|---|---|
| Exterior audio | Dual-dummy `#particlesource` + `say3D` | ✅ `deleteVehicle` | ✅ None |
| Interior audio | `playSound` (driver only) | ✅ Replaces previous | ✅ None |
| Mode switching | `deleteVehicle` kills exterior instantly | ✅ | N/A |

### Overlap values per tone

| Tone | Overlap | Cycle time |
|---|---|---|
| Wail (20.742s) | 0.35s | 20.392s |
| Yelp (5.038s) | 0.15s | 4.888s |
| Priority (9.862s) | 0.15s | 9.712s |
| HiLo (10.211s) | 0.25s | 9.961s |

### Known limitations

| Issue | Status |
|---|---|
| Interior audio for passengers | Not covered — `playSound` only for driver |
| Scheduler jitter from Mean background scripts | Compensated by dual-dummy overlap |
| `say3D` startup latency | Unknown, compensated by generous overlap margins |
| Config override for `CarAttenuation` | Impossible with MakePBO — all syntaxes fail |
| Stationary vs moving gap difference | Likely audio masking + scheduler behavior; overlap handles worst case |
