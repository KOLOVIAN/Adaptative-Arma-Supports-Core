// AAS-Logistics/functions/fn_servertransport.sqf
/* Author: AAS Team
    Description: Master Route for Logistics Transport (Real-Time Flight).
    Spawns bulletproof heli, executes fast pickups, accepts multi-waypoint route plotting,
    allows mid-flight redirects (locked on final approach), handles dynamic radio comms,
    and includes a live-updating map marker for the extraction countdown.
    *Now supports Dynamic Standard/Heavy classes and Adjustable Flight Altitude.*
*/

// FIX: Added _transportType parameter
params ["_caller", "_flightPath", ["_transportType", "Standard"]];
if (!isServer) exitWith {};

// The final destination is the last waypoint in the array
private _finalDest = _flightPath select ((count _flightPath) - 1);

// ==========================================
// --- 1. CORE SETUP & SECURITY ---
// ==========================================
private _playerSide = side group _caller;
if (_playerSide == sideLogic || _playerSide == civilian) then { _playerSide = west; };

// --- DYNAMIC TYPE ROUTING ---
private _multVar = if (_transportType == "Heavy") then { "AAS_LOG_TransportHeavy_CostMult" } else { "AAS_LOG_Transport_CostMult" };
private _cdVar = if (_transportType == "Heavy") then { "AAS_LOG_Cooldown_TransportHeavy" } else { "AAS_LOG_Cooldown_Transport" };
private _lastUseVar = if (_transportType == "Heavy") then { "AAS_LOG_LastUse_TransportHeavy" } else { "AAS_LOG_LastUse_Transport" };
private _heliClassVar = if (_transportType == "Heavy") then { "AAS_LOG_TransportHeavy_HeliClass" } else { "AAS_LOG_Transport_HeliClass" };
private _defaultClass = if (_transportType == "Heavy") then { "B_Heli_Transport_03_F" } else { "B_Heli_Transport_01_F" };

