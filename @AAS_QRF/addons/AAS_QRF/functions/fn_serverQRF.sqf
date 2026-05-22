// AAS-QRF/functions/fn_serverQRF.sqf
/*
    Author: vd
    Description: Spawns a massive multi-domain QRF (Pre-deployment, Air, Ground, Sea).
    REROUTED: Now uses Main AAS Core Economy Logic & Smart Parsers.
*/

params ["_caller", "_dropPos", ["_isZeusOverride", false]];

if (!isServer) exitWith {};

// FIX: If a Virtual Zeus calls this, dynamically adopt the side of the nearest real player.
private _playerSide = side group _caller;
if (_playerSide == sideLogic) then {
    private _realPlayers = allPlayers select {side group _x != sideLogic};
    if (count _realPlayers > 0) then {
        _playerSide = side group (_realPlayers select 0);
    } else {
        _playerSide = west; // Fallback if no players exist
    };
};

// FIX: Antistasi Undercover Bug
if (_playerSide == civilian) then {
    _playerSide = independent; // Default Arma 3 rebel side
    if (!isNil "teamPlayer") then { _playerSide = teamPlayer; }; // Antistasi Ultimate compat
};

// ==========================================
// --- 0. HELPERS ---
// ==========================================

private _fnc_garbageCollect = {
    params ["_vehicle"];
    [_vehicle] spawn {
        params ["_veh"];
        private _crew = crew _veh;
        waitUntil { sleep 10; !alive _veh || isNull _veh };
        if (isNull _veh) exitWith {}; 
        sleep 300; 
        { deleteVehicle _x; } forEach _crew;
        deleteVehicle _veh;
    };
};

private _fnc_forceSide = {
    params ["_units", "_targetSide", "_oldGrp"];
    private _newGrp = createGroup [_targetSide, true];
    _units joinSilent _newGrp;
    if (!isNil "_oldGrp" && {!isNull _oldGrp}) then { deleteGroup _oldGrp; };
    _newGrp
};

private _fnc_protectVehicle = {
    params ["_veh"];
    _veh allowDamage false;
    { _x allowDamage false; _x addRating 100000; } forEach crew _veh;
    
    [_veh] spawn {
        params ["_v"];
        sleep 120;
        if (alive _v) then {
            _v allowDamage true;
            { _x allowDamage true; } forEach crew _v;
        };
    };
    
    _veh addEventHandler ["Killed", {
        params ["_unit"];
        { 
            _x allowDamage true; 
            _x setDamage 1; 
        } forEach crew _unit;
    }];
};

