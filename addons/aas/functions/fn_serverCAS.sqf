// functions/fn_serverCAS.sqf

// We keep the 3rd parameter to absorb the remoteExec payload
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

// Infinite Ammo Tracker: Prevents the AI from abandoning the AO to rearm
_aircraft addEventHandler ["Fired", {
    params ["_unit"];
    _unit setVehicleAmmo 1;
}];

{ 
    private _unit = _x;
    _unit allowDamage false; 
    _unit addRating 100000; 
    [_unit] joinSilent _airGroup;
    
    // Maximize AI aiming stats
    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
} forEach crew _aircraft;


// =========================================================================
// --- 5. VANILLA COMBAT BEHAVIOR ---
// =========================================================================
private _wpAttack = _airGroup addWaypoint [_dropPos, 0];
_airGroup setCombatMode "RED"; 
_airGroup setBehaviour "COMBAT"; 

switch (_behaviorMode) do {
    case 0: { 
        _wpAttack setWaypointType "LOITER";
        _wpAttack setWaypointLoiterRadius _loiterRadius;
        _wpAttack setWaypointSpeed "NORMAL";
        // Only apply Counter-Clockwise override if it is a gunship and the box is checked
        if (_isGunship && _forceOrbit) then { 
            _wpAttack setWaypointLoiterType "CIRCLE_L"; 
        };
    };
    case 1: { 
        _wpAttack setWaypointType "SAD";
        _wpAttack setWaypointSpeed "NORMAL";
    };
};

// --- ANTI-STUCK FAIL-SAFE THREAD ---
// Ensures helicopters don't get stuck hovering over a tree forever
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

// --- DYNAMIC AWARENESS THREAD ---
[_aircraft, _airGroup, _dropPos, _playerSide, _loiterRadius] spawn {
    params ["_aircraft", "_airGroup", "_dropPos", "_playerSide", "_loiterRadius"];
    
    while {alive _aircraft} do {
        // Find everything in a wide area around the target zone
        private _targets = _dropPos nearEntities [["Man", "Car", "Tank", "Ship"], _loiterRadius + 500];
        
        {
            // Only reveal non-friendly, non-civilian targets
            if (side _x != _playerSide && {side _x != civilian} && {alive _x}) then {
                // Instantly inject the target into their sensor data
                _airGroup reveal [_x, 4]; 
            };
        } forEach _targets;

        sleep 5; // Refresh every 5 seconds to keep the "memory" fresh
    };
};

private _rtbTime = parseNumber AAS_RTB_CAS;

// --- TIMING & EXTRACTION THREAD ---
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