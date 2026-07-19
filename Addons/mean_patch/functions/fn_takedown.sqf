// ============================================================
// mean_patch_fnc_takedown — takedown tone audio loop
// ============================================================
//
// Hold-to-play tone: plays priority tone if the siren is active and not
// already in priority mode, otherwise plays wail tone.
// Uses dual-dummy alternation (same design as fn_sirens.sqf).
//
// Why dual-dummy (same as fn_sirens.sqf):
//   The takedown can be held for 10-30+ seconds. A single dummy's say3D
//   loop boundary can experience a frame of scheduler drift (due to Mean's
//   background scripts). Dual-dummy alternation prevents audible gaps by
//   ensuring no single dummy is asked to overlap its own sound.
//
// Priority vs Wail logic:
//   - If siren IS active AND siren is NOT already in priority mode (mode 3):
//     play priority tone (a short, urgent pulse)
//   - Otherwise: play wail tone (a longer, full-cycle tone)
//   This mirrors Ivory's takedown behavior — the takedown amplifies the
//   current urgency by playing a more aggressive tone when possible.
//
// Notes:
//   - Both dummies are created when the takedown activates, and both are
//     deleted on release — this ensures no sound accumulation.
//   - Overlap offsets: priority -0.10s, wail -0.15s (same rationale as
//     fn_sirens.sqf — compensate for scheduler jitter on loop boundaries).
//
// ============================================================

if (!hasInterface) exitWith {};
params ["_car"];

private _wail          = "ivory_ss2000_wail";
private _wailTime      = 20.742;
private _priority      = "ivory_ss2000_priority";
private _priorityTime  = 9.862;

while {alive _car} do
{
    if (alive _car && !isNull driver _car && _car getVariable "ani_takedown" > 0 && (player distance _car <= 350)) then {

        private _dummyA = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummyA attachTo [_car, [0, 0, 0]];
        private _dummyB = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummyB attachTo [_car, [0, 0, 0]];

        private _toggle = false;

        while {_car getVariable "ani_takedown" == 1} do {

            private _dummy     = if (_toggle) then { _dummyA } else { _dummyB };
            private _sound     = "";
            private _cycleTime = 0;

            if (_car getVariable "ani_siren" > 0 && _car getVariable "ani_siren" != 3) then {
                _sound     = _priority;
                _cycleTime = _priorityTime - 0.10;
            } else {
                _sound     = _wail;
                _cycleTime = _wailTime - 0.15;
            };

            _dummy say3D [_sound, 250];
            _toggle = !_toggle;

            private _wakeAt = time + _cycleTime;
            waitUntil {
                time >= _wakeAt ||
                _car getVariable "ani_takedown" != 1 ||
                !alive _car ||
                isNull driver _car
            };
        };

        // Release — kill both dummies instantly, no lingering sound
        deleteVehicle _dummyA;
        deleteVehicle _dummyB;

    } else {
        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && _car getVariable "ani_takedown" > 0 && (player distance _car <= 350))};
    };
};
