// mean_patch_fnc_takedown
// Hold-to-play priority/wail tone. Dual-dummy alternation (consistent with
// fn_sirens) prevents gaps on long holds. Cancellable via deleteVehicle.
// When siren active and not in priority mode: plays priority tone.
// Otherwise: plays wail tone.

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
