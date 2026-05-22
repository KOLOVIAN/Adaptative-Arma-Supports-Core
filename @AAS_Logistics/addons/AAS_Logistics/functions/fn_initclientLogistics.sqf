// AAS-Logistics/functions/fn_initClientLogistics.sqf

if (!hasInterface) exitWith {};

diag_log "[AAS-Logistics] Initializing Logistics Client Module...";

if (isNil "AAS_Loaded_Modules") then { AAS_Loaded_Modules = []; };
if (isNil "AAS_Menu_Registry") then { AAS_Menu_Registry = []; };

AAS_Loaded_Modules pushBackUnique "LOGISTICS";

// =========================================================
// --- TARGETING STATE MACHINE (TRANSPORT ONLY) ---
// =========================================================
AAS_LOG_fnc_startMapTargeting = {
    // FIX: Added _transportType parameter so the server knows which heli to spawn
    params ["_caller", ["_transportType", "Standard"]];
    
    [_caller, _transportType] spawn {
        params ["_caller", "_transportType"];

        if (isNull (findDisplay 8990)) then {
            systemChat "HQ: Plot your flight path. Left-Click to add waypoint. Right-Click to undo. SPACE to confirm";
            playSound "FD_Timer_F";

            createDialog "AAS_LOG_Tablet_Dialog";
            waitUntil { !isNull (findDisplay 8990) }; 
            
            private _disp = findDisplay 8990;
            private _mapCtrl = _disp displayCtrl 8991;
            private _frameCtrl = _disp displayCtrl 8992;

            private _shiftAmountX = 0.085 * safezoneW;
            private _shiftAmountY = 0.05 * safezoneH;
            
            private _posMap = ctrlPosition _mapCtrl;
            _posMap set [0, (_posMap select 0) - _shiftAmountX];
            _posMap set [1, (_posMap select 1) + _shiftAmountY];
            _mapCtrl ctrlSetPosition _posMap;
            _mapCtrl ctrlCommit 0;

            private _posFrame = ctrlPosition _frameCtrl;
            _posFrame set [0, (_posFrame select 0) - _shiftAmountX];
            _posFrame set [1, (_posFrame select 1) + _shiftAmountY];
            _frameCtrl ctrlSetPosition _posFrame;
            _frameCtrl ctrlCommit 0;

            private _themeTextures = call aas_core_fnc_getActiveThemeTextures;
            _frameCtrl ctrlSetText (_themeTextures select 1);
            
            _mapCtrl ctrlMapAnimAdd [0, 0.1, getPos _caller];
            ctrlMapAnimCommit _mapCtrl;
            
            // --- ROUTE PLOTTER INITIALIZATION ---
            private _lzObj = missionNamespace getVariable ["AAS_Active_Smoke", objNull];
            private _lzPos = if (isNull _lzObj) then { getPos _caller } else { getPos _lzObj };
            
            _caller setVariable ["AAS_Path_LZ", _lzPos];
            _caller setVariable ["AAS_Flight_Path", []];
            _caller setVariable ["AAS_Path_Confirmed", false];

            // --- PAGER UI OVERRIDE & SYNC LOOP ---
            [_caller] spawn {
                disableSerialization;
                params ["_caller"];
                
                // Force-open the "dummy" pager since the core mod auto-closed it
                ("AAS_Pager_Layer" call BIS_fnc_rscLayer) cutRsc ["AAS_Pager_HUD", "PLAIN"];
                
                // Keep updating the pager while the map is open
                while { !isNull (findDisplay 8990) } do {
                    private _pagerDisplay = uiNamespace getVariable ["AAS_Pager_Display", displayNull];
                    if (!isNull _pagerDisplay) then {
                        
                        // Apply the correct theme to the dummy pager
                        private _bgCtrl = _pagerDisplay displayCtrl 1200;
                        if (!isNull _bgCtrl) then {
                            private _themeTextures = call aas_core_fnc_getActiveThemeTextures;
                            _bgCtrl ctrlSetText (_themeTextures select 0);
                        };

                        private _ctrl = _pagerDisplay displayCtrl 1500;
                        private _path = _caller getVariable ["AAS_Flight_Path", []];
                        
                        lbClear _ctrl;
                        private _i1 = _ctrl lbAdd "[ PLOTTING FLIGHT ]";
                        private _i2 = _ctrl lbAdd "";
                        
                        // Dynamically build the Waypoint UI Array
                        private _wpStr = "";
                        for "_i" from 1 to 5 do {
                            if (_i <= count _path) then {
                                _wpStr = _wpStr + format ["[WP%1] ", _i];
                            } else {
                                _wpStr = _wpStr + "[   ] ";
                            };
                        };
                        
                        private _i3 = _ctrl lbAdd _wpStr;
                        private _i4 = _ctrl lbAdd "";
                        private _i5 = _ctrl lbAdd "SPACE: Confirm";
                        private _i6 = _ctrl lbAdd "R-CLICK: Undo WP";

                        // Lock selection so it just looks like a screen read-out
                        _ctrl lbSetValue [_i1, -1]; _ctrl lbSetValue [_i2, -1]; 
                        _ctrl lbSetValue [_i3, -1]; _ctrl lbSetValue [_i4, -1];
                        _ctrl lbSetValue [_i5, -1]; _ctrl lbSetValue [_i6, -1];
                        _ctrl lbSetCurSel -1;
                    };
                    sleep 0.1;
                };
                
                // When map closes, kill the pager screen simultaneously
                ("AAS_Pager_Layer" call BIS_fnc_rscLayer) cutText ["", "PLAIN"];
            };

            // --- MAP CLICK HANDLER (LEFT/RIGHT CLICK) ---
            _mapCtrl ctrlAddEventHandler ["MouseButtonClick", {
                params ["_control", "_button", "_xPos", "_yPos"];
                private _path = player getVariable ["AAS_Flight_Path", []];
                
                if (_button == 0) then { // LEFT CLICK (Add WP)
                    if (count _path < 5) then {
                        private _worldPos = _control ctrlMapScreenToWorld [_xPos, _yPos];
                        _path pushBack [_worldPos select 0, _worldPos select 1, 0];
                        player setVariable ["AAS_Flight_Path", _path];
                        playSound "ReadoutClick";
                    } else {
                        systemChat "HQ: Maximum 5 waypoints allowed.";
                    };
                };
                
                if (_button == 1) then { // RIGHT CLICK (Undo WP)
                    if (count _path > 0) then {
                        _path deleteAt (count _path - 1);
                        player setVariable ["AAS_Flight_Path", _path];
                        playSound "ReadoutHideClick1";
                    };
                };
            }];

            // --- KEYBOARD HANDLER (SPACE TO CONFIRM) ---
            _disp displayAddEventHandler ["KeyDown", {
                params ["_display", "_key"];
                if (_key == 14) exitWith { _display closeDisplay 2; true }; // Escape/Backspace (Cancel)
                if (_key == 57) exitWith { // Spacebar (Confirm)
                    if (count (player getVariable ["AAS_Flight_Path", []]) > 0) then {
                        player setVariable ["AAS_Path_Confirmed", true];
                        _display closeDisplay 1; 
                    } else {
                        systemChat "HQ: You must plot at least one waypoint.";
                    };
                    true 
                };
                false
            }];

            // --- DRAW ROUTE HANDLER ---
            _mapCtrl ctrlAddEventHandler ["Draw", {
                params ["_map"];
                private _path = player getVariable ["AAS_Flight_Path", []];
                private _lzPos = player getVariable ["AAS_Path_LZ", getPos player];
                
                if (count _path > 0) then {
                    private _lastPos = _lzPos;
                    {
                        // Draw flight vector line (Thickness set to 6, Color changed to RED)
                        _map drawLine [_lastPos, _x, [0.8, 0, 0, 1], 6]; 
                        
                        private _icon = "\a3\ui_f\data\map\markers\military\dot_ca.paa";
                        private _text = format ["WP %1", _forEachIndex + 1];
                        
                        // If it is the final node, show destination prompt
                        if (_forEachIndex == (count _path) - 1) then {
                            _icon = "\a3\ui_f\data\map\markers\military\pickup_ca.paa";
                            _text = "DESTINATION (SPACE TO CONFIRM)";
                        };
                        
                        // Text and icon color changed to RED
                        _map drawIcon [_icon, [0.8, 0, 0, 1], _x, 24, 24, 0, _text, 1, 0.05, "PuristaBold", "right"];
                        _lastPos = _x;
                    } forEach _path;
                };
            }];

            // Wait for display to close (either via ESC or Spacebar)
            waitUntil { sleep 0.1; isNull (findDisplay 8990) };
            
            private _finalPath = _caller getVariable ["AAS_Flight_Path", []];
            private _isConfirmed = _caller getVariable ["AAS_Path_Confirmed", false];

            // Execution Gateway
            if (_isConfirmed && count _finalPath > 0) then {
                private _heliTypeString = if (_transportType == "Heavy") then {"Heavy Transport"} else {"Transport"};
                systemChat format ["[AAS] Flight plan confirmed. %1 helicopter called.", _heliTypeString];
                playSound "ReadoutClick";
                
                // FIX: Pass the Transport Type alongside the flight path
                [_caller, _finalPath, _transportType] remoteExec ["aas_log_fnc_servertransport", 2];
            } else {
                systemChat "[AAS] Transport request cancelled.";
            };
        };
    };
};

