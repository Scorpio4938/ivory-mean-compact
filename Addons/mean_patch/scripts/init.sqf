#include "\a3\editor_f\Data\Scripts\dikCodes.h"

// Macro for the Mean vehicle gate check, mirrors Ivory's gate pattern
// Checks that the current vehicle is a Mean vehicle (any model variant)
// and that the player is the driver (or front passenger for passenger-accessible actions)
#define MEAN_VEHICLE_GATE \
    private _vcl = vehicle player; \
    if (isNull _vcl) exitWith {}; \
    private _type = typeOf _vcl; \
    if (_type find "M_CVPI"      < 0 && \
        _type find "M_Charger12" < 0 && \
        _type find "M_Tahoe"     < 0 && \
        _type find "M_FPIS"      < 0 && \
        _type find "M_Ambulance" < 0 && \
        _type find "M_Silverado" < 0) exitWith {};

#define MEAN_DRIVER_GATE \
    MEAN_VEHICLE_GATE \
    if (dialog) exitWith {}; \
    if (driver _vcl != player) exitWith {};

// ──────────────────────────────────────
// Horn — hold F
// ──────────────────────────────────────
["Mean Patch", "mean_horn", ["Car Horn", ""], {
    MEAN_DRIVER_GATE
    _vcl setVariable ["ani_horn", 1, true];
}, {
    private _vcl = vehicle player;
    if (!isNull _vcl) then {
        _vcl setVariable ["ani_horn", 0, true];
    };
}, [DIK_F, [false, false, false]], true] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Siren toggle — R  (on: siren+lightbar, off: siren only)
// ──────────────────────────────────────
["Mean Patch", "mean_sirens", ["Emergency - Sirens", ""], {
    MEAN_DRIVER_GATE
    playSound "ivory_beep2";
    if (_vcl getVariable "ani_siren" == 0) then {
        // Turn on: siren + lightbar together
        _vcl setVariable ["ani_lightbar", (_vcl getVariable ["ani_lightbar_todo", 1]), true];
        _vcl setVariable ["ani_siren",    (_vcl getVariable ["ani_siren_todo",    1]), true];
        _vcl animate ["ani_lightbar", 0.1];
    } else {
        // Turn off: siren only, lightbar stays
        _vcl setVariable ["ani_siren", 0, true];
    };
}, {}, [DIK_R, [true, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Next siren tone — Shift+R
// ──────────────────────────────────────
["Mean Patch", "mean_sirens_next", ["Emergency - Sirens (Next)", ""], {
    MEAN_DRIVER_GATE
    playSound "ivory_beep2";

    private _todo = _vcl getVariable ["ani_siren_todo", 1];

    if (_todo == 1) exitWith {
        _vcl setVariable ["ani_siren_todo", 2];
        if (_vcl getVariable "ani_siren" > 0) then { _vcl setVariable ["ani_siren", 2, true]; };
    };
    if (_todo == 2) exitWith {
        _vcl setVariable ["ani_siren_todo", 3];
        if (_vcl getVariable "ani_siren" > 0) then { _vcl setVariable ["ani_siren", 3, true]; };
    };
    if (_todo == 3) exitWith {
        _vcl setVariable ["ani_siren_todo", 4];
        if (_vcl getVariable "ani_siren" > 0) then { _vcl setVariable ["ani_siren", 4, true]; };
    };
    if (_todo == 4) exitWith {
        _vcl setVariable ["ani_siren_todo", 1];
        if (_vcl getVariable "ani_siren" > 0) then { _vcl setVariable ["ani_siren", 1, true]; };
    };
}, {}, [DIK_R, [true, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Direct siren phases — 1 / 2 / 3 / 4
// ──────────────────────────────────────
["Mean Patch", "mean_sirens_phase_1", ["Emergency - Sirens (Wail)", ""], {
    MEAN_DRIVER_GATE
    if (_vcl getVariable "ani_siren" > 0) then {
        _vcl setVariable ["ani_siren", 1, true];
        playSound "ivory_beep2";
    };
    _vcl setVariable ["ani_siren_todo", 1];
}, {}, [DIK_1, [false, false, false]]] call CBA_fnc_addKeybind;

["Mean Patch", "mean_sirens_phase_2", ["Emergency - Sirens (Yelp)", ""], {
    MEAN_DRIVER_GATE
    if (_vcl getVariable "ani_siren" > 0) then {
        _vcl setVariable ["ani_siren", 2, true];
        playSound "ivory_beep2";
    };
    _vcl setVariable ["ani_siren_todo", 2];
}, {}, [DIK_2, [false, false, false]]] call CBA_fnc_addKeybind;

["Mean Patch", "mean_sirens_phase_3", ["Emergency - Sirens (Priority)", ""], {
    MEAN_DRIVER_GATE
    if (_vcl getVariable "ani_siren" > 0) then {
        _vcl setVariable ["ani_siren", 3, true];
        playSound "ivory_beep2";
    };
    _vcl setVariable ["ani_siren_todo", 3];
}, {}, [DIK_3, [false, false, false]]] call CBA_fnc_addKeybind;

["Mean Patch", "mean_sirens_phase_4", ["Emergency - Sirens (HiLo)", ""], {
    MEAN_DRIVER_GATE
    if (_vcl getVariable "ani_siren" > 0) then {
        _vcl setVariable ["ani_siren", 4, true];
        playSound "ivory_beep2";
    };
    _vcl setVariable ["ani_siren_todo", 4];
}, {}, [DIK_4, [false, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Lightbar toggle — T (off kills siren too)
// ──────────────────────────────────────
["Mean Patch", "mean_lights", ["Emergency - Lights", ""], {
    MEAN_DRIVER_GATE
    playSound "ivory_beep2";
    if (_vcl getVariable "ani_lightbar" == 0) then {
        // Turn on
        _vcl setVariable ["ani_lightbar", (_vcl getVariable ["ani_lightbar_todo", 1]), true];
        _vcl animate ["ani_lightbar", 0.1];
    } else {
        // Turn off: lightbar + siren both off
        _vcl setVariable ["ani_lightbar", 0, true];
        _vcl setVariable ["ani_siren", 0, true];
        _vcl animate ["ani_lightbar", 0];
    };
}, {}, [DIK_T, [false, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Takedown lights — hold C  (sets both Ivory var and Mean animation)
// ──────────────────────────────────────
["Mean Patch", "mean_takedown", ["Emergency - Takedown", ""], {
    MEAN_DRIVER_GATE
    _vcl setVariable ["ani_takedown", 1, true];
}, {
    private _vcl = vehicle player;
    if (!isNull _vcl) then {
        _vcl setVariable ["ani_takedown", 0, true];
    };
}, [DIK_C, [false, false, false]], true] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Read Manual — Backslash
// ──────────────────────────────────────
["Mean Patch", "mean_manual", ["Read Manual", ""], {
    MEAN_VEHICLE_GATE
    if (dialog) exitWith {};
    if (driver _vcl == player || (_vcl getCargoIndex player) == 0) then {
        [_vcl] call mean_patch_fnc_manual;
    };
}, {}, [DIK_BACKSLASH, [false, false, false]]] call CBA_fnc_addKeybind;

// ──────────────────────────────────────
// Init override — registers all 37 Mean concrete vehicle classes
// ──────────────────────────────────────
private _allMeanClasses = [
    // CVPI (10 variants)
    "M_CVPI",
    "M_CVPI_Supervisor",
    "M_CVPI_Slick",
    "M_CVPI_NEW",
    "M_CVPI_EMS",
    "M_CVPI_UC_Black",
    "M_CVPI_UC_White",
    "M_CVPI_UC_Blue",
    "M_CVPI_UC_Grey",
    "M_CVPI_UC_Red",
    // Charger 2012 (8 variants)
    "M_Charger12",
    "M_Charger12_NEW",
    "M_Charger12_Slick",
    "M_Charger12_UC_Black",
    "M_Charger12_UC_White",
    "M_Charger12_UC_Blue",
    "M_Charger12_UC_Grey",
    "M_Charger12_UC_Red",
    // Tahoe 2015 (9 variants)
    "M_Tahoe",
    "M_Tahoe_supervisor",
    "M_Tahoe_NEW",
    "M_Tahoe_EMS",
    "M_Tahoe_UC_Black",
    "M_Tahoe_UC_White",
    "M_Tahoe_UC_Blue",
    "M_Tahoe_UC_Grey",
    "M_Tahoe_UC_Red",
    // FPIS Taurus (7 variants)
    "M_FPIS",
    "M_FPIS_NEW",
    "M_FPIS_slick",
    "M_FPIS_UC_White",
    "M_FPIS_UC_Blue",
    "M_FPIS_UC_Grey",
    "M_FPIS_UC_Red",
    // Ambulance (1 variant)
    "M_Ambulance",
    // Silverado (2 variants)
    "M_Silverado",
    "M_Silverado_cab"
];

{
    [_x, "init", {
        params ["_car"];
        _car spawn mean_patch_fnc_initCar;
    }, true, [], true] call CBA_fnc_addClassEventHandler;
} forEach _allMeanClasses;
