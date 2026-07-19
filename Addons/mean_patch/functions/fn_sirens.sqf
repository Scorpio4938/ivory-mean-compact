// ============================================================
// mean_patch_fnc_sirens — siren audio loop
// ============================================================
//
// Based on Ivory's siren system: #particlesource + say3D.
// Interior audio is handled by config (occludeSoundsWhenIn/obstructSoundsWhenIn).
//
// Ivory approach used:
//   - Same variable names (ani_siren, ani_lightbar)
//   - Same sound classes (ivory_ss2000_wail/yelp/priority/hilo)
//   - Same outer structure: while{ alive _car } -> if/else -> idle/active
//   - Same guard conditions (damage < 0.7, lightbar > 0, player distance)
//
// How it works:
//   1. Idle loop (else branch): sleeps 0.01 between checks, waiting for
//      ani_siren > 0, driver present, lightbar on, etc.
//   2. Active loop (if branch): creates TWO #particlesource dummies,
//      alternates say3D between them, checks for mode changes per-frame.
//   3. On exit (mode change / deletion): deleteVehicle kills both dummies,
//      stopping all sound instantly.
//
// Why dual-dummy (vs Ivory's single-dummy):
//   Ivory uses a single dummy + a separate spawn for the inner loop.
//   This works for Ivory because their vehicles have fewer competing
//   scripts (less scheduler jitter). On Mean vehicles, Mean's background
//   scripts (Lightbar.sqf, sirenscv.sqf, radar.sqf, Flashers.sqf) create
//   scheduler contention that causes 1-3 frame timing drift on siren loop
//   boundaries. With a single dummy, this drift sometimes causes the new
//   say3D to arrive before the old one finishes — and #particlesource only
//   supports 1 concurrent say3D, so the new call cancels the old one,
//   creating an audible gap. Dual-dummy alternation ensures the old sound
//   always finishes before alternation, eliminating gaps.
//
// Why overlap offsets (_cycleTime - 0.10/0.12/0.15):
//   Each siren's loop duration has a small offset subtracted to overlap
//   the next cycle slightly, compensating for scheduler jitter.
//   Different offset per tone because each has different duration/loop
//   characteristics:
//     Wail     (20.742s) - 0.15  (long loop, more drift possible)
//     Yelp     ( 5.038s) - 0.10  (short loop, less drift)
//     Priority ( 9.862s) - 0.10  (tight loop)
//     HiLo     (10.211s) - 0.12  (medium loop)
//
// Why deleteVehicle (not detach):
//   _car say3D accumulates sounds — multiple concurrent calls stack and
//   never stop (vehicle object). #particlesource dummies are the ONLY
//   guaranteed cleanup: deleteVehicle removes the object, killing its
//   say3D instantly. detach wouldn't stop the sound.
//
// Why inner while has NO sleep:
//   The waitUntil uses time >= _wakeAt (pure time comparison, no sleep).
//   This minimizes drift — a sleep inside would introduce additional
//   scheduler delay. The condition is checked every frame by the engine.
//
// ============================================================

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
            if (_ani_siren == 1) exitWith { _siren = _siren1; _cycleTime = _siren1Time - 0.15; };
            if (_ani_siren == 2) exitWith { _siren = _siren2; _cycleTime = _siren2Time - 0.10; };
            if (_ani_siren == 3) exitWith { _siren = _siren3; _cycleTime = _siren3Time - 0.10; };
            if (_ani_siren == 4) exitWith { _siren = _siren4; _cycleTime = _siren4Time - 0.12; };
        };

        // Dual-dummy: alternating particlesources so neither cancels its own sound
        private _dummyA = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummyA attachTo [_car, [0, 0, 0]];
        private _dummyB = "#particlesource" createVehicleLocal ASLToAGL getPosWorld _car;
        _dummyB attachTo [_car, [0, 0, 0]];

        private _toggle = false;

        // Inner loop — per-frame check like Ivory (no sleep)
        while {alive _car && _car getVariable "ani_siren" == _ani_siren && !isNull driver _car && damage _car < 0.7 && _car getVariable "ani_lightbar" > 0 && player distance _car <= 850} do {

            private _dummy = if (_toggle) then { _dummyA } else { _dummyB };
            _dummy say3D [_siren, 300];
            _toggle = !_toggle;

            private _wakeAt = time + _cycleTime;
            waitUntil {
                time >= _wakeAt ||
                _car getVariable "ani_siren" != _ani_siren ||
                !alive _car ||
                isNull driver _car ||
                damage _car >= 0.7 ||
                _car getVariable "ani_lightbar" == 0 ||
                player distance _car > 850
            };
        };

        deleteVehicle _dummyA;
        deleteVehicle _dummyB;

    } else {
        waitUntil {sleep 0.01; !alive _car || (!isNull driver _car && (_car getVariable ["ani_siren", 1] > 0) && damage _car < 0.7 && (_car getVariable ["ani_lightbar", 1] > 0) && player distance _car <= 850)};
    };
};
