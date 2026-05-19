// functions/fn_serverReinforcements.sqf

// Added the third parameter that defaults to false for regular players
params ["_caller", "_dropPos", ["_isZeusOverride", false]];

// Dynamically pull and parse the cooldown time from the CBA Settings
private _cooldownTime = parseNumber AAS_Cooldown_Reinf; 
private _playerSide = side group _caller;

// FIX: If a Virtual Zeus calls this, dynamically adopt the side of the nearest real player.
if (_playerSide == sideLogic) then {
    // Get all players that actually have a physical body (not other Zeus cameras)
    private _realPlayers = allPlayers select {side group _x != sideLogic};
    
    if (count _realPlayers > 0) then {
        // Sort them by who is closest to the module's drop location
        private _nearestPlayers = [_realPlayers, [], { _x distance2D _dropPos }, "ASCEND"] call BIS_fnc_sortBy;
        _playerSide = side group (_nearestPlayers select 0); // Inherit the side of the nearest player
    } else {
        // Absolute fail-safe in case the server has zero actual players logged in
        _playerSide = WEST; 
    };
};

// --- 1. COOLDOWN CHECK ---
// We do this FIRST so they don't lose money if the support isn't ready.
// Set to -99999 to match the initServer changes
private _lastUse = missionNamespace getVariable ["AAS_Reinf_LastUseTime", -99999];

