class CfgFunctions
{
    class ADDON
    {
        class COMPONENT
        {

            file = PATH_TO_FUNC;

            class initsettings {}; // <-- FIXED: Removed { preInit = 1; }
            class initclientairstrikes { postInit = 1; }; 
            class seteconomypreset {}; 
            class serverairstrikes {}; 

        };
    };
};