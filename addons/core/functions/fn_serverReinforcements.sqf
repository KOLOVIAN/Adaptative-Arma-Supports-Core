// functions/fn_serverReinforcements.sqf

// We keep the 3rd parameter to absorb the remoteExec payload
params ["_caller", "_dropPos", "_ignoredZeus", ["_reinfType", "AIR_4"]];

private _playerSide = side group _caller;

// --- 0. DYNAMIC VARIABLE ASSIGNMENT ---
private _isArmor = false;
private _isAir = false;
private _isMech = false;
private _isPara = false;
private _vehicleClassRaw = "";
private _squadSize = 0;
private _costMultStr = "1.0";
private _behaviorMode = 0;
private _rtbTimeStr = "300";
private _cooldownTimeStr = "600";
private _troopClasses = [];
private _lastUseVar = "AAS_Reinf_LastUseTime";

switch (_reinfType) do {
    // --- ARMOR ---
    case "ARMOR_TURRET": {
        _isArmor = true; _vehicleClassRaw = AAS_Reinf_Armor_Turret; _costMultStr = AAS_Reinf_Armor_CostMult_Turret; 
        _rtbTimeStr = AAS_RTB_Reinf_Armor; _cooldownTimeStr = AAS_Cooldown_Reinf_Armor; _behaviorMode = AAS_Behavior_Armor;
        _lastUseVar = "AAS_Reinf_Armor_LastUseTime";
    };
    case "ARMOR_APC": {
        _isArmor = true; _vehicleClassRaw = AAS_Reinf_Armor_APC; _costMultStr = AAS_Reinf_Armor_CostMult_APC; 
        _rtbTimeStr = AAS_RTB_Reinf_Armor; _cooldownTimeStr = AAS_Cooldown_Reinf_Armor; _behaviorMode = AAS_Behavior_Armor;
        _lastUseVar = "AAS_Reinf_Armor_LastUseTime";
    };
    case "ARMOR_TANK": {
        _isArmor = true; _vehicleClassRaw = AAS_Reinf_Armor_Tank; _costMultStr = AAS_Reinf_Armor_CostMult_Tank; 
        _rtbTimeStr = AAS_RTB_Reinf_Armor; _cooldownTimeStr = AAS_Cooldown_Reinf_Armor; _behaviorMode = AAS_Behavior_Armor;
        _lastUseVar = "AAS_Reinf_Armor_LastUseTime";
    };
    // --- AIRBORNE INFANTRY ---
    case "AIR_4": {
        _isAir = true; _vehicleClassRaw = AAS_Reinf_Air_LightHeli; _squadSize = 4; _costMultStr = AAS_Reinf_Air_CostMult_4; 
        _rtbTimeStr = AAS_RTB_Reinf_Air; _cooldownTimeStr = AAS_Cooldown_Reinf_Air; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Air_SL, AAS_Reinf_Air_Sniper, AAS_Reinf_Air_AT, AAS_Reinf_Air_AR];
        _lastUseVar = "AAS_Reinf_Air_LastUseTime";
    };
    case "AIR_8": {
        _isAir = true; _vehicleClassRaw = AAS_Reinf_Air_StdHeli; _squadSize = 8; _costMultStr = AAS_Reinf_Air_CostMult_8; 
        _rtbTimeStr = AAS_RTB_Reinf_Air; _cooldownTimeStr = AAS_Cooldown_Reinf_Air; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Air_SL, AAS_Reinf_Air_Sniper, AAS_Reinf_Air_AT, AAS_Reinf_Air_AR];
        _lastUseVar = "AAS_Reinf_Air_LastUseTime";
    };
    case "AIR_12": {
        _isAir = true; _isPara = true; _vehicleClassRaw = AAS_Reinf_Air_Plane; _squadSize = 12; _costMultStr = AAS_Reinf_Air_CostMult_12; 
        _rtbTimeStr = AAS_RTB_Reinf_Air; _cooldownTimeStr = AAS_Cooldown_Reinf_Air; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Air_SL, AAS_Reinf_Air_Sniper, AAS_Reinf_Air_AT, AAS_Reinf_Air_AR];
        _lastUseVar = "AAS_Reinf_Air_LastUseTime";
    };
    // --- MECHANIZED INFANTRY ---
    case "MECH_4": {
        _isMech = true; _vehicleClassRaw = AAS_Reinf_Ground_MRAP; _squadSize = 4; _costMultStr = AAS_Reinf_Ground_CostMult_4; 
        _rtbTimeStr = AAS_RTB_Reinf_Ground; _cooldownTimeStr = AAS_Cooldown_Reinf_Ground; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Ground_SL, AAS_Reinf_Ground_Sniper, AAS_Reinf_Ground_AT, AAS_Reinf_Ground_AR];
        _lastUseVar = "AAS_Reinf_Ground_LastUseTime";
    };
    case "MECH_8": {
        _isMech = true; _vehicleClassRaw = AAS_Reinf_Ground_APC; _squadSize = 8; _costMultStr = AAS_Reinf_Ground_CostMult_8; 
        _rtbTimeStr = AAS_RTB_Reinf_Ground; _cooldownTimeStr = AAS_Cooldown_Reinf_Ground; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Ground_SL, AAS_Reinf_Ground_Sniper, AAS_Reinf_Ground_AT, AAS_Reinf_Ground_AR];
        _lastUseVar = "AAS_Reinf_Ground_LastUseTime";
    };
    case "MECH_12": {
        _isMech = true; _vehicleClassRaw = AAS_Reinf_Ground_Truck; _squadSize = 12; _costMultStr = AAS_Reinf_Ground_CostMult_12; 
        _rtbTimeStr = AAS_RTB_Reinf_Ground; _cooldownTimeStr = AAS_Cooldown_Reinf_Ground; _behaviorMode = AAS_Behavior_Infantry;
        _troopClasses = [AAS_Reinf_Ground_SL, AAS_Reinf_Ground_Sniper, AAS_Reinf_Ground_AT, AAS_Reinf_Ground_AR];
        _lastUseVar = "AAS_Reinf_Ground_LastUseTime";
    };
};

