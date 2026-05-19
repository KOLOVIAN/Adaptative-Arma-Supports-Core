/*
    AAS-Core
    Core Client Initialization
    Architecture: Modular Registry / Non-Blocking Pager UI / BASIC SUPPORTS Integration
    Version: 5.6.0 (Infinite Submenus & Backward Compatibility Upgrade)
*/

if (!hasInterface) exitWith {};

// --- 1. GLOBAL REGISTRY & FALLBACKS ---
if (isNil "AAS_Signal_Grenade") then { AAS_Signal_Grenade = "SmokeShellOrange"; };
if (isNil "AAS_Menu_Registry") then { AAS_Menu_Registry = []; };
if (isNil "AAS_Loaded_Modules") then { AAS_Loaded_Modules = []; }; 
if (isNil "AAS_Pager_Theme") then { AAS_Pager_Theme = 0; }; // Now maps to the dynamic AAS_Theme_Registry index

AAS_Current_Submenu_Data = [];
AAS_Menu_Stack = []; // UPGRADE: Stack to remember nested navigation paths
AAS_Active_Smoke = objNull;

// --- UNIVERSAL THEME GETTER ---
// Call this to receive: ["path\to\pager.paa", "path\to\tablet.paa"]
AAS_fnc_getActiveThemeTextures = {
    private _themeIndex = missionNamespace getVariable ["AAS_Pager_Theme", 0];
    
    // Failsafe: If the registry is empty or index is out of bounds, default to 0
    if (isNil "AAS_Theme_Registry" || {_themeIndex < 0} || {_themeIndex >= count AAS_Theme_Registry}) then { 
        _themeIndex = 0; 
    };
    
    private _themeData = AAS_Theme_Registry select _themeIndex;
    
    // Select 2 is the Pager PAA, Select 3 is the Tablet PAA
    [_themeData select 2, _themeData select 3]
};

// --- 2. DYNAMIC CONTENT GENERATOR (BASIC SUPPORTS) ---
AAS_fnc_refreshBasicSupports = {
    private _basicStrikes = [];

    // UPDATED: Now reads the new Core preset and handles KP Liberation strings
    private _getCost = {
        params ["_custom", "_antistasi", "_overthrow", "_warlords", "_duws", "_kpS", "_kpA", "_kpF"];
        switch (AAS_Econ_Preset_Core) do { 
            case 0: {parseNumber _custom}; 
            case 1: {parseNumber _antistasi}; 
            case 2: { 
                // KP Liberation: Format into a single string for the UI
                private _s = parseNumber _kpS;
                private _a = parseNumber _kpA;
                private _f = parseNumber _kpF;
                if (_s == 0 && _a == 0 && _f == 0) then { 0 } else { format ["%1/%2/%3", _s, _a, _f] };
            };
            case 3: {parseNumber _overthrow}; 
            case 4: {parseNumber _warlords}; 
            case 5: {parseNumber _duws}; 
            case 6: {parseNumber _antistasi}; // Antistasi Personal
            default {0}; 
        };
    };

    // Pass the new specific cost box variables
    private _costSupply = [AAS_Cost_Supply_Custom, AAS_Cost_Supply_Antistasi, AAS_Cost_Supply_Overthrow, AAS_Cost_Supply_Warlords, AAS_Cost_Supply_DUWS, AAS_Cost_Supply_KPLib_S, AAS_Cost_Supply_KPLib_A, AAS_Cost_Supply_KPLib_F] call _getCost;
    private _costCAS    = [AAS_Cost_CAS_Custom, AAS_Cost_CAS_Antistasi, AAS_Cost_CAS_Overthrow, AAS_Cost_CAS_Warlords, AAS_Cost_CAS_DUWS, AAS_Cost_CAS_KPLib_S, AAS_Cost_CAS_KPLib_A, AAS_Cost_CAS_KPLib_F] call _getCost;
    private _costReinf  = [AAS_Cost_Reinf_Custom, AAS_Cost_Reinf_Antistasi, AAS_Cost_Reinf_Overthrow, AAS_Cost_Reinf_Warlords, AAS_Cost_Reinf_DUWS, AAS_Cost_Reinf_KPLib_S, AAS_Cost_Reinf_KPLib_A, AAS_Cost_Reinf_KPLib_F] call _getCost;

    // UPDATED: Now safely handles both numbers (Standard) and Strings (KP Liberation)
    private _formatName = {
        params ["_baseName", "_cost"];
        if (_cost isEqualType "") exitWith { format ["%1 (%2)", _baseName, _cost] };
        if (_cost > 0) then { format ["%1 (%2)", _baseName, _cost] } else { _baseName };
    };

    if (serverTime >= ((missionNamespace getVariable ['AAS_SupplyDrop_LastUseTime', -99999]) + (parseNumber AAS_Cooldown_Supply))) then {
        _basicStrikes pushBack [["SUPPLY DROP", _costSupply] call _formatName, { [_this select 0, _this select 1] remoteExec ["aas_fnc_serverSupplyDrop", 2]; }];
    };

    if (serverTime >= ((missionNamespace getVariable ['AAS_CAS_LastUseTime', -99999]) + (parseNumber AAS_Cooldown_CAS))) then {
        _basicStrikes pushBack [["CAS STRIKE", _costCAS] call _formatName, { [_this select 0, _this select 1] remoteExec ["aas_fnc_serverCAS", 2]; }];
    };

    if (serverTime >= ((missionNamespace getVariable ['AAS_Reinf_LastUseTime', -99999]) + (parseNumber AAS_Cooldown_Reinf))) then {
        _basicStrikes pushBack [["REINFORCEMENTS", _costReinf] call _formatName, { [_this select 0, _this select 1] remoteExec ["aas_fnc_serverReinforcements", 2]; }];
    };

    private _found = false;
    { if ((_x select 0) == "BASIC SUPPORTS") exitWith { _x set [1, _basicStrikes]; _found = true; }; } forEach AAS_Menu_Registry;
    if (!_found) then { AAS_Menu_Registry insert [0, [["BASIC SUPPORTS", _basicStrikes]]]; };
};

