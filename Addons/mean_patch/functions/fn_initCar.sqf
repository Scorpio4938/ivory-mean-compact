// ============================================================
// mean_patch_fnc_initCar — vehicle initialization
// ============================================================
//
// Triggered by GetIn (not config init) — see scripts/init.sqf for
// the full explanation of why CBA "init" caused loading screen hangs.
//
// What this does:
//   1. Sets up Ivory-compatible variables (ani_horn, ani_siren, etc.)
//   2. Spawns 3 audio loops: horn, siren, takedown (each runs as an
//      independent while{ alive _car } thread)
//   3. Adds a "Read Manual" scroll action to the vehicle
//
// Why spawn vs call for the audio functions:
//   - spawn creates a SCHEDULED thread that survives the calling scope.
//     The while{ alive _car } loop inside each function needs to persist
//     independently — call would execute the loop synchronously and block.
//
// Why 3 separate threads instead of 1 combined:
//   - Clarity: each function maps to one Ivory feature (horn, siren,
//     takedown). Keeping them separate makes the code easier to read and
//     debug. The performance cost is negligible for occupied vehicles.
//
// Why all setVariables use public broadcast (true):
//   - In multiplayer, other clients need to see the siren/horn/lightbar
//     state on vehicles they're not local to (e.g., another player's car).
//     The broadcast flag ensures JIP/public sync.
//   - In singleplayer, the flag is a no-op. No performance impact.
//
// Why ini_horn/ani_siren/ani_lightbar start at 0 (off):
//   - The GetIn event fires before the player presses any key.
//     Starting at 0 ensures no sound plays accidentally when entering.
//   - ani_siren_todo and ani_lightbar_todo start at 1 (default Wail
//     tone, default lightbar pattern) — matches Ivory defaults.
//
// ============================================================

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

// ── Spawn Mean-sourced siren, horn, and takedown audio loops ──
_car spawn mean_patch_fnc_horn;
_car spawn mean_patch_fnc_sirens;
_car spawn mean_patch_fnc_takedown;

// ── Add Read Manual scroll-wheel action (runtime, no config needed) ──
_car addAction [
    "<t color='#4EB1BA'>Read Manual</t>",
    { [_this select 0] call mean_patch_fnc_manual; },
    nil, 1.5, false, true, "",
    "driver _target == player"
];
