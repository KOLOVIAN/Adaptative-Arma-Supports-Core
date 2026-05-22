// functions/fn_serverSupplyDrop.sqf

// Added the third parameter that defaults to false for regular players
params ["_caller", "_dropPos", ["_isZeusOverride", false]];

// Dynamically pull and parse the cooldown time from the CBA Settings
private _cooldownTime = parseNumber AAS_Cooldown_Supply; 
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
private _lastUse = missionNamespace getVariable ["AAS_SupplyDrop_LastUseTime", -99999];

// Bypassed if Zeus is calling
if (!_isZeusOverride && {serverTime < (_lastUse + _cooldownTime)}) exitWith {
    private _timeLeft = round(((_lastUse + _cooldownTime) - serverTime) / 60);
    (format ["HQ: Supply Drop on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// --- 2. DYNAMIC ECONOMY CHECK ---
private _econPass = true; // Assume true by default for Zeus

// Bypassed if Zeus is calling
if (!_isZeusOverride) then {
    // Dynamically parsed from CBA settings based on the active global preset
    private _cost = switch (AAS_Econ_Preset_Core) do {
        case 0: { parseNumber AAS_Cost_Supply_Custom };
        case 1: { parseNumber AAS_Cost_Supply_Antistasi };
        case 2: { 
            [
                parseNumber AAS_Cost_Supply_KPLib_S, 
                parseNumber AAS_Cost_Supply_KPLib_A, 
                parseNumber AAS_Cost_Supply_KPLib_F
            ] 
        };
        case 3: { parseNumber AAS_Cost_Supply_Overthrow };
        case 4: { parseNumber AAS_Cost_Supply_Warlords };
        case 5: { parseNumber AAS_Cost_Supply_DUWS };
        case 6: { parseNumber AAS_Cost_Supply_Antistasi };
        default { 0 };
    };
    
    // Call the Central Economy Manager to do the math and check the preset
    _econPass = [_caller, _cost, AAS_Econ_Preset_Core, AAS_Econ_Code_Supply] call AAS_fnc_setEconomyPreset;
};

// If the manager returns false (insufficient funds or failed custom code), abort!
if (!_econPass) exitWith {};

// --- 3. FINALIZE SUPPORT ---
// Now that they passed the economy check, we start the cooldown timer.
// Only trigger the cooldown tracker if a regular player called it
if (!_isZeusOverride) then {
    missionNamespace setVariable ["AAS_SupplyDrop_LastUseTime", serverTime, true];
};

"HQ: Supply Drop inbound. ETA 1 minute." remoteExec ["systemChat", _caller];
"AAS_Voice_Supply" remoteExec ["playSound", _caller]; // <--- VOICE LINE TRIGGER

// =========================================================================
// --- 4. SPAWN HELICOPTER & SMART PARSER ---
// =========================================================================
private _spawnDist = 2500; 
private _spawnPos = _dropPos getPos [_spawnDist, random 360];
_spawnPos set [2, 100];

// Calculate escape position exactly opposite of the spawn to maintain a straight line
private _dirToDrop = _spawnPos getDir _dropPos;
private _escapePos = _dropPos getPos [3000, _dirToDrop]; 
_escapePos set [2, 100];

if (isNil "AAS_Heli_Supply") then { AAS_Heli_Supply = "O_Heli_Light_02_unarmed_F"; };

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

// Parse Helicopter Class & Loadout safely
private _heliParsed = [AAS_Heli_Supply] call _fnc_parseClass;
private _heliClass = _heliParsed select 0;
private _heliLoadout = _heliParsed select 1;

private _heliData = [_spawnPos, _dirToDrop, _heliClass, _playerSide] call BIS_fnc_spawnVehicle;
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

{ 
    _x allowDamage false; 
    _x addRating 100000; 
} forEach crew _heli;

{ _heliGroup disableAI _x } forEach ["AUTOTARGET", "TARGET", "SUPPRESSION", "AUTOCOMBAT"];

// --- 5. THE SKIP-ACTION WAYPOINTS ---
_heli flyInHeight 100; // Raised to 100m to force the AI to ignore ground pathfinding

// Waypoint 1: Dead center on the LZ
private _wpDrop = _heliGroup addWaypoint [_dropPos, 0];
_wpDrop setWaypointType "MOVE";
_wpDrop setWaypointSpeed "FULL"; 
// The AI considers this waypoint finished at 200m, preventing any braking deceleration
_wpDrop setWaypointCompletionRadius 200; 

// Waypoint 2: The Escape Route
private _wpEscape = _heliGroup addWaypoint [_escapePos, 1];
_wpEscape setWaypointType "MOVE";
_wpEscape setWaypointSpeed "FULL"; 
_wpEscape setWaypointStatements ["true", "private _v = vehicle this; {deleteVehicle _x} forEach crew _v; deleteVehicle _v;"];

// --- 6. ANTI-STUCK FAIL-SAFE THREAD ---
[_heli] spawn {
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

        if (_stuckCount >= 60) exitWith { 
            {deleteVehicle _x} forEach crew _heli;
            deleteVehicle _heli;
        };
        
        _lastPos = getPos _heli;
    };
};

// --- 7. DROP & SMART CRATE THREAD ---
[_heli, _dropPos] spawn {
    params ["_heli", "_dropPos"];

    waitUntil { sleep 0.1; (_heli distance2D _dropPos) < 75 || !alive _heli };

    if (alive _heli) then {
        
        private _crate = createVehicle ["IG_supplyCrate_F", [getPos _heli select 0, getPos _heli select 1, (getPos _heli select 2) - 5], [], 0, "CAN_COLLIDE"];
        _crate setVelocity [0, 0, -5]; 
        
        clearWeaponCargoGlobal _crate;
        clearMagazineCargoGlobal _crate;
        clearItemCargoGlobal _crate;
        clearBackpackCargoGlobal _crate;

        _crate addItemCargoGlobal ["FirstAidKit", 15];
        _crate addMagazineCargoGlobal ["HandGrenade", 5];
        _crate addItemCargoGlobal ["ToolKit", 1];
        _crate addItemCargoGlobal ["Medikit", 1];
        _crate addItemCargoGlobal ["ItemGPS", 1];
        _crate addItemCargoGlobal ["ItemRadio", 1];
        _crate addItemCargoGlobal ["NVGoggles_OPFOR", 3];

        private _nearestPlayers = [allPlayers, [], { _x distance2D _dropPos }, "ASCEND"] call BIS_fnc_sortBy;
        if (count _nearestPlayers > 5) then { _nearestPlayers resize 5; };

        {
            private _unit = _x;
            private _pWeapon = primaryWeapon _unit;
            if (_pWeapon != "") then {
                private _pMags = getArray (configFile >> "CfgWeapons" >> _pWeapon >> "magazines");
                if (count _pMags > 0) then { _crate addMagazineCargoGlobal [_pMags select 0, 15]; };
            };
            private _lWeapon = secondaryWeapon _unit;
            if (_lWeapon != "") then {
                private _lMags = getArray (configFile >> "CfgWeapons" >> _lWeapon >> "magazines");
                if (count _lMags > 0) then { _crate addMagazineCargoGlobal [_lMags select 0, 3]; };
            };
        } forEach _nearestPlayers;

        private _chute = createVehicle ["B_Parachute_02_F", getPos _crate, [], 0, "FLY"];
        _chute setObjectScale 0.5; 
        _chute setPos getPos _crate;
        _crate attachTo [_chute, [0, 0, 0]];
        
        [_crate, _chute] spawn {
            params ["_crate", "_chute"];
            waitUntil { sleep 0.5; (getPos _crate select 2) < 2 };
            detach _crate;
            sleep 5;
            deleteVehicle _chute;
        };
    };
};
