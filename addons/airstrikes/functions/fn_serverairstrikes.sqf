// AAS-Airstrikes/functions/fn_serverAirstrikes.sqf
/*
    Author: AAS Team
    Description: Master Strike Router for Airstrikes. Catches the string from the client
    and routes it to the correct spawn and deployment logic.
    REROUTED: Now uses Main AAS Core Economy Logic & Smart Parsers.
*/

params ["_caller", "_dropPos", "_strikeType"];

if (!isServer) exitWith {};

// ==========================================
// --- 1. CORE SETUP & SECURITY ---
// ==========================================

// Get the player's side for spawning friendly planes
private _playerSide = side group _caller;

// Fallback just in case something weird happens with the caller's group or they are "Undercover"
if (_playerSide == sideLogic || _playerSide == civilian) then {
    _playerSide = west; 
};

// ==========================================
// --- 2. HELPERS (Garbage & Parse) ---
// ==========================================
// Ensures planes and crew are deleted when they hit their RTB waypoint or are destroyed
private _fnc_garbageCollect = {
    params ["_vehicle"];
    [_vehicle] spawn {
        params ["_veh"];
        private _crew = crew _veh;
        
        // Wait until the vehicle is dead or natively deleted by Arma
        waitUntil { sleep 10; !alive _veh || isNull _veh };
        
        // If it was successfully deleted by an RTB waypoint, exit
        if (isNull _veh) exitWith {}; 
        
        // If it was shot down, let the wreck stay for 2 minutes for immersion, then clean it up
        sleep 120; 
        { deleteVehicle _x; } forEach _crew;
        deleteVehicle _veh;
    };
};

