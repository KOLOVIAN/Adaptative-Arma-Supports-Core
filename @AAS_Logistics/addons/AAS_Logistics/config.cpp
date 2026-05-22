class CfgPatches {
    class AAS_Logistics {
        name = "AAS - Logistics";
        author = "AAS Team";
        url = "";
        
        // Ensure leading backslashes for binarization
        logo = "\aas_logistics\data\aaslogo_ca.paa";       
        logoSmall = "\aas_logistics\data\aaslogo_ca.paa"; 
        logoOver = "\aas_logistics\data\aaslogo_ca.paa";  

        requiredVersion = 1.60; 
        // Dependent on the core mod
        requiredAddons[] = {"A3_Data_F", "A3_UI_F", "cba_settings", "cba_main", "aas_main"}; 
        units[] = {}; 
        weapons[] = {}; 
    };
};

// =======================================================
// --- GUI INCLUDES ---
// =======================================================
// IMPORTANT: No semicolon at the end of include lines!
#include "ui\aas_tablet_ui.hpp"

// =======================================================
// --- FUNCTIONS REGISTRATION ---
// =======================================================
class CfgFunctions {
    class AAS_LOG { // Prefix updated to LOG
        class logistics_module {
            // Path must match your $PBOPREFIX$ exactly
            file = "\aas_logistics\functions"; 
            class initsettings {}; // <-- FIXED: Removed { preInit = 1; }
            class initclientLogistics { postInit = 1; }; // Client init updated
            class servertransport {}; // Separated transport logic
            class serverdelivery {};  // Separated delivery logic
        };
    };
};

// =======================================================
// --- MULTIPLAYER SECURITY ---
// =======================================================
class CfgRemoteExec {
    class Functions {
        mode = 2; 
        jip = 1; 
        // Whitelist both new server-side functions for execution
        class aas_log_fnc_servertransport { allowedTargets = 2; }; 
        class aas_log_fnc_serverdelivery { allowedTargets = 2; }; 
    };
};

// =======================================================
// --- CUSTOM SOUNDS REGISTRATION ---
// =======================================================
class CfgSounds {
    sounds[] = {}; 
    
    // --- DELIVERY SOUNDS ---
    class log_delivery1 {
        name = "log_delivery1";
        sound[] = {"\aas_logistics\sounds\log_delivery1.ogg", 1, 1};
        titles[] = {};
    };
    class log_delivery2 {
        name = "log_delivery2";
        sound[] = {"\aas_logistics\sounds\log_delivery2.ogg", 1, 1};
        titles[] = {};
    };
    class log_delivery3 {
        name = "log_delivery3";
        sound[] = {"\aas_logistics\sounds\log_delivery3.ogg", 1, 1};
        titles[] = {};
    };
    class log_delivery4 {
        name = "log_delivery4";
        sound[] = {"\aas_logistics\sounds\log_delivery4.ogg", 1, 1};
        titles[] = {};
    };
    class log_delivery5 {
        name = "log_delivery5";
        sound[] = {"\aas_logistics\sounds\log_delivery5.ogg", 1, 1};
        titles[] = {};
    };

    // --- HQ SOUNDS ---
    class log_hq1 {
        name = "log_hq1";
        sound[] = {"\aas_logistics\sounds\log_hq1.ogg", 1, 1};
        titles[] = {};
    };
    class log_hq2 {
        name = "log_hq2";
        sound[] = {"\aas_logistics\sounds\log_hq2.ogg", 1, 1};
        titles[] = {};
    };
    class log_hq3 {
        name = "log_hq3";
        sound[] = {"\aas_logistics\sounds\log_hq3.ogg", 1, 1};
        titles[] = {};
    };
    class log_hq4 {
        name = "log_hq4";
        sound[] = {"\aas_logistics\sounds\log_hq4.ogg", 1, 1};
        titles[] = {};
    };
    class log_hq5 {
        name = "log_hq5";
        sound[] = {"\aas_logistics\sounds\log_hq5.ogg", 1, 1};
        titles[] = {};
    };

    // --- TRANSPORT SOUNDS ---
    class log_transport1 {
        name = "log_transport1";
        sound[] = {"\aas_logistics\sounds\log_transport1.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport2 {
        name = "log_transport2";
        sound[] = {"\aas_logistics\sounds\log_transport2.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport3 {
        name = "log_transport3";
        sound[] = {"\aas_logistics\sounds\log_transport3.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport4 {
        name = "log_transport4";
        sound[] = {"\aas_logistics\sounds\log_transport4.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport5 {
        name = "log_transport5";
        sound[] = {"\aas_logistics\sounds\log_transport5.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport6 {
        name = "log_transport6";
        sound[] = {"\aas_logistics\sounds\log_transport6.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport7 {
        name = "log_transport7";
        sound[] = {"\aas_logistics\sounds\log_transport7.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport8 {
        name = "log_transport8";
        sound[] = {"\aas_logistics\sounds\log_transport8.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport9 {
        name = "log_transport9";
        sound[] = {"\aas_logistics\sounds\log_transport9.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport10 {
        name = "log_transport10";
        sound[] = {"\aas_logistics\sounds\log_transport10.ogg", 1, 1};
        titles[] = {};
    };
};

// =======================================================
// --- CBA EXTENDED EVENT HANDLERS ---
// =======================================================
class Extended_PreInit_EventHandlers {
    class AAS_Logistics_PreInit {
        // Ensures the dedicated server initializes the CBA settings at the correct time
        init = "call compile preprocessFileLineNumbers '\aas_logistics\functions\fn_initsettings.sqf'";
    };
};