// --- 3. PAGER UI FUNCTIONS ---
AAS_fnc_updatePagerContent = {
    params [["_isMainMenu", true], ["_categoryData", []]];
    private _display = uiNamespace getVariable ["AAS_Pager_Display", displayNull];
    if (isNull _display) exitWith {};
    private _ctrl = _display displayCtrl 1500;
    lbClear _ctrl;

    if (_isMainMenu) then {
        call AAS_fnc_refreshBasicSupports;
        AAS_Current_Submenu_Data = [];
        AAS_Menu_Stack = []; // Reset the navigation stack when viewing the main menu
        
        {
            private _idx = _ctrl lbAdd (_x select 0);
            _ctrl lbSetData [_idx, "AAS_CMD_SUBMENU_MAIN"];
            _ctrl lbSetValue [_idx, _forEachIndex];
        } forEach AAS_Menu_Registry;
        
        private _closeIdx = _ctrl lbAdd "[ CLOSE ]";
        _ctrl lbSetData [_closeIdx, "AAS_CMD_CLOSE"];
    } else {
        { 
            private _idx = _ctrl lbAdd (_x select 0);
            private _payload = _x select 1;
            
            // THE SECRET: SQF TYPE CHECKING FOR INFINITE DEPTH
            // If the payload is an array, treat it as a folder. If it's code, treat it as a strike button.
            if (_payload isEqualType []) then {
                _ctrl lbSetData [_idx, "AAS_CMD_SUBMENU_NESTED"];
            } else {
                _ctrl lbSetData [_idx, "AAS_CMD_EXECUTE"];
            };
            
            _ctrl lbSetValue [_idx, _forEachIndex];
        } forEach _categoryData;

        private _backIdx = _ctrl lbAdd "[ < BACK ]";
        _ctrl lbSetData [_backIdx, "AAS_CMD_BACK"];
    }; 
    _ctrl lbSetCurSel 0;
};

