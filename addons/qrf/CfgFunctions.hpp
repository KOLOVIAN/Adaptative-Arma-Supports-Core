class CfgFunctions
{
    class ADDON
    {
        class COMPONENT
        {

            file = PATH_TO_FUNC;

            class initSettings {}; // <-- FIXED: Removed { preInit = 1; }
            class initClientQRF { postInit = 1; }; 
            class setEconomyPreset {}; 
            class serverQRF {}; 
            class moduleQRF {}; // ADDED: Registers the Zeus script

        };
    };
};
