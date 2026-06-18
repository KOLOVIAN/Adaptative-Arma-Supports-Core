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
    // CASE A: PLANE (DUAL-CONE 3D ALIGNMENT & PHANTOM RESTORED)
    // ---------------------------------------------------------------------
    case "PLANE": {
        private _airClassRaw = AAS_CAS_Plane_Class;
        private _behaviorMode = 1;
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
        _aircraft setVelocityModelSpace [0, 150, 0]; 

        // Apply Loadouts & Protection
        if (_customLoadout isNotEqualTo false) then {
            if (_customLoadout isEqualType []) then { _aircraft setUnitLoadout _customLoadout; };
            if (_customLoadout isEqualType "") then { _aircraft call compile _customLoadout; };
        };
        _aircraft allowDamage false; 
        _aircraft flyInHeight _flightHeight;

        // =================================================================
        // --- 1. DYNAMIC WEAPON CLASSIFICATION ---
        // =================================================================
        private _cannonWep = "";
        private _missileWeps = [];
        
        {
            private _wName = toLower _x;
            if (!("laser" in _wName) && !("flare" in _wName) && !("smoke" in _wName) && !("horn" in _wName)) then {
                private _ammoCount = _aircraft ammo _x;
                // Treat weapons with massive ammo pools as the primary cannon
                if (_ammoCount > 300) then {
                    if (_cannonWep == "") then { _cannonWep = _x; };
                } else {
                    // Collect ALL other valid weapons as missiles/rockets
                    _missileWeps pushBack _x; 
                };
            };
        } forEach (weapons _aircraft);

        _aircraft setVariable ["AAS_Plane_Cannon", _cannonWep];
        _aircraft setVariable ["AAS_Plane_Missiles", _missileWeps];
        _aircraft setVariable ["AAS_LastFireTime", serverTime];

        // =================================================================
        // --- 2. ACTIVE HOMING & PERIODIC AMMO REPLENISHMENT ---
        // =================================================================
        
        // 35-Second Ammo Replenish Thread (FIXED)
        [_aircraft] spawn {
            params ["_aircraft"];
            while {alive _aircraft} do {
                sleep 45;
                _aircraft setVehicleAmmo 1;
            };
        };

        // Fired Event Handler (Time Tracking & Missile Guidance ONLY)
        _aircraft addEventHandler ["Fired", {
            params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
            
            _unit setVariable ["AAS_LastFireTime", serverTime];

            private _missiles = _unit getVariable ["AAS_Plane_Missiles", []];
            private _target = _unit getVariable ["AAS_Plane_Target", objNull];

            // If it's any missile/rocket, forcefully guide it to the target
            if (_weapon in _missiles && !isNull _target && {alive _target}) then {
                [_projectile, _target] spawn {
                    params ["_proj", "_tgt"];
                    sleep 0.1; // Let it clear the wings
                    
                    // Native lock if engine allows
                    _proj setMissileTarget _tgt;
                    
                    // Physical vector steering loop (Mod Agnostic)
                    while {alive _proj && alive _tgt} do {
                        private _posP = getPosASL _proj;
                        private _posT = getPosASL _tgt;
                        _posT set [2, (_posT select 2) + 1]; // Aim for center of mass
                        
                        private _dir = vectorNormalized (_posT vectorDiff _posP);
                        private _speed = vectorMagnitude (velocity _proj);
                        
                        _proj setVectorDir _dir;
                        _proj setVelocity (_dir vectorMultiply (_speed max 150));
                        
                        sleep 0.05;
                    };
                };
            };
        }];

        // Crew setup
        { 
            private _unit = _x;
            _unit allowDamage false; 
            _unit addRating 100000; 
            [_unit] joinSilent _airGroup;
            { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
        } forEach crew _aircraft;

        // Waypoints & Behavior
        private _wpAttack = _airGroup addWaypoint [_dropPos, 0];
        _wpAttack setWaypointType "SAD";
        _wpAttack setWaypointSpeed "NORMAL";
        _airGroup setCombatMode "RED"; 
        _airGroup setBehaviour "AWARE"; 

        // =================================================================
        // --- 3. RADAR & PHANTOM FALLBACK THREAD (5s TICK) ---
        // =================================================================
        [_aircraft, _airGroup, _dropPos] spawn {
            params ["_aircraft", "_airGroup", "_dropPos"];
            private _scanRadius = 800;
            private _friendlySide = side _airGroup;
            private _phantoms = [];
            private _noVehTime = 0; // Tracks consecutive seconds without vehicles

            while {alive _aircraft} do {
                sleep 5;
                if (behaviour driver _aircraft == "CARELESS") exitWith {};

                private _pilot = driver _aircraft;
                private _lastFireTime = _aircraft getVariable ["AAS_LastFireTime", serverTime];
                private _timeSinceFire = serverTime - _lastFireTime;
                
                // EXCLUDE PHANTOMS FROM VEHICLE SCAN (FIXED)
                private _vehicles = (_dropPos nearEntities [["LandVehicle", "Ship"], _scanRadius]) select {
                    alive _x && { _friendlySide getFriend (side _x) < 0.6 } && { !(_x in _phantoms) }
                };

                private _target = objNull;
                private _useFallback = false;

                if (count _vehicles > 0) then {
                    _noVehTime = 0; 
                    _target = _vehicles select 0;
                    { if (_x distance2D _dropPos < _target distance2D _dropPos) then { _target = _x; }; } forEach _vehicles;
                } else {
                    _noVehTime = _noVehTime + 5;
                };

                // Triggers: No vehicles for 30s OR no firing for 60s
                if (_noVehTime >= 30 || _timeSinceFire >= 60) then { _useFallback = true; };

                if (_useFallback && isNull _target) then {
                    private _infantry = (_dropPos nearEntities [["Man"], _scanRadius]) select {
                        alive _x && { _friendlySide getFriend (side _x) < 0.6 }
                    };

                    if (count _infantry > 0) then {
                        private _infTarget = _infantry select 0;
                        { if (_x distance2D _dropPos < _infTarget distance2D _dropPos) then { _infTarget = _x; }; } forEach _infantry;

                        // Create or Move the buried Ifrit
                        private _phantomPosASL = (getPosASL _infTarget) vectorAdd [0, 0, -1.8];
                        if (count _phantoms == 0 || {isNull (_phantoms select 0)}) then {
                            private _p = createVehicle ["O_MRAP_02_F", _infTarget, [], 0, "CAN_COLLIDE"];
                            _p allowDamage false; _p engineOn false; _p hideObjectGlobal true;
                            _p setPosASL _phantomPosASL;
                            [_p] joinSilent (group _infTarget); createVehicleCrew _p;
                            { _x allowDamage false; _x hideObjectGlobal true; } forEach crew _p;
                            _phantoms set [0, _p];
                        } else {
                            // Continuously shift to the next living target!
                            (_phantoms select 0) setPosASL _phantomPosASL;
                        };
                        _target = _phantoms select 0; 
                    } else {
                        { if (!isNull _x) then { { deleteVehicle _x } forEach crew _x; deleteVehicle _x; }; } forEach _phantoms;
                        _phantoms = [];
                    };
                };

                _aircraft setVariable ["AAS_Plane_Target", _target];

                if (!isNull _target) then {
                    _airGroup reveal [_target, 4];
                    _pilot doTarget _target;
                };
            };

            { if (!isNull _x) then { { deleteVehicle _x } forEach crew _x; deleteVehicle _x; }; } forEach _phantoms;
        };

        // =================================================================
        // --- 4. 3D ALIGNMENT & DUAL-TOLERANCE TRIGGER (0.1s TICK) ---
        // =================================================================
        [_aircraft] spawn {
            params ["_aircraft"];

            // Helper function to dynamically find the correct fire mode for ANY weapon
            private _fnc_getFireMode = {
                params ["_weaponClass"];
                private _modes = getArray (configFile >> "CfgWeapons" >> _weaponClass >> "modes");
                private _mode = _weaponClass; // Default to classname
                if (count _modes > 0) then {
                    _mode = _modes select 0;
                    if (_mode == "this") then { _mode = _weaponClass; };
                };
                _mode
            };

            while {alive _aircraft} do {
                sleep 0.1;
                if (behaviour driver _aircraft == "CARELESS") exitWith {};

                private _target = _aircraft getVariable ["AAS_Plane_Target", objNull];
                
                if (!isNull _target && {alive _target}) then {
                    private _dist = _aircraft distance _target;
                    
                    // Engagement Window: Under 3000m, above 100m
                    if (_dist < 3000 && _dist > 100) then {
                        
                        // 3D Alignment Math
                        private _vDir = vectorDir _aircraft; 
                        private _vToTgt = vectorNormalized ((getPosASL _target) vectorDiff (getPosASL _aircraft));
                        private _dot = _vDir vectorDotProduct _vToTgt;
                        
                        // -----------------------------------------------------
                        // 10-DEGREE CONE (BOMBS, MISSILES, ROCKETS) -> Cos(10) = ~0.984
                        // -----------------------------------------------------
                        if (_dot >= 0.984 && !(_aircraft getVariable ["AAS_Missiles_Cooldown", false])) then {
                            _aircraft setVariable ["AAS_Missiles_Cooldown", true];
                            
                            [_aircraft, _target, _fnc_getFireMode] spawn {
                                params ["_plane", "_tgt", "_fnc_getFireMode"];
                                private _weps = _plane getVariable ["AAS_Plane_Missiles", []];
                                
                                {
                                    private _weap = _x;
                                    private _mode = [_weap] call _fnc_getFireMode;

                                    // Fire 2 times instead of 4 (FIXED)
                                    for "_j" from 1 to 1 do {
                                        if (!alive _plane || !alive _tgt) exitWith {};
                                        // Tell the AI to focus, then physically force the trigger
                                        _plane fireAtTarget [_tgt, _weap];
                                        _plane forceWeaponFire [_weap, _mode];
                                        sleep 0.3; // Slight delay for cinematic ripple
                                    };
                                } forEach _weps;

                                sleep 10; // 10 Second Cooldown before next missile/bomb barrage
                                if (alive _plane) then { _plane setVariable ["AAS_Missiles_Cooldown", false]; };
                            };
                        };

                        // -----------------------------------------------------
                        // 5-DEGREE CONE (CANNON BURST) -> Cos(5) = ~0.996
                        // -----------------------------------------------------
                        if (_dot >= 0.996 && !(_aircraft getVariable ["AAS_Cannon_Cooldown", false])) then {
                            _aircraft setVariable ["AAS_Cannon_Cooldown", true];
                            
                            [_aircraft, _target, _fnc_getFireMode] spawn {
                                params ["_plane", "_tgt", "_fnc_getFireMode"];
                                private _cannon = _plane getVariable ["AAS_Plane_Cannon", ""];
                                
                                if (_cannon != "") then {
                                    private _mode = [_cannon] call _fnc_getFireMode;

                                    for "_i" from 1 to 20 do {
                                        if (!alive _plane || !alive _tgt) exitWith {};
                                        _plane fireAtTarget [_tgt, _cannon];
                                        _plane forceWeaponFire [_cannon, _mode];
                                        sleep 0.1; // Continuous burst
                                    };
                                };

                                sleep 8; // 8 Second Cooldown before next cannon burst
                                if (alive _plane) then { _plane setVariable ["AAS_Cannon_Cooldown", false]; };
                            };
                        };

                    };
                };
            };
        };
        // =================================================================
        // --- 5. RTB THREAD ---
        // =================================================================
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
    // CASE B: HELICOPTER (QRF-STYLE WAYPOINT REFRESH)
    // ---------------------------------------------------------------------
    case "HELI": {
    private _airClassRaw = AAS_CAS_Heli_Class;
    private _airParsed = [_airClassRaw] call _fnc_parseClass;
    private _airClass = _airParsed select 0;
    
    private _spawnPos = _dropPos getPos [_spawnDist, random 360];
    _spawnPos set [2, 400];
    
    private _airData = [_spawnPos, _spawnPos getDir _dropPos, _airClass, _playerSide] call BIS_fnc_spawnVehicle;
    private _aircraft = _airData select 0;
    private _airGroup = _airData select 2;
    _aircraft allowDamage false;
    { _x allowDamage false; } forEach crew _aircraft;

    // RTB flag — read by all support loops so they can exit cleanly when RTB starts
    _aircraft setVariable ["AAS_CAS_Heli_RTB", false];

    // ============================================================
    // === 90-SECOND IMMORTALITY BUFFER ==========================
    // ============================================================
    [_aircraft] spawn {
        params ["_heli"];
        sleep 90;
        if (alive _heli) then {
            _heli allowDamage true;
            { if (alive _x) then { _x allowDamage true; }; } forEach crew _heli;
        };
    };

    // ============================================================
    // === SCRIPT 1: ENEMY REVEAL (delete this block to disable) ==
    // ============================================================
    [_aircraft, _dropPos] spawn {
        params ["_heli", "_targetPos"];
        while {alive _heli && !(_heli getVariable ["AAS_CAS_Heli_RTB", false])} do {
            private _grp = group _heli;
            if (!isNull _grp) then {
                private _enemies = (_targetPos nearEntities [["Man","Car","Tank","StaticWeapon","Air"], 700]) select {
                    alive _x && {(side _x) getFriend (side _grp) < 0.6}
                };
                { _grp reveal [_x, 4] } forEach _enemies;
            };
            sleep 5;
        };
    };
    // === END SCRIPT 1 ======================================

    // ============================================================
    // === SCRIPT 2: PILOT SALVO (delete this block to disable) ==
    // ============================================================
    _aircraft setVariable ["AAS_lastPilotSalvo", -100];
    private _pilot = driver _aircraft;
    if (!isNull _pilot) then {
        _pilot addEventHandler ["FiredMan", {
            params ["_unit", "_weapon"];
            private _veh = vehicle _unit;
            if (_veh isEqualTo _unit) exitWith {};

            // Don't pile on extra weapon fire once we're trying to leave the AO
            if (_veh getVariable ["AAS_CAS_Heli_RTB", false]) exitWith {};

            // Only react to pilot-turret weapons (safety check)
            if (!(_weapon in (_veh weaponsTurret [-1]))) exitWith {};

            // Cooldown gate
            private _last = _veh getVariable ["AAS_lastPilotSalvo", -100];
            if ((time - _last) < 3) exitWith {};
            _veh setVariable ["AAS_lastPilotSalvo", time];

            private _otherWeapons = (_veh weaponsTurret [-1]) - [_weapon];
            if (_otherWeapons isEqualTo []) exitWith {};

            private _target = _veh findNearestEnemy (getPosATL _veh);
            if (isNull _target) exitWith {};

            [_veh, _otherWeapons, _target] spawn {
                params ["_veh", "_weapons", "_target"];
                {
                    private _wpn = _x;
                    for "_i" from 1 to 2 do {
                        if (alive _veh && {!isNull _target} && {alive _target}) then {
                            _veh fireAtTarget [_target, _wpn];
                            sleep 0.4;
                        };
                    };
                } forEach _weapons;
            };
        }];
    };
    // === END SCRIPT 2 ======================================

    // --- THE QRF ATTACK LOOP ---
    // Refreshes a SAD waypoint every 15s so the heli stays aggressive over the AO.
    // Exits the moment the RTB flag flips so it stops overwriting the extraction waypoint.
    [_aircraft, _airGroup, _dropPos] spawn {
        params ["_heli", "_grp", "_targetPos"];
        
        _grp setCombatMode "RED";
        _grp setBehaviour "COMBAT";
        
        while {alive _heli && {count units _grp > 0} && {!(_heli getVariable ["AAS_CAS_Heli_RTB", false])}} do {
            while {(count (waypoints _grp)) > 0} do { deleteWaypoint ((waypoints _grp) select 0); };
            
            private _wp = _grp addWaypoint [_targetPos getPos [random 50, random 360], 0]; 
            _wp setWaypointType "SAD"; 
            _wp setWaypointSpeed "NORMAL";
            
            sleep 15; 
        };
    };

    // ============================================================
    // === BUG-PROOF RTB THREAD ===================================
    // ============================================================
    // 1. Signals RTB so the QRF loop and supporting scripts stop touching waypoints/weapons
    // 2. Clears combat waypoints, forces CARELESS, pushes a MOVE to _spawnPos with self-delete on arrival
    // 3. Hard 60s deadline — if the heli hasn't left cinematically by then, force-despawn it in place
    [_aircraft, _airGroup, _spawnPos, parseNumber AAS_RTB_CAS] spawn {
        params ["_aircraft", "_airGroup", "_spawnPos", "_rtbTime"];
        sleep _rtbTime;

        // Flip the flag first so the QRF loop stops fighting us for the waypoint slot
        if (!isNull _aircraft) then {
            _aircraft setVariable ["AAS_CAS_Heli_RTB", true];
        };

        // If still flyable, set up a clean cinematic extraction
        if (alive _aircraft) then {
            while {(count (waypoints _airGroup)) > 0} do { deleteWaypoint ((waypoints _airGroup) select 0); };
            _airGroup setBehaviour "CARELESS";
            _airGroup setCombatMode "BLUE";
            {
                _x disableAI "TARGET";
                _x disableAI "AUTOTARGET";
                _x disableAI "AUTOCOMBAT";
            } forEach (units _airGroup);

            private _wpAway = _airGroup addWaypoint [_spawnPos, 0];
            _wpAway setWaypointType "MOVE";
            _wpAway setWaypointSpeed "FULL";
            _wpAway setWaypointStatements ["true", "private _v = vehicle this; {deleteVehicle _x} forEach crew _v; deleteVehicle _v;"];
        };

        // 60-second hard deadline — exits early if the waypoint statement already deleted the heli
        private _deadline = serverTime + 60;
        waitUntil {
            sleep 1;
            isNull _aircraft || {serverTime > _deadline}
        };

        // Force-despawn whatever's left (timed-out flight, wreck, stuck heli, etc.)
        if (!isNull _aircraft) then {
            { if (!isNull _x) then { deleteVehicle _x; }; } forEach crew _aircraft;
            deleteVehicle _aircraft;
        };
    };
};
    // ---------------------------------------------------------------------
    // CASE C: GUNSHIP (UNCHANGED EXCEPT PHANTOM Z-OFFSET SCRIPT)
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
                        
                        // NEW PHANTOM OFFSET LOGIC:
                        // X offset is tiny so they stay on target. Z offset is -1.8m to bury the Ifrit.
                        private _offset = [(_idx * 0.5), 0, -1.8];
                        private _phantomPosASL = (getPosASL _target) vectorAdd _offset;

                        if (_idx >= count _phantoms || { isNull (_phantoms select _idx) }) then {
                            // CAN_COLLIDE prevents Arma from snapping the vehicle back to the surface
                            private _p = createVehicle ["O_MRAP_02_F", _target, [], 0, "CAN_COLLIDE"];
                            _p allowDamage false; 
                            _p engineOn false; 
                            _p hideObjectGlobal true;
                            
                            // Force absolute position underground
                            _p setPosASL _phantomPosASL;
                            
                            [_p] joinSilent (group _target); 
                            createVehicleCrew _p;
                            { 
                                _x allowDamage false; 
                                _x hideObjectGlobal true; 
                            } forEach crew _p;
                            
                            _phantoms set [_idx, _p];
                        } else {
                            // Update position using ASL to keep it buried
                            (_phantoms select _idx) setPosASL _phantomPosASL;
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