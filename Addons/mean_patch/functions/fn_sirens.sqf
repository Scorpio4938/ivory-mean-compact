// mean_patch_fnc_sirens
// Precise copy of Ivory's fn_sirens, hardcoded to emergencySiren = 1 (SS2000).
// References Ivory's CfgSounds class names directly.

#include "\a3\editor_f\Data\Scripts\dikCodes.h"

if (isDedicated) exitWith {};
params ["_car"];

private _siren1     = "ivory_ss2000_wail";
private _siren1Time = 20.742;
private _siren2     = "ivory_ss2000_yelp";
private _siren2Time = 5.038;
private _siren3     = "ivory_ss2000_priority";
private _siren3Time = 9.862;
private _siren4     = "ivory_ss2000_hilo";
private _siren4Time = 10.211;

private _dummy = ObjNull;

while {alive _car} do
{
    if (alive _car && !isNull driver _car && _car getVariable "ani_siren" > 0 && damage _car < 0.7 && (_car getVariable "ani_lightbar" > 0) && (player distance _car <= 850)) then {

        private _ani_siren = _car getVariable "ani_siren";

        private _type      = 0;
        private _siren     = "";
        private _sirenTime = 0;

        call
        {
            if (_ani_siren isEqualTo 1) exitWith { _type = 1; _siren = _siren1; _sirenTime = _siren1Time; };
            if (_ani_siren isEqualTo 2) exitWith { _type = 2; _siren = _siren2; _sirenTime = _siren2Time; };
            if (_ani_siren isEqualTo 3) exitWith { _type = 3; _siren = _siren3; _sirenTime = _siren3Time; };
            if (_ani_siren isEqualTo 4) exitWith { _type = 4; _siren = _siren4; _sirenTime = _siren4Time; };
        };

        _dummy = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummy attachTo [_car, (_car selectionPosition "pos driver")];

        [_car, _siren, _sirenTime, _type, _dummy] spawn {
            params ["_car", "_siren", "_sirenTime", "_type", "_dummy"];
            while {_car getVariable "ani_siren" == _type && !isNull driver _car} do {
                private _timeStarted = time;
                _dummy say3D [_siren, 300];

                waitUntil { time >= _timeStarted + _sirenTime || _car getVariable "ani_siren" != _type || isNull driver _car };
            };
        };

        waitUntil { _car getVariable "ani_siren" != _type };

        detach _dummy;
        deleteVehicle _dummy;

    } else {
        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && (_car getVariable ["ani_siren", 1] > 0) && damage _car < 0.7 && (_car getVariable ["ani_lightbar", 1] > 0) && player distance _car <= 850)};
    };
};
