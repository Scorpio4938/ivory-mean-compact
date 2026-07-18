// mean_patch_fnc_initCar
// Runs ALONGSIDE the original Mean init (which handles lightbar/flasher/radar).
// We only add the Ivory-style siren/horn audio system and Read Manual action.
// Guard variable prevents double-initialisation.

if (!hasInterface) exitWith {};

params ["_car"];

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
