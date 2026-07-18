// mean_patch_fnc_initCar
// Replaces the original Mean init event handler for every Mean vehicle.
// Keeps the original lightbar, flasher, and radar scripts running,
// but replaces the siren with Ivory's multi-tone audio system.
// Only runs on clients (lights and sounds are client-local).

if (!hasInterface) exitWith {};

params ["_car"];

// ── Detect which Mean model this vehicle belongs to ──
private _type = typeOf _car;
private _modelPath = switch (true) do {
    case (_type find "M_CVPI"      >= 0): {"\MeansCars\2011_CVPI\data\scripts\"};
    case (_type find "M_Charger12" >= 0): {"\MeansCars\2012_Charger\data\scripts\"};
    case (_type find "M_Tahoe"     >= 0): {"\MeansCars\2015_Tahoe\data\scripts\"};
    case (_type find "M_FPIS"      >= 0): {"\MeansCars\Ford_Torus\data\scripts\"};
    case (_type find "M_Ambulance" >= 0): {"\MeansCars\Ambulance\data\scripts\"};
    case (_type find "M_Silverado" >= 0): {"\MeansCars\2012_Charger\data\scripts\"};
    default {""};
};

// ── Run original Mean scripts for visuals (lightbar, flashers, radar) ──
if (_modelPath != "") then {
    _car execVM (_modelPath + "lightbar.sqf");
    _car execVM (_modelPath + "Flashers.sqf");
    _car execVM (_modelPath + "radar.sqf");
    // Deliberately NOT running sirenscv.sqf — replaced by ivory_fnc_sirens below
};

// ── Guard against double-initialisation ──
if (_car getVariable ["mean_patch_initialized", false]) exitWith {};
_car setVariable ["mean_patch_initialized", true, true];

// ── Initialise Ivory-style siren / horn variables ──
_car setVariable ["ani_horn",           0, true];
_car setVariable ["ani_siren",          0, true];
_car setVariable ["ani_siren_todo",     1, true];
_car setVariable ["ani_lightbar",       0, true];
_car setVariable ["ani_lightbar_todo",  1, true];

// ── Spawn Ivory siren and horn audio loops ──
_car spawn ivory_fnc_horn;
_car spawn mean_patch_fnc_sirens;

// ── Add Read Manual scroll-wheel action (runtime, no config needed) ──
_car addAction [
    "<t color='#4EB1BA'>Read Manual</t>",
    { [_this select 0] call mean_patch_fnc_manual; },
    nil, 1.5, false, true, "",
    "driver _target == player"
];
