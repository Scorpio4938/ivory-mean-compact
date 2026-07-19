# Siren Audio Investigation Log

## Overview

Investigation into why the Ivory Car Pack's `say3D`-based siren system produces smooth audio on Ivory vehicles but exhibits gaps, glitches, and sound accumulation when applied to the Means Emergency Vehicle Pack.

---

## 2025-07-18 — Initial integration: code identical to Ivory, immediate glitching

### Finding

Our `fn_sirens.sqf` was a byte-for-byte copy of Ivory's `fn_sirens.sqf` (only change: hardcoded `_emergencySiren = 1` instead of reading from config). Despite identical code, the siren audio on Mean vehicles exhibited:

- **Abrupt cut-off** → brief silence → **restart** at every loop boundary
- Happens on ALL four tones (Wail, Yelp, Priority, HiLo)
- Occurs every loop iteration (every ~20.7s for Wail, every ~5.0s for Yelp)

### Ivory's code pattern

```sqf
_dummy = "#particlesource" createVehicleLocal ...;
_dummy attachTo [_car, [0,0,0]];

// Spawned inner loop
[_car, _siren, _sirenTime, _type, _dummy] spawn {
    while {ani_siren == _type} do {
        _timeStarted = time;
        _dummy say3D [_siren, 300];
        waitUntil { time >= _timeStarted + _sirenTime || mode changed || driver lost };
    };
};

// Outer wait
waitUntil { ani_siren != _type };
detach _dummy; deleteVehicle _dummy;
```

### Suspected root cause

Environment difference: Mean vehicle has extra scripts from its original `init` handler (`sirenscv.sqf`, `lightbar.sqf`, `Flashers.sqf`, `radar.sqf`) consuming scheduler time, introducing 1-3 frames of jitter (16-50ms). Ivory vehicles have a clean scheduler. The `#particlesource` single-sound limit means any overlap — even 1 frame — causes cancellation → gap.

---

## 2025-07-18 — Switched to `_car say3D` (direct vehicle playback)

### Change

Replaced `_dummy say3D` with `_car say3D`. Removed `#particlesource` dummy entirely.

### Result

- Accumulation on mode switch: old tones never stop playing because `_car say3D` plays to completion and cannot be cancelled
- After 3-4 tone switches, 4+ concurrent `say3D` calls all playing through `_car`
- "The audio won't normally disappear after you change to another siren"

### Why

`_car say3D` has no cancellation mechanism. Vehicle objects support multiple concurrent `say3D` calls that all mix together. There is no `stopSound` or equivalent command in Arma 3.

### Comparison of sound object types

| Property | `#particlesource` | `_car` (vehicle object) |
|---|---|---|
| Concurrent `say3D` | ❌ New cancels old | ✅ Mixes/layers |
| Stop on demand | ✅ `deleteVehicle` kills all | ❌ Plays to completion |
| Good for same-tone looping | ❌ Can't overlap | ✅ Can overlap |
| Good for mode switching | ✅ Instant silence | ❌ Lingering accumulation |
| In-car volume | Varies by attenuation | Vehicle's own audio processing |

---

## 2025-07-18 — Attempted overlap via `_car say3D` + shorter wait

### Change

Added `- 0.05s` overlap: `waitUntil { time >= _timeStarted + _sirenTime - 0.05 }`

### Result

- At 30fps, frame is ~33ms. Say3D startup latency adds unknown overhead. 
- If total ε > 0.05s, audible gap persists.
- At low frame rates (20fps, 50ms frame), gap is always present.
- The overlap also caused: "the 2nd audio overlaps with the previous on-going one"

### Gap calculation

```
Frame 0:    _car say3D [siren1, 300]    ← sound starts, ends at T+20.742
            waitUntil { time >= T + 20.742 - 0.05  ||  mode change }

Frame ~N:   time >= T+20.692  →  waitUntil exits
            while condition: ani_siren == 1 → true → loops back
            _car say3D [siren1, 300]    ← second sound starts at ~T+20.692+ε
            Previous sound ends at      T+20.742
```

Gap = `ε - 0.05s`. At 30fps (ε ≈ 33ms), gap ≈ 0ms (borderline). At 20fps (ε ≈ 50ms), gap ≈ 0ms (barely). But say3D startup latency adds unpredictable overhead.

---

## 2025-07-18 — Increased overlap to 0.3s on `_car say3D`

### Change

`waitUntil { time >= _timeStarted + _sirenTime - 0.3 }`

