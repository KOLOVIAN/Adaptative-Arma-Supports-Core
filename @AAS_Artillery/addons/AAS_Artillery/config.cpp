class CfgPatches {
    class AAS_Artillery {
        name = "AAS - Artillery";
        author = "AAS Team";
        url = "";
        
        // Ensure leading backslashes for binarization
        logo = "\aas_artillery\data\aaslogo_ca.paa";      
        logoSmall = "\aas_artillery\data\aaslogo_ca.paa"; 
        logoOver = "\aas_artillery\data\aaslogo_ca.paa";  

        requiredVersion = 1.60; 
        // Added "aas_main" to make this dependent on the core mod
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
    class AAS_ART { 
        class artillery_module {
            // Path must match your $PBOPREFIX$ exactly
            file = "\aas_artillery\functions"; 
            class initsettings {}; // <-- FIXED: Removed { preInit = 1; }
            class initclientartillery { postInit = 1; }; 
            class serverartillery {}; 
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
        class aas_art_fnc_serverartillery { allowedTargets = 2; }; 
    };
};

// =======================================================
// --- CUSTOM SOUNDS REGISTRATION ---
// =======================================================
class CfgSounds {
    sounds[] = {};

    // --- TARGETING VOICES ---
    class aas_art_laserdesignate {
        name = "AAS ART Laser Designate";
        sound[] = {"\aas_artillery\sounds\laserdesignate.ogg", db+2, 1};
        titles[] = {};
    };
    class aas_art_targetexpired {
        name = "AAS ART Target Expired";
        sound[] = {"\aas_artillery\sounds\targetexpired.ogg", db+2, 1};
        titles[] = {};
    };
    class aas_art_targetlocked {
        name = "AAS ART Target Locked";
        sound[] = {"\aas_artillery\sounds\targetlocked.ogg", db+3, 1};
        titles[] = {};
    };

    // --- ARTILLERY VOICES ---
    class aas_art_adamdployed {
        name = "AAS ART ADAM Deployed";
        sound[] = {"\aas_artillery\sounds\adamdeployed.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_adamloaded {
        name = "AAS ART ADAM Loaded";
        sound[] = {"\aas_artillery\sounds\adamloaded.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_dpicmloaded {
        name = "AAS ART DPICM Loaded";
        sound[] = {"\aas_artillery\sounds\dpicmloaded.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_launchingrockets {
        name = "AAS ART Launching Rockets";
        sound[] = {"\aas_artillery\sounds\launchingrockets.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_loadinghe {
        name = "AAS ART Loading HE";
        sound[] = {"\aas_artillery\sounds\loadinghe.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_raamsdeployed {
        name = "AAS ART RAAMS Deployed";
        sound[] = {"\aas_artillery\sounds\raamsdeployed.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_raamsloaded {
        name = "AAS ART RAAMS Loaded";
        sound[] = {"\aas_artillery\sounds\raamsloaded.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_roundscomplete1 {
        name = "AAS ART Rounds Complete 1";
        sound[] = {"\aas_artillery\sounds\roundscomplete1.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_roundscomplete2 {
        name = "AAS ART Rounds Complete 2";
        sound[] = {"\aas_artillery\sounds\roundscomplete2.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_settingmortars {
        name = "AAS ART Setting Mortars";
        sound[] = {"\aas_artillery\sounds\settingmortars.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_splash {
        name = "AAS ART Splash";
        sound[] = {"\aas_artillery\sounds\splash.ogg", db+4, 1};
        titles[] = {};
    };
    class aas_art_wprocketsincoming {
        name = "AAS ART WP Rockets Incoming";
        sound[] = {"\aas_artillery\sounds\wprocketsincoming.ogg", db+4, 1};
        titles[] = {};
    };
};

// =======================================================
// --- CBA EXTENDED EVENT HANDLERS ---
// =======================================================
class Extended_PreInit_EventHandlers {
    class AAS_Artillery_PreInit {
        init = "call compile preprocessFileLineNumbers '\aas_artillery\functions\fn_initsettings.sqf'";
    };
};