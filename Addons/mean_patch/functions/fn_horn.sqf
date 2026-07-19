// ============================================================
// mean_patch_fnc_horn — airhorn audio loop
// ============================================================
//
// Hold-to-play airhorn. Uses a single #particlesource dummy so the sound
// stops instantly when released (deleteVehicle kills say3D).
//
// Interior audio handled by config (occludeSoundsWhenIn/obstructSoundsWhenIn).
// (Previously used _car say3D for in-car volume — obsolete now that the
// config occlusion fix makes #particlesource dummies audible inside the cabin.)
//
// Ivory approach used:
//   - Same sound class (ivory_ss2000_airhorn)
//   - Same variable name (ani_horn)
//   - Same guard condition (player distance <= 350)
//   - Same single-dummy architecture (horn doesn't alternate)
//
// Why single dummy (not dual):
//   The horn only plays one sound repeatedly until release. There's no
//   tone switching or alternation needed — a single dummy is sufficient,
//   and the spawned inner loop repeatedly calls say3D on it. Unlike the
//   siren (which switches between tones), the horn never needs dual-dummy.
//
// Why the inner loop is spawned (not inline):
//   The outer while loop needs to continue running so it can detect when
//   ani_horn returns to 0 (release). The inner loop does the audio playback
//   in parallel. Without the spawn, the outer loop would block on the
//   inner loop and never detect the release.
//
// Why deleteVehicle stops the sound:
//   #particlesource object -> say3D sound is linked to the dummy's
//   lifetime. Deleting the dummy instantly stops all sounds playing
//   through it. This is the ONLY reliable way to stop an ongoing say3D
//   without lingering accumulation.
//
// ============================================================

if (!hasInterface) exitWith {};
params ["_car"];

private _airhorn     = "ivory_ss2000_airhorn";
private _airhornTime = 9.932;

while {alive _car} do
{
    if (alive _car && !isNull driver _car && _car getVariable "ani_horn" > 0 && (player distance _car <= 350)) then {

        private _dummy = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummy attachTo [_car, [0, 0, 0]];

        [_car, _airhorn, _airhornTime, _dummy] spawn {
            params ["_car", "_airhorn", "_airhornTime", "_dummy"];
            while {_car getVariable "ani_horn" == 1} do {
                private _timeStarted = time;
                _dummy say3D [_airhorn, 250];
                waitUntil { time >= _timeStarted + _airhornTime || _car getVariable "ani_horn" != 1 };
            };
        };

        waitUntil { _car getVariable "ani_horn" == 0 };

        // Release — kill dummy instantly so sound stops with no lingering
        deleteVehicle _dummy;

    } else {
        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && _car getVariable ["ani_horn", 0] > 0 && (player distance _car <= 350))};
    };
};
