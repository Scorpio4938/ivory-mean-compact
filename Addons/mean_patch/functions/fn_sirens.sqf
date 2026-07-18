// mean_patch_fnc_sirens
// Looping siren audio using createSoundSource with native isLooping=true.
// No say3D while-loop gaps — the engine handles seamless looping internally.
// Same sound class names from Ivory_Data CfgSounds.

if (!hasInterface) exitWith {};
params ["_car"];

private _siren1     = "ivory_ss2000_wail";
private _siren2     = "ivory_ss2000_yelp";
private _siren3     = "ivory_ss2000_priority";
private _siren4     = "ivory_ss2000_hilo";

private _currentTone = 0;
private _soundSource = objNull;

while {alive _car} do
{
    if (alive _car && !isNull driver _car && _car getVariable "ani_siren" > 0 && damage _car < 0.7 && (_car getVariable "ani_lightbar" > 0) && (player distance _car <= 850)) then {

        private _ani_siren = _car getVariable "ani_siren";

        private _siren = "";
        call {
            if (_ani_siren == 1) exitWith { _siren = _siren1; };
            if (_ani_siren == 2) exitWith { _siren = _siren2; };
            if (_ani_siren == 3) exitWith { _siren = _siren3; };
            if (_ani_siren == 4) exitWith { _siren = _siren4; };
        };

        // Only create a new sound source if the tone changed
        if (_currentTone != _ani_siren || isNull _soundSource) then {
            if (!isNull _soundSource) then { deleteVehicle _soundSource; };

            _soundSource = createSoundSource [_siren, getPosWorld _car, [], 0, 300, 1, true];
            _soundSource attachTo [_car, [0,0,0]];
            _currentTone = _ani_siren;
        };

        // Wait until mode changes or conditions break
        waitUntil {
            sleep 0.1;
            _car getVariable "ani_siren" != _currentTone ||
            !alive _car ||
            isNull driver _car ||
            damage _car >= 0.7 ||
            _car getVariable "ani_lightbar" == 0 ||
            player distance _car > 850
        };

        // Clean up
        if (!isNull _soundSource) then { deleteVehicle _soundSource; _soundSource = objNull; };
        _currentTone = 0;

    } else {
        // Not playing — clean up if needed
        if (!isNull _soundSource) then { deleteVehicle _soundSource; _soundSource = objNull; };
        _currentTone = 0;

        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && (_car getVariable ["ani_siren", 1] > 0) && damage _car < 0.7 && (_car getVariable ["ani_lightbar", 1] > 0) && player distance _car <= 850)};
    };
};
