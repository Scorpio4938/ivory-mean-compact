# Ivory Siren System — Implementation Guide for Mean Vehicles

> **Purpose**: This document instructs AI agents (and humans) on how to implement the Ivory siren audio system on additional Mean Emergency Vehicle Pack vehicles. It documents the proven working solution, the critical gotchas, and a step-by-step process to add new vehicles.

---

## Solution Overview

The Ivory siren system is applied to Mean vehicles via two components:

1. **Config patch** (`config.cpp`) — fixes interior audio by adding missing occlusion properties
2. **Siren script** (`fn_sirens.sqf`) — plays siren audio via dual-dummy `#particlesource` + `say3D`

### The Two Problems Solved

| Problem | Root Cause | Fix |
|---|---|---|
| Siren silent inside vehicle | Mean omits `occludeSoundsWhenIn` / `obstructSoundsWhenIn` (Ivory sets `2.5` / `1`) → engine default blocks external sounds in cabin | Config: add these properties to match Ivory |
| Audio gaps at loop boundaries | `#particlesource` cancels its own sound on each new `say3D`; scheduler jitter delays the next call | Dual-dummy alternation + per-frame `waitUntil` with overlap |

---

## Part 1: Config Patch (Interior Audio Fix)

### The Real Root Cause

⚠️ **Do NOT blame `attenuationEffectType`.** Both Ivory AND Mean set `attenuationEffectType = "CarAttenuation"` — they are identical. This was a red herring that wasted significant investigation time.

The actual difference is two properties that Ivory sets and Mean omits:

```cpp
// Ivory vehicles (ALL of them) set these:
occludeSoundsWhenIn = 2.5;    // low = external sounds pass into cabin
obstructSoundsWhenIn = 1;     // low = line-of-sight sounds pass into cabin

// Mean vehicles OMIT these → engine uses high defaults → sounds blocked inside
```

### The Config Merge Pattern (CRITICAL)

To override a property on a class defined in another addon, you must use the **matching-parent redefinition** pattern. Getting this wrong corrupts the vehicle class.

```cpp
class CfgVehicles
{
    class CRFT_Car_Base;                              // 1. Forward-declare the PARENT
    class M_CVPIbase: CRFT_Car_Base                   // 2. Redefine with SAME parent Mean uses
    {
        occludeSoundsWhenIn = 2.5;                    // 3. Add Ivory's values
        obstructSoundsWhenIn = 1;
    };
};
```

**Why this works**: When a class is redefined with a parent that *matches the existing definition's parent*, the Arma engine treats it as an **extension** and **merges** the new properties — preserving `scope`, `side`, `model`, and all of Mean's original config.

### ❌ Patterns That DO NOT Work (do not attempt)

| Pattern | Result |
|---|---|
| `class M_CVPIbase: M_CVPIbase { ... }` (self-inherit) | ❌ Build error: "inherit class does not exist" |
| `class M_CVPIbase;` then `class M_CVPIbase: M_CVPIbase { ... }` | ❌ Build error: "duplicated token or class" |
| `class M_CVPIbase { ... }` (bare, no parent) | ❌ Builds but **REPLACES** the class → loses parent → `No entry ...scope` / `.side` errors |
| Overriding `attenuationEffectType` | ❌ Wrong target — both mods have CarAttenuation |

### `requiredAddons` (REQUIRED)

```cpp
requiredAddons[] = {"Police", "Meanscars", "Ivory_Data", "cba_main"};
```

- **`"Police"`** — the actual `CfgPatches` class name in Mean's config (NOT the folder name). This ensures our addon loads AFTER Mean, so the config merge works. Without it, our class definitions load first and replace Mean's instead of merging.
- **`"Meanscars"`** — kept alongside for the build pipeline.
- **`"Ivory_Data"`** — provides the siren sounds and functions.

---

## Part 2: Siren Script (Exterior Audio)

### Architecture

