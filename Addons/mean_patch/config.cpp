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
                file = "scripts\init.sqf";
            };
        };
        class vehicle
        {
            file = "functions";
            class initCar {};
            class manual {};
        };
    };
};

class CfgVehicles
{
    // -- CVPI base: add emergencySiren property (merged into existing class) --
    class M_CVPIbase
    {
        emergencySiren = 1;
    };

    // -- CVPI: replace init event handler + add Read Manual --
    class M_CVPI
    {
        class EventHandlers
        {
            init = "this spawn mean_patch_fnc_initCar";
        };
        class UserActions
        {
            class Read_Manual
            {
                displayName = "<t color='#4EB1BA'>Read Manual</t>";
                position = "drivewheel";
                radius = 10;
                condition = "driver this == player";
                statement = "[this] call mean_patch_fnc_manual;";
                showWindow = 0;
                onlyForPlayer = 1;
            };
        };
    };
};
