class CfgPatches
{
    class mean_patch
    {
        requiredVersion = 0.1;
        requiredAddons[] = {"Meanscars", "Police", "Ivory_Data", "cba_main"};
        units[] = {};
        weapons[] = {};
    };
};

// Override Mean vehicle attenuation so siren audio is audible inside the cabin
class CfgVehicles
{
    class M_CVPIbase: M_CVPIbase { attenuationEffectType = "DefaultAttenuation"; };
    class M_Charger12base: M_Charger12base { attenuationEffectType = "DefaultAttenuation"; };
    class M_Tahoebase: M_Tahoebase { attenuationEffectType = "DefaultAttenuation"; };
    class M_Ambulancebase: M_Ambulancebase { attenuationEffectType = "DefaultAttenuation"; };
    class M_FPISbase: M_FPISbase { attenuationEffectType = "DefaultAttenuation"; };
    class M_Silveradobase: M_Silveradobase { attenuationEffectType = "DefaultAttenuation"; };
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
