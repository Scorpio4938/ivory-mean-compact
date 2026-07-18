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
            class sirens {};
        };
    };
};

// CBA Extended Init Event Handler — properly suppresses the vanilla config init
class Extended_Init_EventHandlers
{
    class M_CVPI
    {
        class mean_patch_suppress
        {
            init = "this spawn mean_patch_fnc_initCar";
            override = 1;
        };
    };
};
