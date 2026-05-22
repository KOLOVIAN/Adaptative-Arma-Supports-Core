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
// --- MULTIPLAYER SECURITY ---
// =======================================================
class CfgRemoteExec {
    class Functions {
        mode = 2;
        jip = 1;
        class aas_qrf_fnc_serverQRF { allowedTargets = 2; }; 
    };
};

// =======================================================
// --- CUSTOM VOICE LINES FOR VERSION 3.0 ---
// =======================================================
class CfgSounds {
    sounds[] = {};

    class AQR_Voice_HQ_QRF1 {
        name = "AQR_Voice_HQ_QRF1";
        // Volume increased by +2dB (Amplitude multiplier ~ 1.26)
        sound[] = {"\z\aas\addons\qrf\sounds\hq_qrf1.ogg", 1.26, 1, 100}; 
        titles[] = {};
    };
    
    class AQR_Voice_HQ_QRF2 {
        name = "AQR_Voice_HQ_QRF2";
        // Volume increased by +2dB (Amplitude multiplier ~ 1.26)
        sound[] = {"\z\aas\addons\qrf\sounds\hq_qrf2.ogg", 1.26, 1, 100};
        titles[] = {};
    };
    
    class AQR_Voice_Pilot_QRF1 {
        name = "AQR_Voice_Pilot_QRF1";
        // Volume increased by +2dB (Amplitude multiplier ~ 1.26)
        sound[] = {"\z\aas\addons\qrf\sounds\hq_pilotqrf1.ogg", 1.26, 1, 100};
        titles[] = {};
    };
    
    class AQR_Voice_Ground_QRF {
        name = "AQR_Voice_Ground_QRF";
        // Volume increased by +12dB (Amplitude multiplier ~ 3.98)
        sound[] = {"\z\aas\addons\qrf\sounds\hq_groundqrf.ogg", 3.98, 1, 100};
        titles[] = {};
    };
};

// =======================================================
// --- ZEUS MODULE DEFINITION ---
// =======================================================
class CfgVehicles {
    class Logic;
    class Module_F: Logic {
        class AttributesBase;
        class ModuleDescription;
    };

    class AQR_Module_QRF: Module_F {
        scope = 2;              // Visible in Eden Editor
        scopeCurator = 2;       // Visible in Zeus
        displayName = "Call Massive QRF"; 
        category = "NOSEL_AAS_Category"; // Hooks perfectly into the Main Mod's category!
        function = "aas_qrf_fnc_moduleQRF";  // Calls the new script we just made
        functionPriority = 1;
        isGlobal = 0;
        isTriggerActivated = 1;
        isDisposable = 1;
        is3DEN = 0;
        icon = "\a3\Modules_F_Curator\Data\iconOrdnance_ca.paa"; // Default Arma strike icon
    };
};

// =======================================================
// --- CBA EXTENDED EVENT HANDLERS ---
// =======================================================
class Extended_PreInit_EventHandlers {
    class AAS_QRF_PreInit {
        init = "call compile preprocessFileLineNumbers '\z\aas\addons\qrf\functions\fn_initSettings.sqf'";
    };
};