# Loading Screen Hang — Root Cause & Fix

## Status

**Resolved.** Switched init trigger from CBA `"init"` to `"GetIn"`.

---

## Symptom

When all 37 Mean vehicles are placed on the same map and the mission loads, the loading screen hangs. With a single vehicle, loading completes normally.

Introduced when the CBA init override expanded from one class to all 37 (via 6 base classes).

---

## Root Cause (proven, not theorized)

**CBA's XEH re-init mechanism fires all 37 init handlers in a single postInit frame.**

### Init firing timeline in Arma 3

```
1. preInit functions run
2. Mission objects created
   → each object's CONFIG EventHandlers.init fires
   → Mean's init = "_this execVM ..." runs here (spread across loading)
3. Mission init.sqf runs
4. postInit functions run          ← our init.sqf registers CBA handlers HERE
5. CBA XEH re-init
   → detects 37 existing Mean vehicles
   → re-fires "init" for ALL of them IN A SINGLE BURST
   → 111 spawn + 37 addAction + 222 public setVariable in one frame
   → exceeds frame budget → loading screen cannot progress → HANG
```

### Evidence

| | Ivory / Mean | Our patch |
|---|---|---|
| Init trigger | Config `EventHandlers.init` string | CBA `"init"` handler, registered in **postInit** |
| Fires during | Object creation (step 2) — **spread across loading** | CBA XEH re-init (step 5) — **all 37 in one frame** |

**Ivory uses the identical idle-loop architecture** (`while {alive _car}` + `waitUntil {sleep 0.01; ...}`) and does not hang — confirming the idle loops themselves are not the cause. The difference is purely **when** the init fires.

- **Ivory/Mean:** config init fires during step 2, one vehicle at a time as each is created — work is spread across the entire loading process.
- **Ours:** CBA re-fires init in step 5, all 37 concentrated into one frame — a burst the loading screen cannot absorb.

### Why 1 vehicle works / 37 hangs

One handler in the burst (3 spawn + 1 addAction + 6 setVariable) is trivial. Thirty-seven concentrated in one frame exceeds the budget.

---

## The Fix

**Switch from `"init"` to `"GetIn"`.**

CBA does **not** re-fire `GetIn` for existing objects — it's an event, not a state. So zero work happens during loading. Each vehicle initializes on first entry (player or AI).

```sqf
// Before (hangs):
[_x, "init", { params ["_car"]; _car spawn mean_patch_fnc_initCar; }, true] call ...;

// After (no hang):
[_x, "GetIn", { params ["_car"]; _car spawn mean_patch_fnc_initCar; }, true] call ...;
```

Plus a one-time scan (runs 1s after load) for editor-placed vehicles that already have AI drivers:

```sqf
[] spawn {
    sleep 1;
    { if (!isNull driver _x && /* is Mean */ && !alreadyInit) then {[_x] call mean_patch_fnc_initCar}; } forEach vehicles;
};
```

### Why player experience is identical

- Sirens/horn/takedown only matter when a driver is present — our code already gates on `!isNull driver _car`
- `GetIn` fires for both player and AI entry
- The audio functions are byte-for-byte unchanged once spawned
- Read Manual action appears on entry (condition is already `driver _target == player`)
- The one-time scan catches the only gap (editor-placed AI already seated)

---

## Attempted Fixes (history)

| Fix | Result | Why it failed |
|---|---|---|
| 6 base classes instead of 37 concretes | Hang persisted | CBA still re-fires for all 37 derived classes |
| Staggered spawn (50ms offset per vehicle) | Loading fixed | Introduced ~1.85s siren delay — functions not started when player enters |
| **GetIn instead of init** | **Loading fixed, no delay** | CBA doesn't re-fire GetIn; zero burst during loading |
