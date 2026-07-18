// mean_patch_fnc_sirens
// EXACT copy of ivory_fnc_sirens — only change: emergencySiren is hardcoded to 1 (SS2000)
// instead of reading from vehicle config (which we can't safely modify on external classes).

if(isDedicated) exitWith {};
params ["_car"];

private _siren1 = "";
private _siren1Time = "";
private _siren2 = "";
private _siren2Time = "";
private _siren3 = "";
private _siren3Time = "";
private _siren4 = "";
private _siren4Time = "";
private _emergencySiren = 1;

_dummy = ObjNull;

call 
{
	if(_emergencySiren isEqualTo 1) exitWith
	{
		_siren1 = "ivory_ss2000_wail";
		_siren1Time = 20.742;
		_siren2 = "ivory_ss2000_yelp";
		_siren2Time = 5.038;
		_siren3 = "ivory_ss2000_priority";
		_siren3Time = 9.862;
		_siren4 = "ivory_ss2000_hilo";
		_siren4Time = 10.211;
	};
	if(_emergencySiren isEqualTo 2) exitWith
	{
		_siren1 = "ivory_pa300_wail";
		_siren1Time = 18.641;
		_siren2 = "ivory_pa300_yelp";
		_siren2Time = 10.322;
		_siren3 = "ivory_pa300_priority";
		_siren3Time = 10.674;
		_siren4 = "ivory_pa300_hilo";
		_siren4Time = 14.984;
	};
};

while {alive _car} do 
{    
   
	if (alive _car && !isNull driver _car && _car getVariable "ani_siren" > 0 && damage _car < 0.7 && (_car getVariable "ani_lightbar" > 0) && (player distance _car <= 850) ) then {			
	
		private _ani_siren = _car getVariable "ani_siren";

		_type = 0;
		_siren = "";
		_sirenTime = 0;
		
		call 
		{
			if(_ani_siren isEqualTo 1) exitWith
			{
				_type = 1;
				_siren = _siren1;
				_sirenTime = _siren1Time;
			};
			if(_ani_siren isEqualTo 2) exitWith
			{
				_type = 2;
				_siren = _siren2;
				_sirenTime = _siren2Time;
			};
			if(_ani_siren isEqualTo 3) exitWith
			{
				_type = 3;
				_siren = _siren3;
				_sirenTime = _siren3Time;
			};
			if(_ani_siren isEqualTo 4) exitWith
			{
				_type = 4;
				_siren = _siren4;
				_sirenTime = _siren4Time;
			};
		};

		_dummy = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
		_dummy attachTo [_car,[0,0,0]];

		[_car,_siren,_sirenTime,_type,_dummy] spawn {
			params["_car","_siren","_sirenTime","_type","_dummy"];
			while{_car getVariable "ani_siren" == _type && !isNull driver _car} do {
				_timeStarted = time;
				_dummy say3D [_siren,300];

				waitUntil { time >= _timeStarted + _sirenTime || _car getVariable "ani_siren" != _type || isNull driver _car };
			};
		};
		
		waitUntil { _car getVariable "ani_siren" != _type };

		detach _dummy;
		deleteVehicle _dummy;

	} else {
		waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && (_car getVariable ["ani_siren",1] > 0) && damage _car < 0.7 && (_car getVariable ["ani_lightbar",1] > 0) && player distance _car <= 850) };
	};
};
