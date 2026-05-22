// AAS-QRF/functions/fn_initClientQRF.sqf

if (!hasInterface) exitWith {};

diag_log "[AAS-QRF] Initializing QRF Client Module...";

// =========================================================
// --- 1. GLOBAL MODULE REGISTRATION & FAILSAFES ---
// =========================================================
if (isNil "AAS_Loaded_Modules") then { AAS_Loaded_Modules = []; };
if (isNil "AAS_Menu_Registry") then { AAS_Menu_Registry = []; }; 

AAS_Loaded_Modules pushBackUnique "QRF";


// =========================================================
// --- 2. DYNAMIC CONTENT GENERATOR ---
// =========================================================
AQR_fnc_refreshQRF = {
    // --- MASTER MENU TOGGLE CHECK ---
    if (!AQR_Enable_Menu) exitWith {
        private _idx = AAS_Menu_Registry findIf { (_x select 0) == "QUICK REACTION FORCE" };
        if (_idx != -1) then { AAS_Menu_Registry deleteAt _idx; };
    };

    private _qrfOptions = [];
    
    // --- ECONOMY MATH (REROUTED TO CORE PRESET) ---
    // Pulls from QRF specific cost boxes based on the GLOBAL Core Economy choice
    private _qrfCost = switch (AAS_Econ_Preset_Core) do {
        case 0: { parseNumber AQR_Cost_QRF_Custom };
        case 1: { parseNumber AQR_Cost_QRF_Antistasi };
        case 2: { 
            // KP Liberation: Format as "00/00/00"
            private _s = parseNumber (missionNamespace getVariable ["AQR_Cost_QRF_KPLib_S", "350"]);
            private _a = parseNumber (missionNamespace getVariable ["AQR_Cost_QRF_KPLib_A", "350"]);
            private _f = parseNumber (missionNamespace getVariable ["AQR_Cost_QRF_KPLib_F", "350"]);
            format ["%1/%2/%3", _s, _a, _f]
        };
        case 3: { parseNumber AQR_Cost_QRF_Overthrow };
        case 4: { parseNumber AQR_Cost_QRF_Warlords };
        case 5: { parseNumber AQR_Cost_QRF_DUWS };
        case 6: { parseNumber AQR_Cost_QRF_Antistasi }; // Antistasi Personal
        default { 0 }; 
    };

    // --- COOLDOWN CHECK & PUSH ---
    private _cooldownTime = parseNumber AQR_Cooldown_QRF;
    private _lastUse = missionNamespace getVariable ["AAS_QRF_LastUseTime", -99999];

    // Only add the "CALL QRF" option to the submenu if it is NOT on cooldown
    if (serverTime >= (_lastUse + _cooldownTime)) then {
        
        // --- NAME FORMATTING ---
        private _actionName = "CALL QRF";
        
        if (_qrfCost isEqualType "") then {
            // String handling for KP Liberation (e.g., "350/350/350")
            if (_qrfCost != "0/0/0") then { _actionName = format ["CALL QRF (%1)", _qrfCost]; };
        } else {
            // Number handling for standard currencies
            if (_qrfCost > 0) then { _actionName = format ["CALL QRF (%1)", _qrfCost]; };
        };
        
        // Push the action and the execution code into our local array
        _qrfOptions pushBack [
            _actionName, 
            { [_this select 0, _this select 1] remoteExec ["aqr_fnc_serverQRF", 2]; }
        ];
    };

    // --- INJECT INTO GLOBAL REGISTRY ---
    private _found = false;
    { 
        if ((_x select 0) == "QUICK REACTION FORCE") exitWith { 
            _x set [1, _qrfOptions]; 
            _found = true; 
        }; 
    } forEach AAS_Menu_Registry;
    
    if (!_found) then { 
        AAS_Menu_Registry pushBack ["QUICK REACTION FORCE", _qrfOptions]; 
    };
};


// =========================================================
// --- 3. BACKGROUND REGISTRY UPDATER ---
// =========================================================
[] spawn {
    // Ensure player exists AND the registry is fully validated before looping
    waitUntil { !isNull player && time > 0 && !isNil "AAS_Menu_Registry" && !isNil "AAS_Econ_Preset_Core" }; 
    
    while {true} do {
        call AQR_fnc_refreshQRF;
        sleep 1.5; 
    };
};

diag_log "[AAS-QRF] SUCCESS: QRF Module integrated into Tactical Pager Registry.";