// --- SMART PARSER HELPER FUNCTION ---
private _fnc_parseClass = {
    params ["_rawSetting"];
    private _class = _rawSetting;
    private _loadout = false; // FIX: Use false instead of nil
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
// --- 1. COOLDOWN & ECONOMY (REROUTED) ---
// ==========================================
private _cooldownTime = parseNumber AQR_Cooldown_QRF;
private _lastUse = missionNamespace getVariable ["AAS_QRF_LastUseTime", -99999];

if (!_isZeusOverride && {serverTime < (_lastUse + _cooldownTime)}) exitWith {
    private _timeLeft = round(((_lastUse + _cooldownTime) - serverTime) / 60);
    (format ["HQ: QRF on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

private _econPass = true; // Assume true by default for Zeus

if (!_isZeusOverride) then {
    // Dynamically parsed from QRF settings but following the GLOBAL Core Preset
    private _cost = switch (AAS_Econ_Preset_Core) do {
        case 0: { parseNumber AQR_Cost_QRF_Custom };
        case 1: { parseNumber AQR_Cost_QRF_Antistasi };
        case 2: { 
            // KP Liberation: Pack the 3 QRF specific thresholds into an array
            [
                parseNumber (missionNamespace getVariable ["AQR_Cost_QRF_KPLib_S", "350"]), 
                parseNumber (missionNamespace getVariable ["AQR_Cost_QRF_KPLib_A", "350"]), 
                parseNumber (missionNamespace getVariable ["AQR_Cost_QRF_KPLib_F", "350"])
            ] 
        };
        case 3: { parseNumber AQR_Cost_QRF_Overthrow };
        case 4: { parseNumber AQR_Cost_QRF_Warlords };
        case 5: { parseNumber AQR_Cost_QRF_DUWS };
        case 6: { parseNumber AQR_Cost_QRF_Antistasi };
        default { 0 };
    };
    
    // REROUTED: Calling the Main AAS Economy Manager
    _econPass = [_caller, _cost, AAS_Econ_Preset_Core, AQR_Econ_Code] call aas_core_fnc_setEconomyPreset;
};

// Abort if economy check fails
if (isNil "_econPass" || {!_econPass}) exitWith {};

// Start cooldown
if (!_isZeusOverride) then { 
    missionNamespace setVariable ["AAS_QRF_LastUseTime", serverTime, true]; 
};

private _qrfResponses = [
    ["HQ: Copy that, dispatching QRF to your position. Hold tight, over.", "AQR_Voice_HQ_QRF1"],
    ["HQ: Request received, Quick Reaction Force inbound.", "AQR_Voice_HQ_QRF2"]
];
private _selectedResponse = selectRandom _qrfResponses;
(_selectedResponse select 0) remoteExec ["systemChat", _caller];
(_selectedResponse select 1) remoteExec ["playSound", _caller];

// ==========================================
// --- MASTER TIMING & DEPLOYMENT THREAD ---
// ==========================================
[_dropPos, _playerSide, _caller, _fnc_garbageCollect, _fnc_forceSide, _fnc_protectVehicle, _fnc_parseClass] spawn {
    params ["_dropPos", "_playerSide", "_caller", "_fnc_garbageCollect", "_fnc_forceSide", "_fnc_protectVehicle", "_fnc_parseClass"];

    sleep 10; // <--- THIS IS THE 10 SECOND DELAY

    // ==========================================
    // --- ELEMENT 1: PRE-DEPLOYMENT ---
    // ==========================================
    if (AQR_Toggle_PreDep) then {
        [_dropPos, _playerSide, _fnc_garbageCollect, _fnc_forceSide, _fnc_protectVehicle, _fnc_parseClass] spawn {
            params ["_dropPos", "_playerSide", "_fnc_garbageCollect", "_fnc_forceSide", "_fnc_protectVehicle", "_fnc_parseClass"];
            
            private _approachDir = random 360;
            private _spawnPos = _dropPos getPos [2000, _approachDir];
            _spawnPos set [2, 200];
            
            // Smart Parser
            private _planeParsed = [AQR_Plane_Class] call _fnc_parseClass;
            private _planeClass = _planeParsed select 0;
            private _planeLoadout = _planeParsed select 1;
            
            private _planeData = [_spawnPos, (_approachDir - 180), _planeClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _plane = _planeData select 0;
            private _planeGroup = [crew _plane, _playerSide, _planeData select 2] call _fnc_forceSide;
            
            if (_planeLoadout isNotEqualTo false) then {
                if (_planeLoadout isEqualType []) then { _plane setUnitLoadout _planeLoadout; };
                if (_planeLoadout isEqualType "") then { _plane call compile _planeLoadout; };
            };

            [_plane] call _fnc_garbageCollect;
            [_plane] call _fnc_protectVehicle;

            _planeGroup setBehaviour "CARELESS";
            _plane flyInHeight 150;
            _plane setVelocityModelSpace [0, 150, 0]; 

            private _wpFly = _planeGroup addWaypoint [_dropPos, 0];
            _wpFly setWaypointType "MOVE";
            
            private _exitPos = _dropPos getPos [3000, (_approachDir - 180)];
            private _wpExit = _planeGroup addWaypoint [_exitPos, 0];
            _wpExit setWaypointType "MOVE";
            _wpExit setWaypointStatements ["true", "{deleteVehicle _x} forEach (crew (vehicle this) + [vehicle this]);"];

            // Failsafe Hard Delete for Plane
            [_plane] spawn {
                params ["_p"];
                sleep 180;
                if (!isNull _p) then { {deleteVehicle _x} forEach crew _p; deleteVehicle _p; };
            };

            [_plane, _dropPos] spawn {
                params ["_plane", "_dropPos"];
                waitUntil { sleep 0.1; (_plane distance2D _dropPos < 400) || !alive _plane };
                while { alive _plane && (_plane distance2D _dropPos < 600) } do {
                    _plane action ["useWeapon", _plane, driver _plane, 0];
                    sleep 0.3; 
                };
            };

            if (AQR_Toggle_Flares && {sunOrMoon < 0.5}) then {
                waitUntil { sleep 0.1; (_plane distance2D _dropPos < 200) || !alive _plane };
                "HQ: Midnight Sun deployed. LZ is illuminated." remoteExec ["systemChat", side _planeGroup];

                private _pos1 = _dropPos getPos [400, _approachDir];       _pos1 set [2, 450]; 
                private _pos2 = +_dropPos;                                 _pos2 set [2, 400]; 
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
                                        sleep 0.01; 
                                    };
                                    deleteVehicle _light;
                                    deleteVehicle _smoke;
                                };
                                sleep 1.5; 
                            } forEach _flarePositions;
                        };
                    }
                ] remoteExec ["BIS_fnc_spawn", 0]; 
            };
        };
    };

    // ==========================================
    // --- ELEMENT 2: AIR ELEMENT ---
    // ==========================================
    if (AQR_Toggle_Air) then {
        [_dropPos, _playerSide, _caller, _fnc_garbageCollect, _fnc_forceSide, _fnc_protectVehicle, _fnc_parseClass] spawn {
            params ["_dropPos", "_playerSide", "_caller", "_fnc_garbageCollect", "_fnc_forceSide", "_fnc_protectVehicle", "_fnc_parseClass"];
            
            private _approachDir = random 360;
            private _spawnPosTrans = _dropPos getPos [1500, _approachDir];
            _spawnPosTrans set [2, 100]; 
            
            // Smart Parser - Heavy Heli
            private _transParsed = [AQR_Heli_Heavy] call _fnc_parseClass;
            private _transClass = _transParsed select 0;
            private _transLoadout = _transParsed select 1;

            private _transData = [_spawnPosTrans, (_approachDir - 180), _transClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _heliTrans = _transData select 0;
            private _groupTrans = [crew _heliTrans, _playerSide, _transData select 2] call _fnc_forceSide;
            
            if (_transLoadout isNotEqualTo false) then {
                if (_transLoadout isEqualType []) then { _heliTrans setUnitLoadout _transLoadout; };
                if (_transLoadout isEqualType "") then { _heliTrans call compile _transLoadout; };
            };

            [_heliTrans] call _fnc_garbageCollect; 
            [_heliTrans] call _fnc_protectVehicle;

            // --- ANTI-STUCK FAIL-SAFE THREAD ---
            [_heliTrans] spawn {
                params ["_heli"];
                private _lastPos = getPos _heli;
                private _stuckCount = 0;

                while {alive _heli} do {
                    sleep 5;
                    if (isEngineOn _heli) then {
                        if ((getPos _heli) distance2D _lastPos < 5) then {
                            _stuckCount = _stuckCount + 5;
                        } else {
                            _stuckCount = 0; 
                        };
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

            _groupTrans setBehaviour "CARELESS"; 
            _heliTrans flyInHeight 50; 

            // Smart Parser - Escort Heli
            private _spawnPosEscort = _spawnPosTrans getPos [100, (_approachDir + 180)];
            _spawnPosEscort set [2, 150];
            
            private _escortParsed = [AQR_Heli_Escort] call _fnc_parseClass;
            private _escortClass = _escortParsed select 0;
            private _escortLoadout = _escortParsed select 1;

            private _escortData = [_spawnPosEscort, (_approachDir - 180), _escortClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _heliEscort = _escortData select 0;
            private _groupEscort = [crew _heliEscort, _playerSide, _escortData select 2] call _fnc_forceSide;
            
            if (_escortLoadout isNotEqualTo false) then {
                if (_escortLoadout isEqualType []) then { _heliEscort setUnitLoadout _escortLoadout; };
                if (_escortLoadout isEqualType "") then { _heliEscort call compile _escortLoadout; };
            };

            [_heliEscort] call _fnc_garbageCollect; 
            [_heliEscort] call _fnc_protectVehicle;
            _groupEscort setBehaviour "COMBAT";

            // Smart Parser - CAS Heli
            private _spawnPosCAS = _dropPos getPos [1500, (_approachDir + 90)];
            _spawnPosCAS set [2, 150];
            
            private _casParsed = [AQR_Heli_CAS] call _fnc_parseClass;
            private _casClass = _casParsed select 0;
            private _casLoadout = _casParsed select 1;

            private _casData = [_spawnPosCAS, (_approachDir - 90), _casClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _heliCAS = _casData select 0;
            private _groupCAS = [crew _heliCAS, _playerSide, _casData select 2] call _fnc_forceSide;
            
            if (_casLoadout isNotEqualTo false) then {
                if (_casLoadout isEqualType []) then { _heliCAS setUnitLoadout _casLoadout; };
                if (_casLoadout isEqualType "") then { _heliCAS call compile _casLoadout; };
            };

            [_heliCAS] call _fnc_garbageCollect; 
            [_heliCAS] call _fnc_protectVehicle;
            _groupCAS setBehaviour "COMBAT";

            private _wpTrans = _groupTrans addWaypoint [_dropPos, 0];
            _wpTrans setWaypointType "MOVE";
            _wpTrans setWaypointSpeed "FULL"; 

            private _wpEscort = _groupEscort addWaypoint [_dropPos, 0];
            _wpEscort setWaypointType "LOITER";
            _wpEscort setWaypointLoiterRadius 150; 

            private _wpCAS = _groupCAS addWaypoint [_dropPos, 0];
            _wpCAS setWaypointType "SAD"; 

            [_heliTrans, _dropPos, _playerSide, _groupTrans, _groupEscort, _spawnPosTrans, _caller, _fnc_forceSide, _fnc_parseClass] spawn {
                params ["_heliTrans", "_dropPos", "_playerSide", "_groupTrans", "_groupEscort", "_spawnPosTrans", "_caller", "_fnc_forceSide", "_fnc_parseClass"];

                private _helipad = "Land_HelipadEmpty_F" createVehicle _dropPos;

                waitUntil { sleep 0.2; (_heliTrans distance2D _dropPos) < 800 || !alive _heliTrans };
                _heliTrans flyInHeight 20;

                waitUntil { sleep 0.2; (_heliTrans distance2D _dropPos) < 300 || !alive _heliTrans };
                if (alive _heliTrans) then {
                    "PILOT: This is Chopper One, got eyes on the target. Going for insertion." remoteExec ["systemChat", _caller];
                    "AQR_Voice_Pilot_QRF1" remoteExec ["playSound", _caller];
                };

                waitUntil { sleep 0.2; (_heliTrans distance2D _dropPos) < 200 || !alive _heliTrans };
                if (alive _heliTrans) then { 
                    _heliTrans land "GET OUT"; 
                    _heliTrans flyInHeight 0;
                };

                waitUntil { sleep 0.2; isTouchingGround _heliTrans || !alive _heliTrans };
                _heliTrans engineOn false; 
                sleep 1.5; 

                private _tempGroup = createGroup [_playerSide, true]; 
                private _unitTypes = [
                    AQR_Squad_SL, AQR_Squad_SL,
                    AQR_Squad_MG, AQR_Squad_MG,
                    AQR_Squad_AT, AQR_Squad_AT,
                    AQR_Squad_Sniper, AQR_Squad_Sniper
                ];
                
                private _spawnedTroops = [];

                for "_i" from 0 to (count _unitTypes - 1) do {
                    // Smart Parser - Air Troops
                    private _unitParsed = [_unitTypes select _i] call _fnc_parseClass;
                    private _class = _unitParsed select 0;
                    private _loadout = _unitParsed select 1;
                    if (isNil "_class" || {!isClass (configFile >> "CfgVehicles" >> _class)}) then { _class = "B_Soldier_F"; };

                    private _exitDir = (getDir _heliTrans) + (if (_i % 2 == 0) then {90} else {270});
                    private _dist = 5 + (_i * 1.5); 
                    private _doorPos = _heliTrans getPos [_dist, _exitDir];
                    
                    private _unit = _tempGroup createUnit [_class, _doorPos, [], 0, "CAN_COLLIDE"];
                    
                    if (_loadout isNotEqualTo false) then {
                        if (_loadout isEqualType []) then { _unit setUnitLoadout _loadout; };
                        if (_loadout isEqualType "") then { _unit call compile _loadout; };
                    };

                    _unit setDir (getDir _heliTrans); 
                    _unit allowDamage false; 
                    _unit addRating 100000; 
                    
                    _unit disableAI "TARGET";
                    _unit disableAI "AUTOTARGET";
                    
                    _unit setCombatMode "RED";
                    _unit setBehaviour "COMBAT";
                    _unit addEventHandler ["Fired", { (_this select 0) setAmmo [currentWeapon (_this select 0), 50]; }];
                    
                    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
                    
                    _spawnedTroops pushBack _unit;
                    sleep 0.4; 
                };

                private _squadGroup = [_spawnedTroops, _playerSide, _tempGroup] call _fnc_forceSide;

                {
                    _x enableAI "TARGET";
                    _x enableAI "AUTOTARGET";
                    _x allowDamage true; 
                } forEach _spawnedTroops;

                _squadGroup allowFleeing 0;
                _squadGroup setSpeedMode "FULL";

                [_squadGroup, _caller] spawn {
                    params ["_grp", "_target"];
                    while {count units _grp > 0 && alive _target} do {
                        while {(count (waypoints _grp)) > 0} do { deleteWaypoint ((waypoints _grp) select 0); };
                        private _wp = _grp addWaypoint [getPos _target, random 30]; 
                        _wp setWaypointType "SAD"; 
                        sleep 15; 
                    };
                };

                sleep 3;
                _heliTrans engineOn true;
                _heliTrans flyInHeight 50;

                private _wpAway = _groupTrans addWaypoint [_spawnPosTrans, 0];
                _wpAway setWaypointType "MOVE";
                _wpAway setWaypointSpeed "FULL";
                _wpAway setWaypointStatements ["true", "{deleteVehicle _x} forEach (crew (vehicle this) + [vehicle this]);"];

                deleteVehicle _helipad;

                // Failsafe Hard Delete for Trans Heli
                [_heliTrans] spawn {
                    params ["_v"];
                    sleep 300; 
                    if (!isNull _v) then { {deleteVehicle _x} forEach crew _v; deleteVehicle _v; };
                };

                [_groupEscort, _spawnPosTrans] spawn {
                    params ["_groupEscort", "_spawnPosTrans"];
                    sleep (parseNumber AQR_RTB_Escort); 
                    if (count units _groupEscort > 0) then {
                        while {(count (waypoints _groupEscort)) > 0} do { deleteWaypoint ((waypoints _groupEscort) select 0); };
                        private _wpEscortAway = _groupEscort addWaypoint [_spawnPosTrans, 0];
                        _wpEscortAway setWaypointType "MOVE";
                        _wpEscortAway setWaypointSpeed "FULL";
                        _wpEscortAway setWaypointStatements ["true", "{deleteVehicle _x} forEach (crew (vehicle this) + [vehicle this]);"];
                        
                        // Failsafe Hard Delete
                        [vehicle leader _groupEscort] spawn {
                            params ["_v"];
                            sleep 300; 
                            if (!isNull _v) then { {deleteVehicle _x} forEach crew _v; deleteVehicle _v; };
                        };
                    };
                };

                [_spawnedTroops] spawn {
                    params ["_spawnedTroops"];
                    sleep (parseNumber AQR_RTB_Troops); 
                    { deleteVehicle _x; } forEach _spawnedTroops; 
                };
            };

            [_heliCAS, _groupCAS, _spawnPosCAS] spawn {
                params ["_heliCAS", "_groupCAS", "_spawnPosCAS"];
                sleep (parseNumber AQR_RTB_CAS); 
                if (alive _heliCAS) then {
                    while {(count (waypoints _groupCAS)) > 0} do { deleteWaypoint ((waypoints _groupCAS) select 0); };
                    private _wpCasAway = _groupCAS addWaypoint [_spawnPosCAS, 0];
                    _wpCasAway setWaypointType "MOVE";
                    _wpCasAway setWaypointSpeed "FULL";
                    _wpCasAway setWaypointStatements ["true", "{deleteVehicle _x} forEach (crew (vehicle this) + [vehicle this]);"];
                    
                    // Failsafe Hard Delete
                    [_heliCAS] spawn {
                        params ["_v"];
                        sleep 300; 
                        if (!isNull _v) then { {deleteVehicle _x} forEach crew _v; deleteVehicle _v; };
                    };
                };
            };
        };
    };
    sleep 45; // <--- The 45 second wait between Air Element and Ground Element

    // ==========================================
    // --- ELEMENT 3: GROUND ELEMENT ---
    // ==========================================
    if (AQR_Toggle_Ground) then {
        [_dropPos, _playerSide, _caller, _fnc_garbageCollect, _fnc_forceSide, _fnc_protectVehicle, _fnc_parseClass] spawn {
            params ["_dropPos", "_playerSide", "_caller", "_fnc_garbageCollect", "_fnc_forceSide", "_fnc_protectVehicle", "_fnc_parseClass"];

            private _approachDir = random 360;
            private _spawnPosAPC = [];
            
            private _allRoads = _dropPos nearRoads 800;
            private _validRoads = _allRoads select {(_x distance2D _dropPos) >= 500 && !(surfaceIsWater (getPos _x))};

            if (count _validRoads > 0) then {
                _spawnPosAPC = getPos (selectRandom _validRoads);
                _approachDir = _dropPos getDir _spawnPosAPC; 
            } else {
                private _attempts = 0;
                private _idealSpawn = _dropPos getPos [300, _approachDir];
                while {surfaceIsWater _idealSpawn && _attempts < 20} do {
                    _approachDir = random 360;
                    _idealSpawn = _dropPos getPos [300, _approachDir];
                    _attempts = _attempts + 1;
                };
                if (surfaceIsWater _idealSpawn) then { _idealSpawn = _dropPos getPos [150, random 360]; };
                
                // Ensure parsing works before findEmptyPosition
                private _apcParsedSearch = [AQR_Ground_APC] call _fnc_parseClass;
                _spawnPosAPC = _idealSpawn findEmptyPosition [0, 150, _apcParsedSearch select 0];
                if (count _spawnPosAPC == 0) then { _spawnPosAPC = _idealSpawn; }; 
            };
            
            private _spawnPosTurret = _spawnPosAPC getPos [40, _approachDir + 180];

            // Smart Parser - Ground APC
            private _apcParsed = [AQR_Ground_APC] call _fnc_parseClass;
            private _apcClass = _apcParsed select 0;
            private _apcLoadout = _apcParsed select 1;

            private _apcData = [_spawnPosAPC, (_approachDir - 180), _apcClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _apc = _apcData select 0;
            private _groupAPC = [crew _apc, _playerSide, _apcData select 2] call _fnc_forceSide;
            
            if (_apcLoadout isNotEqualTo false) then {
                if (_apcLoadout isEqualType []) then { _apc setUnitLoadout _apcLoadout; };
                if (_apcLoadout isEqualType "") then { _apc call compile _apcLoadout; };
            };

            [_apc] call _fnc_garbageCollect;     
            [_apc] call _fnc_protectVehicle;
            
            // Smart Parser - Ground Turret
            private _turretParsed = [AQR_Ground_Turret] call _fnc_parseClass;
            private _turretClass = _turretParsed select 0;
            private _turretLoadout = _turretParsed select 1;

            private _turretData = [_spawnPosTurret, (_approachDir - 180), _turretClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _turret = _turretData select 0;
            private _groupTurret = [crew _turret, _playerSide, _turretData select 2] call _fnc_forceSide;

            if (_turretLoadout isNotEqualTo false) then {
                if (_turretLoadout isEqualType []) then { _turret setUnitLoadout _turretLoadout; };
                if (_turretLoadout isEqualType "") then { _turret call compile _turretLoadout; };
            };

            [_turret] call _fnc_garbageCollect;     
            [_turret] call _fnc_protectVehicle;

            {
                private _veh = _x;
                (group _veh) setSpeedMode "FULL";
                (group _veh) setBehaviour "AWARE"; 
                (group _veh) setCombatMode "RED"; 
                { _x disableAI "AUTOCOMBAT"; } forEach crew _veh; 
                
                [_veh] spawn {
                    params ["_v"];
                    private _endTime = time + 180;
                    while {time < _endTime && alive _v} do {
                        if ((vectorUp _v) select 2 < 0.2) then {
                            _v setVectorUp surfaceNormal getPos _v;
                            _v setPos (getPos _v vectorAdd [0,0,1.5]);
                        };
                        sleep 3;
                    };
                };
            } forEach [_apc, _turret];

            [_caller] spawn {
                params ["_caller"];
                sleep 30;
                "SERGEANT: Ground element moving in. Check friendly fire, over." remoteExec ["systemChat", _caller];
                "AQR_Voice_Ground_QRF" remoteExec ["playSound", _caller];
            };

            private _wpTurret = _groupTurret addWaypoint [_dropPos getPos [150, _approachDir - 180], 0];
            _wpTurret setWaypointType "SAD";

            [_apc, _turret, _dropPos, _playerSide, _spawnPosAPC, _groupAPC, _groupTurret, _fnc_forceSide, _fnc_parseClass] spawn {
                params ["_apc", "_turret", "_dropPos", "_playerSide", "_spawnPosAPC", "_groupAPC", "_groupTurret", "_fnc_forceSide", "_fnc_parseClass"];

                // FIX: Force APC to drive to the LZ *before* scanning for flanking targets
                private _wpAPC = _groupAPC addWaypoint [_dropPos, 0];
                _wpAPC setWaypointType "MOVE";

                waitUntil { 
                    sleep 1; 
                    (_apc distance2D _dropPos) < 150 || !alive _apc || !canMove _apc 
                };

                if (alive _apc && canMove _apc) then {
                    // Now that we are close to the LZ, scan for immediate threats to flank
                    private _targetPos = _dropPos;
                    private _enemies = allUnits select { alive _x && {((side _x) getFriend _playerSide) < 0.6} && {(_x distance2D _dropPos) < 300} };
                    
                    if (count _enemies > 0) then {
                        _enemies = _enemies apply { [_x distance2D _apc, _x] };
                        _enemies sort true;
                        _targetPos = getPos ((_enemies select 0) select 1);
                    };

                    while {(count (waypoints _groupAPC)) > 0} do { deleteWaypoint ((waypoints _groupAPC) select 0); };
                    private _wpPush = _groupAPC addWaypoint [_targetPos, 0];
                    _wpPush setWaypointType "MOVE";

                    // Push directly onto the enemy position to dismount
                    waitUntil {
                        sleep 1;
                        (_apc distance2D _targetPos) < 50 || !alive _apc || !canMove _apc
                    };
                };

                if (alive _apc && canMove _apc) then {
                    _apc forceSpeed 0;
                    sleep 2; 
                };

                private _tempGroup = createGroup [_playerSide, true]; 
                private _unitTypes = [AQR_Squad_SL, AQR_Squad_SL, AQR_Squad_MG, AQR_Squad_MG, AQR_Squad_AT, AQR_Squad_AT, AQR_Squad_Sniper, AQR_Squad_Sniper];
                private _spawnedTroops = [];

                for "_i" from 0 to (count _unitTypes - 1) do {
                    // Smart Parser - Ground Troops
                    private _unitParsed = [_unitTypes select _i] call _fnc_parseClass;
                    private _class = _unitParsed select 0;
                    private _loadout = _unitParsed select 1;
                    if (isNil "_class" || {!isClass (configFile >> "CfgVehicles" >> _class)}) then { _class = "B_Soldier_F"; };

                    private _exitDir = (getDir _apc) + 180 + (if (_i % 2 == 0) then {45} else {-45});
                    private _dist = 4 + (_i * 1.2); 
                    private _doorPos = _apc getPos [_dist, _exitDir];
                    
                    private _unit = _tempGroup createUnit [_class, _doorPos, [], 0, "CAN_COLLIDE"];
                    
                    if (_loadout isNotEqualTo false) then {
                        if (_loadout isEqualType []) then { _unit setUnitLoadout _loadout; };
                        if (_loadout isEqualType "") then { _unit call compile _loadout; };
                    };

                    _unit setDir (getDir _apc); 
                    _unit allowDamage false; 
                    _unit addRating 100000; 
                    
                    _unit disableAI "TARGET";
                    _unit disableAI "AUTOTARGET";

                    _unit disableAI "AUTOCOMBAT"; 
                    _unit disableAI "COVER";     
                    _unit setCombatMode "RED";
                    _unit setBehaviour "AWARE";   
                    _unit addEventHandler ["Fired", { (_this select 0) setAmmo [currentWeapon (_this select 0), 50]; }];
                    
                    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
                    
                    _spawnedTroops pushBack _unit;
                    sleep 0.3; 
                };

                private _squadGroup = [_spawnedTroops, _playerSide, _tempGroup] call _fnc_forceSide;

                {
                    _x enableAI "TARGET";
                    _x enableAI "AUTOTARGET";
                    _x allowDamage true; 
                } forEach _spawnedTroops;

                _squadGroup allowFleeing 0;
                _squadGroup setSpeedMode "FULL";

                [_squadGroup, _dropPos, _playerSide] spawn {
                    params ["_grp", "_lz", "_playerSide"];
                    while {count units _grp > 0} do {
                        private _leader = leader _grp;
                        private _targetPos = _lz;
                        private _enemies = allUnits select { alive _x && {((side _x) getFriend _playerSide) < 0.6} && {(_x distance2D _leader) < 1500} };
                        
                        if (count _enemies > 0) then {
                            _enemies = _enemies apply { [_x distance2D _leader, _x] };
                            _enemies sort true;
                            _targetPos = getPos ((_enemies select 0) select 1);
                        };

                        while {(count (waypoints _grp)) > 0} do { deleteWaypoint ((waypoints _grp) select 0); };
                        private _wp = _grp addWaypoint [_targetPos, 0];
                        _wp setWaypointType "MOVE"; 
                        _grp setSpeedMode "FULL";
                        _grp setBehaviour "AWARE"; 
                        { _x doMove _targetPos; } forEach units _grp; 
                        
                        sleep 10; 
                    };
                };

                if (alive _apc) then {
                    _apc forceSpeed -1; 
                    _groupAPC setBehaviour "AWARE";
                    _groupAPC setCombatMode "RED";
                    
                    [_groupAPC, _dropPos, _playerSide] spawn {
                        params ["_grpApc", "_lz", "_playerSide"];
                        while {count units _grpApc > 0} do {
                            private _leader = leader _grpApc;
                            private _targetPos = _lz;
                            private _enemies = allUnits select { alive _x && {((side _x) getFriend _playerSide) < 0.6} && {(_x distance2D _leader) < 1500} };
                            
                            if (count _enemies > 0) then {
                                _enemies = _enemies apply { [_x distance2D _leader, _x] };
                                _enemies sort true;
                                _targetPos = getPos ((_enemies select 0) select 1);
                            };

                            while {(count (waypoints _grpApc)) > 0} do { deleteWaypoint ((waypoints _grpApc) select 0); };
                            private _wp = _grpApc addWaypoint [_targetPos, 0];
                            _wp setWaypointType "SAD"; 
                            (vehicle _leader) commandMove _targetPos;
                            sleep 15; 
                        };
                    };
                };
                
                [_turret, _groupTurret, _dropPos, _playerSide] spawn {
                    params ["_turret", "_groupTurret", "_dropPos", "_playerSide"];
                    while {alive _turret && canMove _turret} do {
                        private _targetPos = _dropPos;
                        private _enemies = allUnits select { alive _x && {((side _x) getFriend _playerSide) < 0.6} && {(_x distance2D _dropPos) < 1500} };
                        if (count _enemies > 0) then {
                            _enemies = _enemies apply { [_x distance2D _dropPos, _x] }; 
                            _enemies sort true;
                            _targetPos = getPos ((_enemies select 0) select 1);
                        };

                        while {(count (waypoints _groupTurret)) > 0} do { deleteWaypoint ((waypoints _groupTurret) select 0); };
                        private _vantage = _targetPos getPos [150 + random 100, random 360];
                        private _wp = _groupTurret addWaypoint [_vantage, 0];
                        _wp setWaypointType "SAD";
                        sleep 45; 
                    };
                };

                [_groupAPC, _groupTurret, _spawnPosAPC] spawn {
                    params ["_groupAPC", "_groupTurret", "_spawnPosAPC"];
                    sleep (parseNumber AQR_RTB_Armor);
                    {
                        private _grp = _x;
                        if (count units _grp > 0) then {
                            while {(count (waypoints _grp)) > 0} do { deleteWaypoint ((waypoints _grp) select 0); };
                            private _wp = _grp addWaypoint [_spawnPosAPC, 0];
                            _wp setWaypointType "MOVE";
                            _wp setWaypointSpeed "FULL";
                            _wp setWaypointStatements ["true", "{deleteVehicle _x} forEach (crew (vehicle this) + [vehicle this]);"];
                            
                            // Failsafe Hard Delete
                            [vehicle leader _grp] spawn {
                                params ["_v"];
                                sleep 300;
                                if (!isNull _v) then { {deleteVehicle _x} forEach crew _v; deleteVehicle _v; };
                            };
                        };
                    } forEach [_groupAPC, _groupTurret];
                };
                
                sleep (parseNumber AQR_RTB_Troops); 
                { deleteVehicle _x; } forEach _spawnedTroops; 
            };
        };
    };

    // ==========================================
    // --- ELEMENT 4: SEA ELEMENT ---
    // ==========================================
    if (AQR_Toggle_Sea) then {
        [_dropPos, _playerSide, _fnc_garbageCollect, _fnc_forceSide, _fnc_protectVehicle, _fnc_parseClass] spawn {
            params ["_dropPos", "_playerSide", "_fnc_garbageCollect", "_fnc_forceSide", "_fnc_protectVehicle", "_fnc_parseClass"];

            private _shorePos = [];
            for "_dist" from 100 to 1500 step 100 do {
                for "_dir" from 0 to 315 step 45 do {
                    private _checkPos = _dropPos getPos [_dist, _dir];
                    if (surfaceIsWater _checkPos && {getTerrainHeightASL _checkPos < -2}) exitWith {
                        _shorePos = _checkPos;
                    };
                };
                if (count _shorePos > 0) exitWith {};
            };

            if (count _shorePos == 0) exitWith {};

            private _oceanDir = _dropPos getDir _shorePos; 
            private _inlandDir = _oceanDir - 180;          
            
            private _spawnPosBoat = _shorePos getPos [200, _oceanDir]; 
            private _spawnPosAmphib = _shorePos getPos [100, _oceanDir]; 

            _spawnPosBoat set [2, 3];
            _spawnPosAmphib set [2, 3];

            if (!surfaceIsWater _spawnPosBoat) exitWith {};

            // Smart Parser - Sea Boat
            private _boatParsed = [AQR_Sea_Boat] call _fnc_parseClass;
            private _boatClass = _boatParsed select 0;
            private _boatLoadout = _boatParsed select 1;

            private _boatData = [_spawnPosBoat, _inlandDir, _boatClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _boat = _boatData select 0;
            private _groupBoat = [crew _boat, _playerSide, _boatData select 2] call _fnc_forceSide;

            if (_boatLoadout isNotEqualTo false) then {
                if (_boatLoadout isEqualType []) then { _boat setUnitLoadout _boatLoadout; };
                if (_boatLoadout isEqualType "") then { _boat call compile _boatLoadout; };
            };
            
            [_boat] call _fnc_garbageCollect;     
            [_boat] call _fnc_protectVehicle;

            // Smart Parser - Amphib APC
            private _amphibParsed = [AQR_Sea_Amphib] call _fnc_parseClass;
            private _amphibClass = _amphibParsed select 0;
            private _amphibLoadout = _amphibParsed select 1;

            private _amphibData = [_spawnPosAmphib, _inlandDir, _amphibClass, _playerSide] call BIS_fnc_spawnVehicle;
            private _amphib = _amphibData select 0;
            private _groupAmphib = [crew _amphib, _playerSide, _amphibData select 2] call _fnc_forceSide;

            if (_amphibLoadout isNotEqualTo false) then {
                if (_amphibLoadout isEqualType []) then { _amphib setUnitLoadout _amphibLoadout; };
                if (_amphibLoadout isEqualType "") then { _amphib call compile _amphibLoadout; };
            };
            
            [_amphib] call _fnc_garbageCollect;     
            [_amphib] call _fnc_protectVehicle;

            _groupBoat setSpeedMode "NORMAL";
            _groupBoat setBehaviour "AWARE";
            _groupBoat setCombatMode "RED";

            _groupAmphib setSpeedMode "NORMAL";
            _groupAmphib setBehaviour "CARELESS"; 
            _groupAmphib setCombatMode "BLUE";    
            { _x disableAI "AUTOCOMBAT"; } forEach crew _amphib; 

            [_boat, _dropPos, _playerSide, _shorePos] spawn {
                params ["_boat", "_dropPos", "_playerSide", "_shorePos"];
                private _gunner = gunner _boat;

                while {alive _boat} do {
                    private _targetPos = _dropPos;
                    private _hasTarget = false; 
                    private _enemies = allUnits select { alive _x && {((side _x) getFriend _playerSide) < 0.6} && {(_x distance2D _dropPos) < 1500} };
                    
                    if (count _enemies > 0) then {
                        _enemies = _enemies apply { [_x distance2D _boat, _x] };
                        _enemies sort true;
                        _targetPos = getPos ((_enemies select 0) select 1);
                        _hasTarget = true; 
                    };

                    if (unitReady _boat || speed _boat < 5) then {
                        private _patrolPos = _shorePos getPos [50 + random 200, random 360];
                        if (surfaceIsWater _patrolPos) then { _boat commandMove _patrolPos; };
                    };

                    if (_hasTarget && alive _gunner && {(_boat distance2D _targetPos) < 800}) then {
                        _gunner doWatch _targetPos;
                        sleep 1.5; 
                        
                        for "_b" from 1 to 15 do {
                            if (!alive _gunner || !alive _boat) exitWith {};
                            _boat action ["useWeapon", _boat, _gunner, 0];
                            sleep 0.08; 
                        };
                        sleep 1; 
                    };
                    
                    sleep 0.5; 
                };
            };

            [_amphib, _dropPos, _playerSide, _groupAmphib, _spawnPosAmphib, _fnc_forceSide, _fnc_parseClass] spawn {
                params ["_amphib", "_dropPos", "_playerSide", "_groupAmphib", "_spawnPosAmphib", "_fnc_forceSide", "_fnc_parseClass"];

                private _lastPos = getPos _amphib;
                private _stuckTime = 0;
                private _reachedDropZone = false;
                private _lastMoveTarget = [0,0,0];

                while {alive _amphib && canMove _amphib && !_reachedDropZone} do {
                    
                    if ((_lastPos distance2D _amphib) < 1.5) then { _stuckTime = _stuckTime + 5; } else { _stuckTime = 0; };
                    _lastPos = getPos _amphib;
                    
                    private _targetPos = _dropPos;
                    private _enemies = allUnits select { alive _x && {((side _x) getFriend _playerSide) < 0.6} && {(_x distance2D _dropPos) < 1500} };
                    if (count _enemies > 0) then {
                        _enemies = _enemies apply { [_x distance2D _amphib, _x] };
                        _enemies sort true;
                        _targetPos = getPos ((_enemies select 0) select 1);
                    };

                    if (_stuckTime == 5 || _stuckTime == 10) then {
                        _amphib doMove _targetPos; 
                        _lastMoveTarget = _targetPos; 
                        _amphib forceSpeed -1; 
                        
                        _amphib setVelocity [
                            (velocity _amphib select 0) + (sin (getDir _amphib) * 3), 
                            (velocity _amphib select 1) + (cos (getDir _amphib) * 3), 
                            0.5
                        ];
                    };

                    if (_stuckTime >= 15) then {
                        private _pushPos = _amphib getPos [15, _amphib getDir _dropPos];
                        _pushPos set [2, (getTerrainHeightASL _pushPos) + 1.5];
                        _amphib setVehiclePosition [_pushPos, [], 0, "CAN_COLLIDE"];
                        _amphib setVectorUp surfaceNormal _pushPos;
                        _amphib setVelocity [0,0,0];
                        _stuckTime = 0;
                    };

                    if (_lastMoveTarget distance2D _targetPos > 50) then {
                        _amphib doMove _targetPos;
                        _lastMoveTarget = _targetPos;
                    };

                    if ((_amphib distance2D _targetPos) < 100 && !surfaceIsWater (getPos _amphib)) then {
                        _reachedDropZone = true;
                    };

                    if (!_reachedDropZone) then { sleep 5; }; 
                };

                if (alive _amphib && canMove _amphib) then {
                    _amphib forceSpeed 0;
                    sleep 2; 
                };

                private _tempGroup = createGroup [_playerSide, true]; 
                private _unitTypes = [AQR_Amphib_SL, AQR_Amphib_MG, AQR_Amphib_AT, AQR_Amphib_Sniper];
                private _spawnedTroops = [];

                for "_i" from 0 to 3 do {
                    // Smart Parser - Amphib Troops
                    private _unitParsed = [_unitTypes select _i] call _fnc_parseClass;
                    private _class = _unitParsed select 0;
                    private _loadout = _unitParsed select 1;
                    if (isNil "_class" || {!isClass (configFile >> "CfgVehicles" >> _class)}) then { _class = "B_diver_F"; };

                    private _exitDir = (getDir _amphib) + 180 + (if (_i % 2 == 0) then {45} else {-45});
                    private _dist = 4 + (_i * 1.2); 
                    private _doorPos = _amphib getPos [_dist, _exitDir];
                    
                    private _unit = _tempGroup createUnit [_class, _doorPos, [], 0, "CAN_COLLIDE"];
                    
                    if (_loadout isNotEqualTo false) then {
                        if (_loadout isEqualType []) then { _unit setUnitLoadout _loadout; };
                        if (_loadout isEqualType "") then { _unit call compile _loadout; };
                    };

                    _unit setDir (getDir _amphib); 
                    _unit allowDamage false; 
                    _unit addRating 100000; 
                    
                    _unit disableAI "TARGET";
                    _unit disableAI "AUTOTARGET";

                    _unit disableAI "AUTOCOMBAT"; 
                    _unit disableAI "COVER";     
                    _unit setCombatMode "RED";
                    _unit setBehaviour "AWARE";   
                    _unit setUnitPos "UP";
                    _unit addEventHandler ["Fired", { (_this select 0) setAmmo [currentWeapon (_this select 0), 50]; }];
                    
                    { _unit setSkill [_x, 1]; } forEach ["aimingAccuracy", "aimingShake", "aimingSpeed", "spotDistance", "spotTime", "commanding", "courage", "reloadSpeed"];
                    
                    _spawnedTroops pushBack _unit;
                    sleep 0.3; 
                };

                private _squadGroup = [_spawnedTroops, _playerSide, _tempGroup] call _fnc_forceSide;

                {
                    _x enableAI "TARGET";
                    _x enableAI "AUTOTARGET";
                    _x allowDamage true; 
                } forEach _spawnedTroops;

                _squadGroup allowFleeing 0;
                _squadGroup setSpeedMode "FULL";

                [_squadGroup, _dropPos, _playerSide] spawn {
                    params ["_grp", "_lz", "_playerSide"];
                    while {count units _grp > 0} do {
                        private _leader = leader _grp;
                        private _targetPos = _lz;
                        private _enemies = allUnits select { alive _x && {((side _x) getFriend _playerSide) < 0.6} && {(_x distance2D _leader) < 1500} };
                        
                        if (count _enemies > 0) then {
                            _enemies = _enemies apply { [_x distance2D _leader, _x] };
                            _enemies sort true;
                            _targetPos = getPos ((_enemies select 0) select 1);
                        };

                        while {(count (waypoints _grp)) > 0} do { deleteWaypoint ((waypoints _grp) select 0); };
                        
                        private _wp = _grp addWaypoint [_targetPos, 0];
                        _wp setWaypointType "SAD"; 
                        _grp setSpeedMode "FULL";
                        _grp setBehaviour "AWARE"; 
                        { 
                            _x setUnitPos "UP"; 
                            _x commandMove _targetPos; 
                        } forEach units _grp;
                        
                        sleep 10; 
                    };
                };

                if (alive _amphib) then {
                    _amphib forceSpeed -1; 
                    
                    _groupAmphib setBehaviour "COMBAT";
                    _groupAmphib setCombatMode "RED";
                    { 
                        _x enableAI "AUTOCOMBAT"; 
                        _x enableAI "AUTOTARGET"; 
                        _x enableAI "TARGET"; 
                    } forEach crew _amphib;
                    
                    [_groupAmphib, _dropPos, _playerSide] spawn {
                        params ["_grpAmphib", "_lz", "_playerSide"];
                        while {count units _grpAmphib > 0} do {
                            private _leader = leader _grpAmphib;
                            private _amphibVeh = vehicle _leader;
                            private _targetPos = _lz;
                            private _enemies = allUnits select { alive _x && {((side _x) getFriend _playerSide) < 0.6} && {(_x distance2D _leader) < 1500} };
                            
                            if (count _enemies > 0) then {
                                _enemies = _enemies apply { [_x distance2D _leader, _x] };
                                _enemies sort true;
                                private _closestEnemy = (_enemies select 0) select 1;
                                _targetPos = getPos _closestEnemy;
                                
                                if (!isNull gunner _amphibVeh) then {
                                    private _gunner = gunner _amphibVeh;
                                    _gunner doTarget _closestEnemy;
                                    _gunner doWatch _closestEnemy;
                                    
                                    if (_amphibVeh distance2D _closestEnemy < 600) then {
                                        [_amphibVeh, _gunner, _closestEnemy] spawn {
                                            params ["_veh", "_gun", "_target"];
                                            sleep 1.5; 
                                            for "_f" from 1 to 6 do {
                                                if (!alive _gun || !alive _veh || !alive _target) exitWith {};
                                                _veh action ["useWeapon", _veh, _gun, 0];
                                                sleep 0.15;
                                            };
                                        };
                                    };
                                };
                            };

                            while {(count (waypoints _grpAmphib)) > 0} do { deleteWaypoint ((waypoints _grpAmphib) select 0); };
                            private _wp = _grpAmphib addWaypoint [_targetPos, 0];
                            _wp setWaypointType "SAD"; 
                            _grpAmphib setBehaviour "COMBAT";
                            _grpAmphib setCombatMode "RED";
                            _amphibVeh commandMove _targetPos;
                            
                            sleep 5; 
                        };
                    };
                };

                [_groupAmphib, _spawnPosAmphib, _spawnedTroops] spawn {
                    params ["_groupAmphib", "_spawnPosAmphib", "_spawnedTroops"];
                    sleep (parseNumber AQR_RTB_Sea);
                    
                    if (count units _groupAmphib > 0) then {
                        while {(count (waypoints _groupAmphib)) > 0} do { deleteWaypoint ((waypoints _groupAmphib) select 0); };
                        private _wp = _groupAmphib addWaypoint [_spawnPosAmphib, 0];
                        _wp setWaypointType "MOVE";
                        _wp setWaypointSpeed "FULL";
                        _wp setWaypointStatements ["true", "{deleteVehicle _x} forEach (crew (vehicle this) + [vehicle this]);"];
                        
                        // Failsafe Hard Delete
                        [vehicle leader _groupAmphib] spawn {
                            params ["_v"];
                            sleep 300;
                            if (!isNull _v) then { {deleteVehicle _x} forEach crew _v; deleteVehicle _v; };
                        };
                    };
                    
                    { deleteVehicle _x; } forEach _spawnedTroops;
                };
            };
            
            [_groupBoat, _spawnPosBoat] spawn {
                params ["_groupBoat", "_spawnPosBoat"];
                sleep (parseNumber AQR_RTB_Sea);
                if (count units _groupBoat > 0) then {
                    while {(count (waypoints _groupBoat)) > 0} do { deleteWaypoint ((waypoints _groupBoat) select 0); };
                    private _wp = _groupBoat addWaypoint [_spawnPosBoat, 0];
                    _wp setWaypointType "MOVE";
                    _wp setWaypointSpeed "FULL";
                    _wp setWaypointStatements ["true", "{deleteVehicle _x} forEach (crew (vehicle this) + [vehicle this]);"];
                    
                    // Failsafe Hard Delete
                    [vehicle leader _groupBoat] spawn {
                        params ["_v"];
                        sleep 300;
                        if (!isNull _v) then { {deleteVehicle _x} forEach crew _v; deleteVehicle _v; };
                    };
                };
            };
        };
    };

}; // END MASTER DEPLOYMENT THREAD