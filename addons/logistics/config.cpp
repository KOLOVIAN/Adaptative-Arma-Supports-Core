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
			"A3_Data_F",
			"A3_UI_F",
			"cba_settings",
			"aas_core"
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
        // Whitelist both new server-side functions for execution
        class aas_logistics_fnc_servertransport { allowedTargets = 2; }; 
        class aas_logistics_fnc_serverdelivery { allowedTargets = 2; }; 
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
        sound[] = {"\z\aas\addons\logistics\sounds\log_delivery1.ogg", 1, 1};
        titles[] = {};
    };
    class log_delivery2 {
        name = "log_delivery2";
        sound[] = {"\z\aas\addons\logistics\sounds\log_delivery2.ogg", 1, 1};
        titles[] = {};
    };
    class log_delivery3 {
        name = "log_delivery3";
        sound[] = {"\z\aas\addons\logistics\sounds\log_delivery3.ogg", 1, 1};
        titles[] = {};
    };
    class log_delivery4 {
        name = "log_delivery4";
        sound[] = {"\z\aas\addons\logistics\sounds\log_delivery4.ogg", 1, 1};
        titles[] = {};
    };
    class log_delivery5 {
        name = "log_delivery5";
        sound[] = {"\z\aas\addons\logistics\sounds\log_delivery5.ogg", 1, 1};
        titles[] = {};
    };

    // --- HQ SOUNDS ---
    class log_hq1 {
        name = "log_hq1";
        sound[] = {"\z\aas\addons\logistics\sounds\log_hq1.ogg", 1, 1};
        titles[] = {};
    };
    class log_hq2 {
        name = "log_hq2";
        sound[] = {"\z\aas\addons\logistics\sounds\log_hq2.ogg", 1, 1};
        titles[] = {};
    };
    class log_hq3 {
        name = "log_hq3";
        sound[] = {"\z\aas\addons\logistics\sounds\log_hq3.ogg", 1, 1};
        titles[] = {};
    };
    class log_hq4 {
        name = "log_hq4";
        sound[] = {"\z\aas\addons\logistics\sounds\log_hq4.ogg", 1, 1};
        titles[] = {};
    };
    class log_hq5 {
        name = "log_hq5";
        sound[] = {"\z\aas\addons\logistics\sounds\log_hq5.ogg", 1, 1};
        titles[] = {};
    };

    // --- TRANSPORT SOUNDS ---
    class log_transport1 {
        name = "log_transport1";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport1.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport2 {
        name = "log_transport2";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport2.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport3 {
        name = "log_transport3";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport3.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport4 {
        name = "log_transport4";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport4.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport5 {
        name = "log_transport5";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport5.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport6 {
        name = "log_transport6";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport6.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport7 {
        name = "log_transport7";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport7.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport8 {
        name = "log_transport8";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport8.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport9 {
        name = "log_transport9";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport9.ogg", 1, 1};
        titles[] = {};
    };
    class log_transport10 {
        name = "log_transport10";
        sound[] = {"\z\aas\addons\logistics\sounds\log_transport10.ogg", 1, 1};
        titles[] = {};
    };
};

// =======================================================
// --- CBA EXTENDED EVENT HANDLERS ---
// =======================================================
class Extended_PreInit_EventHandlers {
    class AAS_Logistics_PreInit {
        // Ensures the dedicated server initializes the CBA settings at the correct time
        init = "call compile preprocessFileLineNumbers '\z\aas\addons\logistics\functions\fn_initsettings.sqf'";
    };
};