// =========================================================
// --- DYNAMIC REGISTRY REFRESHER ---
// =========================================================
AAS_LOG_fnc_refreshLogistics = {
    private _logisticsMenu = [];
    
    private _econPreset = missionNamespace getVariable ["AAS_Econ_Preset_Core", 0];
    private _baseCost = 0;
    private _kpLibString = "";

    switch (_econPreset) do {
        case 0: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Custom", "0"]) };
        case 1: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Antistasi", "1000"]) };
        case 2: { 
            private _s = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_KPLib_S", "150"]);
            private _a = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_KPLib_A", "0"]);
            private _f = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_KPLib_F", "150"]);
            _kpLibString = format ["%1/%2/%3", _s, _a, _f];
        };
        case 3: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Overthrow", "2500"]) };
        case 4: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Warlords", "300"]) };
        case 5: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_DUWS", "15"]) };
        case 6: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Antistasi", "1000"]) }; 
    };

    private _fnc_formatName = {
        params ["_rawName", "_multVar"];
        private _actionName = _rawName;
        
        if (_econPreset == 2) then {
            if (_kpLibString != "0/0/0") then { _actionName = format ["%1 (%2)", _actionName, _kpLibString]; };
        } else {
            private _mult = parseNumber (missionNamespace getVariable [_multVar, "1.0"]);
            private _finalCost = round (_baseCost * _mult);
            if (_finalCost > 0) then { _actionName = format ["%1 (%2)", _actionName, _finalCost]; };
        };
        _actionName
    };

    // --- STANDARD TRANSPORT ---
    private _transCd = parseNumber (missionNamespace getVariable ["AAS_LOG_Cooldown_Transport", "600"]);
    private _transLast = missionNamespace getVariable ["AAS_LOG_LastUse_Transport", -99999];

    if (serverTime >= (_transLast + _transCd)) then {
        private _transName = ["Request EXFIL", "AAS_LOG_Transport_CostMult"] call _fnc_formatName;
        _logisticsMenu pushBack [
            _transName, 
            compile " [player, 'Standard'] spawn AAS_LOG_fnc_startMapTargeting; "
        ];
    };

    // --- HEAVY TRANSPORT ---
    private _heavyTransCd = parseNumber (missionNamespace getVariable ["AAS_LOG_Cooldown_TransportHeavy", "600"]);
    private _heavyTransLast = missionNamespace getVariable ["AAS_LOG_LastUse_TransportHeavy", -99999];

    if (serverTime >= (_heavyTransLast + _heavyTransCd)) then {
        private _heavyTransName = ["Request EXFIL (HVY)", "AAS_LOG_TransportHeavy_CostMult"] call _fnc_formatName;
        _logisticsMenu pushBack [
            _heavyTransName, 
            compile " [player, 'Heavy'] spawn AAS_LOG_fnc_startMapTargeting; "
        ];
    };

    private _buildDeliveryMenu = {
        params ["_categoryName", "_prefix", "_count"];
        private _subMenu = [];
        
        // --- DUAL COOLDOWN LOGIC: Check 1-Min Global Cooldown First ---
        private _globalDelivLast = missionNamespace getVariable ["AAS_LOG_LastUse_Delivery_Global", -99999];

        if (serverTime >= (_globalDelivLast + 60)) then {
            // Check Individual Item Cooldowns
            private _itemCd = parseNumber (missionNamespace getVariable ["AAS_LOG_Cooldown_Delivery", "600"]);

            for "_i" from 1 to _count do {
                private _nameVar = format ["AAS_LOG_%1%2_Name", _prefix, _i];
                private _multVar = format ["AAS_LOG_%1%2_Mult", _prefix, _i];
                private _rawName = missionNamespace getVariable [_nameVar, ""];

                private _execId = format ["%1%2", _prefix, _i];
                private _itemLastUse = missionNamespace getVariable [format ["AAS_LOG_LastUse_Delivery_%1", _execId], -99999];

                // Only add it if the specific item is off cooldown AND a valid string is detected
                if (_rawName != "" && {serverTime >= (_itemLastUse + _itemCd)}) then {
                    // Fail-safe for Compositions: Only show if the admin actually pasted a valid array
                    if (_prefix == "Comp" && {missionNamespace getVariable [format ["AAS_LOG_%1%2_Code", _prefix, _i], ""] == ""}) then {
                        continue;
                    };
                    
                    private _itemName = [_rawName, _multVar] call _fnc_formatName;
                    
                    _subMenu pushBack [
                        _itemName,
                        compile format ["
                            private _lzObj = missionNamespace getVariable ['AAS_Active_Smoke', objNull];
                            private _lz = if (isNull _lzObj) then { getPos player } else { getPos _lzObj };
                            [player, _lz, '%1'] remoteExec ['aas_log_fnc_serverdelivery', 2];
                        ", _execId]
                    ];
                };
            };
        };

        if (count _subMenu > 0) then {
            _logisticsMenu pushBack [_categoryName, _subMenu];
        };
    };

    ["Delivery: Vehicles", "Veh", 8] call _buildDeliveryMenu;
    ["Delivery: Equipment", "Equip", 6] call _buildDeliveryMenu;
    ["Delivery: Compositions", "Comp", 10] call _buildDeliveryMenu;

    private _found = false;
    { 
        if ((_x select 0) == "LOGISTICS") exitWith { 
            _x set [1, _logisticsMenu]; 
            _found = true; 
        }; 
    } forEach AAS_Menu_Registry;
    
    if (!_found) then { 
        AAS_Menu_Registry pushBack ["LOGISTICS", _logisticsMenu]; 
    };
};

[] spawn {
    waitUntil { !isNull player && time > 0 && !isNil "AAS_Menu_Registry" && !isNil "AAS_Econ_Preset_Core" }; 
    while {true} do {
        call AAS_LOG_fnc_refreshLogistics;
        sleep 1.5; 
    };
};
diag_log "[AAS-Logistics] SUCCESS: Logistics Module integrated into Tactical Pager Registry.";