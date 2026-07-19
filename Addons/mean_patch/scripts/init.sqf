#include "\a3\editor_f\Data\Scripts\dikCodes.h"

// ──────────────────────────────────────
// Macro: MEAN_VEHICLE_GATE — gating macro for CBA keybinds
//
// Replicates Ivory's pattern of checking the player's current vehicle type
// before processing a keybind. The prefix-matching approach:
//   typeOf vehicle find "M_CVPI" >= 0
// matches ALL variants (M_CVPI, M_CVPI_Supervisor, M_CVPI_NEW, etc.)
// without needing to enumerate 37 concrete class names.
//
// Why prefix matching instead of an exact class list:
//   - Simpler: 6 prefixes cover all 37+ classes
//   - Future-proof: any new Mean variants matching these prefixes work
//   - No config maintenance when Mean updates
//
// This macro exits silently (exitWith {}) if the player is NOT in a
// Mean vehicle. The keybind is always registered — CBA just skips it
// when the gate fails.
// ──────────────────────────────────────
#define MEAN_VEHICLE_GATE \
    private _vcl = vehicle player; \
    if (isNull _vcl) exitWith {}; \
    private _type = typeOf _vcl; \
    if (_type find "M_CVPI"      < 0 && \
        _type find "M_Charger12" < 0 && \
        _type find "M_Tahoe"     < 0 && \
        _type find "M_FPIS"      < 0 && \
        _type find "M_Ambulance" < 0 && \
        _type find "M_Silverado" < 0) exitWith {};

// ──────────────────────────────────────
// Macro: MEAN_DRIVER_GATE — gate for driver-only keybinds
//
// Extends MEAN_VEHICLE_GATE with two additional checks:
//   1. if (dialog) exitWith {} — prevents keybind from firing while
//      the player is in a dialog/UI (e.g., options menu, radar UI)
//   2. if (driver _vcl != player) exitWith {} — restricts to DRIVER only.
//      Some keybinds (Lightbar toggle) could logically work from passenger,
//      but Ivory restricts ALL siren controls to the driver for simplicity.
//
// MEAN_VEHICLE_GATE (without driver check) is used only for the
// Read Manual keybind, where front passengers should also access it.
// ──────────────────────────────────────
#define MEAN_DRIVER_GATE \
    MEAN_VEHICLE_GATE \
    if (dialog) exitWith {}; \
    if (driver _vcl != player) exitWith {};

// ──────────────────────────────────────
// init.sqf — postInit
//
// Runs once when the addon loads (postInit = 1 in CfgFunctions).
// Registers CBA keybinds, settings, and the lazy init mechanism.
//
// Why postInit instead of preInit:
//   - CBA keybinds require the system to be fully initialized
//   - Our lazy GetIn handler registration needs CBA XEH ready
//   - One-time vehicle scan needs all objects to exist
//
// Ivory approach used:
//   - Same CBA keybind registration pattern (CBA_fnc_addKeybind)
//   - Same variable naming (ani_horn, ani_siren, ani_lightbar, etc.)
//   - Same to-be/selected pattern (ani_siren_todo / ani_siren)
//   - Same confirmation beep (playSound "ivory_beep2")
//
// Variable naming convention (Ivory-compatible):
//   ani_siren           = current siren mode (0=off, 1=Wail, 2=Yelp, 3=Priority, 4=HiLo)
//   ani_siren_todo      = remembered siren mode for next power-on (persists across cycles)
//   ani_lightbar        = current lightbar state (0=off, 1+=on)
//   ani_lightbar_todo   = remembered lightbar pattern for next power-on
//   ani_horn            = horn held flag (0=released, 1=pressed)
//   ani_takedown        = takedown held flag
// ──────────────────────────────────────
["Mean Patch", "mean_horn", ["Car Horn", ""], {
    MEAN_DRIVER_GATE
    _vcl setVariable ["ani_horn", 1, true];
}, {
    private _vcl = vehicle player;
    if (!isNull _vcl) then {
        _vcl setVariable ["ani_horn", 0, true];
    };
}, [DIK_F, [false, false, false]], true] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Horn note: hold F
// keyDown sets ani_horn=1 (starts sound), keyUp sets ani_horn=0 (stops).
// The fn_horn.sqf loop reads ani_horn and plays via #particlesource dummy.
// Why hold (not toggle): horn is a short burst, not persistent state.
// Release instantly kills sound via deleteVehicle (see fn_horn.sqf).
// ──────────────────────────────────────

