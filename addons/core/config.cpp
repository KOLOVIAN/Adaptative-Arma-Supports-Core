#include "script_component.hpp"

class CfgPatches {
	class ADDON {

        // Meta information for editor
		name = ADDON_NAME;

        author = "$STR_aas_author";
        authors[] = {"KOLOVIAN"};
        
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
            "A3_Modules_F", 
            "A3_Modules_F_Curator",  
            "cba_settings",
            "3DEN" // Forces mod to load AFTER the Eden Editor
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
// --- BASE UI DEFINITIONS (REQUIRED FOR THE MOD) ---
// =======================================================
class IGUIBack;
class RscListBox;
class RscPicture;
class RscText;

class RscTitles {
    #include "ui\AAS_TacticalPager.hpp" 
};

// =======================================================
// --- EDEN EDITOR CONTEXT MENU ---
// =======================================================
class ctrlMenu;
class Display3DEN {
    class ContextMenu: ctrlMenu {
        class Items {
            // 1. Target the vanilla "Log" folder and inject our button into its array
            class Log {
                items[] += {"AAS_Export_CBA"};
            };
            
            // 2. Define the actual button alongside the Log folder
            class AAS_Export_CBA {
                text = "AAS - Export for CBA Settings";
                action = "[] spawn aas_core_fnc_edenExport;";
                conditionShow = "HoverObject"; // Triggers when hovering over the vehicle/unit
                picture = "\a3\3DEN\Data\Controls\ctrlMenu\link_ca.paa"; 
            };
        };
    };
};

// =======================================================
// --- ZEUS MODULES & FACTION ---
// =======================================================
class CfgFactionClasses {
    class NOSEL_AAS_Category {
        displayName = "AAS Supports";
        priority = 2;
        side = 7; 
    };
};


// =======================================================
// --- REMOTE EXECUTION ---
// =======================================================
class CfgRemoteExec {
    class Functions {
        mode = 2;
        jip = 0;
        class aas_core_fnc_serverCAS { allowedTargets = 2; }; 
        class aas_core_fnc_serverReinforcements { allowedTargets = 2; }; 
        class aas_core_fnc_serverSupplyDrop { allowedTargets = 2; }; 
    };
    class Commands {
        mode = 2;
        jip = 0;
        class playSound { allowedTargets = 0; };
    };
};

// =======================================================
// --- SOUNDS ---
// =======================================================
class CfgSounds {
    // We now officially register every single sound class here
    sounds[] = {
        "AAS_Voice_Signal1", "AAS_Voice_Signal2", "AAS_Voice_Signal3", 
        "AAS_Voice_Supply", "AAS_Voice_CAS", "AAS_Voice_Reinf",
        "AAS_Voice_Armor1", "AAS_Voice_Armor2", "AAS_Voice_CAS2", 
        "AAS_Voice_CAS3", "AAS_Voice_Reinf2", "AAS_Voice_Reinf3", "AAS_Voice_Reinf4"
    };

    class AAS_Voice_Signal1 {
        name = "AAS_Voice_Signal1";
        sound[] = {"\z\aas\addons\core\sounds\hq_signal1.ogg", 1, 1}; 
        titles[] = {};
    };
    class AAS_Voice_Signal2 {
        name = "AAS_Voice_Signal2";
        sound[] = {"\z\aas\addons\core\sounds\hq_signal2.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Signal3 {
        name = "AAS_Voice_Signal3";
        sound[] = {"\z\aas\addons\core\sounds\hq_signal3.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Supply {
        name = "AAS_Voice_Supply";
        sound[] = {"\z\aas\addons\core\sounds\hq_supply.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_CAS {
        name = "AAS_Voice_CAS";
        sound[] = {"\z\aas\addons\core\sounds\hq_cas.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Reinf {
        name = "AAS_Voice_Reinf";
        sound[] = {"\z\aas\addons\core\sounds\hq_reinf.ogg", 1, 1};
        titles[] = {};
    };

    // --- NEWLY ADDED SOUNDS ---
    class AAS_Voice_Armor1 {
        name = "AAS_Voice_Armor1";
        sound[] = {"\z\aas\addons\core\sounds\hq_armor1.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Armor2 {
        name = "AAS_Voice_Armor2";
        sound[] = {"\z\aas\addons\core\sounds\hq_armor2.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_CAS2 {
        name = "AAS_Voice_CAS2";
        sound[] = {"\z\aas\addons\core\sounds\hq_cas2.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_CAS3 {
        name = "AAS_Voice_CAS3";
        sound[] = {"\z\aas\addons\core\sounds\hq_cas3.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Reinf2 {
        name = "AAS_Voice_Reinf2";
        sound[] = {"\z\aas\addons\core\sounds\hq_reinf2.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Reinf3 {
        name = "AAS_Voice_Reinf3";
        sound[] = {"\z\aas\addons\core\sounds\hq_reinf3.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Reinf4 {
        name = "AAS_Voice_Reinf4";
        sound[] = {"\z\aas\addons\core\sounds\hq_reinf4.ogg", 1, 1};
        titles[] = {};
    };
};

// =======================================================
// --- CBA EXTENDED EVENT HANDLERS ---
// =======================================================
class Extended_PreInit_EventHandlers {
    class AAS_Main_PreInit {
        init = "call compile preprocessFileLineNumbers '\z\aas\addons\core\functions\fn_initSettings.sqf'";
    };
};