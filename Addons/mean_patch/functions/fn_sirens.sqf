// mean_patch_fnc_sirens
// Dual-dummy particlesource with responsive mode check.
// Two dummies alternate for seamless same-tone looping.
// Mode switch: deleteVehicle kills old sound instantly — no accumulation.
// Checks for mode change every 0.05s while waiting — responsive.

if (!hasInterface) exitWith {};
params ["_car"];

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

        private _siren     = "";
        private _cycleTime = 0;
        call {
            if (_ani_siren == 1) exitWith { _siren = _siren1; _cycleTime = _siren1Time - 0.35; };
            if (_ani_siren == 2) exitWith { _siren = _siren2; _cycleTime = _siren2Time - 0.15; };
            if (_ani_siren == 3) exitWith { _siren = _siren3; _cycleTime = _siren3Time - 0.15; };
            if (_ani_siren == 4) exitWith { _siren = _siren4; _cycleTime = _siren4Time - 0.25; };
        };

        private _dummyA = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummyA attachTo [_car, [0, 0, 0]];
        private _dummyB = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummyB attachTo [_car, [0, 0, 0]];

        private _toggle  = false;
        private _alive   = true;

        // Inline alternating loop — no nested spawn, responsive mode check
        while {_alive && alive _car && _car getVariable "ani_siren" == _ani_siren && !isNull driver _car && damage _car < 0.7 && _car getVariable "ani_lightbar" > 0 && player distance _car <= 850} do {

            private _dummy = if (_toggle) then { _dummyA } else { _dummyB };
            _dummy say3D [_siren, 300];
            // Interior: play on each occupant so sound originates inside the cabin
            { _x say3D [_siren, 50] } forEach crew _car;
            _toggle = !_toggle;

            // Wait full cycle minus offset, checking mode every 0.05s
            private _wakeAt = time + _cycleTime;
            waitUntil {
                sleep 0.05;
                time >= _wakeAt ||
                _car getVariable "ani_siren" != _ani_siren ||
                !alive _car ||
                isNull driver _car ||
                damage _car >= 0.7 ||
                _car getVariable "ani_lightbar" == 0 ||
                player distance _car > 850
            };

            // If mode changed or conditions broken, flag exit
            if (_car getVariable "ani_siren" != _ani_siren || !alive _car || isNull driver _car || damage _car >= 0.7 || _car getVariable "ani_lightbar" == 0 || player distance _car > 850) then {
                _alive = false;
            };
        };

        // Cleanup — deleteVehicle kills all active say3D instantly
        deleteVehicle _dummyA;
        deleteVehicle _dummyB;

    } else {
        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && (_car getVariable ["ani_siren", 1] > 0) && damage _car < 0.7 && (_car getVariable ["ani_lightbar", 1] > 0) && player distance _car <= 850)};
    };
};
