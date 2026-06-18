// functions/fn_serverReinforcements.sqf

// We keep the 3rd parameter to absorb the remoteExec payload
params ["_caller", "_dropPos", "_ignoredZeus", ["_reinfType", "AIR_4"]];

private _playerSide = side group _caller;

// ==========================================
// --- 1. CATEGORY & PARAMETER RESOLUTION ---
// ==========================================
// Resolve the broad category (ARMOR / AIR / MECH) plus every per-variant tunable up
// front, so the cost/cooldown/voiceline/economy logic below can stay generic.

private _category       = "";   // "ARMOR" | "AIR" | "MECH"
private _isPara         = false; // AIR sub-flag — true only for the 12-man paradrop variant
private _vehicleClassRaw = "";
private _squadSize      = 0;
private _costMultStr    = "1.0";
private _behaviorMode   = 0;
private _rtbTimeStr     = "300";
private _cooldownTimeStr = "600";
private _troopClasses   = [];
private _lastUseVar     = "AAS_Reinf_LastUseTime";

switch (_reinfType) do {
    // --- ARMOR ---
    case "ARMOR_TURRET": {
        _category = "ARMOR"; _vehicleClassRaw = AAS_Reinf_Armor_Turret; _costMultStr = AAS_Reinf_Armor_CostMult_Turret;
        _rtbTimeStr = AAS_RTB_Reinf_Armor; _cooldownTimeStr = AAS_Cooldown_Reinf_Armor; _behaviorMode = AAS_Behavior_Armor;
        _lastUseVar = "AAS_Reinf_Armor_LastUseTime";
    };
    case "ARMOR_APC": {
        _category = "ARMOR"; _vehicleClassRaw = AAS_Reinf_Armor_APC; _costMultStr = AAS_Reinf_Armor_CostMult_APC;
        _rtbTimeStr = AAS_RTB_Reinf_Armor; _cooldownTimeStr = AAS_Cooldown_Reinf_Armor; _behaviorMode = AAS_Behavior_Armor;
        _lastUseVar = "AAS_Reinf_Armor_LastUseTime";
    };
    case "ARMOR_TANK": {
        _category = "ARMOR"; _vehicleClassRaw = AAS_Reinf_Armor_Tank; _costMultStr = AAS_Reinf_Armor_CostMult_Tank;
        _rtbTimeStr = AAS_RTB_Reinf_Armor; _cooldownTimeStr = AAS_Cooldown_Reinf_Armor; _behaviorMode = AAS_Behavior_Armor;
        _lastUseVar = "AAS_Reinf_Armor_LastUseTime";
    };
    // --- AIRBORNE INFANTRY ---
    case "AIR_4": {
        _category = "AIR"; _vehicleClassRaw = AAS_Reinf_Air_LightHeli; _squadSize = 4; _costMultStr = AAS_Reinf_Air_CostMult_4;
        _rtbTimeStr = AAS_RTB_Reinf_Air; _cooldownTimeStr = AAS_Cooldown_Reinf_Air; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Air_SL, AAS_Reinf_Air_Sniper, AAS_Reinf_Air_AT, AAS_Reinf_Air_AR];
        _lastUseVar = "AAS_Reinf_Air_LastUseTime";
    };
    case "AIR_8": {
        _category = "AIR"; _vehicleClassRaw = AAS_Reinf_Air_StdHeli; _squadSize = 8; _costMultStr = AAS_Reinf_Air_CostMult_8;
        _rtbTimeStr = AAS_RTB_Reinf_Air; _cooldownTimeStr = AAS_Cooldown_Reinf_Air; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Air_SL, AAS_Reinf_Air_Sniper, AAS_Reinf_Air_AT, AAS_Reinf_Air_AR];
        _lastUseVar = "AAS_Reinf_Air_LastUseTime";
    };
    case "AIR_12": {
        _category = "AIR"; _isPara = true; _vehicleClassRaw = AAS_Reinf_Air_Plane; _squadSize = 12; _costMultStr = AAS_Reinf_Air_CostMult_12;
        _rtbTimeStr = AAS_RTB_Reinf_Air; _cooldownTimeStr = AAS_Cooldown_Reinf_Air; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Air_SL, AAS_Reinf_Air_Sniper, AAS_Reinf_Air_AT, AAS_Reinf_Air_AR];
        _lastUseVar = "AAS_Reinf_Air_LastUseTime";
    };
    // --- MECHANIZED INFANTRY ---
    case "MECH_4": {
        _category = "MECH"; _vehicleClassRaw = AAS_Reinf_Ground_MRAP; _squadSize = 4; _costMultStr = AAS_Reinf_Ground_CostMult_4;
        _rtbTimeStr = AAS_RTB_Reinf_Ground; _cooldownTimeStr = AAS_Cooldown_Reinf_Ground; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Ground_SL, AAS_Reinf_Ground_Sniper, AAS_Reinf_Ground_AT, AAS_Reinf_Ground_AR];
        _lastUseVar = "AAS_Reinf_Ground_LastUseTime";
    };
    case "MECH_8": {
        _category = "MECH"; _vehicleClassRaw = AAS_Reinf_Ground_APC; _squadSize = 8; _costMultStr = AAS_Reinf_Ground_CostMult_8;
        _rtbTimeStr = AAS_RTB_Reinf_Ground; _cooldownTimeStr = AAS_Cooldown_Reinf_Ground; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Ground_SL, AAS_Reinf_Ground_Sniper, AAS_Reinf_Ground_AT, AAS_Reinf_Ground_AR];
        _lastUseVar = "AAS_Reinf_Ground_LastUseTime";
    };
    case "MECH_12": {
        _category = "MECH"; _vehicleClassRaw = AAS_Reinf_Ground_Truck; _squadSize = 12; _costMultStr = AAS_Reinf_Ground_CostMult_12;
        _rtbTimeStr = AAS_RTB_Reinf_Ground; _cooldownTimeStr = AAS_Cooldown_Reinf_Ground; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Ground_SL, AAS_Reinf_Ground_Sniper, AAS_Reinf_Ground_AT, AAS_Reinf_Ground_AR];
        _lastUseVar = "AAS_Reinf_Ground_LastUseTime";
    };
};