```sqf
_dummyA = "#particlesource" createVehicleLocal ...;
_dummyA attachTo [_car, [0,0,0]];
_dummyB = "#particlesource" createVehicleLocal ...;
_dummyB attachTo [_car, [0,0,0]];

while {siren active} do {
    _dummy = if (_toggle) then {_dummyA} else {_dummyB};
    _dummy say3D [_siren, 300];
    _toggle = !_toggle;
    waitUntil { time >= _wakeAt || mode changed || ... };
};
```

### Why Dual-Dummy

A `#particlesource` cancels its currently playing sound whenever a new `say3D` is called on it. With a single dummy, any scheduling delay past the sound's natural end creates an audible gap. By alternating between two dummies, each one only fires every other cycle — so its previous sound has long finished before the next call.

### Why Per-Frame `waitUntil` (no `sleep`)

```sqf
// ✅ CORRECT — per-frame check, like Ivory's original code
waitUntil { time >= _wakeAt || _car getVariable "ani_siren" != _ani_siren || ... };

// ❌ WRONG — sleep 0.05 adds 66ms+ latency at 30fps → gaps
waitUntil { sleep 0.05; time >= _wakeAt || ... };
```

Mean's background scripts (`lightbar.sqf`, `Flashers.sqf`, `radar.sqf`) already consume scheduler time. Adding `sleep` compounds the jitter. The per-frame check matches Ivory's original responsiveness.

### Overlap Values

The overlap (sirenTime minus cycleTime) pre-fires the next sound before the current one ends, covering any residual jitter:

| Siren | Duration | Overlap | Cycle Time |
|---|---|---|---|
| Wail | 20.742s | 0.15s | 20.592s |
| Yelp | 5.038s | 0.10s | 4.938s |
| Priority | 9.862s | 0.10s | 9.762s |
| HiLo | 10.211s | 0.12s | 10.091s |

These assume per-frame `waitUntil`. If you reintroduce `sleep`, you'll need to roughly double these values.

---

## Part 3: Step-by-Step — Adding a New Mean Vehicle

Follow this checklist when adding siren support to a new Mean vehicle.

### Step 1: Identify the base class and its parent

```bash
# In the new vehicle's config.cpp, find the base class declaration
grep -n "class M_.*base" /path/to/mean/addons/MeansCars/NEW_VEHICLE/config.cpp
```

Expected output:
```
144:    class M_NEWbase: CRFT_Car_Base
```

- The **base class name** is `M_NEWbase`
- The **parent** is `CRFT_Car_Base` (this is standard across all Mean vehicles)

> Note: If the parent is different (not `CRFT_Car_Base`), use that parent instead. Verify it exists at line ~143 of the same config.

### Step 2: Add the config entry

Append a new block inside the existing `class CfgVehicles { ... }` in `Addons/mean_patch/config.cpp`:

```cpp
class M_NEWbase: CRFT_Car_Base
{
    occludeSoundsWhenIn = 2.5;
    obstructSoundsWhenIn = 1;
};
```

**Do NOT** change `requiredAddons[]` — `"Police"` already covers all Mean vehicles.

### Step 3: Verify the vehicle calls the siren function

Check `Addons/mean_patch/scripts/init.sqf` and `fn_initCar.sqf` — the siren function is invoked based on vehicle class names. If the new vehicle isn't picked up automatically, add it to the initialization list.

The siren script is generic — it takes a `_car` parameter and works on any vehicle that:
- Has the `ani_siren` variable set (0-4 for tone selection)
- Has the `ani_lightbar` variable set (> 0 to enable)
- Inherits from a Mean base class with the occlusion fix applied

### Step 4: Build and test

1. Build the PBO (should compile with no errors)
2. Load in-game — **no `scope`/`side` errors in RPT log** (if you see these, the config merge failed — see Troubleshooting)
3. Test exterior: siren audible outside, no gaps at loop boundaries
4. Test interior: siren audible inside the cabin (driver + passengers)
5. Test mode switching: instant silence on switch, no accumulation

---

## Troubleshooting

