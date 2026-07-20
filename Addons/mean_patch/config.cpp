// mean_patch config.cpp
// ======================
// Standalone compatibility patch: ports Ivory Car Pack's siren audio, horn,
// takedown, and keybind system onto Means Emergency Vehicle Pack.
//
// Architecture:
//   Config handles:   CfgPatches dependency chain, CfgVehicles occlusion fix
//                     (config merge pattern), CfgFunctions declaration
//   Scripts handle:   CBA keybinds + lazy init trigger (postInit/init.sqf)
//   Functions handle: siren/horn/takedown audio loops (Ivory-based),
//                     manual display (fn_*.sqf)
//
// Ivory approach used:
//   - Variables ani_horn/ani_siren/ani_siren_todo/ani_lightbar/ani_lightbar_todo
//     follow Ivory's naming and semantics exactly (siren functions read them
//     via getVariable in while-loops)
//   - #particlesource + say3D for audio output (same as Ivory)
//   - CBA keybinds for controls (Ivory uses CBA keybinds too)
//   - Sound classes (ivory_ss2000_*) are defined in Ivory_Data and used unchanged
//
// Why NOT a config-level EventHandlers.init override:
//   Mean's concrete classes already define their own init string in config
//   ("_this execVM '...init.sqf'"). Redefining it replaces Mean's lightbar/
//   flasher/radar scripts. We need to ADD alongside, not replace. So CBA
//   XEH (GetIn handler) is used instead — see scripts/init.sqf.
// ======================

class CfgPatches
{
    class mean_patch
    {
        requiredVersion = 0.1;
        // requiredAddons ensures these mods load BEFORE mean_patch.
        // "Police" + "Meanscars" = Mean's main PBO (each vehicle defines its
        //   own class under CfgPatches { class Police { ... }; }, and
        //   Meanscars is the global addon wrapper)
        // "Ivory_Data" = Ivory's shared data (sound configs for ss2000/pa300)
        // "cba_main" = CBA framework (keybinds, XEH, settings)
        requiredAddons[] = {"Police", "Meanscars", "Ivory_Data", "cba_main"};
        units[] = {};
        weapons[] = {};
    };
};

// ────────────────────────────────────────
// CfgVehicles — occlusion fix (interior siren audibility)
// ────────────────────────────────────────
//
// Ivory approach used: occludeSoundsWhenIn = 2.5 and obstructSoundsWhenIn = 1
// are taken directly from Ivory's vehicle configs. These tell the engine:
//   - occludeSoundsWhenIn = 2.5  — low occlusion threshold (external sounds
//     pass into cabin at close range)
//   - obstructSoundsWhenIn = 1   — minimal obstruction (sounds pass through
//     windows/body easier)
//
// ROOT CAUSE of interior silence: Mean vehicles OMIT these properties entirely,
// so the engine uses high defaults → #particlesource siren sound outside the
// vehicle is mostly blocked when heard from inside the cabin.
// attenuationEffectType is IDENTICAL on both ("CarAttenuation") — NOT the cause.
//
// FIX: redefine each Mean base class with the matching parent.
//
// Config merge pattern (critical — wrong pattern corrupts the class):
//   ❌ WRONG: class M_CVPIbase: M_CVPIbase { ... }  self-reference = replace
//   ❌ WRONG: class M_CVPIbase { ... }               no parent = replace
//   ✅ CORRECT: class CRFT_Car_Base;
//              class M_CVPIbase: CRFT_Car_Base { ... }
//
// Why this pattern works:
//   1. Forward-declare CRFT_Car_Base (it's defined inside Mean's PBO)
//   2. Redefine M_CVPIbase with its ACTUAL parent (CRFT_Car_Base)
//   3. Arma's config compiler sees "same class + same parent" = MERGE
//      (add/override properties while preserving scope, side, model, etc.)
//      Using a DIFFERENT parent or NO parent = REPLACE (class gets wiped)
//
// Why 6 BASE classes, not 37 concrete classes:
//   Adding occludeSoundsWhenIn to the base propagates to ALL derived classes
//   (M_CVPI, M_CVPI_Supervisor, ..., M_Charger12, ..., M_Tahoe, etc.)
//   No need to touch each concrete class.
//
// Note: occlusion fix is a STATIC config property — it applies regardless of
// whether our scripts initialize the vehicle. Sounds play correctly even for
// vanilla Mean sirens from inside the cabin.
// ────────────────────────────────────────
class CfgVehicles
{
    class CRFT_Car_Base;
    class M_CVPIbase: CRFT_Car_Base
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_Charger12base: CRFT_Car_Base
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_Tahoebase: CRFT_Car_Base
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_Ambulancebase: CRFT_Car_Base
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_FPISbase: CRFT_Car_Base
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_Silveradobase: CRFT_Car_Base
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
};

class CfgFunctions
{
    class mean_patch
    {
        project = "mean_patch";
        tag = "mean_patch";
        class Init
        {
            class Init
            {
                postInit = 1;
                // P: drive path convention: \SCORPIO4938_\ivory-mean-compact\Addons\
                // matches the user's Windows P: drive folder structure for MakePBO.
                // MakePBO auto-converts these to the internal PBO file structure.
                file = "\SCORPIO4938_\ivory-mean-compact\Addons\mean_patch\scripts\init.sqf";
            };
        };
        class vehicle
        {
            // Functions are grouped under "vehicle" class for CfgFunctions auto-resolution.
            // Functions like fn_initCar.sqf inside this folder path are callable as
            // mean_patch_fnc_initCar (tag + "_fnc_" + filename minus .sqf).
            // Empty bodies {} are correct — CfgFunctions resolves file names from the
            // CfgFunctions class names, not the body content.
            file = "\SCORPIO4938_\ivory-mean-compact\Addons\mean_patch\functions";
            class initCar {};
            class manual {};
            class sirens {};
            class takedown {};
            class horn {};
        };
    };
};