AAS_fnc_handlePagerSelection = {
    private _display = uiNamespace getVariable ["AAS_Pager_Display", displayNull];
    if (isNull _display) exitWith {};
    private _ctrl = _display displayCtrl 1500;

    private _idx = lbCurSel _ctrl;
    if (_idx == -1) exitWith {}; 
    
    private _cmd = _ctrl lbData _idx;
    private _val = _ctrl lbValue _idx;

    if (_cmd == "AAS_CMD_CLOSE") exitWith { [] call AAS_fnc_closePager; };
    
    if (_cmd == "AAS_CMD_BACK") exitWith { 
        if (count AAS_Menu_Stack > 0) then {
            // Pop the last menu data off the stack to go up one folder level
            private _previousMenu = AAS_Menu_Stack deleteAt (count AAS_Menu_Stack - 1);
            AAS_Current_Submenu_Data = _previousMenu;
            [false, AAS_Current_Submenu_Data] call AAS_fnc_updatePagerContent;
        } else {
            // If the stack is empty, we must go back to the Root Main Menu
            [true] call AAS_fnc_updatePagerContent; 
        };
    };

    if (_cmd == "AAS_CMD_SUBMENU_MAIN") exitWith {
        // Diving from Root Menu into a Module (e.g. Main Menu -> Artillery)
        AAS_Current_Submenu_Data = (AAS_Menu_Registry select _val) select 1;
        [false, AAS_Current_Submenu_Data] call AAS_fnc_updatePagerContent;
    };

    if (_cmd == "AAS_CMD_SUBMENU_NESTED") exitWith {
        // Push the current array to our history stack so we can go 'BACK' to it later
        AAS_Menu_Stack pushBack AAS_Current_Submenu_Data;
        // Dive into the selected sub-folder
        AAS_Current_Submenu_Data = (AAS_Current_Submenu_Data select _val) select 1;
        [false, AAS_Current_Submenu_Data] call AAS_fnc_updatePagerContent;
    };

    if (_cmd == "AAS_CMD_EXECUTE") then {
        private _dropPos = [];
        if (!isNull AAS_Active_Smoke) then { _dropPos = getPos AAS_Active_Smoke; } else { _dropPos = getPos player; };
        private _code = (AAS_Current_Submenu_Data select _val) select 1;
        
        [] call AAS_fnc_closePager;
        
        [player, _dropPos] call _code;
    };
};

// --- SYNCHRONOUS CLEANUP ---
AAS_fnc_closePager = {
    ("AAS_Pager_Layer" call BIS_fnc_rscLayer) cutText ["", "PLAIN"];

    private _mainDisplay = findDisplay 46;
    if (!isNull _mainDisplay) then {
        if (!isNil "AAS_EVH_Scroll") then { _mainDisplay displayRemoveEventHandler ["MouseZChanged", AAS_EVH_Scroll]; AAS_EVH_Scroll = nil; };
        if (!isNil "AAS_EVH_ClickDown") then { _mainDisplay displayRemoveEventHandler ["MouseButtonDown", AAS_EVH_ClickDown]; AAS_EVH_ClickDown = nil; };
        if (!isNil "AAS_EVH_ClickUp") then { _mainDisplay displayRemoveEventHandler ["MouseButtonUp", AAS_EVH_ClickUp]; AAS_EVH_ClickUp = nil; };
        if (!isNil "AAS_EVH_Key") then { _mainDisplay displayRemoveEventHandler ["KeyDown", AAS_EVH_Key]; AAS_EVH_Key = nil; };
        if (!isNil "AAS_EVH_KeyUp") then { _mainDisplay displayRemoveEventHandler ["KeyUp", AAS_EVH_KeyUp]; AAS_EVH_KeyUp = nil; };
    };

    inGameUISetEventHandler ["Action", ""];
    inGameUISetEventHandler ["PrevAction", ""];
    inGameUISetEventHandler ["NextAction", ""];
    AAS_Active_Smoke = objNull;
};