// ──────────────────────────────────────
// Siren toggle — R  (on: siren+lightbar, off: siren only)
//
// Ivory control pattern:
//   - Press #1 (siren OFF → ON): restores siren+lightbar from "todo" values.
//     This remembers the last tone/pattern across on/off cycles.
//   - Press #2 (siren ON → OFF): kills siren only, lightbar keeps running.
//   - T turns lightbar OFF (kills siren too — no lightbar = no emergency).
//   - T turns lightbar ON (does NOT auto-start siren — press R separately).
// ──────────────────────────────────────
["Mean Patch", "mean_sirens", ["Emergency - Sirens", ""], {
    MEAN_DRIVER_GATE
    playSound "ivory_beep2";
    if (_vcl getVariable "ani_siren" == 0) then {
        // Turn on: siren + lightbar together
        _vcl setVariable ["ani_lightbar", (_vcl getVariable ["ani_lightbar_todo", 1]), true];
        _vcl setVariable ["ani_siren",    (_vcl getVariable ["ani_siren_todo",    1]), true];
        _vcl animate ["ani_lightbar", 0.1];
    } else {
        // Turn off: siren only, lightbar stays
        _vcl setVariable ["ani_siren", 0, true];
    };
}, {}, [DIK_R, [true, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Next siren tone — Shift+R
//
// Cycles through 1→2→3→4→1 in the "todo" variable (ani_siren_todo).
// If siren is currently ON, the live ani_siren also updates so the
// sound changes immediately (fn_sirens.sqf detects the mismatch and
// switches to the new tone). If siren is OFF, only todo changes
// (next R-press will use this tone).
//
// Ivory pattern: exitWith chain for sequential cycling. Each exitWith
// exits the keybind handler after setting the new value.
// ──────────────────────────────────────
["Mean Patch", "mean_sirens_next", ["Emergency - Sirens (Next)", ""], {
    MEAN_DRIVER_GATE
    playSound "ivory_beep2";

    private _todo = _vcl getVariable ["ani_siren_todo", 1];

    if (_todo == 1) exitWith {
        _vcl setVariable ["ani_siren_todo", 2];
        if (_vcl getVariable "ani_siren" > 0) then { _vcl setVariable ["ani_siren", 2, true]; };
    };
    if (_todo == 2) exitWith {
        _vcl setVariable ["ani_siren_todo", 3];
        if (_vcl getVariable "ani_siren" > 0) then { _vcl setVariable ["ani_siren", 3, true]; };
    };
    if (_todo == 3) exitWith {
        _vcl setVariable ["ani_siren_todo", 4];
        if (_vcl getVariable "ani_siren" > 0) then { _vcl setVariable ["ani_siren", 4, true]; };
    };
    if (_todo == 4) exitWith {
        _vcl setVariable ["ani_siren_todo", 1];
        if (_vcl getVariable "ani_siren" > 0) then { _vcl setVariable ["ani_siren", 1, true]; };
    };
}, {}, [DIK_R, [true, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Direct siren phases — 1 / 2 / 3 / 4
//
// Select a siren tone directly:
//   1 = Wail     (long	descending/ascending oscillator)
//   2 = Yelp     (fast	warble)
//   3 = Priority (rapid	urgent burst)
//   4 = HiLo     (high-low	cycling tone)
//
// Matches Ivory's numbering exactly. If siren is ON, switches
// immediately (playSound confirmation). If siren is OFF, only
// updates the "todo" (next R-press uses this tone).
// ──────────────────────────────────────
["Mean Patch", "mean_sirens_phase_1", ["Emergency - Sirens (Wail)", ""], {
    MEAN_DRIVER_GATE
    if (_vcl getVariable "ani_siren" > 0) then {
        _vcl setVariable ["ani_siren", 1, true];
        playSound "ivory_beep2";
    };
    _vcl setVariable ["ani_siren_todo", 1];
}, {}, [DIK_1, [false, false, false]]] call CBA_fnc_addKeybind;

["Mean Patch", "mean_sirens_phase_2", ["Emergency - Sirens (Yelp)", ""], {
    MEAN_DRIVER_GATE
    if (_vcl getVariable "ani_siren" > 0) then {
        _vcl setVariable ["ani_siren", 2, true];
        playSound "ivory_beep2";
    };
    _vcl setVariable ["ani_siren_todo", 2];
}, {}, [DIK_2, [false, false, false]]] call CBA_fnc_addKeybind;

["Mean Patch", "mean_sirens_phase_3", ["Emergency - Sirens (Priority)", ""], {
    MEAN_DRIVER_GATE
    if (_vcl getVariable "ani_siren" > 0) then {
        _vcl setVariable ["ani_siren", 3, true];
        playSound "ivory_beep2";
    };
    _vcl setVariable ["ani_siren_todo", 3];
}, {}, [DIK_3, [false, false, false]]] call CBA_fnc_addKeybind;

["Mean Patch", "mean_sirens_phase_4", ["Emergency - Sirens (HiLo)", ""], {
    MEAN_DRIVER_GATE
    if (_vcl getVariable "ani_siren" > 0) then {
        _vcl setVariable ["ani_siren", 4, true];
        playSound "ivory_beep2";
    };
    _vcl setVariable ["ani_siren_todo", 4];
}, {}, [DIK_4, [false, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Lightbar toggle — T (off kills siren too)
//
// Ivory convention: pressing T when lightbar ON → turns both
// lightbar AND siren OFF (no lightbar = no emergency).
// Pressing T when lightbar OFF → turns lightbar ON (but does
// NOT auto-start siren — press R separately).
//
// The animate call updates Mean's lightbar visual animation.
// fn_sirens.sqf gates siren on ani_lightbar > 0 (see fn_sirens.sqf).
// ──────────────────────────────────────
["Mean Patch", "mean_lights", ["Emergency - Lights", ""], {
    MEAN_DRIVER_GATE
    playSound "ivory_beep2";
    if (_vcl getVariable "ani_lightbar" == 0) then {
        // Turn on
        _vcl setVariable ["ani_lightbar", (_vcl getVariable ["ani_lightbar_todo", 1]), true];
        _vcl animate ["ani_lightbar", 0.1];
    } else {
        // Turn off: lightbar + siren both off
        _vcl setVariable ["ani_lightbar", 0, true];
        _vcl setVariable ["ani_siren", 0, true];
        _vcl animate ["ani_lightbar", 0];
    };
}, {}, [DIK_T, [false, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Takedown lights — hold C
//
// Hold-to-play: plays a continuous tone (priority if siren active
// and not already priority, wail otherwise). Fn_takedown.sqf uses
// dual-dummy alternation for seamless playback on long holds.
// Release instantly stops (sets ani_takedown = 0 → deleteVehicle).
// ──────────────────────────────────────
["Mean Patch", "mean_takedown", ["Emergency - Takedown", ""], {
    MEAN_DRIVER_GATE
    _vcl setVariable ["ani_takedown", 1, true];
}, {
    private _vcl = vehicle player;
    if (!isNull _vcl) then {
        _vcl setVariable ["ani_takedown", 0, true];
    };
}, [DIK_C, [false, false, false]], true] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Read Manual — Backslash
//
// Accessible from driver OR front passenger seat (cargo index 0).
// Displays left-side control reference for 8 seconds.
// Uses MEAN_VEHICLE_GATE (allows passenger access) not
// MEAN_DRIVER_GATE (which restricts to driver only).
// ──────────────────────────────────────
["Mean Patch", "mean_manual", ["Read Manual", ""], {
    MEAN_VEHICLE_GATE
    if (dialog) exitWith {};
    if (driver _vcl == player || (_vcl getCargoIndex player) == 0) then {
        [_vcl] call mean_patch_fnc_manual;
    };
}, {}, [DIK_BACKSLASH, [false, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Lazy init — deferred to GetIn (NOT init) to avoid loading-screen hang.
//
// ROOT CAUSE of loading hang: CBA XEH re-fires "init" for ALL existing
// vehicles in a single postInit burst. With 37 Mean vehicles, that's
// 111 spawned threads + 37 addAction + 222 public setVariables in one
// frame — exceeds the loading frame budget and hangs the screen.
//
// FIX: use "GetIn" instead of "init". CBA does NOT re-fire GetIn for
// existing objects, so zero work happens during loading. Each vehicle
// initializes on first entry (player or AI). A one-time scan below
// catches editor-placed vehicles that already have drivers.
// ──────────────────────────────────────
private _allMeanBases = [
    "M_CVPIbase",
    "M_Charger12base",
    "M_Tahoebase",
    "M_FPISbase",
    "M_Ambulancebase",
    "M_Silveradobase"
];

{
    [_x, "GetIn", {
        params ["_car"];
        _car spawn mean_patch_fnc_initCar;
    }, true] call CBA_fnc_addClassEventHandler;
} forEach _allMeanBases;

// One-time scan for vehicles that already have drivers (editor-placed AI).
// Runs after loading completes; only touches vehicles WITH a driver.
[] spawn {
    sleep 1;
    {
        private _type = typeOf _x;
        if (!isNull driver _x &&
            !(_x getVariable ["mean_patch_initialized", false]) &&
            {_type find "M_CVPI" >= 0 || _type find "M_Charger12" >= 0 ||
             _type find "M_Tahoe" >= 0 || _type find "M_FPIS" >= 0 ||
             _type find "M_Ambulance" >= 0 || _type find "M_Silverado" >= 0}) then {
            [_x] call mean_patch_fnc_initCar;
        };
    } forEach vehicles;
};