// Bypassed if Zeus is calling
if (!_isZeusOverride && {serverTime < (_lastUse + _cooldownTime)}) exitWith {
    private _timeLeft = round(((_lastUse + _cooldownTime) - serverTime) / 60);
    (format ["HQ: Reinforcements on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// --- 2. DYNAMIC ECONOMY CHECK ---
private _econPass = true; // Assume true by default for Zeus

// Bypassed if Zeus is calling
if (!_isZeusOverride) then {
    // Dynamically parsed from CBA settings based on the active global preset
    private _cost = switch (AAS_Econ_Preset_Core) do {
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
    
    // Ask the Economy Manager if they can afford it based on their CBA settings
    _econPass = [_caller, _cost, AAS_Econ_Preset_Core, AAS_Econ_Code_Reinf] call AAS_fnc_setEconomyPreset;
};

// If the manager returns false (insufficient funds or failed custom code), abort!
if (!_econPass) exitWith {};

// --- 3. FINALIZE SUPPORT ---
// Now that they passed the economy check, we start the cooldown timer.
// Only trigger the cooldown tracker if a regular player called it
if (!_isZeusOverride) then {
    missionNamespace setVariable ["AAS_Reinf_LastUseTime", serverTime, true];
};

"HQ: Reinforcements inbound. Secure the LZ." remoteExec ["systemChat", _caller];
"AAS_Voice_Reinf" remoteExec ["playSound", _caller];

// =========================================================================
// --- 4. SPAWN HELIPAD & SMART PARSER ---
// =========================================================================
private _helipad = createVehicle ["Land_HelipadEmpty_F", _dropPos, [], 0, "NONE"];

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

// --- SPAWN TRANSPORT HELICOPTER ---
private _spawnDist = 2000;
private _spawnPos = _dropPos getPos [_spawnDist, random 360];
_spawnPos set [2, 150];

// Parse Helicopter Class & Loadout safely
private _heliParsed = [AAS_Heli_Reinf] call _fnc_parseClass;
private _heliClass = _heliParsed select 0;
private _heliLoadout = _heliParsed select 1;

private _heliData = [_spawnPos, _spawnPos getDir _dropPos, _heliClass, _playerSide] call BIS_fnc_spawnVehicle;
private _heli = _heliData select 0;
private _heliGroup = _heliData select 2;

// Apply Custom Eden/Garage Helicopter Code (if pasted)
if (_heliLoadout isNotEqualTo false) then {
    if (_heliLoadout isEqualType []) then { _heli setUnitLoadout _heliLoadout; };
    if (_heliLoadout isEqualType "") then { _heli call compile _heliLoadout; };
};

_heli allowDamage false;
_heliGroup setBehaviour "CARELESS"; 
_heliGroup setCombatMode "BLUE"; 

// The Pilot Fix: Immortal and Bulletproof Faction Logic
{ 
    _x allowDamage false; 
    _x addRating 100000; 
    [_x] joinSilent _heliGroup;
} forEach crew _heli;

{ _heliGroup disableAI _x } forEach ["AUTOTARGET", "TARGET", "SUPPRESSION", "AUTOCOMBAT"];


// --- SPAWN ELITE SQUAD ---
private _reinfGroup = createGroup (side group _caller);
private _squad = [];

// Grab the raw settings
private _rawUnitTypes = [AAS_Reinf_SL, AAS_Reinf_MG, AAS_Reinf_AT, AAS_Reinf_Sniper];

for "_i" from 0 to 3 do {
    // Parse the individual soldier's classname and Virtual Arsenal export
    private _unitParsed = [_rawUnitTypes select _i] call _fnc_parseClass;
    private _unitClass = _unitParsed select 0;
    private _unitLoadout = _unitParsed select 1;

    private _unit = _reinfGroup createUnit [_unitClass, _spawnPos, [], 0, "NONE"];
    
    // Apply Virtual Arsenal Custom Gear (if pasted)
    if (_unitLoadout isNotEqualTo false) then {
        if (_unitLoadout isEqualType []) then { _unit setUnitLoadout _unitLoadout; };
        if (_unitLoadout isEqualType "") then { _unit call compile _unitLoadout; };
    };

    // Immortal from the exact moment of creation to survive the flight.
    _unit allowDamage false;
    
    _unit addRating 100000; 
    [_unit] joinSilent _reinfGroup; 
    _unit setCaptive false; 

    // Keep the max skills so they are still highly lethal, regardless of what gear they spawn with
    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];

    _unit moveInCargo _heli;
    _squad pushBack _unit;
};

// Landing Waypoint
private _wpLand = _heliGroup addWaypoint [_dropPos, 0];
_wpLand setWaypointType "MOVE";
_wpLand setWaypointStatements ["true", "(vehicle this) land 'LAND';"];

// --- ANTI-STUCK FAIL-SAFE THREAD ---
// Checks every 5 seconds. If stuck for 45s while engine is ON, deletes the helicopter.
// FIX: _squad passed to the thread to separate troop survival from the helicopter.
[_heli, _squad] spawn {
    params ["_heli", "_squad"];
    private _lastPos = getPos _heli;
    private _stuckCount = 0;

    while {alive _heli} do {
        sleep 5;
        
        // Only count as stuck if the engine is running
        if (isEngineOn _heli) then {
            if ((getPos _heli) distance2D _lastPos < 5) then {
                _stuckCount = _stuckCount + 5;
            } else {
                _stuckCount = 0; // Reset if moving normally
            };
        } else {
            // Engine is off (helicopter is unloading troops). Suspend the timer.
            _stuckCount = 0;
        };

        // If stuck for 45 seconds, delete it to free server resources
        if (_stuckCount >= 45) exitWith {
            // FIX: Exclude the spawned squad members from deletion!
            {
                if (!(_x in _squad)) then { deleteVehicle _x; };
            } forEach crew _heli;
            
            deleteVehicle _heli;
        };
        
        _lastPos = getPos _heli;
    };
};

// Parse the total RTB (Despawn) time to pass into the thread
private _rtbTime = parseNumber AAS_RTB_Reinf;

// --- LANDING & EXTRACTION THREAD ---
// Passed _caller and _rtbTime into the thread array
[_heli, _heliGroup, _reinfGroup, _squad, _spawnPos, _helipad, _dropPos, _caller, _rtbTime] spawn {
    params ["_heli", "_heliGroup", "_reinfGroup", "_squad", "_spawnPos", "_helipad", "_dropPos", "_caller", "_rtbTime"];

    waitUntil { sleep 0.1; (getPosVisual _heli select 2) < 1.5 || !alive _heli };
    
    // Engine turns OFF here, automatically pausing the failsafe timer
    _heli engineOn false; 
    sleep 1;

    {
        unassignVehicle _x;
        _x action ["GetOut", _heli]; 
        sleep 0.8; 
    } forEach _squad;

    waitUntil { sleep 0.5; ({alive _x && _x in _heli} count _squad) == 0 || !alive _heli };
    
    // --- DYNAMIC SQUAD BEHAVIOR ---
    switch (AAS_Behavior_Reinf) do {
        case 0: {
            // Guard LZ - High Aggression
            _reinfGroup setCombatMode "RED";
            _reinfGroup setBehaviour "COMBAT";
            
            private _wpGuard = _reinfGroup addWaypoint [_dropPos, 0];
            _wpGuard setWaypointType "GUARD";
        };
        case 1: {
            // Follow Player - Vanilla Dynamic Scaling
            // "AWARE" keeps them upright and chill, but ready to return fire.
            _reinfGroup setCombatMode "YELLOW";
            _reinfGroup setBehaviour "AWARE";
            
            // The squad merges into the caller's group and adopts the player's pace
            _squad joinSilent (group _caller);
        };
        case 2: {
            // Rush Enemies - High Aggression
            _reinfGroup setCombatMode "RED";
            _reinfGroup setBehaviour "COMBAT";
            
            private _wpSAD = _reinfGroup addWaypoint [_dropPos, 0];
            _wpSAD setWaypointType "SAD";
        };
    };

    sleep 2;
    
    // Engine turns ON here, failsafe resumes watching its back!
    _heli engineOn true;
    
    while {(count (waypoints _heliGroup)) > 0} do { deleteWaypoint ((waypoints _heliGroup) select 0); };
    private _wpAway = _heliGroup addWaypoint [_spawnPos, 0];
    _wpAway setWaypointType "MOVE";
    _wpAway setWaypointSpeed "FULL";
    _wpAway setWaypointStatements ["true", "private _v = vehicle this; {deleteVehicle _x} forEach crew _v; deleteVehicle _v;"];
    
    deleteVehicle _helipad;

    // FIX APPLIED HERE: 120-second boots-on-the-ground combat buff begins now.
    sleep 120;
    { if (alive _x) then { _x allowDamage true; }; } forEach _squad; // Mortality restored.
    
    // FIX: Completely bypass extraction if the user entered a permanent duration (99999 or -1)
    if (_rtbTime >= 99999 || _rtbTime < 0) exitWith {};

    // Calculate remaining time before the squad despawns
    private _remainingTime = _rtbTime - 120;
    if (_remainingTime > 0) then {
        sleep _remainingTime;
    };

    // Despawn the surviving members
    { if (alive _x) then { deleteVehicle _x; }; } forEach _squad;
};