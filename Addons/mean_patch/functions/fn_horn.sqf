// mean_patch_fnc_horn
// Hold-to-play airhorn. Uses #particlesource dummy (cancellable via deleteVehicle)
// so the sound stops instantly on release — no lingering accumulation.
// Interior audio handled by config (occludeSoundsWhenIn/obstructSoundsWhenIn).
// (Previously used _car say3D "for in-car volume" — obsolete now that the config
// occlusion fix makes #particlesource dummies audible inside the cabin.)

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