AAS_fnc_openPager = {
    params [["_smoke", objNull]];
    if (!isNull (uiNamespace getVariable ["AAS_Pager_Display", displayNull])) exitWith {};
    
    AAS_Active_Smoke = _smoke;
    ("AAS_Pager_Layer" call BIS_fnc_rscLayer) cutRsc ["AAS_Pager_HUD", "PLAIN"];
    [true] call AAS_fnc_updatePagerContent;

    inGameUISetEventHandler ["Action", "true"];
    inGameUISetEventHandler ["PrevAction", "true"];
    inGameUISetEventHandler ["NextAction", "true"];

    private _display = findDisplay 46;
    private _pagerDisplay = uiNamespace getVariable ["AAS_Pager_Display", displayNull];

    // --- DYNAMIC TEXTURE SWAP ---
    private _bgCtrl = _pagerDisplay displayCtrl 1200;
    if (!isNull _bgCtrl) then {
        // Fetch the active texture array and grab index 0 (The Pager Texture)
        private _themeTextures = call AAS_fnc_getActiveThemeTextures;
        _bgCtrl ctrlSetText (_themeTextures select 0);
    };

    // --- PRE-EMPTIVE CLEANUP ---
    if (!isNil "AAS_EVH_Scroll") then { _display displayRemoveEventHandler ["MouseZChanged", AAS_EVH_Scroll]; };
    if (!isNil "AAS_EVH_ClickUp") then { _display displayRemoveEventHandler ["MouseButtonUp", AAS_EVH_ClickUp]; };
    if (!isNil "AAS_EVH_Key") then { _display displayRemoveEventHandler ["KeyDown", AAS_EVH_Key]; };

    // --- SMART HIDE TRACKER (SCOPING IN) ---
    [_pagerDisplay] spawn {
        disableSerialization;
        params ["_display"];
        private _isHidden = false;
        private _bg = _display displayCtrl 1200;
        private _text = _display displayCtrl 1000;
        private _list = _display displayCtrl 1500;
        
        while {!isNull _display} do {
            if (cameraView == "GUNNER" && !_isHidden) then {
                _isHidden = true;
                _bg ctrlShow false; _text ctrlShow false; _list ctrlShow false;
                inGameUISetEventHandler ["Action", ""];
                inGameUISetEventHandler ["PrevAction", ""];
                inGameUISetEventHandler ["NextAction", ""];
            };
            if (cameraView != "GUNNER" && _isHidden) then {
                _isHidden = false;
                _bg ctrlShow true; _text ctrlShow true; _list ctrlShow true;
                inGameUISetEventHandler ["Action", "true"];
                inGameUISetEventHandler ["PrevAction", "true"];
                inGameUISetEventHandler ["NextAction", "true"];
            };
            sleep 0.1;
        };
    };

    // --- THE MASTER FAILSAFE MONITOR ---
    [_pagerDisplay] spawn {
        disableSerialization;
        params ["_display"];
        private _timeout = serverTime + 150; 
        
        waitUntil {
            sleep 0.5;
            isNull _display || {!alive player} || {serverTime > _timeout} 
        };

        if (!isNull _display) then { 
            [] call AAS_fnc_closePager; 
        };
    };

    // --- STATUS TEXT ANIMATION LOOP ---
    [_pagerDisplay] spawn {
        disableSerialization;
        params ["_display"];
        private _ctrl = _display displayCtrl 1000; 
        if (isNull _ctrl) exitWith {};
        while {!isNull _ctrl} do {
            _ctrl ctrlSetFade 1; _ctrl ctrlCommit 0.5; sleep 0.5;
            _ctrl ctrlSetFade 0; _ctrl ctrlCommit 0.1; sleep 0.8; 
        };
    };

    AAS_EVH_Scroll = _display displayAddEventHandler ["MouseZChanged", {
        params ["", "_scroll"];
        if (cameraView == "GUNNER") exitWith {false}; 
        private _ctrl = (uiNamespace getVariable ["AAS_Pager_Display", displayNull]) displayCtrl 1500;
        if (isNull _ctrl) exitWith {false};
        playSound "ReadoutClick"; 
        if (_scroll < 0) then { _ctrl lbSetCurSel (lbCurSel _ctrl + 1) } else { _ctrl lbSetCurSel (lbCurSel _ctrl - 1) };
        true;
    }];

    // ==============================================================
    // STANDARD INPUT HANDLERS 
    // ==============================================================

    AAS_EVH_ClickUp = _display displayAddEventHandler ["MouseButtonUp", { 
        params ["", "_button"];
        if (cameraView == "GUNNER") exitWith {false}; 
        if (_button == 2) then { 
            playSound "Click"; 
            call AAS_fnc_handlePagerSelection; 
        }; 
        false;
    }];
    
    AAS_EVH_Key = _display displayAddEventHandler ["KeyDown", {
        params ["", "_key"];
        if (cameraView == "GUNNER") exitWith {false}; 
        
        private _ctrl = (uiNamespace getVariable ["AAS_Pager_Display", displayNull]) displayCtrl 1500;
        if (isNull _ctrl) exitWith {false};

        if (_key == 14) exitWith { [] call AAS_fnc_closePager; true; }; // Backspace
        if (_key == 57) exitWith { playSound "Click"; call AAS_fnc_handlePagerSelection; true; }; // Spacebar

        if (_key == 200) exitWith { // Arrow Up
            playSound "ReadoutClick";
            if (lbCurSel _ctrl > 0) then { _ctrl lbSetCurSel (lbCurSel _ctrl - 1); };
            true;
        };

        if (_key == 208) exitWith { // Arrow Down
            playSound "ReadoutClick";
            if (lbCurSel _ctrl < (lbSize _ctrl) - 1) then { _ctrl lbSetCurSel (lbCurSel _ctrl + 1); };
            true;
        };

        false;
    }];
};

