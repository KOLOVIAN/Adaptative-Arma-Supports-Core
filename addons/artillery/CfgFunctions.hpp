class CfgFunctions
{
    class ADDON
    {
        class COMPONENT
        {

            file = PATH_TO_FUNC;

            class initsettings {}; // <-- FIXED: Removed { preInit = 1; }
            class initclientartillery { postInit = 1; }; 
            class serverartillery {}; 

        };
    };
};