// mean_patch_fnc_takedown
// Copy of ivory_fnc_takedown with hardcoded emergencySiren = 1 (SS2000).
// C key: holds priority tone while pressed, wail otherwise.
// When siren is active and not in priority mode: plays priority tone.
// Otherwise: plays wail tone.

if (!hasInterface) exitWith {};
params ["_car"];

private _airhorn     = "ivory_ss2000_wail";
private _airhornTime = 20.742;
private _airhorn2    = "ivory_ss2000_priority";
private _airhornTime2 = 9.862;

private _dummy = objNull;

while {alive _car} do
{
    if (alive _car && !isNull driver _car && _car getVariable "ani_takedown" > 0 && (player distance _car <= 350)) then {

        _dummy = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummy attachTo [_car, [0,0,0]];

        [_car, _airhorn, _airhornTime, _airhorn2, _airhornTime2, _dummy] spawn {
            params ["_car", "_airhorn", "_airhornTime", "_airhorn2", "_airhornTime2", "_dummy"];
            while {_car getVariable "ani_takedown" == 1} do {
                private _timeStarted = time;

                if (_car getVariable "ani_siren" > 0 && _car getVariable "ani_siren" != 3) then {
                    _dummy say3D [_airhorn2, 250];
                    waitUntil { time >= _timeStarted + _airhornTime2 || _car getVariable "ani_takedown" != 1 };
                } else {
                    _dummy say3D [_airhorn, 250];
                    waitUntil { time >= _timeStarted + _airhornTime || _car getVariable "ani_takedown" != 1 };
                };
            };
        };

        waitUntil { _car getVariable "ani_takedown" == 0 };

    } else {
        if (!isNull _dummy) then { detach _dummy; deleteVehicle _dummy; _dummy = objNull; };

        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && _car getVariable "ani_takedown" > 0 && (player distance _car <= 350))};
    };
};
