// functions/fn_serverCAS.sqf

// Added the third parameter that defaults to false for regular players
params ["_caller", "_dropPos", ["_isZeusOverride", false]];

// Dynamically pull and parse the cooldown time from the CBA Settings
private _cooldownTime = parseNumber AAS_Cooldown_CAS; 
private _flightHeight = parseNumber AAS_Height_CAS; // Dynamic Height
private _loiterRadius = parseNumber AAS_Loiter_CAS; // Dynamic Loiter Radius
private _playerSide = side group _caller;

// FIX: If a Virtual Zeus calls this, dynamically adopt the side of the nearest real player.
if (_playerSide == sideLogic) then {
    private _realPlayers = allPlayers select {side group _x != sideLogic};
    
    if (count _realPlayers > 0) then {
        private _nearestPlayers = [_realPlayers, [], { _x distance2D _dropPos }, "ASCEND"] call BIS_fnc_sortBy;
        _playerSide = side group (_nearestPlayers select 0); 
    } else {
        _playerSide = WEST; 
    };
};

// --- 1. COOLDOWN CHECK ---
private _lastUse = missionNamespace getVariable ["AAS_CAS_LastUseTime", -99999];

if (!_isZeusOverride && {serverTime < (_lastUse + _cooldownTime)}) exitWith {
    private _timeLeft = round(((_lastUse + _cooldownTime) - serverTime) / 60);
    (format ["HQ: CAS on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// --- 2. DYNAMIC ECONOMY CHECK ---
private _econPass = true; // Assume true by default for Zeus

if (!_isZeusOverride) then {
    // Dynamically parsed from CBA settings based on the active global preset
    private _cost = switch (AAS_Econ_Preset_Core) do {
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
    
    // Call the Central Economy Manager to do the math and check the preset
    _econPass = [_caller, _cost, AAS_Econ_Preset_Core, AAS_Econ_Code_CAS] call AAS_fnc_setEconomyPreset;
};

if (!_econPass) exitWith {};

// --- 3. FINALIZE SUPPORT ---
if (!_isZeusOverride) then {
    missionNamespace setVariable ["AAS_CAS_LastUseTime", serverTime, true];
};

"HQ: Close Air Support near your position. Keep your heads down." remoteExec ["systemChat", _caller];
"AAS_Voice_CAS" remoteExec ["playSound", _caller]; 

// =========================================================================
// --- 4. SPAWN AIRCRAFT & APPLY CUSTOM LOADOUTS ---
// =========================================================================
private _spawnDist = 3000;
private _spawnPos = _dropPos getPos [_spawnDist, random 360];

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

// Parse Aircraft Class & Loadout safely
private _airParsed = [AAS_Heli_CAS] call _fnc_parseClass;
private _airClass = _airParsed select 0;
private _customLoadout = _airParsed select 1;

// Determine if the user pasted a Plane instead of a Helicopter
private _isPlane = _airClass isKindOf "Plane";

// --- GUNSHIP IDENTIFICATION & GEOMETRY OVERRIDE ---
private _isGunship = missionNamespace getVariable ["AAS_CAS_CounterClockwise", false];
if (!_isGunship && {(_airClass isKindOf "V44_Base_F" || {_airClass find "AC130" > -1} || {_airClass find "Gunship" > -1})}) then {
    _isGunship = true;
};

// Adjust spawn altitude to prevent collisions or guarantee depression angles
if (_isPlane) then { _flightHeight = _flightHeight max 400; };
if (_isGunship) then {
    _flightHeight = 500; 
    _loiterRadius = 1100; 
};

_spawnPos set [2, _flightHeight]; 

// Spawn the vehicle
private _airData = [_spawnPos, _spawnPos getDir _dropPos, _airClass, _playerSide] call BIS_fnc_spawnVehicle;
private _aircraft = _airData select 0;
private _airGroup = _airData select 2;

// Inject forward momentum so planes don't instantly stall on spawn
if (_isPlane) then {
    _aircraft setVelocityModelSpace [0, 150, 0]; // ~540 km/h push
};

// --- APPLY THE PERSONALIZED LOADOUT ---
if (_customLoadout isNotEqualTo false) then {
    if (_customLoadout isEqualType []) then { _aircraft setUnitLoadout _customLoadout; };
    if (_customLoadout isEqualType "") then { _aircraft call compile _customLoadout; };
};

_aircraft allowDamage false; 
_aircraft flyInHeight _flightHeight;

// --- SILENCE TRACKER (NEW) ---
// We initialize a timer and an Event Handler that constantly tracks when the gunship fires
_aircraft setVariable ["AAS_LastFireTime", serverTime];
_aircraft addEventHandler ["Fired", {
    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
    _unit setVariable ["AAS_LastFireTime", serverTime];
}];

{ 
    private _unit = _x;
    _unit allowDamage false; 
    _unit addRating 100000; 
    [_unit] joinSilent _airGroup;
    
    // Maximize AI aiming stats so they actually hit what they shoot at
    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
} forEach crew _aircraft;

// --- COMBAT BEHAVIOR ---
private _wpAttack = _airGroup addWaypoint [_dropPos, 0];
_airGroup setCombatMode "RED"; // Universal permission to fire

if (_isGunship) then {
    // Gunships need COMBAT to shoot, but we will lobotomize the pilot manually
    _airGroup setBehaviour "COMBAT"; 
    
    _wpAttack setWaypointType "LOITER";
    _wpAttack setWaypointLoiterType "CIRCLE_L"; // Force Counter-Clockwise
    _wpAttack setWaypointLoiterRadius _loiterRadius;
    _wpAttack setWaypointSpeed "LIMITED";
    
    // Completely disable the pilot's combat brain so he strictly flies the loiter path
    private _pilot = driver _aircraft;
    _pilot disableAI "TARGET";
    _pilot disableAI "AUTOTARGET";
    _pilot disableAI "WEAPONAIM";
} else {
    _airGroup setBehaviour "COMBAT";

    // Dynamically assign behavior based on CBA settings and Aircraft Type
    switch (AAS_Behavior_CAS) do {
        case 0: { 
            _wpAttack setWaypointType "LOITER";
            private _radius = if (_isPlane) then { _loiterRadius max 1500 } else { _loiterRadius };
            _wpAttack setWaypointLoiterRadius _radius;
            _wpAttack setWaypointSpeed "NORMAL";
        };
        case 1: { 
            _wpAttack setWaypointType "SAD";
            _wpAttack setWaypointSpeed "NORMAL";
        };
    };
};

// --- ANTI-STUCK FAIL-SAFE THREAD ---
// Planes never get "stuck" hovering, so we only run this for helicopters
if (!_isPlane && !_isGunship) then {
    [_aircraft] spawn {
        params ["_heli"];
        private _lastPos = getPos _heli;
        private _stuckCount = 0;

        while {alive _heli} do {
            sleep 5;
            if ((getPos _heli) distance2D _lastPos < 5) then {
                _stuckCount = _stuckCount + 5;
            } else {
                _stuckCount = 0; 
            };

            if (_stuckCount >= 45) exitWith {
                {deleteVehicle _x} forEach crew _heli;
                deleteVehicle _heli;
            };
            
            _lastPos = getPos _heli;
        };
    };
};

// --- AGGRESSION & TARGETING THREAD (UPGRADED) ---
[_aircraft, _airGroup, _dropPos, _playerSide, _isPlane, AAS_Behavior_CAS, _isGunship, _loiterRadius] spawn {
    params ["_aircraft", "_airGroup", "_dropPos", "_playerSide", "_isPlane", "_behavior", "_isGunship", "_loiterRadius"];
    
    // Set scan radius slightly larger than the orbit radius
    private _scanRadius = _loiterRadius + 500;
    private _lastTarget = objNull;

    while {alive _aircraft && {(_aircraft distance2D _dropPos) < 3500}} do {
        
        // Infinite ammo forced directly into the weapon magazines to prevent reloading pauses
        _aircraft setVehicleAmmo 1;
        
        private _targets = _dropPos nearEntities [["Man", "Car", "Tank", "Ship"], _scanRadius];
        private _validTargets = [];
        
        {
            if (side _x != _playerSide && {side _x != civilian} && {alive _x}) then {
                // Maximize AI knowledge of the target instantly
                _airGroup reveal [_x, 4]; 
                _validTargets pushBack _x;
            };
        } forEach _targets;

        if (count _validTargets > 0) then {
            
            private _sortedTargets = [_validTargets, [], { _x distance2D _aircraft }, "ASCEND"] call BIS_fnc_sortBy;
            private _primaryTarget = _sortedTargets select 0;
            
            if (_isGunship) then {
                private _gunners = (crew _aircraft) - [driver _aircraft];
                
                // Normal AI Targeting
                if (_primaryTarget != _lastTarget || !alive _lastTarget) then {
                    _gunners doTarget _primaryTarget;
                    _gunners doFire _primaryTarget;
                    _lastTarget = _primaryTarget;
                };

                // --- THE DEADLOCK BREAKER ---
                // FIX: Time threshold reduced to 10 seconds. 
                // If 10 seconds have passed without a single shot fired from the vehicle:
                private _lastFired = _aircraft getVariable ["AAS_LastFireTime", serverTime];
                if (serverTime - _lastFired >= 10) then {
                    
                    {
                        private _gunner = _x;
                        private _turret = _aircraft unitTurret _gunner;
                        private _weps = _aircraft weaponsTurret _turret;
                        
                        // Force a random weapon selection to scramble the AI's frozen state
                        if (count _weps > 0) then {
                            private _wep = selectRandom _weps;
                            _gunner selectWeapon _wep;
                            
                            // Force an engine-level shot command directly at the target
                            _aircraft fireAtTarget [_primaryTarget, _wep];
                        };
                    } forEach _gunners;

                    // Reset the timer and memory so they get a fresh 10-second window
                    _aircraft setVariable ["AAS_LastFireTime", serverTime];
                    _lastTarget = objNull; 
                };

            } else {
                (units _airGroup) doTarget _primaryTarget;
                
                // NOSE-ALIGN FIX (SAD MODE ONLY)
                if (!_isPlane && {_behavior == 1} && {(_aircraft distance2D _primaryTarget) < 1000}) then {
                    (driver _aircraft) doWatch _primaryTarget;
                };
            };
        };

        sleep 3; 
    };
};

private _rtbTime = parseNumber AAS_RTB_CAS;

// --- TIMING & BEHAVIOR THREAD ---
[_aircraft, _airGroup, _spawnPos, _rtbTime] spawn {
    params ["_aircraft", "_airGroup", "_spawnPos", "_rtbTime"];

    sleep 120;

    if (alive _aircraft) then {
        _aircraft allowDamage true;
        { if (alive _x) then { _x allowDamage true; }; } forEach crew _aircraft;
    };

    private _remainingTime = _rtbTime - 120;
    if (_remainingTime > 0) then {
        sleep _remainingTime;
    };

    // Force Retreat
    if (alive _aircraft) then {
        while {(count (waypoints _airGroup)) > 0} do { deleteWaypoint ((waypoints _airGroup) select 0); };
        
        _airGroup setBehaviour "CARELESS";
        _airGroup setCombatMode "BLUE";
        
        private _wpAway = _airGroup addWaypoint [_spawnPos, 0];
        _wpAway setWaypointType "MOVE";
        _wpAway setWaypointSpeed "FULL";
        _wpAway setWaypointStatements ["true", "private _v = vehicle this; {deleteVehicle _x} forEach crew _v; deleteVehicle _v;"];
    };
};