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
// and obstructSoundsWhenIn=1, allowing external sounds (#particlesource siren)
// to pass through into the cabin. Mean vehicles omit these properties, so the
// engine uses high defaults that block external sounds inside.
//
// FIX: bare-class merge adds these properties to the existing Mean base classes.
// "Police" in requiredAddons ensures our addon loads AFTER Mean, so the merge
// preserves the original CRFT_Car_Base parent inheritance.
class CfgVehicles
{
    class M_CVPIbase
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_Charger12base
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_Tahoebase
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_Ambulancebase
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_FPISbase
    {
        occludeSoundsWhenIn = 2.5;
        obstructSoundsWhenIn = 1;
    };
    class M_Silveradobase
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
