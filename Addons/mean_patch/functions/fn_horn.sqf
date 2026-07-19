// mean_patch_fnc_horn
// Uses _car say3D directly (not dummy) for better in-car volume.
// Hardcoded SS2000 airhorn for Mean emergency vehicles.
// Single-shot hold-to-play — no looping or accumulation concerns.

if (!hasInterface) exitWith {};
params ["_car"];

private _airhorn     = "ivory_ss2000_airhorn";
private _airhornTime = 9.932;

while {alive _car} do
{
    if (alive _car && !isNull driver _car && _car getVariable "ani_horn" > 0 && (player distance _car <= 350)) then {

        [_car, _airhorn, _airhornTime] spawn {
            params ["_car", "_airhorn", "_airhornTime"];
            while {_car getVariable "ani_horn" == 1} do {
                private _timeStarted = time;
                _car say3D [_airhorn, 250];
                waitUntil { time >= _timeStarted + _airhornTime || _car getVariable "ani_horn" != 1 };
            };
        };

        waitUntil { _car getVariable "ani_horn" == 0 };

    } else {
        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && _car getVariable ["ani_horn", 0] > 0 && (player distance _car <= 350))};
    };
};