private _cooldownTime = parseNumber _cooldownTimeStr;
private _rtbTime = parseNumber _rtbTimeStr;

// --- 1. COOLDOWN CHECK ---
private _lastUse = missionNamespace getVariable [_lastUseVar, -99999];

if (serverTime < (_lastUse + _cooldownTime)) exitWith {
    private _timeLeft = round(((_lastUse + _cooldownTime) - serverTime) / 60);
    (format ["HQ: Reinforcements on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// --- 2. DYNAMIC ECONOMY CHECK ---
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

private _econPass = [_caller, _finalCost, AAS_Econ_Preset_Core, AAS_Econ_Code_Reinf] call AAS_fnc_setEconomyPreset;
if (!_econPass) exitWith {};

// --- 3. FINALIZE SUPPORT ---
missionNamespace setVariable [_lastUseVar, serverTime, true];

// Backwards compatibility sync for initCLIENT.sqf menu hider
missionNamespace setVariable ["AAS_Reinf_LastUseTime", serverTime, true]; 

// ==========================================
// --- RANDOMIZED VOICELINES INTEGRATION ---
// ==========================================
if (_isArmor) then {
    private _armorComms = [
        ["HQ: Copy that ground team. Armor on the way to your position, over.", "AAS_Voice_Armor1"],
        ["HQ: Armor is half a click from your position. ETA 1 minute, over.", "AAS_Voice_Armor2"]
    ];
    private _selectedComm = selectRandom _armorComms;
    
    (_selectedComm select 0) remoteExec ["systemChat", _caller];
    (_selectedComm select 1) remoteExec ["playSound", _caller];
} else {
    // This fires for both Airborne (_isAir) and Mechanized Infantry (_isMech)
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
// --- 4. EXECUTION THREAD ---
// =========================================================================
[_caller, _dropPos, _playerSide, _isArmor, _isAir, _isMech, _isPara, _vehicleClassRaw, _squadSize, _behaviorMode, _rtbTime, _troopClasses, _fnc_parseClass] spawn {
    params ["_caller", "_dropPos", "_playerSide", "_isArmor", "_isAir", "_isMech", "_isPara", "_vehicleClassRaw", "_squadSize", "_behaviorMode", "_rtbTime", "_troopClasses", "_fnc_parseClass"];

    // Realistic 30 Seconds Delay for Ground forces
    if (_isArmor || _isMech) then { sleep 7; };

    private _spawnPos = [];
    private _spawnDir = 0;

    // --- UPGRADED SPAWN & PATHING LOGIC ---
    if (_isArmor || _isMech) then {
        // Prioritize roads up to 500m away
        private _roadsNear = _dropPos nearRoads 500;
        
        if (count _roadsNear > 0) then {
            // Found a road - spawn exactly on it and face it down the path
            private _road = _roadsNear select 0;
            _spawnPos = getPos _road;
            private _roadConnectedTo = roadsConnectedTo _road;
            if (count _roadConnectedTo > 0) then {
                _spawnDir = _road getDir (_roadConnectedTo select 0);
            } else {
                _spawnDir = _spawnPos getDir _dropPos;
            };
        } else {
            // No roads within 500m - Spawn 350m away in the field, actively avoiding known enemies
            private _enemies = (_dropPos nearEntities [["Man"], 500]) select { _playerSide getFriend (side _x) < 0.6 };
            if (count _enemies > 0) then {
                // Find a heading away from the closest enemy
                private _closestEnemy = _enemies select 0;
                private _enemyDir = _dropPos getDir _closestEnemy;
                private _safeDir = _enemyDir + 180 + (random 60 - 30); // Opposite direction with a bit of randomness
                _spawnPos = _dropPos getPos [350, _safeDir];
            } else {
                // No enemies, random 350m spawn
                _spawnPos = _dropPos getPos [350, random 360];
            };
            
            // Failsafe check so we don't spawn inside a rock
            private _safePos = [_spawnPos, 0, 150, 5, 0, 0.25, 0] call BIS_fnc_findSafePos;
            if (count _safePos > 1) then { _spawnPos = _safePos; };
            _spawnDir = _spawnPos getDir _dropPos;
        };
    } else {
        // Airborne logic remains the same (high altitude)
        _spawnPos = _dropPos getPos [2500, random 360];
        _spawnPos set [2, 150];
        _spawnDir = _spawnPos getDir _dropPos;
    };

    // Parse Vehicle Class & Loadout safely
    private _vehParsed = [_vehicleClassRaw] call _fnc_parseClass;
    private _vehClass = _vehParsed select 0;
    private _vehLoadout = _vehParsed select 1;

    private _vehData = [_spawnPos, _spawnDir, _vehClass, _playerSide] call BIS_fnc_spawnVehicle;
    private _vehicle = _vehData select 0;
    private _vehGroup = _vehData select 2;

    // Apply Custom Loadout if provided
    if (_vehLoadout isNotEqualTo false) then {
        if (_vehLoadout isEqualType []) then { _vehicle setUnitLoadout _vehLoadout; };
        if (_vehLoadout isEqualType "") then { _vehicle call compile _vehLoadout; };
    };

    // Apply strict immortality to vehicle and crew for transit
    _vehicle allowDamage false;
    
    // [FIX 1] Fixed the nested _x override issue by declaring _crewMember
    { 
        private _crewMember = _x;
        _crewMember allowDamage false; 
        _crewMember addRating 100000; 
        [_crewMember] joinSilent _vehGroup; 
        
        // Maximize AI skills
        { _crewMember setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
    } forEach crew _vehicle;

    // ==========================================
    // --- PATH A: ARMOR EXECUTION
    // ==========================================
    if (_isArmor) then {
        
        // Ignore enemies during transit so they don't get distracted
        _vehGroup setBehaviour "CARELESS";
        _vehGroup setCombatMode "BLUE";
        
        private _wpLand = _vehGroup addWaypoint [_dropPos, 0];
        _wpLand setWaypointType "MOVE";
        _wpLand setWaypointSpeed "FULL";
        _wpLand setWaypointCompletionRadius 50;

        // Wait until arrived or destroyed
        waitUntil { sleep 1; (_vehicle distance2D _dropPos) < 100 || !alive _vehicle };
        
        if (!alive _vehicle) exitWith {};

        // 120s Immortality Buff
        [_vehicle] spawn {
            params ["_veh"];
            sleep 120;
            if (alive _veh) then {
                _veh allowDamage true;
                { if (alive _x) then { _x allowDamage true; }; } forEach crew _veh;
            };
        };

        // Apply specific Armor Behavior
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

        // Despawn Logic
        [_vehicle, _vehGroup, _spawnPos, _rtbTime] spawn {
            params ["_vehicle", "_vehGroup", "_spawnPos", "_rtbTime"];
            if (_rtbTime >= 99999 || _rtbTime < 0) exitWith {};
            sleep _rtbTime;
            
            if (alive _vehicle) then {
                // Remove from player group if joined previously
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
    } 
    // ==========================================
    // --- PATH B: INFANTRY (AIR & MECH) EXECUTION
    // ==========================================
    else {
        
        private _reinfGroup = createGroup _playerSide;
        private _squad = [];

        // Build the squad class list based on the chosen size
        private _unitToSpawn = [];
        for "_i" from 1 to _squadSize do {
            _unitToSpawn pushBack (_troopClasses select ((_i - 1) mod 4));
        };

        {
            private _unitParsed = [_x] call _fnc_parseClass;
            private _unitClass = _unitParsed select 0;
            private _unitLoadout = _unitParsed select 1;

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

            // Infantry uses _unit instead of _x, so it doesn't conflict with the skill string array
            { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];

            _unit moveInCargo _vehicle;
            _squad pushBack _unit;
        } forEach _unitToSpawn;

        // Transport Pathing
        _vehGroup setBehaviour "CARELESS"; 
        _vehGroup setCombatMode "BLUE";
        
        // [FIX 2] disableAI expects an Object (Unit), not a Group. 
        if (_isAir) then {
            {
                private _aiFeature = _x;
                { _x disableAI _aiFeature; } forEach (units _vehGroup);
            } forEach ["AUTOTARGET", "TARGET", "SUPPRESSION", "AUTOCOMBAT"];
        };

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
            if (_isAir) then {
                _wpLand setWaypointStatements ["true", "(vehicle this) land 'LAND';"];
            } else {
                _wpLand setWaypointCompletionRadius 50; // Ensure completion radius aligns with the 50m wait check
            };
        };

        // --- HELICOPTER TRANSPORT FAILSAFE ---
        if (_isAir && !_isPara) then {
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

        // --- UNLOAD & EXTRACT THREAD ---
        [_vehicle, _vehGroup, _reinfGroup, _squad, _spawnPos, _dropPos, _caller, _rtbTime, _behaviorMode, _isPara, _isAir] spawn {
            params ["_vehicle", "_vehGroup", "_reinfGroup", "_squad", "_spawnPos", "_dropPos", "_caller", "_rtbTime", "_behaviorMode", "_isPara", "_isAir"];

            // 1. Unloading Sequence
            if (_isPara) then {
                waitUntil { sleep 0.5; (_vehicle distance2D _dropPos) < 300 || !alive _vehicle };
                if (alive _vehicle) then {
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
                if (_isAir) then {
                    waitUntil { sleep 0.1; (getPosVisual _vehicle select 2) < 1.5 || !alive _vehicle };
                    if (alive _vehicle) then { _vehicle engineOn false; sleep 1; };
                } else {
                    // GROUND TRANSPORT HALT LOGIC:
                    // Wait strictly until it hits the 55m radius (5m buffer) or is immobilized.
                    // Removed 'speed == 0' so it doesn't dismount randomly when dodging a tree.
                    waitUntil { sleep 1; (_vehicle distance2D _dropPos) <= 55 || !alive _vehicle || !canMove _vehicle };
                    
                    if (alive _vehicle) then {
                        // Force the AI driver to hit the brakes immediately
                        while {(count (waypoints _vehGroup)) > 0} do { deleteWaypoint ((waypoints _vehGroup) select 0); };
                        doStop _vehicle; 
                    };
                };

                if (alive _vehicle) then {
                    {
                        unassignVehicle _x;
                        _x action ["GetOut", _vehicle]; 
                        sleep 0.8; 
                    } forEach _squad;
                };
            };

            // Wait until everyone is out of the vehicle
            waitUntil { sleep 0.5; ({alive _x && _x in _vehicle} count _squad) == 0 || !alive _vehicle };

            // 2. Dynamic Infantry Behavior
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

            // 3. Transport Extraction & Lingering
            [_vehicle, _vehGroup, _isAir, _isPara, _spawnPos] spawn {
                params ["_vehicle", "_vehGroup", "_isAir", "_isPara", "_spawnPos"];
                
                if (alive _vehicle) then {
                    if (_isAir && !_isPara) then { 
                        _vehicle engineOn true; 
                    };
                    
                    if (!_isAir) then {
                        // Activate 2-minute Overwatch mode for Ground Vehicles (Uses turrets to cover troops)
                        _vehGroup setCombatMode "RED";
                        _vehGroup setBehaviour "COMBAT";
                        sleep 120;
                    };

                    if (alive _vehicle) then {
                        // Clear any combat waypoints and force RTB
                        while {(count (waypoints _vehGroup)) > 0} do { deleteWaypoint ((waypoints _vehGroup) select 0); };
                        
                        private _wpAway = _vehGroup addWaypoint [_spawnPos, 0];
                        _wpAway setWaypointType "MOVE";
                        _wpAway setWaypointSpeed "FULL";
                        
                        if (!_isAir) then {
                            // Turn off combat mode so it ignores enemies and drives away
                            _vehGroup setBehaviour "CARELESS";
                            _vehGroup setCombatMode "BLUE";
                            
                            // Restore vehicle mortality as it leaves the AO
                            _vehicle allowDamage true;
                            { _x allowDamage true; } forEach crew _vehicle;
                        };

                        private _timeout = serverTime + 180;
                        waitUntil { sleep 5; (_vehicle distance2D _spawnPos) < 200 || !alive _vehicle || serverTime > _timeout };
                        
                        { deleteVehicle _x } forEach crew _vehicle;
                        deleteVehicle _vehicle;
                    };
                };
            };

            // 4. Infantry Immortality Buffer (Exactly 90 seconds after feet on the ground)
            sleep 90;
            { if (alive _x) then { _x allowDamage true; }; } forEach _squad;

            if (_rtbTime >= 99999 || _rtbTime < 0) exitWith {};
            private _remainingTime = _rtbTime - 90;
            if (_remainingTime > 0) then { sleep _remainingTime; };

            // 5. Infantry RTB Despawn Failsafe
            { if (alive _x) then { deleteVehicle _x; }; } forEach _squad;
        };
    };
};