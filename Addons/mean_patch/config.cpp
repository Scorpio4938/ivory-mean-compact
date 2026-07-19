class CfgPatches
{
    class mean_patch
    {
        requiredVersion = 0.1;
        requiredAddons[] = {"Police", "Meanscars", "Ivory_Data", "cba_main"};
        units[] = {};
        weapons[] = {};
    };
};

// Add Ivory's occlusion values to Mean vehicles.
//
// ROOT CAUSE of interior silence: Ivory vehicles set occludeSoundsWhenIn=2.5
// and obstructSoundsWhenIn=1 (low values, external sounds pass into cabin).
// Mean vehicles OMITS these → engine uses high defaults → #particlesource
// siren blocked inside. attenuationEffectType is the SAME on both (not the cause).
//
// FIX: redefine each base class with its SAME parent (CRFT_Car_Base).
// Specifying the matching parent is what triggers a config MERGE (preserving
// all of Mean's original properties) instead of a REPLACE (which corrupts
// the class and loses scope/side/etc).
//
// CRFT_Car_Base is forward-declared because it is defined inside Mean's config.
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
                file = "\SCORPIO4938_\ivory-mean-compact\Addons\mean_patch\scripts\init.sqf";
            };
        };
        class vehicle
        {
            file = "\SCORPIO4938_\ivory-mean-compact\Addons\mean_patch\functions";
            class initCar {};
            class manual {};
            class sirens {};
        };
    };
};