// ==========================================
// --- 2. ECONOMY & COOLDOWN CHECK ---
// ==========================================
private _econPreset = missionNamespace getVariable ["AAS_Econ_Preset_Core", 0];
private _baseCost = switch (_econPreset) do {
    case 0: { parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Custom", "0"]) };
    case 1: { parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Antistasi", "1000"]) };
    case 3: { parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Overthrow", "2500"]) };
    case 4: { parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Warlords", "300"]) };
    case 5: { parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_DUWS", "15"]) };
    case 6: { parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_Antistasi", "1000"]) };
    default { 0 };
};

private _cost = 0;
if (_econPreset == 2) then {
    _cost = [
        parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_KPLib_S", "150"]),
        parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_KPLib_A", "0"]),
        parseNumber (missionNamespace getVariable ["AAS_LOG_Cost_Base_KPLib_F", "150"])
    ];
} else {
    private _mult = parseNumber (missionNamespace getVariable [_multVar, "1.0"]);
    _cost = round (_baseCost * _mult);
};

private _cdTime = parseNumber (missionNamespace getVariable [_cdVar, "600"]);
private _lastUse = missionNamespace getVariable [_lastUseVar, -99999];

if (serverTime < (_lastUse + _cdTime)) exitWith {
    private _timeLeft = 1 max round (((_lastUse + _cdTime) - serverTime) / 60);
    (format ["HQ: %1 on cooldown. Available in %2 mins.", _transportType, _timeLeft]) remoteExec ["systemChat", _caller];
};

private _econCode = missionNamespace getVariable ["AAS_LOG_Econ_Code", ""];
private _econPass = [_caller, _cost, _econPreset, _econCode] call aas_core_fnc_setEconomyPreset;
if (isNil "_econPass" || {!_econPass}) exitWith {};

missionNamespace setVariable [_lastUseVar, serverTime, true];

// --- HQ APPROVAL COMMS (3 Second Delay) ---
[_caller] spawn {
    params ["_caller"];
    sleep 3;
    private _hqComms = [
        ["log_hq4", "HQ: Copy that Ground Team, we are sending a helicopter to pick you up."],
        ["log_hq5", "HQ: Transport request approved. Helicopter inbound, over."]
    ];
    private _selected = selectRandom _hqComms;
    (_selected select 1) remoteExec ["systemChat", _caller];
    [_selected select 0] remoteExec ["playSound", _caller];
};

// ==========================================
// --- 3. SMART PARSER HELPER ---
// ==========================================
private _fnc_parseClass = {
    params ["_rawSetting"];
    private _class = _rawSetting;
    private _loadout = false;
    private _trimmed = (_rawSetting splitString " ") joinString "";
    
    if ((_trimmed select [0,1] == "[") && {(_trimmed select [(count _trimmed) - 1, 1] == "]")}) then {
        private _parsed = call compile _rawSetting;
        if (_parsed isEqualType []) then {
            _class = _parsed select 0;
            if (count _parsed > 1) then { _loadout = _parsed select 1; };
        };
    };
    [_class, _loadout]
};

// ==========================================
// --- 4. LZ DEFINITION & HELI SPAWN ---
// ==========================================
private _lzObj = missionNamespace getVariable ["AAS_Active_Smoke", objNull];
private _lz = if (isNull _lzObj) then { getPos _caller } else { getPos _lzObj };

private _helipad = createVehicle ["Land_HelipadEmpty_F", _lz, [], 0, "NONE"];

private _spawnDist = 2000;
private _spawnPos = _lz getPos [_spawnDist, random 360];
_spawnPos set [2, 100];

private _rawHeliClass = missionNamespace getVariable [_heliClassVar, _defaultClass];
private _heliParsed = [_rawHeliClass] call _fnc_parseClass;
private _heliClass = _heliParsed select 0;
private _heliLoadout = _heliParsed select 1;

private _heliData = [_spawnPos, _spawnPos getDir _lz, _heliClass, _playerSide] call BIS_fnc_spawnVehicle;
private _heli = _heliData select 0;
private _heliGroup = _heliData select 2;

if (_heliLoadout isNotEqualTo false) then {
    if (_heliLoadout isEqualType []) then { _heli setUnitLoadout _heliLoadout; };
    if (_heliLoadout isEqualType "") then { _heli call compile _heliLoadout; };
};

// --- AI BULLETPROOFING & SPEED HACKS ---
_heli allowDamage false;
_heli setCaptive true; 
_heliGroup setBehaviour "CARELESS";
_heliGroup setCombatMode "BLUE";
_heliGroup setSpeedMode "FULL";

{ 
    _x allowDamage false;
    _x setCaptive true; 
    _x addRating 100000; 
    [_x] joinSilent _heliGroup; 
} forEach crew _heli;

_heli setVariable ["AAS_Original_Crew", crew _heli];

{ _heliGroup disableAI _x } forEach ["AUTOTARGET", "TARGET", "SUPPRESSION", "AUTOCOMBAT", "MINEDETECTION"];

private _flightHeight = missionNamespace getVariable ["AAS_LOG_Transport_FlightHeight", 70];
_heli flyInHeight _flightHeight; 

// Send to LZ
private _wpLand = _heliGroup addWaypoint [_lz, 0];
_wpLand setWaypointType "MOVE";
_wpLand setWaypointSpeed "FULL";
_wpLand setWaypointStatements ["true", "(vehicle this) land 'GET IN';"]; 

// ==========================================
// --- 5. EXECUTION THREAD ---
// ==========================================
[_heli, _heliGroup, _lz, _flightPath, _finalDest, _helipad, _caller, _flightHeight] spawn {
    params ["_heli", "_heliGroup", "_lz", "_flightPath", "_finalDest", "_helipad", "_caller", "_flightHeight"];
    
    // --- COMMS SWITCHBOARD HELPER ---
    private _fnc_comms = {
        params ["_heli", "_caller", "_msg", "_type", ["_sound", ""]];
        private _targets = [];
        switch (_type) do {
            case 1: { _targets = [_caller]; }; 
            case 2: { 
                _targets = (crew _heli) select {isPlayer _x};
                _targets pushBackUnique _caller;
            }; 
            case 3: { 
                _targets = (crew _heli) select {isPlayer _x};
            };
        };
        _targets = _targets select {alive _x && !isNull _x};
        if (count _targets > 0) then {
            _msg remoteExec ["systemChat", _targets];
            if (_sound != "") then {
                [_sound] remoteExec ["playSound", _targets];
            };
        };
    };

    // --- SCRIPTED ENGINE CLAMP HELPER ---
    private _fnc_toggleClamp = {
        params ["_heli", "_state"];
        // Check if the optional compatibility clamp is enabled in CBA settings
        private _useClamp = missionNamespace getVariable ["AAS_LOG_Transport_Clamp", false];
        if (!_useClamp) exitWith {}; // 100% Ignored if toggled off

        if (_state) then {
            _heli setVariable ["AAS_Clamp_Active", true];
            
            // Aggressive loop to force the engine off
            [_heli] spawn {
                params ["_h"];
                while {alive _h && _h getVariable ["AAS_Clamp_Active", false]} do {
                    _h engineOn false;
                    // Disable pathing just in case the AI tries to taxi without the engine
                    { _x disableAI "PATH"; } forEach (crew _h select { !isPlayer _x });
                    sleep 1;
                };
            };
        } else {
            _heli setVariable ["AAS_Clamp_Active", false];
            { _x enableAI "PATH"; } forEach (crew _heli select { !isPlayer _x });
            _heli engineOn true;
        };
    };

    // --- PHASE 1: APPROACH INITIAL LZ ---
    waitUntil { sleep 1; _heli distance2D _lz < 300 || !alive _heli };
    if (!alive _heli) exitWith {};
    
    private _appLines = [
        ["log_transport1", "PILOT: LIMA 4 to Ground Team, we are approaching landing zone, over."],
        ["log_transport2", "PILOT: LIMA 4 to Ground Team, be at the LZ, our ETA is 1 minute, over."],
        ["log_transport3", "PILOT: On final approach. Keep the LZ clear, over."]
    ];
    private _selApp = selectRandom _appLines;
    [_heli, _caller, _selApp select 1, 1, _selApp select 0] call _fnc_comms;

    waitUntil { sleep 2; isTouchingGround _heli || !alive _heli };
    if (!alive _heli) exitWith { deleteVehicle _helipad; };

    // >>>> ACTIVATE ENGINE CLAMP <<<<
    [_heli, true] call _fnc_toggleClamp;

    _heli engineOn true; // Ignored immediately if clamp loop is active
    _heli setVariable ["AAS_ReadyToGo", false, true];

    // --- PHASE 2: BOARDING & LIVE MARKER ---
    [
        _heli,
        [
            "<t color='#00FF00'>Pilot, we are ready. Take off.</t>", 
            { (_this select 0) setVariable ["AAS_ReadyToGo", true, true]; }, 
            nil, 1.5, true, true, "", "isPlayer _this && _this in _target"
        ]
    ] remoteExec ["addAction", 0, _heli];

    // Create the live countdown marker on the map
    private _extMarkerName = format ["AAS_Ext_Marker_%1", floor(random 100000)];
    private _extMarker = createMarker [_extMarkerName, getPos _heli];
    _extMarker setMarkerType "b_air";        // NATO Helicopter Symbol
    _extMarker setMarkerColor "ColorGreen";  // Dark/Standard Green

    private _timeout = serverTime + 180;
    waitUntil { 
        sleep 1; 
        private _timeLeft = 0 max round (_timeout - serverTime);
        
        // Pin marker to heli and update text every second
        _extMarker setMarkerPos (getPos _heli);
        _extMarker setMarkerText format [" EXTRACTION (%1s)", _timeLeft];
        
        (_heli getVariable ["AAS_ReadyToGo", false]) || 
        (serverTime > _timeout) || 
        !alive _heli
    };

    // Delete the marker the exact moment they take off
    deleteMarker _extMarker;
    if (!alive _heli) exitWith { deleteVehicle _helipad; };

    [_heli] remoteExec ["removeAllActions", 0, _heli];
    
    // >>>> DEACTIVATE ENGINE CLAMP <<<<
    [_heli, false] call _fnc_toggleClamp;
    
    _heli engineOn true;

    // --- PHASE 3: MULTI-WAYPOINT ENROUTE ---
    while {(count (waypoints _heliGroup)) > 0} do { deleteWaypoint ((waypoints _heliGroup) select 0); };
    
    private _destPad = createVehicle ["Land_HelipadEmpty_F", _finalDest, [], 0, "NONE"];
    _heli setVariable ["AAS_Active_Pad", _destPad]; 
    _heli setVariable ["AAS_Current_Target_Dest", _finalDest, true]; 
    
    // Inject the plotted waypoints
    {
        private _wp = _heliGroup addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "FULL";
        
        // Only the final waypoint executes the landing
        if (_forEachIndex == (count _flightPath) - 1) then {
            _wp setWaypointStatements ["true", "(vehicle this) land 'GET OUT';"]; 
        };
    } forEach _flightPath;

    _heli flyInHeight _flightHeight; 
    
    waitUntil { sleep 1; (getPos _heli select 2) > 5 || !alive _heli };
    
    // 10 Seconds After Takeoff Audio
    sleep 10;
    private _takeoffLines = [
        ["log_transport4", "PILOT: Proceeding to destination. Buckle up!"],
        ["log_transport5", "PILOT: Executing flight plan."]
    ];
    private _selTO = selectRandom _takeoffLines;
    [_heli, _caller, _selTO select 1, 2, _selTO select 0] call _fnc_comms;

    missionNamespace setVariable ["aas_logistics_fnc_RedirectMap", {
        params ["_target", "_caller", "_actionId"];
        _target setVariable ["AAS_Dest_Changed", true, true]; 
        [_target, _caller] remoteExec ["removeAllActions", 0, _target]; 
        
        [_target, _caller] spawn {
            params ["_heli", "_player"];
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
            
            _mapCtrl ctrlMapAnimAdd [0, 0.1, getPos _player];
            ctrlMapAnimCommit _mapCtrl;
            
            _player setVariable ["AAS_MapClick_Pos", []];
            
            _mapCtrl ctrlAddEventHandler ["MouseButtonClick", {
                params ["_control", "_button", "_xPos", "_yPos"];
                if (_button == 0) then { 
                    private _worldPos = _control ctrlMapScreenToWorld [_xPos, _yPos];
                    player setVariable ["AAS_MapClick_Pos", [_worldPos select 0, _worldPos select 1, 0]];
                };
            }];
            
            _disp displayAddEventHandler ["KeyDown", {
                params ["_display", "_key"];
                if (_key == 14) then { _display closeDisplay 2; true } else { false };
            }];
            
            waitUntil { 
                sleep 0.1; 
                isNull (findDisplay 8990) || 
                {(_player getVariable ["AAS_MapClick_Pos", []] isNotEqualTo [])} 
            };
            
            private _newPos = _player getVariable ["AAS_MapClick_Pos", []];
            if (!isNull (findDisplay 8990)) then { closeDialog 1; }; 
            
            if (!(_newPos isEqualTo [])) then {
                _heli setVariable ["AAS_New_Dest", _newPos, true]; 
            };
        };
    }, true];

    _heli setVariable ["AAS_Dest_Changed", false, true];
    
    [
        _heli,
        [
            "<t color='#FFA500'>Change Destination (Map)</t>", 
            { _this call aas_logistics_fnc_RedirectMap; }, 
            nil, 1.5, true, true, "", 
            "!(_target getVariable ['AAS_Dest_Changed', false]) && isPlayer _this && _this in _target && (_target distance2D (_target getVariable ['AAS_Current_Target_Dest', [0,0,0]]) > 400)"
        ]
    ] remoteExec ["addAction", 0, _heli];

    // --- ENROUTE LOOP ---
    private _currentDest = _finalDest;
    private _300mTriggered = false;

    while {alive _heli && !isTouchingGround _heli && (_heli distance2D _currentDest > 50)} do {
        
        // Check for Redirect
        private _newDest = _heli getVariable ["AAS_New_Dest", []];
        if (_newDest isNotEqualTo []) then {
            _heli setVariable ["AAS_New_Dest", [], true]; 
            _currentDest = _newDest;
            _heli setVariable ["AAS_Current_Target_Dest", _currentDest, true]; 
            _300mTriggered = false; 
            
            deleteVehicle (_heli getVariable ["AAS_Active_Pad", objNull]);
            private _newPad = createVehicle ["Land_HelipadEmpty_F", _currentDest, [], 0, "NONE"];
            _heli setVariable ["AAS_Active_Pad", _newPad];
            
            while {(count (waypoints _heliGroup)) > 0} do { deleteWaypoint ((waypoints _heliGroup) select 0); };
            private _wpRedir = _heliGroup addWaypoint [_currentDest, 0];
            _wpRedir setWaypointType "MOVE";
            _wpRedir setWaypointSpeed "FULL";
            _wpRedir setWaypointStatements ["true", "(vehicle this) land 'GET OUT';"];
            
            sleep 3;
            [_heli, _caller, "PILOT: Copy that, rerouting to new destination.", 2, "log_transport6"] call _fnc_comms;
        };

        // Approaching Final Destination Audio
        if (!_300mTriggered && (_heli distance2D _currentDest < 300)) then {
            _300mTriggered = true;
            private _destLines = [
                ["log_transport7", "PILOT: Approaching destination, get ready to disembark."],
                ["log_transport8", "PILOT: Approaching LZ. Get ready."],
                ["log_transport9", "PILOT: LZ on sight. Get ready Ground Team."]
            ];
            private _selDest = selectRandom _destLines;
            [_heli, _caller, _selDest select 1, 2, _selDest select 0] call _fnc_comms;
        };

        sleep 1;
    };

    // --- PHASE 4: ARRIVAL & DISEMBARK ---
    waitUntil { sleep 2; isTouchingGround _heli || !alive _heli };
    if (!alive _heli) exitWith { deleteVehicle _helipad; deleteVehicle (_heli getVariable ["AAS_Active_Pad", objNull]); };

    // >>>> ACTIVATE ENGINE CLAMP <<<<
    [_heli, true] call _fnc_toggleClamp;

    sleep 3;
    [_heli, _caller, "PILOT: Go, go, go, we have touched down. Dismount.", 2, "log_transport10"] call _fnc_comms;

    _heli engineOn true;
    private _originalCrew = _heli getVariable ["AAS_Original_Crew", []];

    private _evictTime = serverTime + 60;
    waitUntil { 
        sleep 2; 
        private _currentPassengers = (crew _heli) - _originalCrew;
        (count _currentPassengers == 0) || (serverTime > _evictTime)
    };

    // >>>> DEACTIVATE ENGINE CLAMP <<<<
    [_heli, false] call _fnc_toggleClamp;

    { 
        if (!(_x in _originalCrew)) then { 
            unassignVehicle _x;
            moveOut _x; 
        }; 
    } forEach crew _heli;

    // --- PHASE 5: CLEANUP & DESPAWN ---
    deleteVehicle _helipad;
    deleteVehicle (_heli getVariable ["AAS_Active_Pad", objNull]);

    private _despawnPos = _currentDest getPos [3000, random 360];
    private _wpLeave = _heliGroup addWaypoint [_despawnPos, 0];
    _wpLeave setWaypointType "MOVE";
    _wpLeave setWaypointSpeed "FULL";
    
    _heli flyInHeight 150; 
    
    waitUntil { sleep 1; (getPos _heli select 2) > 5 || !alive _heli };
    waitUntil { sleep 5; (_heli distance2D _currentDest > 2500) || !alive _heli };
    
    if (alive _heli) then {
        { deleteVehicle _x } forEach crew _heli;
        deleteVehicle _heli;
    };
    deleteGroup _heliGroup;
};