class CfgFunctions
{
    class ADDON
    {
        class COMPONENT
        {

            file = PATH_TO_FUNC;

            class initSettings {}; // <-- FIXED: Removed { preInit = 1; }
            class initClient { postInit = 1; }; 
            class initServer { postInit = 1; };
            class serverCAS {};
            class serverReinforcements {};
            class serverSupplyDrop {};
            class setEconomyPreset {}; 
            class edenExport {}; // Registered the exporter

        };
    };
};