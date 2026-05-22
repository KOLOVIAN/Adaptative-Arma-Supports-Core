#include "script_component.hpp"

class CfgPatches {
	class ADDON {

        // Meta information for editor
		name = ADDON_NAME;

        author = "$STR_aas_author";
        authors[] = {"KOLOVIAN", "Nomas / Redwan S. [AET]", "OverlordZorn [CVO]"};
        
        url = "$STR_aas_URL";

		VERSION_CONFIG;

        // Addon Specific Information
        // Minimum compatible version. When the game's version is lower, pop-up warning will appear when launching the game.
        requiredVersion = 2.02;

        // Required addons, used for setting load order.
        // When any of the addons is missing, pop-up warning will appear when launching the game.
        requiredAddons[] = {
			QPVAR(main),
			"cba_main",
			"aas_core",
			"A3_Data_F",
			"A3_UI_F",
			"A3_Data_F",
			"cba_settings"
			};

		// Optional. If this is 1, if any of requiredAddons[] entry is missing in your game the entire config will be ignored and return no error (but in rpt) so useful to make a compat Mod (Since Arma 3 2.14)
		skipWhenMissingDependencies = 1;
        
        // List of objects (CfgVehicles classes) contained in the addon. Important also for Zeus content (units and groups)
        units[] = {};

        // List of weapons (CfgWeapons classes) contained in the addon.
        weapons[] = {};

	};
};

#include "CfgFunctions.hpp"

// =======================================================
// --- GUI INCLUDES ---
// =======================================================
// IMPORTANT: No semicolon at the end of include lines!
#include "ui\aas_tablet_ui.hpp"

// =======================================================
// --- MULTIPLAYER SECURITY ---
// =======================================================
class CfgRemoteExec {
    class Functions {
        mode = 2; 
        jip = 1; 
        class aas_artillery_fnc_serverartillery { allowedTargets = 2; }; 
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
        sound[] = {"\z\aas\addons\artillery\sounds\laserdesignate.ogg", "db+2", 1};
        titles[] = {};
    };
    class aas_art_targetexpired {
        name = "AAS ART Target Expired";
        sound[] = {"\z\aas\addons\artillery\sounds\targetexpired.ogg", "db+2", 1};
        titles[] = {};
    };
    class aas_art_targetlocked {
        name = "AAS ART Target Locked";
        sound[] = {"\z\aas\addons\artillery\sounds\targetlocked.ogg", "db+3", 1};
        titles[] = {};
    };

    // --- ARTILLERY VOICES ---
    class aas_art_adamdployed {
        name = "AAS ART ADAM Deployed";
        sound[] = {"\z\aas\addons\artillery\sounds\adamdeployed.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_adamloaded {
        name = "AAS ART ADAM Loaded";
        sound[] = {"\z\aas\addons\artillery\sounds\adamloaded.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_dpicmloaded {
        name = "AAS ART DPICM Loaded";
        sound[] = {"\z\aas\addons\artillery\sounds\dpicmloaded.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_launchingrockets {
        name = "AAS ART Launching Rockets";
        sound[] = {"\z\aas\addons\artillery\sounds\launchingrockets.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_loadinghe {
        name = "AAS ART Loading HE";
        sound[] = {"\z\aas\addons\artillery\sounds\loadinghe.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_raamsdeployed {
        name = "AAS ART RAAMS Deployed";
        sound[] = {"\z\aas\addons\artillery\sounds\raamsdeployed.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_raamsloaded {
        name = "AAS ART RAAMS Loaded";
        sound[] = {"\z\aas\addons\artillery\sounds\raamsloaded.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_roundscomplete1 {
        name = "AAS ART Rounds Complete 1";
        sound[] = {"\z\aas\addons\artillery\sounds\roundscomplete1.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_roundscomplete2 {
        name = "AAS ART Rounds Complete 2";
        sound[] = {"\z\aas\addons\artillery\sounds\roundscomplete2.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_settingmortars {
        name = "AAS ART Setting Mortars";
        sound[] = {"\z\aas\addons\artillery\sounds\settingmortars.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_splash {
        name = "AAS ART Splash";
        sound[] = {"\z\aas\addons\artillery\sounds\splash.ogg", "db+4", 1};
        titles[] = {};
    };
    class aas_art_wprocketsincoming {
        name = "AAS ART WP Rockets Incoming";
        sound[] = {"\z\aas\addons\artillery\sounds\wprocketsincoming.ogg", "db+4", 1};
        titles[] = {};
    };
};

// =======================================================
// --- CBA EXTENDED EVENT HANDLERS ---
// =======================================================
class Extended_PreInit_EventHandlers {
    class AAS_Artillery_PreInit {
        init = "call compile preprocessFileLineNumbers '\z\aas\addons\artillery\functions\fn_initsettings.sqf'";
    };
};