### `No entry 'bin\config.bin/CfgVehicles/M_NEWbase.scope'` errors

**Cause**: The base class is being REPLACED instead of MERGED. You used a bare class or the wrong parent.

**Fix**: Ensure you used the matching-parent pattern:
```cpp
class CRFT_Car_Base;                          // forward-declare parent
class M_NEWbase: CRFT_Car_Base { ... };       // SAME parent as Mean's definition
```

Verify the parent name is correct:
```bash
grep -A1 "class M_NEWbase" mean/config.cpp    # should show ": CRFT_Car_Base"
```

### Build error: "inherit class does not exist"

**Cause**: Self-inheritance (`class X: X`) or parent not declared.

**Fix**: Forward-declare the parent class, inherit from the parent (not self).

### Build error: "duplicated token or class"

**Cause**: Used forward declaration on the class itself then self-inherited.

**Fix**: Forward-declare the PARENT only, not the class being overridden.

### Siren still silent inside vehicle

**Cause**: Either the config didn't load (check RPT for errors), or `requiredAddons` is missing `"Police"`.

**Fix**:
1. Check `requiredAddons[]` includes `"Police"`
2. Verify no RPT errors on addon load
3. Confirm the exact base class name matches Mean's config

### Audio gaps at loop boundaries

**Cause**: `sleep` in `waitUntil`, or overlap too small.

**Fix**:
1. Remove any `sleep` from the inner `waitUntil`
2. Increase overlap values (add 0.05-0.10s and retest)

### Sound accumulation on mode switch

**Cause**: Using `_car say3D` instead of `#particlesource` — vehicle `say3D` cannot be cancelled.

**Fix**: Only use `#particlesource` dummies. `deleteVehicle` cancels their sound instantly on mode switch.

---

## Key Files Reference

| File | Purpose |
|---|---|
| `Addons/mean_patch/config.cpp` | Config patch — occlusion property merge for all Mean base classes |
| `Addons/mean_patch/functions/fn_sirens.sqf` | Dual-dummy siren playback loop |
| `Addons/mean_patch/functions/fn_initCar.sqf` | Per-vehicle initialization (sets up variables, calls siren) |
| `Addons/mean_patch/scripts/init.sqf` | postInit — registers vehicles |
| `ivory-mods/ivory/Addons/ivory_data/config.cpp` | Ivory siren sound definitions (`CfgSounds`) |
| `ivory-mods/ivory/Addons/ivory_data/functions/vehicle/fn_sirens.sqf` | Ivory's original siren script (reference) |

### Currently Supported Vehicles

| Base Class | Vehicle | Status |
|---|---|---|
| `M_CVPIbase` | 2011 CVPI | ✅ Working |
| `M_Charger12base` | 2012 Charger | ✅ Working |
| `M_Tahoebase` | 2015 Tahoe | ✅ Working |
| `M_Ambulancebase` | Ambulance | ✅ Working |
| `M_FPISbase` | Ford Taurus (FPIS) | ✅ Working |
| `M_Silveradobase` | Silverado | ✅ Working |

---

## Design Principles (for future work)

1. **Stay close to Ivory's original approach.** Ivory's system works well on its own vehicles. Deviations (extra `sleep`, `_car say3D`, `playSound` fallbacks) introduced more problems than they solved.

2. **Config fixes are cleaner than script workarounds.** The occlusion property merge is a one-time fix that makes the standard `#particlesource` approach work everywhere — no special-casing in SQF.

3. **Dual-dummy is the only reliable gapless approach** given the `#particlesource` single-sound cancellation behavior. Single-dummy cannot be made gapless under scheduler jitter.

4. **Per-frame `waitUntil` over `sleep`.** Any `sleep` in the timing loop compounds Mean's existing scheduler load.

5. **Verify claims empirically.** The biggest time sink in this investigation was the false claim that Ivory doesn't set `attenuationEffectType`. Always `grep` the actual config files before accepting a root-cause hypothesis.
