class CfgPatches {
    class AAS_QRF {
        name = "AAS - Quick Reaction Force";
        author = "AAS Team";
        url = "";
        requiredVersion = 1.60;
        // Removed "aas_main" temporarily to guarantee this mod loads regardless of load-order names
        requiredAddons[] = {"A3_Data_F", "A3_UI_F", "cba_settings", "aas_main"};
        units[] = {};
        weapons[] = {};
    };
};

// =======================================================
// --- FUNCTIONS REGISTRATION ---
// =======================================================
class CfgFunctions {
    class AQR { 
        class QRF_Module {
            file = "AAS_QRF\functions"; 
            class initSettings {}; // <-- FIXED: Removed { preInit = 1; }
            class initClientQRF { postInit = 1; }; 
            class setEconomyPreset {}; 
            class serverQRF {}; 
            class moduleQRF {}; // ADDED: Registers the Zeus script
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
        class aqr_fnc_serverQRF { allowedTargets = 2; }; 
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
        sound[] = {"\AAS_QRF\sounds\hq_qrf1.ogg", 1.26, 1, 100}; 
        titles[] = {};
    };
    
    class AQR_Voice_HQ_QRF2 {
        name = "AQR_Voice_HQ_QRF2";
        // Volume increased by +2dB (Amplitude multiplier ~ 1.26)
        sound[] = {"\AAS_QRF\sounds\hq_qrf2.ogg", 1.26, 1, 100};
        titles[] = {};
    };
    
    class AQR_Voice_Pilot_QRF1 {
        name = "AQR_Voice_Pilot_QRF1";
        // Volume increased by +2dB (Amplitude multiplier ~ 1.26)
        sound[] = {"\AAS_QRF\sounds\hq_pilotqrf1.ogg", 1.26, 1, 100};
        titles[] = {};
    };
    
    class AQR_Voice_Ground_QRF {
        name = "AQR_Voice_Ground_QRF";
        // Volume increased by +12dB (Amplitude multiplier ~ 3.98)
        sound[] = {"\AAS_QRF\sounds\hq_groundqrf.ogg", 3.98, 1, 100};
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
        function = "aqr_fnc_moduleQRF";  // Calls the new script we just made
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
        init = "call compile preprocessFileLineNumbers '\AAS_QRF\functions\fn_initSettings.sqf'";
    };
};