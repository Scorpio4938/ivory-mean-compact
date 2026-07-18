// mean_patch_fnc_sirens
// Plays sirens through the vehicle itself (not a dummy) so concurrent
// say3D calls mix rather than cancel. 0.3s overlap for seamless looping.
// Direct vehicle say3D also improves in-car volume.

if (!hasInterface) exitWith {};
params ["_car"];
if (_car getVariable ["mean_sirens_running", false]) exitWith {};
_car setVariable ["mean_sirens_running", true, true];

private _siren1     = "ivory_ss2000_wail";
private _siren1Time = 20.742;
private _siren2     = "ivory_ss2000_yelp";
private _siren2Time = 5.038;
private _siren3     = "ivory_ss2000_priority";
private _siren3Time = 9.862;
private _siren4     = "ivory_ss2000_hilo";
private _siren4Time = 10.211;

while {alive _car} do
{
    if (alive _car && !isNull driver _car && _car getVariable "ani_siren" > 0 && damage _car < 0.7 && (_car getVariable "ani_lightbar" > 0) && (player distance _car <= 850)) then {

        private _ani_siren = _car getVariable "ani_siren";

        private _type      = 0;
        private _siren     = "";
        private _sirenTime = 0;

        call {
            if (_ani_siren == 1) exitWith { _type = 1; _siren = _siren1; _sirenTime = _siren1Time; };
            if (_ani_siren == 2) exitWith { _type = 2; _siren = _siren2; _sirenTime = _siren2Time; };
            if (_ani_siren == 3) exitWith { _type = 3; _siren = _siren3; _sirenTime = _siren3Time; };
            if (_ani_siren == 4) exitWith { _type = 4; _siren = _siren4; _sirenTime = _siren4Time; };
        };

        // Spawned loop — plays through the car directly (supports concurrent say3D)
        [_car, _siren, _sirenTime, _type] spawn {
            params ["_car", "_siren", "_sirenTime", "_type"];
            while {_car getVariable "ani_siren" == _type && !isNull driver _car} do {
                private _timeStarted = time;
                _car say3D [_siren, 300];
                waitUntil { time >= _timeStarted + _sirenTime - 0.05 || _car getVariable "ani_siren" != _type || isNull driver _car };
            };
        };

        waitUntil { _car getVariable "ani_siren" != _type || isNull driver _car };

    } else {
        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && (_car getVariable ["ani_siren", 1] > 0) && damage _car < 0.7 && (_car getVariable ["ani_lightbar", 1] > 0) && player distance _car <= 850)};
    };
};
