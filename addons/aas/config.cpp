class CfgPatches {
    class aas_main { 
        name = "AAS - Adaptative Arma Supports";
        author = "KOLOVIAN";
        requiredVersion = 1.60;
        requiredAddons[] = {
            "A3_Data_F", 
            "A3_Modules_F", 
            "A3_Modules_F_Curator", 
            "cba_main", 
            "cba_settings",
            "3DEN" // Forces mod to load AFTER the Eden Editor
        }; 
        weapons[] = {};
    };
};

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
                action = "[] spawn aas_fnc_edenExport;";
                conditionShow = "HoverObject"; // Triggers when hovering over the vehicle/unit
                picture = "\a3\3DEN\Data\Controls\ctrlMenu\link_ca.paa"; 
            };
        };
    };
};

// =======================================================
// --- FUNCTIONS ---
// =======================================================
class CfgFunctions {
    class aas { 
        class supportScripts {
            file = "\z\aas\addons\aas\functions"; 
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
        class aas_fnc_serverCAS { allowedTargets = 2; }; 
        class aas_fnc_serverReinforcements { allowedTargets = 2; }; 
        class aas_fnc_serverSupplyDrop { allowedTargets = 2; }; 
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
    sounds[] = {};
    class AAS_Voice_Signal1 {
        name = "AAS_Voice_Signal1";
        sound[] = {"\z\aas\addons\aas\sounds\hq_signal1.ogg", 1, 1}; 
        titles[] = {};
    };
    class AAS_Voice_Signal2 {
        name = "AAS_Voice_Signal2";
        sound[] = {"\z\aas\addons\aas\sounds\hq_signal2.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Signal3 {
        name = "AAS_Voice_Signal3";
        sound[] = {"\z\aas\addons\aas\sounds\hq_signal3.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Supply {
        name = "AAS_Voice_Supply";
        sound[] = {"\z\aas\addons\aas\sounds\hq_supply.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_CAS {
        name = "AAS_Voice_CAS";
        sound[] = {"\z\aas\addons\aas\sounds\hq_cas.ogg", 1, 1};
        titles[] = {};
    };
    class AAS_Voice_Reinf {
        name = "AAS_Voice_Reinf";
        sound[] = {"\z\aas\addons\aas\sounds\hq_reinf.ogg", 1, 1};
        titles[] = {};
    };
};

// =======================================================
// --- CBA EXTENDED EVENT HANDLERS ---
// =======================================================
class Extended_PreInit_EventHandlers {
    class AAS_Main_PreInit {
        init = "call compile preprocessFileLineNumbers '\z\aas\addons\aas\functions\fn_initSettings.sqf'";
    };
};