// --- SMART PARSER HELPER FUNCTION ---
// Reusable logic to extract classnames and Virtual Arsenal/Garage loadouts
private _fnc_parseClass = {
    params ["_rawSetting"];
    private _class = _rawSetting;
    private _loadout = false; // FIX: Default to false instead of nil
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
// --- 3. SERVER ECONOMY & COOLDOWN CHECK ---
// ==========================================

// REROUTED: Safely grab the GLOBAL economy preset from Core
private _econPreset = missionNamespace getVariable ["AAS_Econ_Preset_Core", 0];

// Safely grab the base cost depending on the preset
private _baseCost = switch (_econPreset) do {
    case 0: { parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Custom", "0"]) };
    case 1: { parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Antistasi", "1000"]) };
    case 3: { parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Overthrow", "3000"]) };
    case 4: { parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Warlords", "400"]) };
    case 5: { parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_DUWS", "10"]) };
    case 6: { parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_Antistasi", "1000"]) }; 
    default { 0 }; 
};

private _cost = 0;
private _cdTime = 0;
private _lastUseVar = "";
private _mult = 1.0;

// Route the multiplier and cooldown variables safely based on the requested strike
switch (_strikeType) do {
    case "MidnightSun": {
        _mult = parseNumber (missionNamespace getVariable ["AAS_AS_Mult_MidnightSun", "0.5"]);
        _cdTime = parseNumber (missionNamespace getVariable ["AAS_AS_Cooldown_MidnightSun", "300"]);
        _lastUseVar = "AAS_AS_LastUse_MidnightSun";
    };
    case "GunRun": {
        _mult = parseNumber (missionNamespace getVariable ["AAS_AS_Mult_GunRun", "1.5"]);
        _cdTime = parseNumber (missionNamespace getVariable ["AAS_AS_Cooldown_GunRun", "300"]);
        _lastUseVar = "AAS_AS_LastUse_GunRun";
    };
    case "UnguidedBomb": {
        _mult = parseNumber (missionNamespace getVariable ["AAS_AS_Mult_UnguidedBomb", "4.0"]);
        _cdTime = parseNumber (missionNamespace getVariable ["AAS_AS_Cooldown_UnguidedBomb", "600"]);
        _lastUseVar = "AAS_AS_LastUse_UnguidedBomb";
    };
    case "CruiseMissile": {
        _mult = parseNumber (missionNamespace getVariable ["AAS_AS_Mult_CruiseMissile", "8.0"]);
        _cdTime = parseNumber (missionNamespace getVariable ["AAS_AS_Cooldown_CruiseMissile", "720"]);
        _lastUseVar = "AAS_AS_LastUse_CruiseMissile";
    };
    case "JDAM": {
        _mult = parseNumber (missionNamespace getVariable ["AAS_AS_Mult_JDAM", "10.0"]);
        _cdTime = parseNumber (missionNamespace getVariable ["AAS_AS_Cooldown_JDAM", "720"]);
        _lastUseVar = "AAS_AS_LastUse_JDAM";
    };
};

// Calculate final cost
if (_econPreset == 2) then {
    // KP Liberation: Base Thresholds Only (No Multipliers) packed into an array
    _cost = [
        parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_KPLib_S", "50"]),
        parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_KPLib_A", "100"]),
        parseNumber (missionNamespace getVariable ["AAS_AS_Cost_Base_KPLib_F", "50"])
    ];
} else {
    // Standard Economy: Base Cost * Multiplier
    _cost = round (_baseCost * _mult);
};

// --- Cooldown Validation ---
private _lastUse = missionNamespace getVariable [_lastUseVar, -99999];
if (serverTime < (_lastUse + _cdTime)) exitWith {
    // If the menu glitched and let them click it anyway, abort the execution
    private _timeLeft = 1 max round (((_lastUse + _cdTime) - serverTime) / 60);
    (format ["HQ: Airstrike on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// --- Economy Deduction ---
private _econCode = missionNamespace getVariable ["AAS_AS_Econ_Code", ""];
// REROUTED: Call the Master Router
private _econPass = [_caller, _cost, _econPreset, _econCode] call aas_core_fnc_setEconomyPreset;

// If the manager returns false (insufficient funds), abort!
if (isNil "_econPass" || {!_econPass}) exitWith {};

// --- Lock the Cooldown Timer ---
// Passed both checks! Register the time this was used across the server.
missionNamespace setVariable [_lastUseVar, serverTime, true];


// ====================================================================================
// ====================================================================================
// --- 4. MASTER STRIKE ROUTER ---
// ====================================================================================
// ====================================================================================
switch (_strikeType) do {
    
    // ================================================================================
    // [1] AIRSTRIKE: MIDNIGHT SUN
    // ================================================================================
    case "MidnightSun": {
        // 6-Second Comms Delay
        [_caller] spawn {
            params ["_caller"];
            sleep 6;
            "PILOT: Midnight Sun protocol authorized. Deploying illumination over the AO." remoteExec ["systemChat", _caller];
            "aas_as_pilotmidnightsun" remoteExec ["playSound", _caller];
        };
        
        private _rawSetting = missionNamespace getVariable ["AAS_AS_Plane_MidnightSun", "B_T_VTOL_01_vehicle_F"];

        // Passed smart parser helper into the thread
        [_caller, _dropPos, _playerSide, _fnc_garbageCollect, _fnc_parseClass, _rawSetting] spawn {
            params ["_caller", "_dropPos", "_playerSide", "_fnc_garbageCollect", "_fnc_parseClass", "_rawSetting"];
            
            // --- 90-DEGREE INTERCEPT MATH ---
            private _approachDir = (_caller getDir _dropPos) + 90;
            private _spawnPos = _dropPos getPos [2000, _approachDir];
            _spawnPos set [2, 450]; 
            
            // --- SMART PARSER ---
            private _parsed = [_rawSetting] call _fnc_parseClass;
            private _planeClass = _parsed select 0;
            private _planeLoadout = _parsed select 1;

            private _planeData = [_spawnPos, (_approachDir - 180), _planeClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _plane = _planeData select 0;
            private _planeGroup = _planeData select 2;
            
            // --- CUSTOM LOADOUT APPLICATION ---
            if (_planeLoadout isNotEqualTo false) then {
                if (_planeLoadout isEqualType []) then { _plane setUnitLoadout _planeLoadout; };
                if (_planeLoadout isEqualType "") then { _plane call compile _planeLoadout; };
            };

            _planeGroup deleteGroupWhenEmpty true;

            // --- IMMORTALITY & FACTION FIX ---
            _plane allowDamage false; 
            _plane setCaptive true; // Makes AI completely ignore it
            _plane addRating 10000000;
            { _x addRating 10000000; } forEach (crew _plane);

            _planeGroup setBehaviour "CARELESS";
            _plane disableAI "AUTOTARGET";
            _plane disableAI "TARGET";

            // --- 60 SECOND FAILSAFE ---
            [_plane] spawn {
                params ["_plane"];
                sleep 60;
                if (alive _plane) then {
                    {deleteVehicle _x} forEach (crew _plane);
                    deleteVehicle _plane;
                };
            };

            // --- ON RAILS FLIGHT PATH ---
            private _exitPos = _dropPos getPos [3000, (_approachDir - 180)];
            _exitPos set [2, 450];

            private _vectorDir = [_spawnPos, _exitPos] call BIS_fnc_vectorFromXToY;
            private _vectorUp = [0,0,1];
            private _speed = 150; 
            private _velocity = [_vectorDir, _speed] call BIS_fnc_vectorMultiply;
            private _duration = (_spawnPos distance _exitPos) / _speed;

            // Align plane instantly to the rail
            _plane setVectorDirAndUp [_vectorDir, _vectorUp];

            // Fork the rail movement loop so we don't stall the flare math
            [_plane, _spawnPos, _exitPos, _duration, _velocity, _vectorDir, _vectorUp] spawn {
                params ["_plane", "_start", "_end", "_dur", "_vel", "_vDir", "_vUp"];
                private _startTime = time;
                
                waitUntil {
                    private _progress = ((time - _startTime) / _dur) min 1;
                    _plane setVelocityTransformation [
                        _start, _end,
                        _vel, _vel,
                        _vDir, _vDir,
                        _vUp, _vUp,
                        _progress
                    ];
                    _plane setVelocity velocity _plane;
                    sleep 0.01;
                    (_progress >= 1) || !alive _plane
                };

                // Despawn smoothly at the end of the rail
                if (alive _plane) then {
                    {deleteVehicle _x} forEach (crew _plane);
                    deleteVehicle _plane;
                };
            };

            // Countermeasure / Visual drop sequence
            [_plane, _dropPos] spawn {
                params ["_plane", "_dropPos"];
                waitUntil { sleep 0.1; (_plane distance2D _dropPos < 400) || !alive _plane };
                while { alive _plane && (_plane distance2D _dropPos < 600) } do {
                    _plane action ["useWeapon", _plane, driver _plane, 0];
                    sleep 0.3;
                };
            };

            // Flare Deployment Logic
            waitUntil { sleep 0.1; (_plane distance2D _dropPos < 200) || !alive _plane };

            if (!alive _plane) exitWith {};

            // Flares spawn at 450m, 400m, and 350m
            private _pos1 = _dropPos getPos [400, _approachDir];        _pos1 set [2, 450];
            private _pos2 = +_dropPos;                                  _pos2 set [2, 400];
            private _pos3 = _dropPos getPos [400, (_approachDir - 180)]; _pos3 set [2, 350];
            
            private _flarePositions = [_pos1, _pos2, _pos3];
            
            [
                [_flarePositions], 
                {
                    params ["_flarePositions"];
                    if (!hasInterface) exitWith {};

                    [_flarePositions] spawn {
                        params ["_flarePositions"];

                        {
                            private _flarePos = _x;
                            
                            private _light = "#lightpoint" createVehicleLocal _flarePos;
                            _light setLightColor [0.9, 0.9, 0.95];
                            _light setLightAmbient [0.9, 0.9, 0.95];
                            _light setLightIntensity 12000;
                            _light setLightAttenuation [0, 0, 0, 0.005, 300, 900];
                            _light setLightDayLight true;
                            _light setLightUseFlare true;
                            _light setLightFlareMaxDistance 5000;

                            private _smoke = "#particlesource" createVehicleLocal _flarePos;
                            _smoke setParticleClass "Flare1";

                            playSound3D ["A3\Sounds_F\weapons\Flare_Gun\flaregun_1_shoot.wss", player, false, getPosASL player, 1.2, 0.3, 0];

                            // Post-processing and Camera Shake
                            if (alive player) then {
                                private _dist = player distance2D _flarePos;
                                if (_dist < 1500) then {
                                    private _strength = 1 - (_dist / 1500);
                                    
                                    private _pp = ppEffectCreate ["ColorCorrections", 1500];
                                    _pp ppEffectEnable true;
                                    _pp ppEffectAdjust [1, 1, (0.8 * _strength), [1, 1, 1, 0], [1, 1, 1, 1], [0.299, 0.587, 0.114, 0]];
                                    _pp ppEffectCommit 0;
                                    _pp ppEffectAdjust [1, 1, 0, [0, 0, 0, 0], [1, 1, 1, 1], [0.299, 0.587, 0.114, 0]];
                                    _pp ppEffectCommit (1.0 * _strength);
                                    
                                    [_pp, (1.0 * _strength)] spawn {
                                        params ["_pp", "_time"];
                                        sleep _time;
                                        ppEffectDestroy _pp;
                                    };
                                    addCamShake [1 * _strength, 1, 20];
                                };
                            };

                            // Flare movement and flicker animation
                            [_light, _smoke] spawn {
                                params ["_light", "_smoke"];
                                
                                private _endTime = time + 210;
                                private _startTime = time;
                                private _frame = 0;
                                private _startPosASL = AGLToASL (getPos _light);
                                private _anchorX = _startPosASL select 0;
                                private _anchorY = _startPosASL select 1;
                                private _currentZ = _startPosASL select 2;
                                private _baseIntensity = 12000;
                                private _currentTarget = _baseIntensity;
                                private _currentIntensity = _baseIntensity;
                                
                                while {time < _endTime && _currentZ > 2} do {
                                    private _elapsed = time - _startTime;
                                    
                                    private _fadeMult = 1;
                                    if (_elapsed > 120) then {
                                        _fadeMult = 1 - ((_elapsed - 120) / 90);
                                    };
                                    
                                    private _activeBase = _baseIntensity * _fadeMult;

                                    _frame = _frame + 1;
                                    if (_frame % 5 == 0) then {
                                        _light setLightFlareSize ((25 + random 30) * _fadeMult);
                                        if (random 100 > 80) then {
                                            if (random 100 > 90) then { _currentTarget = _activeBase * 0.3; }
                                            else {
                                                if (random 100 > 90) then { _currentTarget = _activeBase * 2.0; }
                                                else { _currentTarget = _activeBase + ((random 8000) - 4000) * _fadeMult; };
                                            };
                                        };
                                        _currentIntensity = _currentIntensity + ((_currentTarget - _currentIntensity) * 0.2);
                                        _light setLightIntensity _currentIntensity;
                                    };

                                    _currentZ = _currentZ - (2.1 * 0.01);
                                    private _newPosASL = [
                                        _anchorX + (sin (_elapsed * 20) * 15),
                                        _anchorY + (cos (_elapsed * 12.5) * 15),
                                        _currentZ
                                    ];
                                    
                                    _light setPosASL _newPosASL;
                                    _smoke setPosASL _newPosASL;
                                    sleep 0.05; 
                                };
                                deleteVehicle _light;
                                deleteVehicle _smoke;
                            };
                            sleep 1.5;
                        } forEach _flarePositions;
                    };
                }
            ] remoteExec ["spawn", 0]; 
        };
    };
    
    // ================================================================================
    // [2] AIRSTRIKE: GUN RUN
    // ================================================================================
    case "GunRun": {
        // 6-Second Comms Delay
        [_caller] spawn {
            params ["_caller"];
            sleep 6;
            "PILOT: Gun run committed, keep your heads down! Over." remoteExec ["systemChat", _caller];
            "aas_as_pilotgunrun" remoteExec ["playSound", _caller];
        };
        
        private _rawSetting = missionNamespace getVariable ["AAS_AS_Plane_GunRun", "B_Plane_CAS_01_dynamicLoadout_F"]; 

        [_caller, _dropPos, _playerSide, _fnc_garbageCollect, _fnc_parseClass, _rawSetting] spawn {
            params ["_caller", "_dropPos", "_playerSide", "_fnc_garbageCollect", "_fnc_parseClass", "_rawSetting"];

            // --- APPROACH VECTOR MATH ---
            private _dir = _caller getDir _dropPos;
            // Failsafe: If the player calls it Danger Close (under 15m), use their body rotation so it doesn't spawn in their face
            if ((_caller distance2D _dropPos) < 15) then {
                _dir = getDir _caller;
            };

            private _pos = +_dropPos;
            _pos set [2, (_pos select 2) max (getTerrainHeightASL _pos)];

            // Mathematical flight path setup
            private _dis = 3000;
            private _alt = 1000;
            private _speed = 400 / 3.6; // ~111 m/s
            private _duration = ([0,0] distance [_dis, _alt]) / _speed;

            private _planePos = [_pos, _dis, _dir + 180] call BIS_fnc_relPos;
            _planePos set [2, (_pos select 2) + _alt];

            // --- NEW: SMART PARSER ---
            private _parsed = [_rawSetting] call _fnc_parseClass;
            private _planeClass = _parsed select 0;
            private _planeLoadout = _parsed select 1;

            // Spawn the CAS Plane
            private _planeArray = [_planePos, _dir, _planeClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _plane = _planeArray select 0;
            private _planeGroup = _planeArray select 2;
            
            // --- CUSTOM LOADOUT APPLICATION ---
            if (_planeLoadout isNotEqualTo false) then {
                if (_planeLoadout isEqualType []) then { _plane setUnitLoadout _planeLoadout; };
                if (_planeLoadout isEqualType "") then { _plane call compile _planeLoadout; };
            };

            _planeGroup deleteGroupWhenEmpty true;
            [_plane] call _fnc_garbageCollect; 

            // --- IMMORTALITY, ANTI-RENEGADE & STOIC AI FIX ---
            _plane allowDamage false;
            _plane setCaptive true; // Keeps AA from immediately tracking it
            _plane addRating 10000000;
            { _x addRating 10000000; } forEach (crew _plane);

            // Strip all AI autonomy so they don't fight the rails or get distracted by ground targets
            _plane disableAI "MOVE";
            _plane disableAI "TARGET";
            _plane disableAI "AUTOTARGET";
            _plane disableAI "FSM";
            _plane setCombatMode "BLUE";
            _planeGroup setBehaviour "CARELESS";

            // 15-Second Vulnerability Delay
            [_plane] spawn {
                params ["_plane"];
                sleep 15;
                if (alive _plane) then { _plane allowDamage true; };
            };

            // 90-Second Absolute Despawn Failsafe
            [_plane] spawn {
                params ["_plane"];
                sleep 90;
                if (alive _plane) then {
                    {deleteVehicle _x} forEach (crew _plane);
                    deleteVehicle _plane;
                };
            };

            // Snap plane to starting vector
            _plane setPosASL _planePos;
            private _vectorDir = [_planePos, _pos] call BIS_fnc_vectorFromXToY;
            private _velocity = [_vectorDir, _speed] call BIS_fnc_vectorMultiply;
            _plane setVectorDir _vectorDir;
            [_plane, -90 + atan (_dis / _alt), 0] call BIS_fnc_setPitchBank;
            private _vectorUp = vectorUp _plane;

            // Extract the plane's Gun and Missile classnames dynamically
            private _weaponTypes = ["machinegun", "missilelauncher"];
            private _weapons = [];
            {
                if (toLower ((_x call BIS_fnc_itemType) select 1) in _weaponTypes) then {
                    private _modes = getArray (configFile >> "cfgWeapons" >> _x >> "modes");
                    if (count _modes > 0) then {
                        private _mode = _modes select 0;
                        if (_mode == "this") then {_mode = _x;};
                        _weapons pushBack [_x, _mode];
                    };
                };
            } forEach (_planeClass call BIS_fnc_weaponsEntityType);

            // Strip any non-CAS weapons off the plane
            {
                if !(toLower ((_x call BIS_fnc_itemType) select 1) in (_weaponTypes + ["countermeasureslauncher"])) then {
                    _plane removeWeapon _x;
                };
            } forEach (weapons _plane);

            // ==========================================
            // --- THE APPROACH & FIRE LOOP ---
            // ==========================================
            private _time = time;
            private _offset = 20; 
            private _fireNull = true;
            private _fire = scriptNull;

            waitUntil {
                private _fireProgress = _plane getVariable ["fireProgress", 0];

                // Force the plane down the rail
                _plane setVelocityTransformation [
                    _planePos, [_pos select 0, _pos select 1, (_pos select 2) + _offset + _fireProgress * 12],
                    _velocity, _velocity,
                    _vectorDir, _vectorDir,
                    _vectorUp, _vectorUp,
                    (time - _time) / _duration
                ];
                _plane setVelocity velocity _plane;

                // When within 1000m, generate a laser target and force the pilot to fire
                if ((getPosASL _plane) distance _pos < 1000 && _fireNull) then {
                    private _targetType = if (_playerSide getFriend west > 0.6) then {"LaserTargetW"} else {"LaserTargetE"};
                    private _target = createVehicle [_targetType, _pos, [], 0, "NONE"];
                    
                    _plane reveal laserTarget _target;
                    _plane doWatch laserTarget _target;
                    _plane doTarget laserTarget _target;

                    _fireNull = false;
                    
                    // Cinematic Camera Shake
                    [
                        [_pos], {
                            params ["_pos"];
                            if (!hasInterface) exitWith {};
                            if (player distance2D _pos < 800) then {
                                addCamShake [4, 4, 25]; 
                            };
                        }
                    ] remoteExec ["spawn", 0];

                    if (missionNamespace getVariable ["AAS_AS_Toggle_Brrrt", true]) then {
                        [_plane, ["aas_as_brrrt", 8000, 1]] remoteExec ["say3D", 0];
                    };

                    _fire = [_plane, _weapons, _target] spawn {
                        params ["_plane", "_weapons", "_target"];
                        private _planeDriver = driver _plane;
                        private _duration = 3; 
                        private _time = time + _duration;
                        
                        waitUntil {
                            { _planeDriver fireAtTarget [_target, (_x select 0)]; } forEach _weapons;
                            _plane setVariable ["fireProgress", (1 - ((_time - time) / _duration)) max 0 min 1];
                            sleep 0.1;
                            time > _time || isNull _plane
                        };
                        deleteVehicle _target; 
                    };
                };

                sleep 0.01;
                (!_fireNull && {scriptDone _fire}) || !alive _plane
            };

            // ==========================================
            // --- ON-RAILS EGRESS (NO AI CONTROL) ---
            // ==========================================
            if (alive _plane) then {
                // Pop flares on exit safely in a separate thread
                [_plane] spawn {
                    params ["_plane"];
                    for "_i" from 0 to 2 do {
                        if (!alive _plane) exitWith {};
                        (driver _plane) forceWeaponFire ["CMFlareLauncher", "Burst"];
                        sleep 1.1;
                    };
                };

                private _egressStart = getPosASL _plane;
                private _egressEnd = _pos getPos [3000, _dir];
                _egressEnd set [2, _alt + 200]; // Climb up and away

                private _egressDir = [_egressStart, _egressEnd] call BIS_fnc_vectorFromXToY;
                private _egressVel = [_egressDir, _speed] call BIS_fnc_vectorMultiply;
                private _egressDur = (_egressStart distance _egressEnd) / _speed;

                // Force pitch up for climb out
                _plane setVectorDir _egressDir;
                [_plane, 15, 0] call BIS_fnc_setPitchBank;
                private _egressUp = vectorUp _plane;

                private _eTime = time;
                
                // Force the plane out of the AO on an inescapable rail
                waitUntil {
                    private _p = ((time - _eTime) / _egressDur) min 1;
                    _plane setVelocityTransformation [
                        _egressStart, _egressEnd,
                        _egressVel, _egressVel,
                        _egressDir, _egressDir,
                        _egressUp, _egressUp,
                        _p
                    ];
                    _plane setVelocity velocity _plane;
                    sleep 0.01;
                    (_p >= 1) || !alive _plane
                };

                // Despawn smoothly at the end of the rail
                if (alive _plane) then {
                    {deleteVehicle _x} forEach (crew _plane);
                    deleteVehicle _plane;
                };
            };
        };
    };
    
    // ================================================================================
    // [3] AIRSTRIKE: CARPET BOMBING 
    // ================================================================================
    case "UnguidedBomb": {
        // 6-Second Comms Delay
        [_caller] spawn {
            params ["_caller"];
            sleep 6;
            "PILOT: Roger that, carpet bombing run authorized, ordnance inbound." remoteExec ["systemChat", _caller];
            "aas_as_pilotcarpet" remoteExec ["playSound", _caller];
        };
        
        private _rawSetting = missionNamespace getVariable ["AAS_AS_Plane_UnguidedBomb", "B_Plane_Fighter_01_F"]; 

        [_caller, _dropPos, _playerSide, _fnc_garbageCollect, _fnc_parseClass, _rawSetting] spawn {
            params ["_caller", "_dropPos", "_playerSide", "_fnc_garbageCollect", "_fnc_parseClass", "_rawSetting"];

            // --- APPROACH VECTOR MATH ---
            private _dir = _caller getDir _dropPos;
            // Failsafe: If the player calls it Danger Close (under 15m), use their body rotation
            if ((_caller distance2D _dropPos) < 15) then {
                _dir = getDir _caller;
            };

            private _pos = +_dropPos;
            _pos set [2, (_pos select 2) max (getTerrainHeightASL _pos)];

            // Mathematical flight path setup for LEVEL FLIGHT
            private _dis = 3500;
            private _alt = 300; // 300m is the sweet spot for unguided bomb spread
            private _speed = 150; // Slower speed = tighter carpet spread
            private _duration = ([0,0] distance [_dis, _alt]) / _speed;

            private _planePos = [_pos, _dis, _dir + 180] call BIS_fnc_relPos;
            _planePos set [2, (_pos select 2) + _alt];

            // --- NEW: SMART PARSER ---
            private _parsed = [_rawSetting] call _fnc_parseClass;
            private _planeClass = _parsed select 0;
            private _planeLoadout = _parsed select 1;

            // Spawn the Bomber
            private _planeArray = [_planePos, _dir, _planeClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _plane = _planeArray select 0;
            private _planeGroup = _planeArray select 2;

            // --- CUSTOM LOADOUT APPLICATION ---
            if (_planeLoadout isNotEqualTo false) then {
                if (_planeLoadout isEqualType []) then { _plane setUnitLoadout _planeLoadout; };
                if (_planeLoadout isEqualType "") then { _plane call compile _planeLoadout; };
            };
            
            _planeGroup deleteGroupWhenEmpty true;
            [_plane] call _fnc_garbageCollect; 

            // --- IMMORTALITY, ANTI-RENEGADE & STOIC AI FIX ---
            _plane allowDamage false;
            _plane setCaptive true; // Keeps AA from tracking it immediately
            _plane addRating 10000000;
            { _x addRating 10000000; } forEach (crew _plane);

            // Strip all AI autonomy
            _plane disableAI "MOVE";
            _plane disableAI "TARGET";
            _plane disableAI "AUTOTARGET";
            _plane disableAI "FSM";
            _plane setCombatMode "BLUE";
            _planeGroup setBehaviour "CARELESS";

            // 15-Second Vulnerability Delay
            [_plane] spawn {
                params ["_plane"];
                sleep 15;
                if (alive _plane) then { _plane allowDamage true; };
            };

            // 90-Second Absolute Despawn Failsafe
            [_plane] spawn {
                params ["_plane"];
                sleep 90;
                if (alive _plane) then {
                    {deleteVehicle _x} forEach (crew _plane);
                    deleteVehicle _plane;
                };
            };

            _plane setPosASL _planePos;
            private _vectorDir = [_planePos, _pos] call BIS_fnc_vectorFromXToY;
            private _velocity = [_vectorDir, _speed] call BIS_fnc_vectorMultiply;
            _plane setVectorDir _vectorDir;
            [_plane, 0, 0] call BIS_fnc_setPitchBank; // Force LEVEL FLIGHT
            private _vectorUp = vectorUp _plane;

            // ==========================================
            // --- THE APPROACH & CARPET DROP LOOP ---
            // ==========================================
            private _time = time;
            private _bombsDropped = false;

            waitUntil {
                // Force the plane down the level rail
                _plane setVelocityTransformation [
                    _planePos, [_pos select 0, _pos select 1, (_pos select 2) + _alt],
                    _velocity, _velocity,
                    _vectorDir, _vectorDir,
                    _vectorUp, _vectorUp,
                    (time - _time) / _duration
                ];
                _plane setVelocity velocity _plane;

                // When the plane is approx 1200m out, physics dictate the bomb will hit the target.
                if ((getPosASL _plane) distance2D _pos < 1200 && !_bombsDropped) then {
                    _bombsDropped = true;
                    
                    // Fork a separate thread to drop the bombs so we don't stutter the plane's movement
                    [_plane, _pos] spawn {
                        params ["_plane", "_pos"];
                        
                        // Drop 8x Mk82 500lb Bombs
                        for "_i" from 1 to 8 do {
                            if (!alive _plane) exitWith {};
                            
                            // Alternate between Left (-4.5m) and Right (+4.5m) wing pylons
                            private _wingOffset = if (_i % 2 == 0) then { 4.5 } else { -4.5 };
                            
                            // Spawn the bomb physically beneath the specific wing
                            private _bomb = createVehicle ["Bo_Mk82", _plane modelToWorld [_wingOffset, 0, -3], [], 0, "FLY"];
                            
                            // Align the bomb with the plane and give it the plane's exact forward momentum
                            _bomb setVectorDirAndUp [vectorDir _plane, vectorUp _plane];
                            _bomb setVelocity (velocity _plane);
                            
                            // 0.15 seconds between drops creates a perfectly spaced carpet
                            sleep 0.15; 
                        };

                        // Wait for the bombs to hit the ground (roughly 7-8 seconds from 300m), then shake cameras
                        sleep 8; 
                        [
                            [_pos], {
                                params ["_pos"];
                                if (!hasInterface) exitWith {};
                                private _dist = player distance2D _pos;
                                if (_dist < 1200) then {
                                    // Massive camera shake for Carpet Bombing
                                    addCamShake [8 - (_dist/150), 6, 25]; 
                                };
                            }
                        ] remoteExec ["spawn", 0];
                    };
                };

                sleep 0.01;
                // Break the loop when the plane passes over the target
                (_plane distance2D _pos < 100) || !alive _plane
            };

            // ==========================================
            // --- ON-RAILS EGRESS (NO AI CONTROL) ---
            // ==========================================
            if (alive _plane) then {
                private _egressStart = getPosASL _plane;
                private _egressEnd = _pos getPos [3500, _dir];
                _egressEnd set [2, _alt + 300]; // Climb up and away

                private _egressDir = [_egressStart, _egressEnd] call BIS_fnc_vectorFromXToY;
                private _egressVel = [_egressDir, _speed] call BIS_fnc_vectorMultiply;
                private _egressDur = (_egressStart distance _egressEnd) / _speed;

                // Force pitch up for climb out
                _plane setVectorDir _egressDir;
                [_plane, 15, 0] call BIS_fnc_setPitchBank;
                private _egressUp = vectorUp _plane;

                private _eTime = time;
                
                // Force the plane out of the AO on an inescapable rail
                waitUntil {
                    private _p = ((time - _eTime) / _egressDur) min 1;
                    _plane setVelocityTransformation [
                        _egressStart, _egressEnd,
                        _egressVel, _egressVel,
                        _egressDir, _egressDir,
                        _egressUp, _egressUp,
                        _p
                    ];
                    _plane setVelocity velocity _plane;
                    sleep 0.01;
                    (_p >= 1) || !alive _plane
                };

                // Despawn smoothly at the end of the rail
                if (alive _plane) then {
                    {deleteVehicle _x} forEach (crew _plane);
                    deleteVehicle _plane;
                };
            };
        };
    };
    
    // ================================================================================
    // [4] AIRSTRIKE: CRUISE MISSILE
    // ================================================================================
    case "CruiseMissile": {
        // 6-Second Comms Delay
        [_caller] spawn {
            params ["_caller"];
            sleep 6;
            "HQ: Cruise missile launch detected. Impact imminent." remoteExec ["systemChat", _caller];
            "aas_as_hqmissile" remoteExec ["playSound", _caller];
        };
        
        [_caller, _dropPos, _playerSide] spawn {
            params ["_caller", "_dropPos", "_playerSide"];

            // --- APPROACH VECTOR MATH ---
            private _dir = _caller getDir _dropPos;
            // Failsafe: Danger Close
            if ((_caller distance2D _dropPos) < 15) then {
                _dir = getDir _caller;
            };
            
            // Lock the target position to ATL and convert to ASL for flawless guidance math
            private _targetPosATL = +_dropPos;
            _targetPosATL set [2, 0]; 
            private _targetPosASL = AGLToASL _targetPosATL;

            // Calculate a 2D spawn position 2500m behind the caller
            private _spawnPos2D = (getPosASL _caller) getPos [2500, _dir + 180];
            
            // FIX: Set the missile's altitude to 300m ABOVE the max height of caller or target
            // This ensures it never spawns in a valley and crashes into a mountain on its way to a higher elevation
            private _spawnAlt = (((getPosASL _caller) select 2) max (_targetPosASL select 2)) + 300;
            private _spawnPosASL = [_spawnPos2D select 0, _spawnPos2D select 1, _spawnAlt]; 

            // Vanilla NATO Cruise Missile Classname (No parser needed)
            private _missileClass = "ammo_Missile_Cruise_01";
            private _missile = createVehicle [_missileClass, _spawnPosASL, [], 0, "FLY"];
            
            // Invulnerability so it doesn't hit a bird or clipping error and despawn early
            _missile allowDamage false;

            // Strictly force it into the ASL altitude so the engine doesn't snap it to the ground
            _missile setPosASL _spawnPosASL;
            
            // Calculate the initial vector directly at the target
            private _vectorDir = [getPosASL _missile, _targetPosASL] call BIS_fnc_vectorFromXToY;
            _missile setVectorDir _vectorDir;
            _missile setVectorUp [0, 0, 1];

            // Set the cruise missile speed to 250 m/s (Approx 900 km/h)
            private _speed = 250; 
            _missile setVelocity ([_vectorDir, _speed] call BIS_fnc_vectorMultiply);

            private _flybyPlayed = false;
            
            // 20-second hard timeout failsafe (2500m at 250m/s takes 10s. 20s allows for plenty of buffer).
            private _timeout = time + 20;

            // ==========================================
            // --- ACTIVE GUIDANCE & FLYBY LOOP ---
            // ==========================================
            private _lastPos = getPosATL _missile; // Track position for interception checks
            
            // Expanded hit radius to 30m to prevent tick-rate overshoot
            while {alive _missile && {(_missile distance _targetPosASL) > 30} && {time < _timeout}} do {
                _lastPos = getPosATL _missile;
                private _currentPos = getPosASL _missile;
                private _newDir = [_currentPos, _targetPosASL] call BIS_fnc_vectorFromXToY;
                
                _missile setVectorDir _newDir;
                _missile setVectorUp [0,0,1];
                _missile setVelocity ([_newDir, _speed] call BIS_fnc_vectorMultiply);
                
                // Check if it's close to the caller to play the "Woosh" sound
                if (!_flybyPlayed && {(_missile distance _caller) < 300}) then {
                    _flybyPlayed = true;
                    // Play a native Arma 3 rocket flyby sound globally near the caller
                    [
                        [_caller], {
                            params ["_c"];
                            if (hasInterface && {player distance _c < 600}) then {
                                playSound3D ["A3\Sounds_F\weapons\Rockets\titan_flyby.wss", player, false, getPosASL player, 5, 1, 0];
                            };
                        }
                    ] remoteExec ["spawn", 0];
                };

                sleep 0.05; 
            };

            // ==========================================
            // --- IMPACT & CINEMATICS ---
            // ==========================================
            // ANTI-GHOST DETONATION: If the missile was shot down more than 100m from the target, abort the explosion!
            if (!alive _missile && {(_lastPos distance2D _targetPosATL) > 100}) exitWith {};

            // If it timed out but is still alive, we force detonate it exactly at the target.
            private _impactPos = if (alive _missile && time < _timeout) then { getPosATL _missile } else { _targetPosATL };
            if (alive _missile) then { deleteVehicle _missile; };
            
            // Keep the fireball above the terrain geometry
            private _boomPos = +_impactPos;
            _boomPos set [2, 1]; 
            
            // Spawn the manual detonations (Guaranteed Explosion)
            createVehicle ["HelicopterExploBig", _boomPos, [], 0, "CAN_COLLIDE"];
            private _b1 = createVehicle ["Bo_GBU12_LGB", _boomPos, [], 0, "CAN_COLLIDE"]; _b1 setDamage 1;
            private _b2 = createVehicle ["Bo_Mk82", _boomPos getPos [3, random 360], [], 0, "CAN_COLLIDE"]; _b2 setDamage 1;

            // Guaranteed Kill-Zone (20 meters)
            private _killZone = nearestObjects [_impactPos, ["AllVehicles", "House", "Strategic"], 20];
            { _x setDamage [1, true]; } forEach _killZone;

            // Splash Damage Zone (40 meters)
            private _damageZone = nearestObjects [_impactPos, ["AllVehicles", "House", "Strategic"], 40];
            {
                if (alive _x && !(_x in _killZone)) then {
                    _x setDamage [((damage _x) + 0.6), true];
                };
            } forEach _damageZone;

            // Screen shake and trauma
            [
                [_impactPos], {
                    params ["_pos"];
                    if (!hasInterface) exitWith {};
                    
                    private _dist = player distance2D _pos;
                    if (_dist < 1500) then {
                        addCamShake [18 - (_dist/85), 4, 20]; 
                        
                        if (_dist < 500) then {
                            playSound "combat_deafness"; 
                            private _blur = ppEffectCreate ["DynamicBlur", 500];
                            _blur ppEffectEnable true;
                            _blur ppEffectAdjust [2];
                            _blur ppEffectCommit 0;
                            _blur ppEffectAdjust [0];
                            _blur ppEffectCommit 5;
                            [_blur] spawn { sleep 5; ppEffectDestroy (_this select 0); };
                        };
                    };
                }
            ] remoteExec ["spawn", 0];
        };
    };
    
    // ================================================================================
    // [5] AIRSTRIKE: JDAM
    // ================================================================================
    case "JDAM": {
        // 6-Second Comms Delay
        [_caller] spawn {
            params ["_caller"];
            sleep 6;
            "PILOT: Roger Wilco, high-altitude strike inbound. Danger Close!" remoteExec ["systemChat", _caller];
            "aas_as_pilotjdam" remoteExec ["playSound", _caller];
        };
        
        private _rawSetting = missionNamespace getVariable ["AAS_AS_Plane_JDAM", "B_Plane_Fighter_01_Stealth_F"]; 

        [_caller, _dropPos, _playerSide, _fnc_garbageCollect, _fnc_parseClass, _rawSetting] spawn {
            params ["_caller", "_dropPos", "_playerSide", "_fnc_garbageCollect", "_fnc_parseClass", "_rawSetting"];

            // --- APPROACH VECTOR MATH ---
            private _dir = _caller getDir _dropPos;
            // Failsafe: Danger Close
            if ((_caller distance2D _dropPos) < 15) then {
                _dir = getDir _caller;
            };
            
            // Lock the target position to ATL and convert to ASL for flawless guidance math
            private _targetPosATL = +_dropPos;
            _targetPosATL set [2, 0]; // Ground level
            private _targetPosASL = AGLToASL _targetPosATL;

            // Spawn plane VERY high and far away
            private _alt = 2000;
            private _dis = 5000; 
            private _spawnPos = _targetPosATL getPos [_dis, _dir + 180];
            _spawnPos set [2, _alt];
            
            private _exitPos = _targetPosATL getPos [_dis, _dir];
            _exitPos set [2, _alt];

            // --- NEW: SMART PARSER ---
            private _parsed = [_rawSetting] call _fnc_parseClass;
            private _planeClass = _parsed select 0;
            private _planeLoadout = _parsed select 1;

            private _planeArray = [_spawnPos, _dir, _planeClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _plane = _planeArray select 0;
            private _planeGroup = _planeArray select 2;

            // --- CUSTOM LOADOUT APPLICATION ---
            if (_planeLoadout isNotEqualTo false) then {
                if (_planeLoadout isEqualType []) then { _plane setUnitLoadout _planeLoadout; };
                if (_planeLoadout isEqualType "") then { _plane call compile _planeLoadout; };
            };
            
            _planeGroup deleteGroupWhenEmpty true;
            [_plane] call _fnc_garbageCollect; 

            // --- IMMORTALITY, ANTI-RENEGADE & STOIC AI FIX ---
            _plane allowDamage false;
            _plane setCaptive true;
            _plane addRating 10000000;
            { _x addRating 10000000; } forEach (crew _plane);

            _plane disableAI "MOVE";
            _plane disableAI "TARGET";
            _plane disableAI "AUTOTARGET";
            _plane disableAI "FSM";
            _planeGroup setBehaviour "CARELESS";

            // 15-Second Vulnerability Delay
            [_plane] spawn {
                params ["_plane"];
                sleep 15;
                if (alive _plane) then { _plane allowDamage true; };
            };

            // Absolute Despawn Failsafe (Extra long for 10km total flight path)
            [_plane] spawn {
                params ["_plane"];
                sleep 120;
                if (alive _plane) then {
                    {deleteVehicle _x} forEach (crew _plane);
                    deleteVehicle _plane;
                };
            };

            _plane setPosASL _spawnPos;
            
            private _speed = 250; // 900 km/h
            private _duration = (_spawnPos distance _exitPos) / _speed;
            private _vectorDir = [_spawnPos, _exitPos] call BIS_fnc_vectorFromXToY;
            private _velocity = [_vectorDir, _speed] call BIS_fnc_vectorMultiply;
            private _vectorUp = [0,0,1];
            
            _plane setVectorDirAndUp [_vectorDir, _vectorUp];

            // ==========================================
            // --- FLIGHT RAIL & BOMB DROP ---
            // ==========================================
            private _time = time;
            private _bombDropped = false;

            waitUntil {
                private _progress = ((time - _time) / _duration) min 1;
                
                _plane setVelocityTransformation [
                    _spawnPos, _exitPos,
                    _velocity, _velocity,
                    _vectorDir, _vectorDir,
                    _vectorUp, _vectorUp,
                    _progress
                ];
                _plane setVelocity velocity _plane;

                // RELEASE POINT: 2500m gives the bomb a perfect glide slope from 2000m up
                if (!_bombDropped && {(_plane distance2D _targetPosATL) < 2500}) then {
                    _bombDropped = true;
                    
                    [_plane, _targetPosATL, _targetPosASL, _dir] spawn {
                        params ["_plane", "_targetPosATL", "_targetPosASL", "_dir"];
                        
                        if (!alive _plane) exitWith {}; // Failsafe if plane vanished
                        
                        // Spawn the bomb safely beneath the stealth fighter
                        private _bomb = createVehicle ["Bo_GBU12_LGB", _plane modelToWorld [0,0,-8], [], 0, "FLY"];
                        _bomb setDir _dir;
                        
                        // Inherit the jet's momentum
                        _bomb setVelocity [
                            (velocity _plane select 0), 
                            (velocity _plane select 1), 
                            -50
                        ];
                        
                        private _lastPos = getPosATL _bomb;
                        
                        // Active Guidance Loop (Expanded to 30m to prevent overshoot)
                        while {alive _bomb && {(_bomb distance _targetPosASL) > 30}} do {
                            _lastPos = getPosATL _bomb;
                            private _speed = (vectorMagnitude (velocity _bomb)) max 150; 
                            private _dirToTarget = [getPosASL _bomb, _targetPosASL] call BIS_fnc_vectorFromXToY;
                            
                            _bomb setVectorDir _dirToTarget;
                            _bomb setVectorUp [0,0,1];
                            _bomb setVelocity ([_dirToTarget, _speed] call BIS_fnc_vectorMultiply);
                            
                            sleep 0.05; 
                        };

                        // ==========================================
                        // --- CINEMATIC IMPACT & AUGMENTED KILL ---
                        // ==========================================
                        // ANTI-GHOST DETONATION: Did C-RAM shoot it down mid-air? Abort!
                        if (!alive _bomb && {(_lastPos distance2D _targetPosATL) > 75}) exitWith {};
                        
                        private _impactPos = if (alive _bomb) then { getPosATL _bomb } else { _targetPosATL };
                        if (alive _bomb) then { deleteVehicle _bomb; };
                        
                        // 1. THE FIREBALL & SMOKE AFTERMATH:
                        private _boomPos = +_impactPos;
                        _boomPos set [2, 1]; 
                        
                        // Massive Hollywood fireball + Native Fragmentation for Infantry
                        createVehicle ["HelicopterExploBig", _boomPos, [], 0, "CAN_COLLIDE"];
                        private _b1 = createVehicle ["Bo_GBU12_LGB", _boomPos, [], 0, "CAN_COLLIDE"]; _b1 setDamage 1;
                        
                        sleep 0.05;
                        
                        createVehicle ["HelicopterExploBig", _boomPos getPos [4, random 360], [], 0, "CAN_COLLIDE"];
                        private _b2 = createVehicle ["Bo_GBU12_LGB", _boomPos getPos [3, random 360], [], 0, "CAN_COLLIDE"]; _b2 setDamage 1;
                        private _b3 = createVehicle ["Bo_Mk82", _boomPos getPos [3, random 360], [], 0, "CAN_COLLIDE"]; _b3 setDamage 1;
                        // Adding raw fragmentation strictly for infantry lethality in the blast center
                        createVehicle ["R_80mm_HE", _boomPos getPos [2, random 360], [], 0, "CAN_COLLIDE"] setDamage 1;
                        createVehicle ["R_80mm_HE", _boomPos getPos [4, random 360], [], 0, "CAN_COLLIDE"] setDamage 1;

                        // Artillery shells throw huge, lingering dust and smoke columns into the air
                        createVehicle ["Sh_155mm_AMOS", _boomPos getPos [5, random 360], [], 0, "CAN_COLLIDE"] setDamage 1;
                        createVehicle ["Sh_155mm_AMOS", _boomPos getPos [5, random 360], [], 0, "CAN_COLLIDE"] setDamage 1;

                        // 2. THE DELETE BUTTON (Guaranteed Kill-Zone expanded to 40m)
                        // "AllVehicles" includes infantry ("Man") and heavy armor.
                        private _killZone = nearestObjects [_impactPos, ["AllVehicles", "Building", "House", "Strategic"], 40];
                        {
                            _x setDamage [1, true]; 
                        } forEach _killZone;

                        // 3. THE CRACKED FOUNDATION (Severe Damage Zone expanded to 85m)
                        private _damageZone = nearestObjects [_impactPos, ["AllVehicles", "Building", "House", "Strategic"], 85];
                        {
                            if (alive _x && !(_x in _killZone)) then {
                                _x setDamage [((damage _x) + 0.8), true]; // Almost destroys anything caught here
                            };
                        } forEach _damageZone;

                        // 4. THE SHOCKWAVE & TRAUMA
                        [
                            [_impactPos], {
                                params ["_pos"];
                                if (!hasInterface) exitWith {};
                                
                                private _dist = player distance2D _pos;
                                
                                if (_dist < 1200) then {
                                    addCamShake [15 - (_dist/80), 4, 20];
                                    
                                    // Flashbang & Concussion Effect for close proximity
                                    if (_dist < 400) then {
                                        playSound "combat_deafness"; 
                                        
                                        private _blur = ppEffectCreate ["DynamicBlur", 500];
                                        _blur ppEffectEnable true;
                                        _blur ppEffectAdjust [1.5]; 
                                        _blur ppEffectCommit 0;
                                        _blur ppEffectAdjust [0];
                                        _blur ppEffectCommit 4; 
                                        [_blur] spawn { sleep 4; ppEffectDestroy (_this select 0); };
                                        
                                        private _flash = ppEffectCreate ["ColorCorrections", 1500];
                                        _flash ppEffectEnable true;
                                        _flash ppEffectAdjust [1, 1, 0, [1, 1, 1, 1], [1, 1, 1, 1], [0.299, 0.587, 0.114, 0]];
                                        _flash ppEffectCommit 0;
                                        _flash ppEffectAdjust [1, 1, 0, [0, 0, 0, 0], [1, 1, 1, 1], [0.299, 0.587, 0.114, 0]];
                                        _flash ppEffectCommit 1.5;
                                        [_flash] spawn { sleep 1.5; ppEffectDestroy (_this select 0); };
                                    };
                                };
                            }
                        ] remoteExec ["spawn", 0];
                    };
                };

                sleep 0.01;
                (_progress >= 1) || !alive _plane
            };

            // Plane reached the end of the rail
            if (alive _plane) then {
                {deleteVehicle _x} forEach (crew _plane);
                deleteVehicle _plane;
            };
        };
    };
    
    // ================================================================================
    // FAILSAFE
    // ================================================================================
    default {
        // Failsafe in case a typo slips into the client menu strings
        diag_log format ["[AAS-Airstrikes] ERROR: Unknown strike type requested: %1", _strikeType];
    };
};