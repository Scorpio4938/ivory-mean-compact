class CfgPatches
{
    class mean_patch
    {
        requiredVersion = 0.1;
        requiredAddons[] = {"Meanscars", "Ivory_Data", "cba_main"};
        units[] = {};
        weapons[] = {};
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
        };
    };
};

class CfgVehicles
{
    // -- CVPI: add emergencySiren so Ivory's fn_sirens knows the siren set --
    // Properties merge additively — no class inheritance corruption here
    class M_CVPI
    {
        emergencySiren = 1;
    };
};
