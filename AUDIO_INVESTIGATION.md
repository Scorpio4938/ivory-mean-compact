# Siren Audio Investigation Log

## Overview

Investigation into why the Ivory Car Pack's `say3D`-based siren system produces smooth audio on Ivory vehicles but exhibits gaps and interior silence when applied to the Means Emergency Vehicle Pack.

---

## Part 1: The Interior Silence Problem (SOLVED)

### Root Cause: Missing `occludeSoundsWhenIn` / `obstructSoundsWhenIn`

**The previous investigation was WRONG.** It blamed `attenuationEffectType = "CarAttenuation"` for interior silence, claiming Ivory vehicles don't set it. This is false — **all 28 Ivory addons AND all 6 Mean vehicles set `attenuationEffectType = "CarAttenuation"`**. They are identical in this regard.

The **real difference** is two properties that Ivory sets and Mean omits:

| Property | Ivory (all vehicles) | Mean (all vehicles) | Effect |
|---|---|---|---|
| `attenuationEffectType` | `"CarAttenuation"` | `"CarAttenuation"` | Same — NOT the cause |
| `occludeSoundsWhenIn` | **2.5** | **NOT SET** | Controls sound occlusion (geometry blocking) when listener is inside. Low = sounds pass through. Default (when unset) = high = sounds blocked. |
| `obstructSoundsWhenIn` | **1** | **NOT SET** | Controls sound obstruction (line-of-sight) when inside. Same logic. |

Ivory explicitly sets these to **low values**, allowing external sound sources (`#particlesource` siren dummy) to pass through into the cabin. Mean omits them → engine uses high defaults → `#particlesource` siren is blocked inside.

This explains everything:
- **Ivory siren audible inside Ivory**: low occlude/obstruct → sound passes through
- **Ivory siren silent inside Mean**: high default occlude/obstruct → sound blocked
- **Mean's own `_vcl say3D` works inside**: vehicle-sourced sounds bypass occlusion (same-entity classification)

### Fix: Config Override via Bare-Class Merge

```cpp
class CfgVehicles
{
    class M_CVPIbase
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    // ... repeat for all 6 Mean base classes
};
```

**Why this syntax works (and previous attempts didn't):**

| Attempt | Syntax | Result |
|---|---|---|
| 1. Self-inherit | `class M_CVPIbase: M_CVPIbase { ... }` | ❌ "inherit class does not exist" — creates a subclass, not a merge |
| 2. Forward decl + self-inherit | `class M_CVPIbase;` then `class M_CVPIbase: M_CVPIbase { ... }` | ❌ "duplicated token or class" |
| 3. Bare class (no "Police") | `class M_CVPIbase { ... }` | ❌ Corrupted class — wrong load order (loaded before Mean) |
| **4. Bare class + "Police"** | `class M_CVPIbase { ... }` with `requiredAddons[] = {"Police", ...}` | ✅ Merges correctly — preserves CRFT_Car_Base parent |

The key: `class X { ... }` (bare, no parent) MERGES properties into the existing class. `class X: X { ... }` creates a subclass. "Police" in `requiredAddons` ensures our addon loads AFTER Mean, so the merge preserves the original parent.

---

## Part 2: The Exterior Gap Problem

### Root Cause: `#particlesource` single-sound limit + scheduler latency

The Arma 3 engine cancels any currently playing sound when a new `say3D` is called on the same `#particlesource`. If the next call fires even 1 frame after the sound ends, there's an audible gap.

Contributing factors on Mean vehicles:
- Background scripts (`lightbar.sqf`, `Flashers.sqf`, `radar.sqf`) consume scheduler time
- Our previous code added `sleep 0.05` to `waitUntil`, adding 66ms+ latency at 30fps

### Fix: Dual-dummy alternation + per-frame waitUntil

**Dual-dummy**: Two `#particlesource` dummies (A/B) alternate. Each fires every `2 × (sirenTime - overlap)`. No single dummy receives a new `say3D` while its previous sound plays → no cancellation.

**Per-frame waitUntil** (no `sleep`): Checks every frame like Ivory's original code. At 60fps, checks every 16ms. Much more responsive than `sleep 0.05` (66ms).

```sqf
private _wakeAt = time + _cycleTime;
waitUntil {
    time >= _wakeAt || _car getVariable "ani_siren" != _ani_siren || ...
};
```

### .wav Duration Verification

All Ivory siren `.wss` files decoded to `.wav` and measured. Hardcoded `_sirenTime` values match exactly:

| Sound | Hardcoded `_sirenTime` | Actual `.wav` duration | Match |
|---|---|---|---|
| Wail | 20.742s | 20.742s | ✅ |
| Yelp | 5.038s | 5.038s | ✅ |
| Priority | 9.862s | 9.862s | ✅ |
| HiLo | 10.211s | 10.211s | ✅ |

### Waveform Correlation Analysis

Tail-vs-head correlation measured at various overlaps. At any overlap ≥ 0.05s, all four tones are uncorrelated (near zero). Overlap phase conflict is not a concern.

### Final Overlap Values (with per-frame waitUntil)

| Siren | Duration | Overlap | Notes |
|---|---|---|---|
| 1 — Wail | 20.742s | 0.15s | Longest cycle, most jitter exposure |
| 2 — Yelp | 5.038s | 0.10s | Short cycle |
| 3 — Priority | 9.862s | 0.10s | Medium cycle |
| 4 — HiLo | 10.211s | 0.12s | Quieter tail |

These are smaller than the previous values (which compensated for `sleep 0.05` latency). Per-frame `waitUntil` is much more responsive, needing less overlap margin.

---

## Current Architecture

| Component | Mechanism | Why |
|---|---|---|
| Interior audio | Config: `occludeSoundsWhenIn=2.5, obstructSoundsWhenIn=1` | Matches Ivory — allows `#particlesource` through cabin |
| Exterior audio | Dual-dummy `#particlesource` + `say3D` with overlap | Gapless, cancellable on mode switch |
| Mode switching | `deleteVehicle` kills both dummies | Instant silence, no accumulation |
| Loop timing | Per-frame `waitUntil` (no `sleep`) | Matches Ivory's responsiveness |

### What was removed
- ~~`playSound` fallback~~ — no longer needed; config fix makes `#particlesource` audible inside
- ~~`sleep 0.05` in waitUntil~~ — was causing 66ms+ latency → gaps
- ~~`attenuationEffectType = "DefaultAttenuation"` override~~ — wrong target; both mods use CarAttenuation

---

## Key Files

| File | Purpose |
|---|---|
| `Addons/mean_patch/config.cpp` | Config override: adds Ivory's occlude/obstruct values to Mean vehicles |
| `Addons/mean_patch/functions/fn_sirens.sqf` | Dual-dummy siren loop, per-frame waitUntil |
| `ivory-mods/ivory/Addons/ivory_*/config.cpp` | Ivory vehicle configs (reference for correct values) |
| `ivory-mods/mean/addons/MeansCars/*/config.cpp` | Mean vehicle configs (missing the values we add) |

---

## Investigation History

1. **Initial theory**: Scheduler jitter from Mean background scripts → gaps. **Partially correct** — jitter exists but was amplified by our `sleep 0.05`.
2. **Interior theory**: `attenuationEffectType = CarAttenuation` blocks `#particlesource` inside. **WRONG** — both mods have it.
3. **Corrected finding**: Missing `occludeSoundsWhenIn`/`obstructSoundsWhenIn` is the real cause. Ivory sets low values; Mean omits them. **CONFIRMED** — verified across all 28 Ivory addons and all 6 Mean vehicles.
