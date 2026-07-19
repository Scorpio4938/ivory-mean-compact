# Synthesis: Siren Audio Fix Recommendations

Based on the full investigation in `AUDIO_INVESTIGATION.md`, current code review, and findings from all phases.

---

## Issue 1: Exterior Audio Gaps at Loop Boundaries

### Root Cause

Arma 3's engine imposes a fundamental constraint on `#particlesource` entities: **every `say3D` call on the same `#particlesource` instantly cancels the previous sound**. Ivory's original single-dummy design calls `say3D` in a tight loop — the gap between "last sound ends via cancellation" and "next `say3D` fires" is normally ~1 frame. But Mean vehicles load background scripts (`lightbar.sqf`, `Flashers.sqf`, `radar.sqf`) that run continuous `while` loops with `sleep` calls, consuming scheduler time. This introduces 2–4 frames of jitter (33–66ms at 30fps, up to ~130ms worst case), making the cancellation gap clearly audible. This is **not** a `.wav` duration mismatch — every tone's hardcoded `_sirenTime` matches its actual file length exactly.

### Fix (already implemented in `fn_sirens.sqf`)

**Dual-dummy `#particlesource` alternation.** Two dummies (A and B) fire on alternating half-cycles, each firing only once every `2 × (cycleTime)` seconds. Because no single dummy ever receives a new `say3D` while its previous sound is still playing, cancellation is impossible. An overlap margin (dummy B fires `_cycleTime` after dummy A, which is `sirenDuration - overlap` seconds) compensates for scheduler jitter:

| Tone | Duration | Overlap | Effective Cycle |
|---|---|---|---|
| Wail | 20.742s | 0.35s | 20.392s |
| Yelp | 5.038s | 0.15s | 4.888s |
| Priority | 9.862s | 0.15s | 9.712s |
| HiLo | 10.211s | 0.25s | 9.961s |

Overlap values >= 0.05s produce near-zero waveform correlation (verified by FFT analysis), so no phase cancellation from overlap. Wail needs 0.35s because its longer cycle is more exposed to scheduler drift.

| File | Status |
|---|---|
| `fn_sirens.sqf` — dual-dummy alternation | ✅ Already implemented |
| `fn_sirens.sqf` — overlap values per tone | ✅ Already implemented |
| `fn_sirens.sqf` — responsive mode check via `waitUntil` | ✅ Already implemented |

---

## Issue 2: Siren Not Audible Inside Mean Vehicles

### Root Cause

A `#particlesource` dummy is treated by Arma's audio engine as an **external sound source** — even when `attachTo`'d at `[0,0,0]`. The config property `attenuationEffectType = "CarAttenuation"` (set on all 6 Mean base classes) mutes external sound sources when the listener is inside the vehicle cabin. The `#particlesource` dummy hits this filter; `say3D` directly on the vehicle (`_vcl say3D`) does not, because it originates from the vehicle object itself.

**Regarding the "both Ivory and Mean have CarAttenuation" question:** The investigation found Ivory does NOT set this property. If the user's latest check confirms both do have it, then the root cause is the same either way — `#particlesource` dummy = external source → attenuated by CarAttenuation, regardless of which vehicle it's on. The fact that Mean's own original siren uses `_vcl say3D` and IS audible inside is consistent with this explanation — `_vcl say3D` bypasses CarAttenuation because the source is the vehicle object.

### Fix (partially implemented)

**Two-prong approach, already in current code:**

1. **Exterior** (existing `#particlesource` + `say3D`) — unchanged, handles everyone outside the vehicle.
2. **Interior/driver** — `playSound` is a 2D command that ignores 3D positioning and CarAttenuation entirely. It plays at full volume regardless of listener position. Crucially, calling `playSound` again **replaces** the previous call (no accumulation like `say3D`). Limited to driver only for simplicity.

The current `fn_sirens.sqf` already includes:
```sqf
if (driver _car == player) then { playSound [_siren, 1.0]; };
```

### Config override for `attenuationEffectType` — IMPOSSIBLE

All three MakePBO syntaxes were tried. All fail (inherit-from-nonexistent, duplicate-token, or runtime class corruption). There is no SQF command to change `attenuationEffectType` at runtime. `playSound` is the only viable approach.

| Approach | Result |
|---|---|
| Config override `M_CVPIbase { attenuationEffectType = "DefaultAttenuation"; }` | ❌ MakePBO can't resolve external parent classes |
| Forward declaration + inherit | ❌ Duplicate token error |
| Bare redefinition | ❌ Corrupts class at runtime |
| SQF runtime change | ❌ No command exists |
| `_car say3D` | ❌ Not cancellable — sounds accumulate |
| `playSound` for driver | ✅ Works, cancellable, bypasses CarAttenuation |

---

## Current Code Status

| Component | File | Status |
|---|---|---|
| Config CPP | `config.cpp` | ✅ CfgPatches, CfgFunctions set up correctly |
| Init bridge | `fn_initCar.sqf` | ✅ Guards double-init, sets vars, spawns siren + horn |
| Siren audio | `fn_sirens.sqf` | ✅ Dual-dummy + playSound, but see risks below |
| Horn audio | `ivory_fnc_horn` | ✅ Reused from Ivory |
| Keybinds | `init.sqf` | ✅ CBA keybinds with MEAN_DRIVER_GATE |
| Read Manual | `fn_manual.sqf` | ✅ Scroll-wheel action + backslash keybind |
| Class events | `init.sqf` | ✅ CBA_addClassEventHandler for CVPI (other models? see below) |

---

## Critical Gap: Only CVPI has the init handler

The `init.sqf` uses `CBA_fnc_addClassEventHandler` only for `"M_CVPI"`. The other 5 vehicle models (Charger, Tahoe, FPIS/Taurus, Ambulance, Silverado) are **not registered**. This means only CVPI variants get the siren patch — all other Mean vehicles fall back to their original siren system.

This also explains why the exterior gap was noticed: the init handler only fires for CVPI, so investigator likely only tested CVPI. The gap findings are correct for CVPI but untested on other models.

---

## Risks & Concerns

| Risk | Severity | Mitigation |
|---|---|---|
| Only CVPI registered in `CBA_fnc_addClassEventHandler` | **HIGH** — 31/37 vehicles don't get the patch | Register all 6 base classes in `init.sqf` |
| `playSound` driver-only — passengers hear nothing inside | Medium | Acceptable limitation for v1; future enhancement could use `say2D` or per-occupant `playSound` |
| `playSound` uses Arma's individual sound setting (SFX volume), not vehicle audio | Low | User's SFX volume control already governs all game sounds |
| Dual-dummy creates 2 `#particlesource` entities per vehicle — memory/performance at scale | Low | Entities are lightweight; deleteVehicle cleans up on mode switch/exit |
| CBA keybind gate macros duplicate vehicle type list in multiple closures | Low | Refactor into a single `isMeanVehicle` function |

---

## Recommended Next Steps

1. **Add class event handlers for all 6 models** in `init.sqf` (CVPI, Charger, Tahoe, FPIS, Ambulance, Silverado)
2. **Test stationary gap** on each model at 30fps to confirm dual-dummy overlap values are sufficient
3. **Test interior audibility** using `playSound` — verify volume balance between interior `playSound` and exterior `say3D`
4. **Test mode switching** (tone changes, on→off→on) to verify `deleteVehicle` cleanup is instant and no phantom audio remains
5. **Consider `playSound` volume tuning** — `1.0` may be too loud or too quiet relative to exterior; test with different volume levels