// --- 4. THE GRENADE SCANNER LOOP ---
[] spawn {
    while {true} do {
        if (!alive player || {vehicle player != player && speed (vehicle player) > 30}) then {
            sleep 2;
        } else {
            private _nearSmokes = nearestObjects [player, [AAS_Signal_Grenade], 25];
            {
                private _smoke = _x;
                if (!(_smoke getVariable ["AAS1_Tracked", false]) && {speed _smoke > 1}) then {
                    private _closestPlayer = player;
                    private _minDistSqr = player distanceSqr _smoke;
                    {
                        if (isPlayer _x && {alive _x} && {_x distanceSqr _smoke < _minDistSqr}) then {
                            _closestPlayer = _x; _minDistSqr = _x distanceSqr _smoke;
                        };
                    } forEach allPlayers;

                    if (_closestPlayer == player) then {
                        _smoke setVariable ["AAS1_Tracked", true, false];
                        
                        private _signalOptions = [
                            ["AAS_Voice_Signal1", "HQ: Signal spotted, what do you need? over"],
                            ["AAS_Voice_Signal2", "HQ: This is HQ, we are tracking your signal, standing by for support."],
                            ["AAS_Voice_Signal3", "HQ: This is HQ, signal received, standing by for support, over"]
                        ];
                        private _selectedSignal = selectRandom _signalOptions;
                        playSound (_selectedSignal select 0);
                        systemChat (_selectedSignal select 1);
                        [_smoke] call AAS_fnc_openPager;
                    };
                };
            } forEach _nearSmokes;
            
            sleep 0.25;
        };
    };
};

// --- 5. KEYBIND OVERRIDE ---
[
    "AAS - Adaptative Arma Supports", "AAS_Keybind_OpenPager",         
    ["Open Tactical Pager", "Manually opens the support menu."], 
    {
        if (isNull (uiNamespace getVariable ["AAS_Pager_Display", displayNull])) then {
            playSound "ReadoutClick"; 
            [objNull] call AAS_fnc_openPager;
            systemChat "[AAS] TRANSMITTING GPS COORDINATES TO HQ...";
        };
    }, "" 
] call CBA_fnc_addKeybind;

// --- 6. STARTUP NOTIFICATION ---
[] spawn {
    sleep 2; 
    // NEW: Check if the user has toggled on the startup message
    if (missionNamespace getVariable ["AAS_Show_Startup_Message", true]) then {
        private _moduleText = "";
        if (count AAS_Loaded_Modules > 0) then {
            private _names = "";
            { _names = _names + format ["[%1]", _x]; } forEach AAS_Loaded_Modules;
            _moduleText = " + " + _names;
        };
        systemChat format ["[AAS - Core loaded]%1", _moduleText];
    };
};

diag_log "[AAS] Core initialized. VERSION 5.6.0 (Infinite Submenus Upgrade)";