### Result

- Gap eliminated but... "the overlap time make the sound conflict between transition"
- "when in yelp, the 1 sound file part is 'going down', the overlapped sound could be 'going up'"
- Old tone and new tone played simultaneously for 0.3s → audible phase conflict
- Fine-tuning the overlap was described as "way too complicated"

### Root cause of conflict

With `_car say3D`, the old `say3D` call (0.3s remaining) and the new `say3D` call (just started) mix concurrently. The audio files are long-form recordings (~5-20s), not single-cycle clips. The 0.3s overlap captures different waveform phases: the end of one tone cyclically conflicts with the start of another.

---

## 2025-07-18 — Workflow investigation: dual-dummy particlesource

### Finding from multi-agent analysis

The `#particlesource` single-sound limit is the primary root cause. Every new `say3D` on a particlesource **cancels** the previous one. This is a strict Arma engine behavior — not configurable.

### Design of dual-dummy approach

- Two `#particlesource` dummies (A and B) at `[0,0,0]`
- Each dummy has its own single-sound limit
- Alternating: A plays, then B plays, then A plays again
- The offset is `_sirenTime - 0.08` (0.08s before current sound ends)
- Mode switch: `deleteVehicle` on both dummies → instant silence → new dummies for new tone

### Correct timing trace (full cycle, not half)

```
T+0:       A says sound (20.742s) → ends T+20.742
T+20.662:  B says sound (20.742s) → ends T+41.404
T+41.324:  A says sound (20.742s) → A's previous ended T+20.742. No cancel.
T+62.048:  B says sound (20.742s) → B's previous ended T+41.404. No cancel.
```

Each dummy fires every `2 × (_sirenTime − 0.08)` seconds. Each sound completes before its dummy fires again. No cancellation within a dummy.

---

## 2025-07-19 — Initial implementation had half-cycle bug

### Bug

Used `_halfCycle = _sirenTime * 0.5` instead of `_cycleTime = _sirenTime - 0.08`.

### Consequence

For wail (20.742s): halfCycle = 10.371s. Dummy A fired at T+0, then again at T+20.582. But A's first sound lasts 20.742s. The second fire at T+20.582 cancels the first sound at T+20.582 (0.16s early). Gap.

Additionally, the transition point was at the wrong time — the overlap started at the half-cycle mark (10.371s) while the actual gap is at the full cycle mark (20.742s).

---

## 2025-07-19 — Fixed to full-cycle timing

### Change

`_cycleTime = _sirenTime - 0.08` (was `_halfCycle = _sirenTime * 0.5`)

### Result

"the result is so-so, the audio gap is there but smaller"

---

## Persistent unknowns

| Question | Status |
|---|---|
| What is the exact `say3D` audio-pipeline startup latency? | Not measured. Varies by engine load. |
| What is the actual `.ogg` file duration for each Ivory siren tone? | `_sirenTime` values: 20.742, 5.038, 9.862, 10.211. These are claimed to match Ivory's files, but we couldn't verify the actual file durations. |
| Does `CfgMusic` (with duration metadata) provide better loop accuracy than `CfgSounds`? | The research found `CfgMusic` has explicit `duration` field, suggesting the engine CAN manage track duration. Switching siren audio to `CfgMusic` might enable engine-managed seamless looping. This was NOT tested. |
| What is the frame-time jitter range on the specific hardware running the game? | Not measured directly. Depends on CPU, other mods, mission complexity. |

---

## External research references

- KillzoneKid blog: [some-of-the-goodies-heading-for-1-50/](https://killzonekid.com/some-of-the-goodies-heading-for-1-50/) — CfgSounds update
- KillzoneKid blog: [tracks2config-and-sound_duration/](https://killzonekid.com/tracks2config-and-sound_duration/) — CfgMusic duration field
- **No known community solution** for gapless `say3D` looping exists in public Arma modding documentation

---

## Summary

The `#particlesource` single-sound limit is the fundamental constraint. It makes Ivory's approach brittle — requiring sub-frame scheduling precision that only works in a clean script environment. On Mean vehicles, background scripts introduce enough jitter to break the timing. The dual-dummy approach minimizes but cannot eliminate the gap because SQF timers + `say3D` startup latency have non-zero, unpredictable overhead.

A true gapless solution would likely require switching from `CfgSounds` to `CfgMusic` (using the engine's native duration management), using a different audio API (like `createSoundSource` if available), or relying on Bohemia exposing native gapless audio features.