if (_category == "") exitWith {};

private _cooldownTime = parseNumber _cooldownTimeStr;
private _rtbTime      = parseNumber _rtbTimeStr;

// ==========================================
// --- 2. COOLDOWN CHECK ---
// ==========================================
private _lastUse = missionNamespace getVariable [_lastUseVar, -99999];

if (serverTime < (_lastUse + _cooldownTime)) exitWith {
    private _timeLeft = round(((_lastUse + _cooldownTime) - serverTime) / 60);
    (format ["HQ: Reinforcements on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// ==========================================
// --- 3. DYNAMIC ECONOMY CHECK ---
// ==========================================
private _baseCost = switch (AAS_Econ_Preset_Core) do {
    case 0: { parseNumber AAS_Cost_Reinf_Custom };
    case 1: { parseNumber AAS_Cost_Reinf_Antistasi };
    case 2: {
        [
            parseNumber AAS_Cost_Reinf_KPLib_S,
            parseNumber AAS_Cost_Reinf_KPLib_A,
            parseNumber AAS_Cost_Reinf_KPLib_F
        ]
    };
    case 3: { parseNumber AAS_Cost_Reinf_Overthrow };
    case 4: { parseNumber AAS_Cost_Reinf_Warlords };
    case 5: { parseNumber AAS_Cost_Reinf_DUWS };
    case 6: { parseNumber AAS_Cost_Reinf_Antistasi };
    default { 0 };
};

private _finalCost = _baseCost;

// Apply the CBA multiplier UNLESS it is KP Liberation (Preset 2)
if (AAS_Econ_Preset_Core != 2) then {
    _finalCost = round (_baseCost * (parseNumber _costMultStr));
};

private _econPass = [_caller, _finalCost, AAS_Econ_Preset_Core, AAS_Econ_Code_Reinf] call aas_core_fnc_setEconomyPreset;
if (!_econPass) exitWith {};

// --- FINALIZE SUPPORT ---
missionNamespace setVariable [_lastUseVar, serverTime, true];

// Backwards compatibility sync for initCLIENT.sqf menu hider
missionNamespace setVariable ["AAS_Reinf_LastUseTime", serverTime, true];

// ==========================================
// --- 4. RANDOMIZED VOICELINES ---
// ==========================================
if (_category == "ARMOR") then {
    private _armorComms = [
        ["HQ: Copy that ground team. Armor on the way to your position, over.", "AAS_Voice_Armor1"],
        ["HQ: Armor is half a click from your position. ETA 1 minute, over.", "AAS_Voice_Armor2"]
    ];
    private _selectedComm = selectRandom _armorComms;

    (_selectedComm select 0) remoteExec ["systemChat", _caller];
    (_selectedComm select 1) remoteExec ["playSound", _caller];
} else {
    // Both AIR and MECH share the generic "reinforcements inbound" voice pool
    private _reinfComms = [
        ["HQ: Reinforcements inbound. Secure the LZ.", "AAS_Voice_Reinf"],
        ["HQ: Reinforcements are on their way. Hold your position, over.", "AAS_Voice_Reinf2"],
        ["HQ: Reinforcements inbound. ETA 2 minutes.", "AAS_Voice_Reinf3"],
        ["HQ: Copy that ground team, the squad is approaching your position.", "AAS_Voice_Reinf4"]
    ];
    private _selectedComm = selectRandom _reinfComms;

    (_selectedComm select 0) remoteExec ["systemChat", _caller];
    (_selectedComm select 1) remoteExec ["playSound", _caller];
};


// =========================================================================
// --- 5. SHARED HELPERS ---
// =========================================================================

// --- SMART PARSER HELPER FUNCTION ---
// Accepts either a bare classname ("B_Soldier_F") or a packed array string
// ("[\"B_Soldier_F\", [<loadout array>]]") and returns [_class, _loadoutOrFalse].
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

// --- GROUND TRANSIT WATCHDOG ---
// Monitors a ground vehicle moving to a destination. Auto-recovers from
// flips (vectorUp Z < 0.5) and stuck states (<5m progress over 15s) by
// teleporting 10m toward the destination. Enforces a hard transit timeout.
//
// Args:
//   _veh        - vehicle to watch
//   _dest       - destination position
//   _arrivalRad - arrival radius in meters
//   _maxTime    - hard transit timeout in seconds
//
// Returns:
//   "ARRIVED" - within radius, OR alive but canMove false (immobilized in place)
//   "DEAD"    - vehicle is no longer alive
//   "TIMEOUT" - exceeded _maxTime; caller is responsible for cleanup
private _fnc_groundWatchdog = {
    params ["_veh", "_dest", "_arrivalRad", "_maxTime"];

    private _start = serverTime;
    private _lastPos = getPosATL _veh;
    private _stuckSeconds = 0;
    private _tickInterval = 3;
    private _stuckThreshold = 15;
    private _flipThreshold = 0.5;
    private _result = "TIMEOUT";

    while { true } do {
        sleep _tickInterval;

        // Exit conditions checked first so we never "recover" a vehicle that just arrived
        if (!alive _veh) exitWith { _result = "DEAD" };
        if ((_veh distance2D _dest) < _arrivalRad) exitWith { _result = "ARRIVED" };
        if (!canMove _veh) exitWith { _result = "ARRIVED" }; // Immobilized-in-place: still useful, treat as arrival
        if ((serverTime - _start) > _maxTime) exitWith { _result = "TIMEOUT" };

        private _bearing = _veh getDir _dest;
        private _curPos = getPosATL _veh;

        // Flip detection — tilted past ~60 degrees
        if (((vectorUp _veh) select 2) < _flipThreshold) then {
            private _newPos = _veh getPos [10, _bearing];
            _newPos set [2, 0];
            _veh setVectorUp [0, 0, 1];
            _veh setPos _newPos;
            _veh setDir _bearing;
            _stuckSeconds = 0;
            _lastPos = getPosATL _veh;
            diag_log format ["[AAS Reinf] Watchdog flip-recovered %1 toward %2", typeOf _veh, _dest];
        } else {
            // Stuck detection — <5m progress in tick window
            if ((_curPos distance2D _lastPos) < 5) then {
                _stuckSeconds = _stuckSeconds + _tickInterval;
                if (_stuckSeconds >= _stuckThreshold) then {
                    private _newPos = _veh getPos [10, _bearing];
                    _newPos set [2, 0];
                    _veh setPos _newPos;
                    _stuckSeconds = 0;
                    diag_log format ["[AAS Reinf] Watchdog unstuck %1 toward %2", typeOf _veh, _dest];
                };
            } else {
                _stuckSeconds = 0;
            };
            _lastPos = getPosATL _veh;
        };
    };

    _result
};


// =========================================================================
// --- 6. MASTER EXECUTION SWITCH ---
// =========================================================================
switch (_category) do {

    // ---------------------------------------------------------------------
    // CASE A: ARMOR
    // ---------------------------------------------------------------------
    // Spawns a single armored vehicle on a nearby road (or ~350m field if no
    // road within 500m), drives it to the drop position under CARELESS+BLUE,
    // hands the player a 120s post-arrival immortality buffer, applies the
    // configured armor behavior, then despawns at RTB time.
    // ---------------------------------------------------------------------
    case "ARMOR": {
        [_caller, _dropPos, _playerSide, _vehicleClassRaw, _behaviorMode, _rtbTime, _fnc_parseClass, _fnc_groundWatchdog] spawn {
            params ["_caller", "_dropPos", "_playerSide", "_vehicleClassRaw", "_behaviorMode", "_rtbTime", "_fnc_parseClass", "_fnc_groundWatchdog"];

            // Realistic dispatch delay before convoy moves
            sleep 7;

            // --- SPAWN POSITION (ROADS FIRST, FIELD FALLBACK) ---
            private _spawnPos = [];
            private _spawnDir = 0;

            private _roadsNear = _dropPos nearRoads 500;
            if (count _roadsNear > 0) then {
                // Found a road — spawn exactly on it and face it down the path
                private _road = _roadsNear select 0;
                _spawnPos = getPos _road;
                private _roadConnectedTo = roadsConnectedTo _road;
                if (count _roadConnectedTo > 0) then {
                    _spawnDir = _road getDir (_roadConnectedTo select 0);
                } else {
                    _spawnDir = _spawnPos getDir _dropPos;
                };
            } else {
                // No roads within 500m — Spawn 350m away, actively avoiding known enemies
                private _enemies = (_dropPos nearEntities [["Man"], 500]) select { _playerSide getFriend (side _x) < 0.6 };
                if (count _enemies > 0) then {
                    // Find a heading away from the closest enemy
                    private _closestEnemy = _enemies select 0;
                    private _enemyDir = _dropPos getDir _closestEnemy;
                    private _safeDir = _enemyDir + 180 + (random 60 - 30); // Opposite direction with a bit of randomness
                    _spawnPos = _dropPos getPos [350, _safeDir];
                } else {
                    _spawnPos = _dropPos getPos [350, random 360];
                };

                // Failsafe check so we don't spawn inside a rock
                private _safePos = [_spawnPos, 0, 150, 5, 0, 0.25, 0] call BIS_fnc_findSafePos;
                if (count _safePos > 1) then { _spawnPos = _safePos; };
                _spawnDir = _spawnPos getDir _dropPos;
            };

            // --- VEHICLE SPAWN & LOADOUT ---
            private _vehParsed = [_vehicleClassRaw] call _fnc_parseClass;
            private _vehClass = _vehParsed select 0;
            private _vehLoadout = _vehParsed select 1;

            private _vehData = [_spawnPos, _spawnDir, _vehClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _vehicle = _vehData select 0;
            private _vehGroup = _vehData select 2;

            if (_vehLoadout isNotEqualTo false) then {
                if (_vehLoadout isEqualType []) then { _vehicle setUnitLoadout _vehLoadout; };
                if (_vehLoadout isEqualType "") then { _vehicle call compile _vehLoadout; };
            };

            // Apply strict immortality to vehicle and crew for transit
            _vehicle allowDamage false;
            {
                private _crewMember = _x;
                _crewMember allowDamage false;
                _crewMember addRating 100000;
                [_crewMember] joinSilent _vehGroup;
                { _crewMember setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
            } forEach crew _vehicle;

            // --- TRANSIT PATHING (CARELESS — ignore enemies en route) ---
            _vehGroup setBehaviour "CARELESS";
            _vehGroup setCombatMode "BLUE";

            private _wpLand = _vehGroup addWaypoint [_dropPos, 0];
            _wpLand setWaypointType "MOVE";
            _wpLand setWaypointSpeed "FULL";
            _wpLand setWaypointCompletionRadius 50;

            // Watchdog auto-recovers flips/stuck and enforces a 200s transit timeout
            private _transitResult = [_vehicle, _dropPos, 100, 200] call _fnc_groundWatchdog;

            if (_transitResult == "DEAD") exitWith {};
            if (_transitResult == "TIMEOUT") exitWith {
                diag_log format ["[AAS Reinf] Armor reinforcement timed out, despawning %1", typeOf _vehicle];
                { deleteVehicle _x } forEach crew _vehicle;
                deleteVehicle _vehicle;
            };
            // "ARRIVED" — continue with post-arrival logic

            // --- 120s POST-ARRIVAL IMMORTALITY BUFFER ---
            [_vehicle] spawn {
                params ["_veh"];
                sleep 120;
                if (alive _veh) then {
                    _veh allowDamage true;
                    { if (alive _x) then { _x allowDamage true; }; } forEach crew _veh;
                };
            };

            // --- ARMOR BEHAVIOR ---
            switch (_behaviorMode) do {
                case 0: { // Follow Player (Proximity Pathing Loop)
                    _vehGroup setBehaviour "AWARE";
                    _vehGroup setCombatMode "YELLOW";
                    [_vehicle, _vehGroup, _caller] spawn {
                        params ["_veh", "_grp", "_plr"];
                        while {alive _veh && alive _plr} do {
                            if ((_veh distance2D _plr) > 100) then {
                                while {(count (waypoints _grp)) > 0} do { deleteWaypoint ((waypoints _grp) select 0); };
                                private _wp = _grp addWaypoint [getPos _plr, 0];
                                _wp setWaypointType "MOVE";
                            };
                            sleep 15;
                        };
                    };
                };
                case 1: { // Join Player
                    _vehGroup setBehaviour "AWARE";
                    _vehGroup setCombatMode "YELLOW";
                    // Prevent crew from dismounting and abandoning the tank when grouped with player
                    _vehicle allowCrewInImmobile true;
                    (units _vehGroup) joinSilent (group _caller);
                };
                case 2: { // Engage Nearest (Aggressive Push)
                    _vehGroup setBehaviour "COMBAT";
                    _vehGroup setCombatMode "RED";
                    private _wpSAD = _vehGroup addWaypoint [_dropPos, 0];
                    _wpSAD setWaypointType "SAD";
                };
            };

            // --- RTB & DESPAWN ---
            if (_rtbTime >= 99999 || _rtbTime < 0) exitWith {};
            sleep _rtbTime;

            if (alive _vehicle) then {
                // Detach from player group if joined previously
                private _grp = createGroup (side _vehicle);
                (crew _vehicle) joinSilent _grp;

                _grp setBehaviour "CARELESS";
                _grp setCombatMode "BLUE";
                private _wp = _grp addWaypoint [_spawnPos, 0];
                _wp setWaypointType "MOVE";
                _wp setWaypointSpeed "FULL";

                private _timeout = serverTime + 180; // 3 min tolerance
                waitUntil { sleep 5; (_vehicle distance2D _spawnPos) < 200 || !alive _vehicle || serverTime > _timeout };

                { deleteVehicle _x } forEach crew _vehicle;
                deleteVehicle _vehicle;
            };
        };
    };


    // ---------------------------------------------------------------------
    // CASE B: AIRBORNE INFANTRY
    // ---------------------------------------------------------------------
    // Spawns a transport aircraft 2.5km out at 150m height. Heli variants
    // land and dismount via doors; the 12-man variant paradrops from 250m.
    // Includes a heli-only "engine stall" failsafe, delayed overflow spawn
    // for squads larger than cargo capacity, dynamic infantry behavior, and
    // a 90s post-dismount immortality buffer followed by RTB despawn.
    // ---------------------------------------------------------------------
    case "AIR": {
        [_caller, _dropPos, _playerSide, _isPara, _vehicleClassRaw, _squadSize, _behaviorMode, _rtbTime, _troopClasses, _fnc_parseClass] spawn {
            params ["_caller", "_dropPos", "_playerSide", "_isPara", "_vehicleClassRaw", "_squadSize", "_behaviorMode", "_rtbTime", "_troopClasses", "_fnc_parseClass"];

            // --- SPAWN POSITION (HIGH-ALTITUDE STANDOFF) ---
            private _spawnPos = _dropPos getPos [2500, random 360];
            _spawnPos set [2, 150];
            private _spawnDir = _spawnPos getDir _dropPos;

            // --- VEHICLE SPAWN & LOADOUT ---
            private _vehParsed = [_vehicleClassRaw] call _fnc_parseClass;
            private _vehClass = _vehParsed select 0;
            private _vehLoadout = _vehParsed select 1;

            private _vehData = [_spawnPos, _spawnDir, _vehClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _vehicle = _vehData select 0;
            private _vehGroup = _vehData select 2;

            if (_vehLoadout isNotEqualTo false) then {
                if (_vehLoadout isEqualType []) then { _vehicle setUnitLoadout _vehLoadout; };
                if (_vehLoadout isEqualType "") then { _vehicle call compile _vehLoadout; };
            };

            _vehicle allowDamage false;
            {
                private _crewMember = _x;
                _crewMember allowDamage false;
                _crewMember addRating 100000;
                [_crewMember] joinSilent _vehGroup;
                { _crewMember setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
            } forEach crew _vehicle;

            // --- TROOP SPAWN W/ OVERFLOW QUEUE ---
            private _reinfGroup = createGroup _playerSide;
            private _squad = [];

            // Build the squad class list based on the chosen size (cycles through the 4 roles)
            private _unitToSpawn = [];
            for "_i" from 1 to _squadSize do {
                _unitToSpawn pushBack (_troopClasses select ((_i - 1) mod 4));
            };

            private _maxCargo = _vehicle emptyPositions "cargo";
            private _overflowData = [];
            private _spawnedCount = 0;

            {
                private _unitParsed = [_x] call _fnc_parseClass;
                private _unitClass = _unitParsed select 0;
                private _unitLoadout = _unitParsed select 1;

                if (_spawnedCount < _maxCargo) then {
                    private _unit = _reinfGroup createUnit [_unitClass, _spawnPos, [], 0, "NONE"];
                    if (_unitLoadout isNotEqualTo false) then {
                        if (_unitLoadout isEqualType []) then { _unit setUnitLoadout _unitLoadout; };
                        if (_unitLoadout isEqualType "") then { _unit call compile _unitLoadout; };
                    };

                    // Troops start immortal to survive transit
                    _unit allowDamage false;
                    _unit addRating 100000;
                    [_unit] joinSilent _reinfGroup;
                    _unit setCaptive false;
                    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];

                    _unit moveInCargo _vehicle;
                    _squad pushBack _unit;
                    _spawnedCount = _spawnedCount + 1;
                } else {
                    // Vehicle is full — defer this unit until the LZ
                    _overflowData pushBack [_unitClass, _unitLoadout];
                };
            } forEach _unitToSpawn;

            // Lock cargo so the AI squad leader CANNOT order a dismount mid-transit
            _vehicle lockCargo true;

            // Force the squad itself passive so they don't engage en route
            _reinfGroup setBehaviour "CARELESS";
            _reinfGroup setCombatMode "BLUE";

            // Transport pathing
            _vehGroup setBehaviour "CARELESS";
            _vehGroup setCombatMode "BLUE";

            // Air crew must not engage during transit — full AI lobotomy on combat features
            {
                private _aiFeature = _x;
                { _x disableAI _aiFeature; } forEach (units _vehGroup);
            } forEach ["AUTOTARGET", "TARGET", "SUPPRESSION", "AUTOCOMBAT"];

            if (_isPara) then {
                _vehicle flyInHeight 250;
                private _wpDrop = _vehGroup addWaypoint [_dropPos, 0];
                _wpDrop setWaypointType "MOVE";
                _wpDrop setWaypointSpeed "FULL";
                _wpDrop setWaypointCompletionRadius 100;
            } else {
                private _wpLand = _vehGroup addWaypoint [_dropPos, 0];
                _wpLand setWaypointType "MOVE";
                _wpLand setWaypointSpeed "FULL";
                _wpLand setWaypointStatements ["true", "(vehicle this) land 'LAND';"];
            };

            // --- HELICOPTER TRANSPORT FAILSAFE (heli variants only) ---
            // Detects a hovering/stalled heli (engine on but <5m movement over 45s) and force-despawns it
            if (!_isPara) then {
                [_vehicle, _squad] spawn {
                    params ["_heli", "_squad"];
                    private _lastPos = getPos _heli;
                    private _stuckCount = 0;
                    while {alive _heli} do {
                        sleep 5;
                        if (isEngineOn _heli) then {
                            if ((getPos _heli) distance2D _lastPos < 5) then { _stuckCount = _stuckCount + 5; } else { _stuckCount = 0; };
                        } else {
                            _stuckCount = 0;
                        };
                        if (_stuckCount >= 45) exitWith {
                            { if (!(_x in _squad)) then { deleteVehicle _x; }; } forEach crew _heli;
                            deleteVehicle _heli;
                        };
                        _lastPos = getPos _heli;
                    };
                };
            };

            // --- UNLOAD SEQUENCE ---
            if (_isPara) then {
                // Paradrop: jump from 250m once near the AO, force parachute backpack
                waitUntil { sleep 0.5; (_vehicle distance2D _dropPos) < 300 || !alive _vehicle };
                if (alive _vehicle) then {
                    _vehicle lockCargo false; // Unlock before jump
                    {
                        unassignVehicle _x;
                        moveOut _x;
                        sleep 0.5;

                        // Force a parachute backpack for the jump
                        removeBackpack _x;
                        _x addBackpack "B_Parachute";
                    } forEach _squad;
                };
            } else {
                // Heli landing: wait for skids on the ground, kill engine, open doors
                waitUntil { sleep 0.1; (getPosVisual _vehicle select 2) < 1.5 || !alive _vehicle };
                if (alive _vehicle) then { _vehicle engineOn false; sleep 1; };

                if (alive _vehicle) then {
                    _vehicle lockCargo false; // UNLOCK DOORS so troops can get out
                    {
                        unassignVehicle _x;
                        _x action ["GetOut", _vehicle];
                        sleep 0.8;
                    } forEach _squad;
                };
            };

            // Wait until everyone is out of the vehicle
            waitUntil { sleep 0.5; ({alive _x && _x in _vehicle} count _squad) == 0 || !alive _vehicle };

            // --- DELAYED OVERFLOW SPAWN ---
            // For troops that couldn't fit in the transport — drop them near the LZ on a staggered radius
            if (count _overflowData > 0) then {
                private _spawnCenter = if (alive _vehicle) then { getPosATL _vehicle } else { _dropPos };
                if (_isPara) then { _spawnCenter = _dropPos; _spawnCenter set [2, 0]; };

                {
                    _x params ["_uClass", "_uLoadout"];

                    private _pos = _spawnCenter getPos [5 + random 10, random 360];
                    private _unit = _reinfGroup createUnit [_uClass, _pos, [], 0, "NONE"];

                    if (_uLoadout isNotEqualTo false) then {
                        if (_uLoadout isEqualType []) then { _unit setUnitLoadout _uLoadout; };
                        if (_uLoadout isEqualType "") then { _unit call compile _uLoadout; };
                    };

                    _unit allowDamage false; // Will be made mortal in 90 seconds like the rest
                    _unit addRating 100000;
                    [_unit] joinSilent _reinfGroup;
                    _unit setCaptive false;
                    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];

                    // Push them into the main squad array so they get the immortal removal & RTB despawn
                    _squad pushBack _unit;
                } forEach _overflowData;
            };

            // --- INFANTRY BEHAVIOR ---
            switch (_behaviorMode) do {
                case 0: { // Follow Player (pseudo-group proximity loop)
                    _reinfGroup setCombatMode "YELLOW";
                    _reinfGroup setBehaviour "AWARE";
                    [_reinfGroup, _caller] spawn {
                        params ["_grp", "_plr"];
                        while { ({alive _x} count units _grp) > 0 && alive _plr } do {
                            if ((leader _grp distance2D _plr) > 50) then {
                                _grp move (getPos _plr);
                            };
                            sleep 10;
                        };
                    };
                };
                case 1: { // Join Player
                    _reinfGroup setCombatMode "YELLOW";
                    _reinfGroup setBehaviour "AWARE";
                    _squad joinSilent (group _caller);
                };
                case 2: { // Engage Nearest (Banzai Charge)
                    _reinfGroup setCombatMode "RED";
                    _reinfGroup setBehaviour "COMBAT";
                    private _wpSAD = _reinfGroup addWaypoint [_dropPos, 0];
                    _wpSAD setWaypointType "SAD";
                };
            };

            // --- TRANSPORT EXTRACTION (NO LINGERING — AIRCRAFT LEAVES IMMEDIATELY) ---
            // Air transport stays immortal during extraction; the squad has its own 90s ground-buffer.
            [_vehicle, _vehGroup, _isPara, _spawnPos] spawn {
                params ["_vehicle", "_vehGroup", "_isPara", "_spawnPos"];

                if (alive _vehicle) then {
                    if (!_isPara) then {
                        _vehicle engineOn true;
                    };

                    // Clear landing waypoints and head home
                    while {(count (waypoints _vehGroup)) > 0} do { deleteWaypoint ((waypoints _vehGroup) select 0); };

                    private _wpAway = _vehGroup addWaypoint [_spawnPos, 0];
                    _wpAway setWaypointType "MOVE";
                    _wpAway setWaypointSpeed "FULL";

                    private _timeout = serverTime + 180;
                    waitUntil { sleep 5; (_vehicle distance2D _spawnPos) < 200 || !alive _vehicle || serverTime > _timeout };

                    { deleteVehicle _x } forEach crew _vehicle;
                    deleteVehicle _vehicle;
                };
            };

            // --- TROOP IMMORTALITY BUFFER (90s after feet on the ground) ---
            sleep 90;
            { if (alive _x) then { _x allowDamage true; }; } forEach _squad;

            if (_rtbTime >= 99999 || _rtbTime < 0) exitWith {};
            private _remainingTime = _rtbTime - 90;
            if (_remainingTime > 0) then { sleep _remainingTime; };

            // --- INFANTRY RTB DESPAWN ---
            { if (alive _x) then { deleteVehicle _x; }; } forEach _squad;
        };
    };


    // ---------------------------------------------------------------------
    // CASE C: MECHANIZED INFANTRY
    // ---------------------------------------------------------------------
    // Same spawn logic as ARMOR (roads-first, field fallback), drives troops
    // to the AO under CARELESS+BLUE with the ground watchdog enforcing
    // timeouts and recovering from flips/stuck. On arrival troops dismount
    // via doors, overflow drops near the vehicle, infantry behavior applies,
    // and the transport runs a 2-minute overwatch before extracting home.
    // ---------------------------------------------------------------------
    case "MECH": {
        [_caller, _dropPos, _playerSide, _vehicleClassRaw, _squadSize, _behaviorMode, _rtbTime, _troopClasses, _fnc_parseClass, _fnc_groundWatchdog] spawn {
            params ["_caller", "_dropPos", "_playerSide", "_vehicleClassRaw", "_squadSize", "_behaviorMode", "_rtbTime", "_troopClasses", "_fnc_parseClass", "_fnc_groundWatchdog"];
            scopeName "mechThread";

            // Realistic dispatch delay before convoy moves
            sleep 7;

            // --- SPAWN POSITION (ROADS FIRST, FIELD FALLBACK) ---
            private _spawnPos = [];
            private _spawnDir = 0;

            private _roadsNear = _dropPos nearRoads 500;
            if (count _roadsNear > 0) then {
                private _road = _roadsNear select 0;
                _spawnPos = getPos _road;
                private _roadConnectedTo = roadsConnectedTo _road;
                if (count _roadConnectedTo > 0) then {
                    _spawnDir = _road getDir (_roadConnectedTo select 0);
                } else {
                    _spawnDir = _spawnPos getDir _dropPos;
                };
            } else {
                private _enemies = (_dropPos nearEntities [["Man"], 500]) select { _playerSide getFriend (side _x) < 0.6 };
                if (count _enemies > 0) then {
                    private _closestEnemy = _enemies select 0;
                    private _enemyDir = _dropPos getDir _closestEnemy;
                    private _safeDir = _enemyDir + 180 + (random 60 - 30);
                    _spawnPos = _dropPos getPos [350, _safeDir];
                } else {
                    _spawnPos = _dropPos getPos [350, random 360];
                };

                private _safePos = [_spawnPos, 0, 150, 5, 0, 0.25, 0] call BIS_fnc_findSafePos;
                if (count _safePos > 1) then { _spawnPos = _safePos; };
                _spawnDir = _spawnPos getDir _dropPos;
            };

            // --- VEHICLE SPAWN & LOADOUT ---
            private _vehParsed = [_vehicleClassRaw] call _fnc_parseClass;
            private _vehClass = _vehParsed select 0;
            private _vehLoadout = _vehParsed select 1;

            private _vehData = [_spawnPos, _spawnDir, _vehClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _vehicle = _vehData select 0;
            private _vehGroup = _vehData select 2;

            if (_vehLoadout isNotEqualTo false) then {
                if (_vehLoadout isEqualType []) then { _vehicle setUnitLoadout _vehLoadout; };
                if (_vehLoadout isEqualType "") then { _vehicle call compile _vehLoadout; };
            };

            _vehicle allowDamage false;
            {
                private _crewMember = _x;
                _crewMember allowDamage false;
                _crewMember addRating 100000;
                [_crewMember] joinSilent _vehGroup;
                { _crewMember setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
            } forEach crew _vehicle;

            // --- TROOP SPAWN W/ OVERFLOW QUEUE ---
            private _reinfGroup = createGroup _playerSide;
            private _squad = [];

            private _unitToSpawn = [];
            for "_i" from 1 to _squadSize do {
                _unitToSpawn pushBack (_troopClasses select ((_i - 1) mod 4));
            };

            private _maxCargo = _vehicle emptyPositions "cargo";
            private _overflowData = [];
            private _spawnedCount = 0;

            {
                private _unitParsed = [_x] call _fnc_parseClass;
                private _unitClass = _unitParsed select 0;
                private _unitLoadout = _unitParsed select 1;

                if (_spawnedCount < _maxCargo) then {
                    private _unit = _reinfGroup createUnit [_unitClass, _spawnPos, [], 0, "NONE"];
                    if (_unitLoadout isNotEqualTo false) then {
                        if (_unitLoadout isEqualType []) then { _unit setUnitLoadout _unitLoadout; };
                        if (_unitLoadout isEqualType "") then { _unit call compile _unitLoadout; };
                    };

                    _unit allowDamage false;
                    _unit addRating 100000;
                    [_unit] joinSilent _reinfGroup;
                    _unit setCaptive false;
                    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];

                    _unit moveInCargo _vehicle;
                    _squad pushBack _unit;
                    _spawnedCount = _spawnedCount + 1;
                } else {
                    _overflowData pushBack [_unitClass, _unitLoadout];
                };
            } forEach _unitToSpawn;

            // Lock cargo so the AI squad leader CANNOT order a dismount mid-transit
            _vehicle lockCargo true;

            // Force the squad itself passive so they don't engage en route
            _reinfGroup setBehaviour "CARELESS";
            _reinfGroup setCombatMode "BLUE";

            // Transport pathing
            _vehGroup setBehaviour "CARELESS";
            _vehGroup setCombatMode "BLUE";

            private _wpLand = _vehGroup addWaypoint [_dropPos, 0];
            _wpLand setWaypointType "MOVE";
            _wpLand setWaypointSpeed "FULL";
            _wpLand setWaypointCompletionRadius 50;

            // Watchdog: 200s transit timeout, 55m arrival radius. Immobilized vehicles
            // (canMove false) are treated as ARRIVED so troops dismount on the spot
            // rather than getting deleted along with a broken truck.
            private _transitResult = [_vehicle, _dropPos, 55, 200] call _fnc_groundWatchdog;

            if (_transitResult == "TIMEOUT") then {
                diag_log format ["[AAS Reinf] Mech reinforcement timed out, despawning %1 with %2 troops", typeOf _vehicle, count _squad];
                // Despawn full reinforcement: troops aboard + crew + vehicle
                { deleteVehicle _x } forEach _squad;
                { deleteVehicle _x } forEach crew _vehicle;
                deleteVehicle _vehicle;
                breakOut "mechThread";
            };

            // --- UNLOAD SEQUENCE ---
            if (alive _vehicle) then {
                // Force the AI driver to hit the brakes immediately
                while {(count (waypoints _vehGroup)) > 0} do { deleteWaypoint ((waypoints _vehGroup) select 0); };
                doStop _vehicle;

                _vehicle lockCargo false; // UNLOCK DOORS so troops can get out
                {
                    unassignVehicle _x;
                    _x action ["GetOut", _vehicle];
                    sleep 0.8;
                } forEach _squad;
            };

            // Wait until everyone is out of the vehicle
            waitUntil { sleep 0.5; ({alive _x && _x in _vehicle} count _squad) == 0 || !alive _vehicle };

            // --- DELAYED OVERFLOW SPAWN ---
            if (count _overflowData > 0) then {
                private _spawnCenter = if (alive _vehicle) then { getPosATL _vehicle } else { _dropPos };

                {
                    _x params ["_uClass", "_uLoadout"];

                    private _pos = _spawnCenter getPos [5 + random 10, random 360];
                    private _unit = _reinfGroup createUnit [_uClass, _pos, [], 0, "NONE"];

                    if (_uLoadout isNotEqualTo false) then {
                        if (_uLoadout isEqualType []) then { _unit setUnitLoadout _uLoadout; };
                        if (_uLoadout isEqualType "") then { _unit call compile _uLoadout; };
                    };

                    _unit allowDamage false;
                    _unit addRating 100000;
                    [_unit] joinSilent _reinfGroup;
                    _unit setCaptive false;
                    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];

                    _squad pushBack _unit;
                } forEach _overflowData;
            };

            // --- INFANTRY BEHAVIOR ---
            switch (_behaviorMode) do {
                case 0: { // Follow Player (pseudo-group proximity loop)
                    _reinfGroup setCombatMode "YELLOW";
                    _reinfGroup setBehaviour "AWARE";
                    [_reinfGroup, _caller] spawn {
                        params ["_grp", "_plr"];
                        while { ({alive _x} count units _grp) > 0 && alive _plr } do {
                            if ((leader _grp distance2D _plr) > 50) then {
                                _grp move (getPos _plr);
                            };
                            sleep 10;
                        };
                    };
                };
                case 1: { // Join Player
                    _reinfGroup setCombatMode "YELLOW";
                    _reinfGroup setBehaviour "AWARE";
                    _squad joinSilent (group _caller);
                };
                case 2: { // Engage Nearest (Banzai Charge)
                    _reinfGroup setCombatMode "RED";
                    _reinfGroup setBehaviour "COMBAT";
                    private _wpSAD = _reinfGroup addWaypoint [_dropPos, 0];
                    _wpSAD setWaypointType "SAD";
                };
            };

            // --- TRANSPORT EXTRACTION (2-MIN OVERWATCH, THEN RTB) ---
            // Transport stays in COMBAT/RED for 2 minutes to provide turret cover for
            // the dismounted squad, then disengages, restores mortality, and drives home.
            [_vehicle, _vehGroup, _spawnPos] spawn {
                params ["_vehicle", "_vehGroup", "_spawnPos"];

                if (alive _vehicle) then {
                    // 2-minute overwatch — transport uses its turret to cover troops
                    _vehGroup setCombatMode "RED";
                    _vehGroup setBehaviour "COMBAT";
                    sleep 120;

                    if (alive _vehicle) then {
                        // Clear combat waypoints and force RTB
                        while {(count (waypoints _vehGroup)) > 0} do { deleteWaypoint ((waypoints _vehGroup) select 0); };

                        private _wpAway = _vehGroup addWaypoint [_spawnPos, 0];
                        _wpAway setWaypointType "MOVE";
                        _wpAway setWaypointSpeed "FULL";

                        // Disengage and restore mortality as the transport leaves the AO
                        _vehGroup setBehaviour "CARELESS";
                        _vehGroup setCombatMode "BLUE";
                        _vehicle allowDamage true;
                        { _x allowDamage true; } forEach crew _vehicle;

                        private _timeout = serverTime + 180;
                        waitUntil { sleep 5; (_vehicle distance2D _spawnPos) < 200 || !alive _vehicle || serverTime > _timeout };

                        { deleteVehicle _x } forEach crew _vehicle;
                        deleteVehicle _vehicle;
                    };
                };
            };

            // --- TROOP IMMORTALITY BUFFER (90s after feet on the ground) ---
            sleep 90;
            { if (alive _x) then { _x allowDamage true; }; } forEach _squad;

            if (_rtbTime >= 99999 || _rtbTime < 0) exitWith {};
            private _remainingTime = _rtbTime - 90;
            if (_remainingTime > 0) then { sleep _remainingTime; };

            // --- INFANTRY RTB DESPAWN ---
            { if (alive _x) then { deleteVehicle _x; }; } forEach _squad;
        };
    };
};
