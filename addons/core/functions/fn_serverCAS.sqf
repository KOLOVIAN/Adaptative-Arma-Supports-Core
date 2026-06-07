// functions/fn_serverCAS.sqf

// We keep the 3rd parameter to absorb the remoteExec payload
params ["_caller", "_dropPos", "_ignoredZeus", ["_casType", "HELI"]];

private _playerSide = side group _caller;

// ==========================================
// --- 1. PRE-EXECUTION: COST MULTIPLIER ---
// ==========================================
// We must fetch the cost multiplier BEFORE the economy check
private _costMultStr = "1.0";
switch (_casType) do {
    case "PLANE":   { _costMultStr = AAS_CAS_Plane_CostMult; };
    case "HELI":    { _costMultStr = AAS_CAS_Heli_CostMult; };
    case "GUNSHIP": { _costMultStr = AAS_CAS_Gunship_CostMult; };
};

// ==========================================
// --- 2. COOLDOWN CHECK ---
// ==========================================
private _cooldownTime = parseNumber AAS_Cooldown_CAS; 
private _lastUse = missionNamespace getVariable ["AAS_CAS_LastUseTime", -99999];

if (serverTime < (_lastUse + _cooldownTime)) exitWith {
    private _timeLeft = round(((_lastUse + _cooldownTime) - serverTime) / 60);
    (format ["HQ: CAS on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// ==========================================
// --- 3. DYNAMIC ECONOMY CHECK ---
// ==========================================
private _baseCost = switch (AAS_Econ_Preset_Core) do {
    case 0: { parseNumber AAS_Cost_CAS_Custom };
    case 1: { parseNumber AAS_Cost_CAS_Antistasi };
    case 2: { 
        [
            parseNumber AAS_Cost_CAS_KPLib_S, 
            parseNumber AAS_Cost_CAS_KPLib_A, 
            parseNumber AAS_Cost_CAS_KPLib_F
        ] 
    };
    case 3: { parseNumber AAS_Cost_CAS_Overthrow };
    case 4: { parseNumber AAS_Cost_CAS_Warlords };
    case 5: { parseNumber AAS_Cost_CAS_DUWS };
    case 6: { parseNumber AAS_Cost_CAS_Antistasi };
    default { 0 };
};

private _finalCost = _baseCost;

// Apply the CBA multiplier UNLESS it is KP Liberation (Preset 2)
if (AAS_Econ_Preset_Core != 2) then {
    _finalCost = round (_baseCost * (parseNumber _costMultStr));
};

// Call the Central Economy Manager
private _econPass = [_caller, _finalCost, AAS_Econ_Preset_Core, AAS_Econ_Code_CAS] call aas_core_fnc_setEconomyPreset;
if (!_econPass) exitWith {};

// --- FINALIZE SUPPORT ---
missionNamespace setVariable ["AAS_CAS_LastUseTime", serverTime, true];

// ==========================================
// --- 4. RANDOMIZED VOICELINES INTEGRATION ---
// ==========================================
private _casComms = [
    ["HQ: Close Air Support near your position. Keep your heads down.", "AAS_Voice_CAS"],
    ["HQ: Close Air Support authorized. Aircraft is inbound, over.", "AAS_Voice_CAS2"],
    ["HQ: Roger that, aircraft dispatched. ETA 1 minute.", "AAS_Voice_CAS3"]
];
private _selectedComm = selectRandom _casComms;

(_selectedComm select 0) remoteExec ["systemChat", _caller];
(_selectedComm select 1) remoteExec ["playSound", _caller];


// =========================================================================
// --- 5. SHARED HELPERS & VARIABLES ---
// =========================================================================
private _rtbTime = parseNumber AAS_RTB_CAS;
private _spawnDist = 3000;

// --- SMART PARSER HELPER FUNCTION ---
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


// =========================================================================
// --- 6. MASTER EXECUTION SWITCH ---
// =========================================================================
switch (_casType) do {

    // ---------------------------------------------------------------------
    // CASE A: PLANE (CLEAN VANILLA SLATE)
    // ---------------------------------------------------------------------
    case "PLANE": {
        private _airClassRaw = AAS_CAS_Plane_Class;
        private _behaviorMode = AAS_CAS_Plane_Behavior; // Kept variable to avoid breaking dependencies
        private _flightHeight = 400; // Planes need a safe baseline
        private _loiterRadius = 1500;

        // Parse Air Class
        private _airParsed = [_airClassRaw] call _fnc_parseClass;
        private _airClass = _airParsed select 0;
        private _customLoadout = _airParsed select 1;

        // Spawning
        private _spawnPos = _dropPos getPos [_spawnDist, random 360];
        _spawnPos set [2, _flightHeight]; 
        private _airData = [_spawnPos, _spawnPos getDir _dropPos, _airClass, _playerSide] call BIS_fnc_spawnVehicle;
        private _aircraft = _airData select 0;
        private _airGroup = _airData select 2;

        // Apply specific Plane logic (Anti-Stall Push)
        _aircraft setVelocityModelSpace [0, 150, 0]; // ~540 km/h push

        // Apply Loadouts & Protection
        if (_customLoadout isNotEqualTo false) then {
            if (_customLoadout isEqualType []) then { _aircraft setUnitLoadout _customLoadout; };
            if (_customLoadout isEqualType "") then { _aircraft call compile _customLoadout; };
        };
        _aircraft allowDamage false; 
        _aircraft flyInHeight _flightHeight;

        // Infinite Ammo Tracker
        _aircraft setVariable ["AAS_LastFireTime", serverTime];
        _aircraft addEventHandler ["Fired", {
            params ["_unit"];
            _unit setVehicleAmmo 1;
            _unit setVariable ["AAS_LastFireTime", serverTime];
        }];

        // Crew setup - FIXED SHADOWING
        { 
            private _unit = _x;
            _unit allowDamage false; 
            _unit addRating 100000; 
            [_unit] joinSilent _airGroup;
            { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
        } forEach crew _aircraft;

        // Waypoints & Behavior - STRIPPED TO BARE VANILLA
        private _wpAttack = _airGroup addWaypoint [_dropPos, 0];
        _wpAttack setWaypointType "SAD";
        _wpAttack setWaypointSpeed "NORMAL";
        _airGroup setCombatMode "RED"; 
        _airGroup setBehaviour "AWARE"; // Crucial fix: "AWARE" prevents pilot evasive panic

        // RTB Thread
        [_aircraft, _airGroup, _spawnPos, _rtbTime] spawn {
            params ["_aircraft", "_airGroup", "_spawnPos", "_rtbTime"];
            sleep 120;
            if (alive _aircraft) then { _aircraft allowDamage true; { if (alive _x) then { _x allowDamage true; }; } forEach crew _aircraft; };
            private _remainingTime = _rtbTime - 120;
            if (_remainingTime > 0) then { sleep _remainingTime; };
            if (alive _aircraft) then {
                while {(count (waypoints _airGroup)) > 0} do { deleteWaypoint ((waypoints _airGroup) select 0); };
                _airGroup setBehaviour "CARELESS"; _airGroup setCombatMode "BLUE";
                private _wpAway = _airGroup addWaypoint [_spawnPos, 0];
                _wpAway setWaypointType "MOVE"; _wpAway setWaypointSpeed "FULL";
                _wpAway setWaypointStatements ["true", "private _v = vehicle this; {deleteVehicle _x} forEach crew _v; deleteVehicle _v;"];
            };
        };
    };

    // ---------------------------------------------------------------------
    // CASE B: HELICOPTER (CLEAN VANILLA SLATE)
    // ---------------------------------------------------------------------
    case "HELI": {
        private _airClassRaw = AAS_CAS_Heli_Class;
        private _behaviorMode = AAS_CAS_Heli_Behavior; // Kept variable
        private _flightHeight = parseNumber AAS_CAS_Heli_Height;
        private _loiterRadius = parseNumber AAS_CAS_Heli_Radius;

        // Parse Air Class
        private _airParsed = [_airClassRaw] call _fnc_parseClass;
        private _airClass = _airParsed select 0;
        private _customLoadout = _airParsed select 1;

        // Spawning
        private _spawnPos = _dropPos getPos [_spawnDist, random 360];
        _spawnPos set [2, _flightHeight]; 
        private _airData = [_spawnPos, _spawnPos getDir _dropPos, _airClass, _playerSide] call BIS_fnc_spawnVehicle;
        private _aircraft = _airData select 0;
        private _airGroup = _airData select 2;

        // Apply Loadouts & Protection
        if (_customLoadout isNotEqualTo false) then {
            if (_customLoadout isEqualType []) then { _aircraft setUnitLoadout _customLoadout; };
            if (_customLoadout isEqualType "") then { _aircraft call compile _customLoadout; };
        };
        _aircraft allowDamage false; 
        _aircraft flyInHeight _flightHeight;

        // Infinite Ammo Tracker
        _aircraft setVariable ["AAS_LastFireTime", serverTime];
        _aircraft addEventHandler ["Fired", {
            params ["_unit"];
            _unit setVehicleAmmo 1;
            _unit setVariable ["AAS_LastFireTime", serverTime];
        }];

        // Crew setup - FIXED SHADOWING
        { 
            private _unit = _x;
            _unit allowDamage false; 
            _unit addRating 100000; 
            [_unit] joinSilent _airGroup;
            { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
        } forEach crew _aircraft;

        // Waypoints & Behavior - STRIPPED TO BARE VANILLA
        private _wpAttack = _airGroup addWaypoint [_dropPos, 0];
        _wpAttack setWaypointType "SAD";
        _wpAttack setWaypointSpeed "NORMAL";
        _airGroup setCombatMode "RED"; 
        _airGroup setBehaviour "AWARE"; // Crucial fix: "AWARE" prevents pilot evasive panic

        // Specific Heli Logic: Anti-Stuck Thread
        [_aircraft] spawn {
            params ["_heli"];
            private _lastPos = getPos _heli;
            private _stuckCount = 0;
            while {alive _heli} do {
                sleep 5;
                if ((getPos _heli) distance2D _lastPos < 5) then { _stuckCount = _stuckCount + 5; } else { _stuckCount = 0; };
                if (_stuckCount >= 45) exitWith { {deleteVehicle _x} forEach crew _heli; deleteVehicle _heli; };
                _lastPos = getPos _heli;
            };
        };

        // RTB Thread
        [_aircraft, _airGroup, _spawnPos, _rtbTime] spawn {
            params ["_aircraft", "_airGroup", "_spawnPos", "_rtbTime"];
            sleep 120;
            if (alive _aircraft) then { _aircraft allowDamage true; { if (alive _x) then { _x allowDamage true; }; } forEach crew _aircraft; };
            private _remainingTime = _rtbTime - 120;
            if (_remainingTime > 0) then { sleep _remainingTime; };
            if (alive _aircraft) then {
                while {(count (waypoints _airGroup)) > 0} do { deleteWaypoint ((waypoints _airGroup) select 0); };
                _airGroup setBehaviour "CARELESS"; _airGroup setCombatMode "BLUE";
                private _wpAway = _airGroup addWaypoint [_spawnPos, 0];
                _wpAway setWaypointType "MOVE"; _wpAway setWaypointSpeed "FULL";
                _wpAway setWaypointStatements ["true", "private _v = vehicle this; {deleteVehicle _x} forEach crew _v; deleteVehicle _v;"];
            };
        };
    };

    // ---------------------------------------------------------------------
    // CASE C: GUNSHIP (UNCHANGED)
    // ---------------------------------------------------------------------
    case "GUNSHIP": {
        private _airClassRaw = AAS_CAS_Gunship_Class;
        private _behaviorMode = 0; // ALWAYS Loiter
        private _flightHeight = parseNumber AAS_CAS_Gunship_Height;
        private _loiterRadius = parseNumber AAS_CAS_Gunship_Radius;
        private _forceOrbit = AAS_CAS_Gunship_Orbit;

        // Parse Air Class
        private _airParsed = [_airClassRaw] call _fnc_parseClass;
        private _airClass = _airParsed select 0;
        private _customLoadout = _airParsed select 1;

        // Spawning
        private _spawnPos = _dropPos getPos [_spawnDist, random 360];
        _spawnPos set [2, _flightHeight]; 
        private _airData = [_spawnPos, _spawnPos getDir _dropPos, _airClass, _playerSide] call BIS_fnc_spawnVehicle;
        private _aircraft = _airData select 0;
        private _airGroup = _airData select 2;

        // Apply Loadouts & Protection
        if (_customLoadout isNotEqualTo false) then {
            if (_customLoadout isEqualType []) then { _aircraft setUnitLoadout _customLoadout; };
            if (_customLoadout isEqualType "") then { _aircraft call compile _customLoadout; };
        };
        _aircraft allowDamage false; 
        _aircraft flyInHeight _flightHeight;

        // Infinite Ammo Tracker
        _aircraft setVariable ["AAS_LastFireTime", serverTime];
        _aircraft addEventHandler ["Fired", {
            params ["_unit"];
            _unit setVehicleAmmo 1;
            _unit setVariable ["AAS_LastFireTime", serverTime];
        }];

        // Crew setup - FIXED SHADOWING
        { 
            private _unit = _x;
            _unit allowDamage false; 
            _unit addRating 100000; 
            [_unit] joinSilent _airGroup;
            { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
        } forEach crew _aircraft;

        // Waypoints & Behavior
        private _wpAttack = _airGroup addWaypoint [_dropPos, 0];
        _airGroup setCombatMode "RED"; 
        _airGroup setBehaviour "COMBAT"; 

        _wpAttack setWaypointType "LOITER";
        _wpAttack setWaypointLoiterRadius _loiterRadius;
        _wpAttack setWaypointSpeed "NORMAL";
        if (_forceOrbit) then { _wpAttack setWaypointLoiterType "CIRCLE_L"; };

        // Specific Gunship Logic: Pilot Lobotomy & Phantom Thread
        private _pilot = driver _aircraft;
        { _pilot disableAI _x } forEach ["TARGET", "AUTOTARGET", "AUTOCOMBAT", "WEAPONAIM"];

        [_aircraft, _airGroup, _dropPos, _loiterRadius] spawn {
            params ["_aircraft", "_airGroup", "_dropPos", "_loiterRadius"];
            private _friendlySide = side _airGroup;
            private _scanRadius = _loiterRadius * 1.2;
            private _pilot = driver _aircraft;
            private _gunners = crew _aircraft select { _x != _pilot };
            private _phantoms = [];

            while {alive _aircraft} do {
                sleep 5;
                private _enemies = (_dropPos nearEntities [["Man"], _scanRadius]) select { alive _x && { _friendlySide getFriend (side _x) < 0.6 } };

                if (count _enemies > 0) then {
                    private _target = _enemies select 0;
                    { if (_x distance2D _dropPos < _target distance2D _dropPos) then { _target = _x; }; } forEach _enemies;

                    {
                        private _idx = _forEachIndex;
                        private _gunner = _x;
                        private _offset = [(_idx * 15), 0, 0];
                        private _phantomPos = (getPos _target) vectorAdd _offset;

                        if (_idx >= count _phantoms || { isNull (_phantoms select _idx) }) then {
                            private _p = createVehicle ["O_MRAP_02_F", _phantomPos, [], 0, "NONE"];
                            _p allowDamage false; _p engineOn false; _p hideObjectGlobal true;
                            [_p] joinSilent (group _target); createVehicleCrew _p;
                            { _x allowDamage false; _x hideObjectGlobal true; } forEach crew _p;
                            _phantoms set [_idx, _p];
                        } else {
                            (_phantoms select _idx) setPos _phantomPos;
                        };
                        _gunner doTarget (_phantoms select _idx);
                    } forEach _gunners;
                } else {
                    { if (!isNull _x) then { { deleteVehicle _x } forEach crew _x; deleteVehicle _x; }; } forEach _phantoms;
                    _phantoms = [];
                };
            };

            // Final RTB Phantom Cleanup
            { if (!isNull _x) then { { deleteVehicle _x } forEach crew _x; deleteVehicle _x; }; } forEach _phantoms;
        };

        // RTB Thread
        [_aircraft, _airGroup, _spawnPos, _rtbTime] spawn {
            params ["_aircraft", "_airGroup", "_spawnPos", "_rtbTime"];
            sleep 120;
            if (alive _aircraft) then { _aircraft allowDamage true; { if (alive _x) then { _x allowDamage true; }; } forEach crew _aircraft; };
            private _remainingTime = _rtbTime - 120;
            if (_remainingTime > 0) then { sleep _remainingTime; };
            if (alive _aircraft) then {
                while {(count (waypoints _airGroup)) > 0} do { deleteWaypoint ((waypoints _airGroup) select 0); };
                _airGroup setBehaviour "CARELESS"; _airGroup setCombatMode "BLUE";
                private _wpAway = _airGroup addWaypoint [_spawnPos, 0];
                _wpAway setWaypointType "MOVE"; _wpAway setWaypointSpeed "FULL";
                _wpAway setWaypointStatements ["true", "private _v = vehicle this; {deleteVehicle _x} forEach crew _v; deleteVehicle _v;"];
            };
        };
    };
};