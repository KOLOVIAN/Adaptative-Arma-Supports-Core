// functions/fn_serverCAS.sqf

// We keep the 3rd parameter to absorb the remoteExec payload, but ignore the old Zeus override.
// The 4th parameter is our new support tag.
params ["_caller", "_dropPos", "_ignoredZeus", ["_casType", "HELI"]];

private _playerSide = side group _caller;

// --- 0. DYNAMIC VARIABLE ASSIGNMENT ---
private _airClassRaw = "";
private _behaviorMode = 0;
private _flightHeight = 150;
private _loiterRadius = 400;
private _costMultStr = "1.0";
private _isGunship = false;
private _isPlane = false;
private _forceOrbit = false;

// Map the correct CBA settings based on the tag passed from the client
switch (_casType) do {
    case "PLANE": {
        _airClassRaw = AAS_CAS_Plane_Class;
        _behaviorMode = AAS_CAS_Plane_Behavior;
        _flightHeight = 400; // Planes need a safe baseline
        _loiterRadius = 1500;
        _costMultStr = AAS_CAS_Plane_CostMult;
        _isPlane = true;
    };
    case "HELI": {
        _airClassRaw = AAS_CAS_Heli_Class;
        _behaviorMode = AAS_CAS_Heli_Behavior;
        _flightHeight = parseNumber AAS_CAS_Heli_Height;
        _loiterRadius = parseNumber AAS_CAS_Heli_Radius;
        _costMultStr = AAS_CAS_Heli_CostMult;
    };
    case "GUNSHIP": {
        _airClassRaw = AAS_CAS_Gunship_Class;
        _behaviorMode = 0; // Gunships ALWAYS loiter
        _flightHeight = parseNumber AAS_CAS_Gunship_Height;
        _loiterRadius = parseNumber AAS_CAS_Gunship_Radius;
        _costMultStr = AAS_CAS_Gunship_CostMult;
        _forceOrbit = AAS_CAS_Gunship_Orbit;
        _isGunship = true;
    };
};

// --- 1. COOLDOWN CHECK ---
private _cooldownTime = parseNumber AAS_Cooldown_CAS; 
private _lastUse = missionNamespace getVariable ["AAS_CAS_LastUseTime", -99999];

