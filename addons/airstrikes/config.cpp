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
        requiredAddons[] = {QPVAR(main),"cba_main","A3_Data_F", "A3_UI_F", "cba_settings", "aas_core"};

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
        class airstrikes_fnc_serverairstrikes { allowedTargets = 2; }; 
    };
};

// =======================================================
// --- CUSTOM SOUNDS REGISTRATION ---
// =======================================================
class CfgSounds {
    sounds[] = {};
    class aas_as_brrrt {
        name = "AAS AS Brrrt";
        sound[] = {"\z\aas\addons\airstrikes\sounds\brrrt.ogg", "db+25", 1}; 
        titles[] = {};
    };
    class aas_as_hqmissile {
        name = "AAS AS HQ Missile";
        sound[] = {"\z\aas\addons\airstrikes\sounds\hqmissile.ogg", "db+5", 1};
        titles[] = {};
    };
    class aas_as_laserdesignate {
        name = "AAS AS Laser Designate";
        sound[] = {"\z\aas\addons\airstrikes\sounds\laserdesignate.ogg", "db+2", 1};
        titles[] = {};
    };
    class aas_as_pilotcarpet {
        name = "AAS AS Pilot Carpet Bombing";
        sound[] = {"\z\aas\addons\airstrikes\sounds\pilotcarpet.ogg", "db+7", 1};
        titles[] = {};
    };
    class aas_as_pilotgunrun {
        name = "AAS AS Pilot Gun Run";
        sound[] = {"\z\aas\addons\airstrikes\sounds\pilotgunrun.ogg", "db+7", 1};
        titles[] = {};
    };
    class aas_as_pilotjdam {
        name = "AAS AS Pilot JDAM";
        sound[] = {"\z\aas\addons\airstrikes\sounds\pilotjdam.ogg", "db+7", 1};
        titles[] = {};
    };
    class aas_as_pilotmidnightsun {
        name = "AAS AS Pilot Midnight Sun";
        sound[] = {"\z\aas\addons\airstrikes\sounds\pilotmidnightsun.ogg", "db+7", 1};
        titles[] = {};
    };
    class aas_as_targetexpired {
        name = "AAS AS Target Expired";
        sound[] = {"\z\aas\addons\airstrikes\sounds\targetexpired.ogg", "db+2", 1};
        titles[] = {};
    };
    class aas_as_targetlocked {
        name = "AAS AS Target Locked";
        sound[] = {"\z\aas\addons\airstrikes\sounds\targetlocked.ogg", "db+3", 1};
        titles[] = {};
    };
};

// =======================================================
// --- CBA EXTENDED EVENT HANDLERS ---
// =======================================================
class Extended_PreInit_EventHandlers {
    class airstrikes_PreInit {
        // Double check this path exactly matches your PBO structure!
        init = "call compile preprocessFileLineNumbers '\z\aas\addons\airstrikes\functions\fn_initsettings.sqf'";
    };
};