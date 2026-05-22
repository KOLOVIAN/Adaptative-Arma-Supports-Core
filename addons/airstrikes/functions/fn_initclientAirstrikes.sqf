// AAS-Airstrikes/functions/fn_initClientAirstrikes.sqf

if (!hasInterface) exitWith {};


diag_log "[AAS-Airstrikes] Initializing Airstrikes Client Module...";

if (isNil "AAS_Loaded_Modules") then { AAS_Loaded_Modules = []; };
if (isNil "AAS_Menu_Registry") then { AAS_Menu_Registry = []; };

AAS_Loaded_Modules pushBackUnique "AIRSTRIKES";

// =========================================================
// --- TARGETING STATE MACHINE & LOGIC ---
// =========================================================
aas_airstrikes_fnc_startTargeting = {
    params ["_caller", "_strikeType"];
    
    [_caller, _strikeType] spawn {
        params ["_caller", "_strikeType"];
        
        systemChat "HQ: Targeting window opened. You have 60 seconds to designate the target";
        [] spawn { sleep 0.5; playSound "aas_as_laserdesignate"; };

        [
            "<t size='0.8' font='PuristaSemiBold' color='#E5E5E5'>AAS TARGETING<br/>Use a <t color='#FF4444'>Laser Designator</t> or switch to <t color='#44FF44'>MAP TARGETING</t> (Pager)</t>",
            -1, 0.05, 8, 1, 0, 8998
        ] spawn BIS_fnc_dynamicText;

        private _timeout = time + 60;
        private _lockTime = 0;
        private _lastPos = [0,0,0];
        private _locked = false;
        private _targetPos = [0,0,0];
        private _lastLaserCheck = time;
        
        _caller setVariable ["AAS_TargetMode", "LASER"];
        _caller setVariable ["AAS_MapClick_Pos", []];
        _caller setVariable ["AAS_MapClick_Time", 0];

        private _hudY = missionNamespace getVariable ["AAS_AS_HUD_Height", 0.35];
        private _hudSize = missionNamespace getVariable ["AAS_AS_HUD_Size", 1.0];
        private _dangerRadius = missionNamespace getVariable ["AAS_AS_DangerClose_Radius", 150];

        private _sizeBracket = 3 * _hudSize;
        private _sizeText = 1.5 * _hudSize;
        private _sizeBracketLock = 4.5 * _hudSize;
        private _sizeTextLock = 1.8 * _hudSize;

        // ==========================================
        // --- CUSTOM TARGETING PAGER UI ---
        // ==========================================
        private _refreshTargetingUI = {
            params [["_uiState", "LASER"]]; // States: "LASER", "MAP_IDLE", "MAP_LOCKING"
            
            private _pagerDisplay = uiNamespace getVariable ["AAS_Pager_Display", displayNull];
            if (isNull _pagerDisplay) then {
                ("AAS_Pager_Layer" call BIS_fnc_rscLayer) cutRsc ["AAS_Pager_HUD", "PLAIN"];
                _pagerDisplay = uiNamespace getVariable ["AAS_Pager_Display", displayNull];
            };
            
            private _display = findDisplay 46;

            // 1. Restore the Theme via Universal Getter
            private _bgCtrl = _pagerDisplay displayCtrl 1200;
            if (!isNull _bgCtrl) then {
                private _themeTextures = call aas_core_fnc_getActiveThemeTextures;
                _bgCtrl ctrlSetText (_themeTextures select 0);
            };

            // 2. Inject Dedicated Targeting Commands or Dummy Status
            private _ctrl = _pagerDisplay displayCtrl 1500;
            
            // Dynamically capture the native font size so we can safely scale it
            private _defaultHeight = _ctrl getVariable ["AAS_Default_FontHeight", -1];
            if (_defaultHeight == -1) then {
                _defaultHeight = ctrlFontHeight _ctrl;
                _ctrl setVariable ["AAS_Default_FontHeight", _defaultHeight];
            };

            lbClear _ctrl;
            
            if (_uiState == "MAP_IDLE") then {
                // Freeze the Pager visually with 35% larger font
                _ctrl ctrlSetFontHeight (_defaultHeight * 1.35); 
                private _i1 = _ctrl lbAdd "[AAS MAP LINKED]";
                private _i2 = _ctrl lbAdd "";
                private _i3 = _ctrl lbAdd "PRESS [ESC] / [BCKSPC]";
                private _i4 = _ctrl lbAdd "TO RETURN TO *LASER*";
                _ctrl lbSetValue [_i1, -1]; _ctrl lbSetValue [_i2, -1]; 
                _ctrl lbSetValue [_i3, -1]; _ctrl lbSetValue [_i4, -1];
                _ctrl lbSetCurSel -1; 
                
            } else {
                if (_uiState == "MAP_LOCKING") then {
                    // Update the dummy screen with coordinates and 45% larger font
                    _ctrl ctrlSetFontHeight (_defaultHeight * 1.45); 
                    private _i1 = _ctrl lbAdd "[ TARGET POSITION ]";
                    private _i2 = _ctrl lbAdd "[  TRANSMITTED  ]";
                    private _i3 = _ctrl lbAdd "";
                    
                    private _clickPos = player getVariable ["AAS_MapClick_Pos", []];
                    if (count _clickPos > 0) then {
                        private _i4 = _ctrl lbAdd format ["GRID: %1", mapGridPosition _clickPos];
                        _ctrl lbSetValue [_i4, -1];
                    };
                    
                    _ctrl lbSetValue [_i1, -1]; _ctrl lbSetValue [_i2, -1]; _ctrl lbSetValue [_i3, -1];
                    _ctrl lbSetCurSel -1;
                    
                } else {
                    // Standard LASER Targeting Mode (Restore Default Font)
                    _ctrl ctrlSetFontHeight _defaultHeight;
                    private _idxMap = _ctrl lbAdd "[ SWITCH TO MAP TARGETING ]";
                    _ctrl lbSetValue [_idxMap, 1];
                    private _idxCancel = _ctrl lbAdd "[ CANCEL TARGETING ]";
                    _ctrl lbSetValue [_idxCancel, 2];
                    _ctrl lbSetCurSel 0;
                };
            };

            // 3. Pre-emptive Handlers Cleanup
            if (!isNil "AAS_AS_EVH_Scroll") then { _display displayRemoveEventHandler ["MouseZChanged", AAS_AS_EVH_Scroll]; AAS_AS_EVH_Scroll = nil; };
            if (!isNil "AAS_AS_EVH_Click") then { _display displayRemoveEventHandler ["MouseButtonUp", AAS_AS_EVH_Click]; AAS_AS_EVH_Click = nil; };
            if (!isNil "AAS_AS_EVH_Key") then { _display displayRemoveEventHandler ["KeyDown", AAS_AS_EVH_Key]; AAS_AS_EVH_Key = nil; };

            // 4. State Handlers
            if (_uiState == "LASER") then {
                inGameUISetEventHandler ["Action", "true"];
                inGameUISetEventHandler ["PrevAction", "true"];
                inGameUISetEventHandler ["NextAction", "true"];

                AAS_AS_EVH_Scroll = _display displayAddEventHandler ["MouseZChanged", {
                    params ["", "_scroll"];
                    if (cameraView == "GUNNER") exitWith {false}; 
                    private _ctrl = (uiNamespace getVariable ["AAS_Pager_Display", displayNull]) displayCtrl 1500;
                    if (isNull _ctrl) exitWith {false};
                    playSound "ReadoutClick"; 
                    if (_scroll < 0) then { _ctrl lbSetCurSel (lbCurSel _ctrl + 1) } else { _ctrl lbSetCurSel (lbCurSel _ctrl - 1) };
                    true;
                }];

                AAS_AS_EVH_Click = _display displayAddEventHandler ["MouseButtonUp", { 
                    params ["", "_button"];
                    if (cameraView == "GUNNER") exitWith {false};
                    if (_button == 2) exitWith { 
                        playSound "Click"; 
                        private _ctrl = (uiNamespace getVariable ["AAS_Pager_Display", displayNull]) displayCtrl 1500;
                        private _val = _ctrl lbValue (lbCurSel _ctrl);
                        if (_val == 1) then { player setVariable ["AAS_TargetMode", "MAP"]; };
                        if (_val == 2) then { player setVariable ["AAS_TargetMode", "CANCEL"]; };
                        true; 
                    }; 
                    false;
                }];
                
                AAS_AS_EVH_Key = _display displayAddEventHandler ["KeyDown", {
                    params ["", "_key"];
                    if (_key == 14) exitWith { player setVariable ["AAS_TargetMode", "CANCEL"]; true; }; // Backspace
                    if (_key == 57) exitWith { // Spacebar (Mirrors the MMB functionality)
                        playSound "Click"; 
                        private _ctrl = (uiNamespace getVariable ["AAS_Pager_Display", displayNull]) displayCtrl 1500;
                        private _val = _ctrl lbValue (lbCurSel _ctrl);
                        if (_val == 1) then { player setVariable ["AAS_TargetMode", "MAP"]; };
                        if (_val == 2) then { player setVariable ["AAS_TargetMode", "CANCEL"]; };
                        true;
                    };
                    false;
                }];
            } else {
                inGameUISetEventHandler ["Action", ""];
                inGameUISetEventHandler ["PrevAction", ""];
                inGameUISetEventHandler ["NextAction", ""];
            };
        };

        // Expose function safely to the uiNamespace so the Map Event Handlers can call it
        uiNamespace setVariable ["aas_airstrikes_fnc_refreshTargetingUI", _refreshTargetingUI];

        // Wait for Core Mod to fully clear the main Pager, then launch the Targeting Pager
        sleep 0.15; 
        ["LASER"] call _refreshTargetingUI;
        private _pagerDisplay = uiNamespace getVariable ["AAS_Pager_Display", displayNull];

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
                    if (player getVariable ["AAS_TargetMode", ""] != "MAP") then {
                        inGameUISetEventHandler ["Action", "true"];
                        inGameUISetEventHandler ["PrevAction", "true"];
                        inGameUISetEventHandler ["NextAction", "true"];
                    };
                };
                sleep 0.1;
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

        // --- CLEANUP MONITOR ---
        [_pagerDisplay] spawn {
            disableSerialization;
            params ["_display"];
            waitUntil { sleep 0.5; isNull _display || !alive player || (player getVariable ["AAS_TargetMode", ""] == "CANCEL") || (player getVariable ["AAS_TargetMode", ""] == "FINISHED") };
            
            if (!isNull _display) then { ("AAS_Pager_Layer" call BIS_fnc_rscLayer) cutText ["", "PLAIN"]; };

            private _mainDisplay = findDisplay 46;
            if (!isNull _mainDisplay) then {
                if (!isNil "AAS_AS_EVH_Scroll") then { _mainDisplay displayRemoveEventHandler ["MouseZChanged", AAS_AS_EVH_Scroll]; };
                if (!isNil "AAS_AS_EVH_Click") then { _mainDisplay displayRemoveEventHandler ["MouseButtonUp", AAS_AS_EVH_Click]; };
                if (!isNil "AAS_AS_EVH_Key") then { _mainDisplay displayRemoveEventHandler ["KeyDown", AAS_AS_EVH_Key]; };
            };

            inGameUISetEventHandler ["Action", ""];
            inGameUISetEventHandler ["PrevAction", ""];
            inGameUISetEventHandler ["NextAction", ""];
        };


        // ==========================================
        // --- THE MASTER TARGETING LOOP ---
        // ==========================================
        while {time < _timeout && !_locked && (_caller getVariable ["AAS_TargetMode", "LASER"] != "CANCEL")} do {
            private _mode = _caller getVariable ["AAS_TargetMode", "LASER"];

            // ------------------------------------------
            // STATE 1: LASER TARGETING 
            // ------------------------------------------
            if (_mode == "LASER") then {
                if (time > _lastLaserCheck + 1) then {
                    _lastLaserCheck = time;
                    private _laser = laserTarget _caller;
                    
                    if (!isNull _laser) then {
                        private _currentPos = getPosATL _laser;
                        if (_lastPos distance _currentPos < 3) then {
                            _lockTime = _lockTime + 1;
                            playSound3D ["a3\sounds_f\weapons\rockets\locked_1.wss", _caller, false, getPosASL _caller, 1, 1, 0]; 
                            
                            private _scanText = format [
                                "<t align='center' color='#FFD700' size='%1' font='PuristaBold'>[   ]</t><br/><t align='center' color='#FFD700' size='%2' font='PuristaBold'>[AAS: LOCKING TARGET... %3%4]</t>", 
                                _sizeBracket, _sizeText, (_lockTime * 20), "%"
                            ];
                            [_scanText, -1, _hudY, 1.2, 0, 0, 8999] spawn BIS_fnc_dynamicText;

                        } else { 
                            if (_lockTime > 0) then {
                                private _lostText = format ["<t align='center' color='#FF0000' size='%1' font='PuristaBold'>[ X ]</t><br/><t align='center' color='#FF0000' size='%2' font='PuristaBold'>[AAS: TARGET LOST]</t>", _sizeBracket, _sizeText];
                                [_lostText, -1, _hudY, 1.5, 0.1, 0, 8999] spawn BIS_fnc_dynamicText;
                            };
                            _lockTime = 0; 
                        };
                        
                        _lastPos = _currentPos;
                        
                        if (_lockTime >= 5) exitWith {
                            if (_caller distance2D _currentPos < _dangerRadius) then {
                                systemChat "AAS: WARNING! Target is DANGER CLOSE. Relocating lock...";
                                private _dangerText = format ["<t align='center' color='#FF0000' size='%1' font='PuristaBold'>[ ! ]</t><br/><t align='center' color='#FF0000' size='%2' font='PuristaBold'>[DANGER CLOSE - LOCK ABORTED]</t>", _sizeBracket, _sizeText];
                                [_dangerText, -1, _hudY, 2, 0.1, 0, 8999] spawn BIS_fnc_dynamicText;
                                playSound "FD_CP_Not_Clear_F";
                                _lockTime = 0;
                            } else { 
                                _locked = true; 
                                _targetPos = _currentPos; 
                            };
                        };
                    } else { 
                        if (_lockTime > 0) then {
                            private _lostText = format ["<t align='center' color='#FF0000' size='%1' font='PuristaBold'>[ X ]</t><br/><t align='center' color='#FF0000' size='%2' font='PuristaBold'>[AAS: TARGET LOST]</t>", _sizeBracket, _sizeText];
                            [_lostText, -1, _hudY, 1.5, 0.1, 0, 8999] spawn BIS_fnc_dynamicText;
                        };
                        _lockTime = 0; 
                    };
                };
            };

            // ------------------------------------------
            // STATE 2: TABLET TARGETING
            // ------------------------------------------
            if (_mode == "MAP") then {
                if (isNull (findDisplay 8990)) then {
                    
                    // Turn the Pager into an aesthetic Status Screen
                    ["MAP_IDLE"] call _refreshTargetingUI;
                    
                    systemChat "[AAS - DATALINK ESTABLISHED - AWAITING COORDINATES]";
                    playSound "FD_Timer_F";
                    ["", -1, -1, 0, 0, 0, 8999] spawn BIS_fnc_dynamicText; 
                    ["", -1, -1, 0, 0, 0, 8998] spawn BIS_fnc_dynamicText; 

                    createDialog "AAS_AS_Tablet_Dialog";
                    
                    // Map Initialization & Draw Logic
                    [_caller] spawn {
                        params ["_caller"];
                        waitUntil { !isNull (findDisplay 8990) }; 
                        
                        private _disp = findDisplay 8990;
                        private _mapCtrl = _disp displayCtrl 8991;
                        private _frameCtrl = _disp displayCtrl 8992;

                        // ===============================================
                        // --- DYNAMICALLY SHIFT THE UI (8.5% L, 5% D) ---
                        // ===============================================
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

                        // Support closing with Backspace (DIK 14) exactly like ESC
                        _disp displayAddEventHandler ["KeyDown", {
                            params ["_display", "_key"];
                            if (_key == 14) then { _display closeDisplay 2; true } else { false };
                        }];
                        
                        // Dynamic Tablet Era Swap via Universal Getter
                        private _themeTextures = call aas_core_fnc_getActiveThemeTextures;
                        _frameCtrl ctrlSetText (_themeTextures select 1);
                        
                        _mapCtrl ctrlMapAnimAdd [0, 0.1, getPos _caller];
                        ctrlMapAnimCommit _mapCtrl;
                        
                        _caller setVariable ["AAS_Radar_Targets", []];
                        [_caller] spawn {
                            params ["_caller"];
                            private _playerSide = side _caller;
                            while {!isNull (findDisplay 8990)} do {
                                private _rawTargets = _caller nearEntities [["Man", "Car", "Tank", "Ship"], 2000];
                                private _filtered = _rawTargets select {
                                    alive _x && 
                                    {!(_x isKindOf "Animal")} && 
                                    { ((_playerSide getFriend (side _x)) >= 0.6) || ((_playerSide knowsAbout _x) >= 1.5) }
                                };
                                _caller setVariable ["AAS_Radar_Targets", _filtered];
                                sleep 1; 
                            };
                        };

                        _mapCtrl ctrlAddEventHandler ["Draw", {
                            params ["_map"];
                            private _dangerRadius = missionNamespace getVariable ["AAS_AS_DangerClose_Radius", 150];
                            private _p1 = getPosVisual player;
                            
                            private _p2 = screenToWorld [0.5, 0.5]; 
                            if (_p1 distance2D _p2 > 5000) then { _p2 = _p1 getPos [5000, getDirVisual player]; };
                            
                            _map drawLine [_p1, _p2, [1, 0, 0, 0.8]]; 
                            _map drawIcon ["\a3\ui_f\data\map\markers\military\dot_ca.paa", [1, 0, 0, 1], _p2, 10, 10, 0, "", 0];
                            _map drawEllipse [_p1, _dangerRadius, _dangerRadius, 0, [1,0,0,1], ""]; 

                            private _radarTargets = player getVariable ["AAS_Radar_Targets", []];
                            {
                                private _targetSide = side _x;
                                private _color = [0.7, 0.7, 0.7, 1]; 
                                switch (_targetSide) do {
                                    case west: { _color = [0, 0.3, 0.6, 1]; }; 
                                    case east: { _color = [0.6, 0, 0, 1]; };   
                                    case independent: { _color = [0, 0.5, 0, 1]; }; 
                                    case civilian: { _color = [0.5, 0, 0.5, 1]; }; 
                                };
                                
                                _map drawIcon [
                                    getText (configFile >> "CfgVehicles" >> typeOf _x >> "icon"),
                                    _color, getPosVisual _x, 24, 24, getDirVisual _x, "", 0, 0.03, "TahomaB", "center"
                                ];
                            } forEach _radarTargets;

                            private _clickPos = player getVariable ["AAS_MapClick_Pos", []];
                            
                            if (_clickPos isEqualTo []) then {
                                private _mouseScreen = getMousePosition;
                                private _mouseWorld = _map ctrlMapScreenToWorld _mouseScreen;
                                private _dist = _p1 distance2D _mouseWorld;
                                private _dir = _p1 getDir _mouseWorld;
                                private _alt = getTerrainHeightASL _mouseWorld;
                                
                                private _pos1 = _map ctrlMapScreenToWorld [(_mouseScreen select 0) - 0.02, (_mouseScreen select 1) - 0.03];
                                private _pos2 = _map ctrlMapScreenToWorld [(_mouseScreen select 0) - 0.02, (_mouseScreen select 1) + 0.00];
                                private _pos3 = _map ctrlMapScreenToWorld [(_mouseScreen select 0) - 0.02, (_mouseScreen select 1) + 0.03];
                                
                                _map drawIcon ["#(argb,8,8,3)color(0,0,0,0)", [1,0,0,1], _pos1, 1, 1, 0, format ["DIST: %1m", round _dist], 1, 0.07, "PuristaBold", "right"];
                                _map drawIcon ["#(argb,8,8,3)color(0,0,0,0)", [1,0,0,1], _pos2, 1, 1, 0, format ["DIR: %1°", round _dir], 1, 0.07, "PuristaBold", "right"];
                                _map drawIcon ["#(argb,8,8,3)color(0,0,0,0)", [1,0,0,1], _pos3, 1, 1, 0, format ["ALT: %1m", round _alt], 1, 0.07, "PuristaBold", "right"];
                            };

                            if (!(_clickPos isEqualTo [])) then {
                                private _timeLeft = 0 max ((player getVariable ["AAS_MapClick_Time", 0]) - time);
                                _map drawIcon [
                                    "\a3\ui_f\data\map\markers\military\objective_ca.paa", 
                                    [1, 0, 0, 1], _clickPos, 35, 35, time * 45, 
                                    format ["LOCKING: %1s", _timeLeft toFixed 1], 
                                    1, 0.05, "PuristaBold", "right"
                                ];
                            };
                        }];

                        _mapCtrl ctrlAddEventHandler ["MouseButtonClick", {
                            params ["_control", "_button", "_xPos", "_yPos"];
                            if (_button == 0) then { 
                                private _currentLock = player getVariable ["AAS_MapClick_Pos", []];
                                if (count _currentLock > 0) then {
                                    player setVariable ["AAS_MapClick_Pos", []];
                                    player setVariable ["AAS_MapClick_Time", 0];
                                    playSound "ReadoutClick";
                                    ["MAP_IDLE"] call (uiNamespace getVariable "aas_airstrikes_fnc_refreshTargetingUI");
                                } else {
                                    private _worldPos = _control ctrlMapScreenToWorld [_xPos, _yPos];
                                    player setVariable ["AAS_MapClick_Pos", [_worldPos select 0, _worldPos select 1, 0]];
                                    player setVariable ["AAS_MapClick_Time", time + 5.5]; 
                                    playSound "FD_Timer_F"; 
                                    
                                    // Push Coordinates to the Dummy Pager
                                    ["MAP_LOCKING"] call (uiNamespace getVariable "aas_airstrikes_fnc_refreshTargetingUI");
                                };
                            };
                        }];
                    };

                    // Suspend the background loop while the map is active
                    waitUntil { 
                        sleep 0.1; 
                        isNull (findDisplay 8990) || 
                        {(_caller getVariable ["AAS_TargetMode", "LASER"] == "CANCEL")} || 
                        {(_caller getVariable ["AAS_MapClick_Pos", []] isNotEqualTo []) && (time > (_caller getVariable ["AAS_MapClick_Time", 0]) + 0.2)} 
                    };
                    
                    private _clickPos = _caller getVariable ["AAS_MapClick_Pos", []];
                    private _clickTime = _caller getVariable ["AAS_MapClick_Time", 0];

                    // Check if it closed because of a successful map lock
                    if (!(_clickPos isEqualTo []) && {time > (_clickTime + 0.2)}) then {
                        if (_caller distance2D _clickPos < _dangerRadius) then {
                            systemChat "AAS: WARNING! Target is DANGER CLOSE. Strike Aborted.";
                            playSound "FD_CP_Not_Clear_F";
                            _caller setVariable ["AAS_MapClick_Pos", []]; 
                            
                            // Revert to MAP IDLE mode while map remains open
                            ["MAP_IDLE"] call _refreshTargetingUI; 
                        } else {
                            _locked = true;
                            _targetPos = _clickPos;
                            if (!isNull (findDisplay 8990)) then { closeDialog 1; }; 
                        };
                    } else {
                        // User cancelled the map manually (ESC or Backspace). Revert to laser and restore pager UI
                        if (_caller getVariable ["AAS_TargetMode", ""] != "CANCEL") then {
                            _caller setVariable ["AAS_TargetMode", "LASER"];
                            ["LASER"] call _refreshTargetingUI;
                            systemChat "[AAS - LASER TARGETING MODE SELECTED]";
                            playSound "FD_Timer_F";
                        };
                    };
                };
            };
            sleep 0.1; 
        };

        // ==========================================
        // --- CLEANUP & EXECUTION ---
        // ==========================================
        
        // Clean up the global UI namespace hook
        uiNamespace setVariable ["aas_airstrikes_fnc_refreshTargetingUI", nil];
        
        // This triggers the Failsafe Monitor to instantly delete all Event Handlers and Visuals
        _caller setVariable ["AAS_TargetMode", "FINISHED"]; 
        
        if (!isNull (findDisplay 8990)) then { closeDialog 1; }; 
        ["", -1, -1, 0, 0, 0, 8998] spawn BIS_fnc_dynamicText; 

        if (_caller getVariable ["AAS_TargetMode", ""] == "CANCEL") exitWith {
            systemChat "HQ: Targeting cancelled.";
        };

        if (_locked) then {
            systemChat "HQ: Target LOCKED. Coordinates transmitted.";
            
            [_caller, _hudY, _sizeBracketLock, _sizeTextLock] spawn {
                params ["_caller", "_hudY", "_sizeBracketLock", "_sizeTextLock"];
                private _lockedText = format [
                    "<t align='center' color='#FF0000' size='%1' font='PuristaBold'>[   ]</t><br/><t align='center' color='#FF0000' size='%2' font='PuristaBold'>[AAS: TARGET LOCKED]</t>", 
                    _sizeBracketLock, _sizeTextLock
                ];

                for "_i" from 1 to 3 do {
                    playSound3D ["a3\sounds_f\weapons\rockets\locked_3.wss", _caller, false, getPosASL _caller, 1.5, 1, 0]; 
                    [_lockedText, -1, _hudY, 0.2, 0, 0, 8999] spawn BIS_fnc_dynamicText;
                    sleep 0.3; 
                };
                
                sleep 0.2;
                playSound "aas_as_targetlocked";
            };

            [_caller, _targetPos, _strikeType] remoteExec ["aas_airstrikes_fnc_serverAirstrikes", 2];
        } else { 
            ["", -1, -1, 0, 0, 0, 8999] spawn BIS_fnc_dynamicText; 
            systemChat "HQ: Targeting window expired."; 
            [] spawn { sleep 0.2; playSound "aas_as_targetexpired"; };
        };
    };
};