if (serverTime < (_lastUse + _cooldownTime)) exitWith {
    private _timeLeft = round(((_lastUse + _cooldownTime) - serverTime) / 60);
    (format ["HQ: CAS on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// --- 2. DYNAMIC ECONOMY CHECK ---
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
private _econPass = [_caller, _finalCost, AAS_Econ_Preset_Core, AAS_Econ_Code_CAS] call AAS_fnc_setEconomyPreset;
if (!_econPass) exitWith {};

// --- 3. FINALIZE SUPPORT ---
missionNamespace setVariable ["AAS_CAS_LastUseTime", serverTime, true];

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
private _airParsed = [_airClassRaw] call _fnc_parseClass;
private _airClass = _airParsed select 0;
private _customLoadout = _airParsed select 1;

// Failsafe: Detect if a user pasted a plane into a helicopter box
if (!_isPlane && {_airClass isKindOf "Plane"}) then { 
    _isPlane = true; 
    if (!_isGunship) then { _flightHeight = _flightHeight max 400; };
};

_spawnPos set [2, _flightHeight]; 

// Spawn the vehicle
private _airData = [_spawnPos, _spawnPos getDir _dropPos, _airClass, _playerSide] call BIS_fnc_spawnVehicle;
private _aircraft = _airData select 0;
private _airGroup = _airData select 2;

// Inject forward momentum so fixed-wing aircraft don't instantly stall
if (_isPlane && !_isGunship) then {
    _aircraft setVelocityModelSpace [0, 150, 0]; // ~540 km/h push
};

// --- APPLY THE PERSONALIZED LOADOUT ---
if (_customLoadout isNotEqualTo false) then {
    if (_customLoadout isEqualType []) then { _aircraft setUnitLoadout _customLoadout; };
    if (_customLoadout isEqualType "") then { _aircraft call compile _customLoadout; };
};

_aircraft allowDamage false; 
_aircraft flyInHeight _flightHeight;

// --- SILENCE TRACKER ---
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
    
    // Maximize AI aiming stats
    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
} forEach crew _aircraft;

// --- COMBAT BEHAVIOR ---
private _wpAttack = _airGroup addWaypoint [_dropPos, 0];
_airGroup setCombatMode "RED"; 

if (_isGunship) then {
    _airGroup setBehaviour "COMBAT"; 
    
    _wpAttack setWaypointType "LOITER";
    if (_forceOrbit) then { _wpAttack setWaypointLoiterType "CIRCLE_L"; }; 
    _wpAttack setWaypointLoiterRadius _loiterRadius;
    _wpAttack setWaypointSpeed "LIMITED";
    
    // Lobotomize the pilot to strictly fly the loiter path
    if (_forceOrbit) then {
        private _pilot = driver _aircraft;
        _pilot disableAI "TARGET";
        _pilot disableAI "AUTOTARGET";
        _pilot disableAI "WEAPONAIM";
    };
} else {
    _airGroup setBehaviour "COMBAT";

    switch (_behaviorMode) do {
        case 0: { 
            _wpAttack setWaypointType "LOITER";
            _wpAttack setWaypointLoiterRadius _loiterRadius;
            _wpAttack setWaypointSpeed "NORMAL";
        };
        case 1: { 
            _wpAttack setWaypointType "SAD";
            _wpAttack setWaypointSpeed "NORMAL";
        };
    };
};

// --- ANTI-STUCK FAIL-SAFE THREAD ---
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

// --- AGGRESSION & TARGETING THREAD ---
[_aircraft, _airGroup, _dropPos, _playerSide, _isPlane, _behaviorMode, _isGunship, _loiterRadius] spawn {
    params ["_aircraft", "_airGroup", "_dropPos", "_playerSide", "_isPlane", "_behavior", "_isGunship", "_loiterRadius"];
    
    private _scanRadius = _loiterRadius + 500;
    private _lastTarget = objNull;

    while {alive _aircraft && {(_aircraft distance2D _dropPos) < 3500}} do {
        
        // Infinite ammo to prevent reloading pauses
        _aircraft setVehicleAmmo 1;
        
        private _targets = _dropPos nearEntities [["Man", "Car", "Tank", "Ship"], _scanRadius];
        private _validTargets = [];
        
        {
            if (side _x != _playerSide && {side _x != civilian} && {alive _x}) then {
                _airGroup reveal [_x, 4]; 
                _validTargets pushBack _x;
            };
        } forEach _targets;

        if (count _validTargets > 0) then {
            
            private _sortedTargets = [_validTargets, [], { _x distance2D _aircraft }, "ASCEND"] call BIS_fnc_sortBy;
            private _primaryTarget = _sortedTargets select 0;
            
            if (_isGunship) then {
                private _gunners = (crew _aircraft) - [driver _aircraft];
                
                if (_primaryTarget != _lastTarget || !alive _lastTarget) then {
                    _gunners doTarget _primaryTarget;
                    _gunners doFire _primaryTarget;
                    _lastTarget = _primaryTarget;
                };

                // --- THE DEADLOCK BREAKER ---
                private _lastFired = _aircraft getVariable ["AAS_LastFireTime", serverTime];
                if (serverTime - _lastFired >= 10) then {
                    
                    {
                        private _gunner = _x;
                        private _turret = _aircraft unitTurret _gunner;
                        private _weps = _aircraft weaponsTurret _turret;
                        
                        if (count _weps > 0) then {
                            private _wep = selectRandom _weps;
                            _gunner selectWeapon _wep;
                            _aircraft fireAtTarget [_primaryTarget, _wep];
                        };
                    } forEach _gunners;

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

    sleep 120; // 2 minutes invulnerability window

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