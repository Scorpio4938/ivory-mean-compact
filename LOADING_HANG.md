# Loading Screen Hang — Diagnostic Report

## Status

**Unresolved.** Staggered spawn works but introduces siren delay. Reverted.

---

## Symptom

When all 37 Mean vehicles are placed on the same map and the mission loads, the loading screen hangs (progress stops, game never enters playable state). With a single vehicle, loading completes normally.

This was introduced in ticket 02 when we expanded the CBA init override from a single class (`M_CVPI`) to all 37 concrete classes via 6 base class registrations.

---

## Root Cause

Each Mean vehicle triggers our CBA `init` handler (via `CBA_fnc_addClassEventHandler` registered on the 6 base classes). The handler fires `_car spawn mean_patch_fnc_initCar`, which spawns 3 functions:

- `mean_patch_fnc_horn`
- `mean_patch_fnc_sirens`
- `mean_patch_fnc_takedown`

37 vehicles × 3 functions = **111 concurrent spawned threads** during mission loading. Each thread enters an idle loop:

```sqf
waitUntil {sleep 0.01; !alive _car || (condition) ...};
```

During the loading screen, Arma's SQF VM pauses — all spawned scripts are queued. When loading completes, all 111 threads wake up **simultaneously** in the same frame. The SQF scheduler processes them sequentially, but the burst of thread activation competes with:

- Vanilla Mean scripts (4 per vehicle = 148 more threads)
- Other addons' scripts
- The mission's own init

This overwhelms the scheduler and manifests as a loading screen hang.

Additionally, vanilla Lightbar.sqf uses `setObjectTexture` with `sleep 0.05-0.2` intervals. With 37 × 1 = 37 lightbar loops (not 37 × 4 = 148 because we're registering on base classes alongside vanilla init), the scheduler contention during initial burst is significant.

### Why it doesn't happen in Ivory

- Ivory doesn't have 37+ vehicles spawning on a single map by default
- Each Ivory vehicle addon is independent; CBA handlers are registered per-vehicle-class, not propagated via base classes
- The original Mean mod doesn't use CBA XEH — its init runs from direct config `EventHandlers.init`, no CBA overhead

### Why it doesn't happen in original Mean

The original Mean mod uses `init = "_this execVM ..."` in each vehicle's config. This is a single script per vehicle (4 execVMs per vehicle), not 3 spawned functions via CBA wrapper. The vanilla handler doesn't have CBA's hierarchy lookup or event dispatch overhead.

---

## Attempted Fixes

| Fix | Result | Problem |
|---|---|---|
| 6 base class reg instead of 37 concretes | Hang persisted | CBA propagates to all 37 derived anyway |
| Staggered spawn with 50ms offset per vehicle | Loading hang fixed | **Introduced ~1.85s siren delay on last vehicles** — player can get in and press R before functions start |

---

## Why Staggered Spawn Introduces Delay

```sqf
// Stagger approach:
[_car, _offset] spawn {
    params ["_car", "_offset"];
    sleep _offset;           // ← vehicle 37 sleeps 1.85s
    _car spawn mean_patch_fnc_horn;
    _car spawn mean_patch_fnc_sirens;
    _car spawn mean_patch_fnc_takedown;
};
```

The `sleep _offset` happens INSIDE the spawned thread. If the player gets into vehicle 20 before its 1.0s offset expires, `mean_patch_fnc_sirens` hasn't started yet. The R key sets `setVariable ["ani_siren", 1]` but there's no function running to read it. Milliseconds of delay becomes seconds.

---

## Remaining Options (not yet tried)

1. **Spawn functions immediately, but delay their ENTRY into the idle loop:**
   Each function starts immediately but adds `waitUntil { time > 0.5 }` at the top. This defers the first schedule slot for all 111 threads by 0.5s, spreading them across ~16 frames instead of 1.

2. **Don't spawn functions per-vehicle. Use global event-driven approach:**
   Instead of each vehicle having its own siren/horn/takedown while-loop, register a per-frame handler (via `CBA_fnc_addPerFrameHandler` or `onEachFrame`) that checks a global list of active vehicles. This replaces 111 threads with 1.

3. **Defer spawn to first `GetIn`:**
   Don't spawn any functions at init. Add a `GetIn` event handler that spawns them when a player enters. Only 1-2 vehicles will be occupied at any time, so only 3-6 threads instead of 111.

4. **Reduce thread count by combining functions:**
   Merge horn, siren, and takedown into a single `while {alive _car} do { ... }` loop. 37 threads instead of 111.

---

## Key Files

| File | Role |
|---|---|
| `Addons/mean_patch/scripts/init.sqf` | CBA init override registration (6 base classes → propagates to 37) |
| `Addons/mean_patch/functions/fn_initCar.sqf` | Spawns 3 audio functions per vehicle |
| `Addons/mean_patch/functions/fn_horn.sqf` | `while {alive _car}` idle loop |
| `Addons/mean_patch/functions/fn_sirens.sqf` | `while {alive _car}` idle loop |
| `Addons/mean_patch/functions/fn_takedown.sqf` | `while {alive _car}` idle loop |

## Reproduction

1. Open editor
2. Place one of each Mean vehicle variant (37 total)
3. Click Play
4. Loading screen hangs indefinitely