// =========================================================
// --- DYNAMIC REGISTRY REFRESHER (REROUTED TO CORE) ---
// =========================================================
aas_airstrikes_fnc_refreshAirstrikes = {
    private _airstrikeOptions = [];
    
    // REROUTED: Fetch the Global Economy Preset instead of the local one
    private _econPreset = missionNamespace getVariable ["AAS_Econ_Preset_Core", 0];
    
    private _baseCost = 0;
    private _kpLibString = "";

    // Fetch the Base Costs or KP Liberation array
    switch (_econPreset) do {
        case 0: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Custom", "0"]) };
        case 1: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Antistasi", "1000"]) };
        case 2: { 
            // KP Liberation Format Setup: Grabs the base thresholds and formats them safely
            private _s = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_KPLib_S", "50"]);
            private _a = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_KPLib_A", "100"]);
            private _f = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_KPLib_F", "50"]);
            _kpLibString = format ["%1/%2/%3", _s, _a, _f];
        };
        case 3: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Overthrow", "3000"]) };
        case 4: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Warlords", "400"]) };
        case 5: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_DUWS", "10"]) };
        case 6: { _baseCost = parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Antistasi", "1000"]) }; 
    };

    private _strikes = [
        ["Midnight Sun", "AAS_AS_Mult_MidnightSun", "AAS_AS_Cooldown_MidnightSun", "AAS_AS_LastUse_MidnightSun", "MidnightSun"],
        ["Gun Run", "AAS_AS_Mult_GunRun", "AAS_AS_Cooldown_GunRun", "AAS_AS_LastUse_GunRun", "GunRun"],
        ["Carpet Bombing", "AAS_AS_Mult_UnguidedBomb", "AAS_AS_Cooldown_UnguidedBomb", "AAS_AS_LastUse_UnguidedBomb", "UnguidedBomb"],
        ["Cruise Missile", "AAS_AS_Mult_CruiseMissile", "AAS_AS_Cooldown_CruiseMissile", "AAS_AS_LastUse_CruiseMissile", "CruiseMissile"],
        ["JDAM", "AAS_AS_Mult_JDAM", "AAS_AS_Cooldown_JDAM", "AAS_AS_LastUse_JDAM", "JDAM"]
    ];

    {
        _x params ["_name", "_multVar", "_cdVar", "_lastUseVar", "_id"];
        private _cd = parseNumber (missionNamespace getVariable [_cdVar, "300"]);
        private _last = missionNamespace getVariable [_lastUseVar, -99999];

        if (serverTime >= (_last + _cd)) then {
            private _actionName = _name;
            
            // Format Logic Split: KP Liberation (String) vs Standard (Multiplied Number)
            if (_econPreset == 2) then {
                if (_kpLibString != "0/0/0") then { _actionName = format ["%1 (%2)", _name, _kpLibString]; };
            } else {
                private _mult = parseNumber (missionNamespace getVariable [_multVar, "1"]);
                private _finalCost = round (_baseCost * _mult);
                if (_finalCost > 0) then { _actionName = format ["%1 (%2)", _name, _finalCost]; };
            };
            
            _airstrikeOptions pushBack [
                _actionName, 
                compile format [" [player, '%1'] spawn aas_airstrikes_fnc_startTargeting; ", _id]
            ];
        };
    } forEach _strikes;

    private _found = false;
    { 
        if ((_x select 0) == "AIRSTRIKES") exitWith { 
            _x set [1, _airstrikeOptions]; 
            _found = true; 
        }; 
    } forEach AAS_Menu_Registry;
    
    if (!_found) then { 
        AAS_Menu_Registry pushBack ["AIRSTRIKES", _airstrikeOptions]; 
    };
};

[] spawn {
    // FAILSAFE FIX: Ensure Core Mod variables actually exist before attempting to inject
    waitUntil { !isNull player && time > 0 && !isNil "AAS_Menu_Registry" && !isNil "AAS_Econ_Preset_Core" }; 
    while {true} do {
        call aas_airstrikes_fnc_refreshAirstrikes;
        sleep 1.5; 
    };
};
diag_log "[AAS-Airstrikes] SUCCESS: Airstrikes Module integrated into Tactical Pager Registry.";