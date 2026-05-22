class CfgFunctions
{
    class ADDON
    {
        class COMPONENT
        {

            file = PATH_TO_FUNC;

            class initsettings {}; // <-- FIXED: Removed { preInit = 1; }
            class initclientLogistics { postInit = 1; }; // Client init updated
            class servertransport {}; // Separated transport logic
            class serverdelivery {};  // Separated delivery logic

        };
    };
};