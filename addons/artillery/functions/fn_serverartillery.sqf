// AAS-Artillery/functions/fn_serverArtillery.sqf
/* Author: AAS Team
    Description: Master Strike Router for Artillery. Catches the string from the
    client and routes it to the correct spawn and deployment logic. 
    REROUTED: Now uses Main AAS Core Economy Logic.
*/

params ["_caller", "_dropPos", "_strikeType"];

if (!isServer) exitWith {};

// ==========================================
// --- 1. CORE SETUP & SECURITY ---
// ==========================================
// Get the player's side for spawning friendly shells/vehicles if needed later
private _playerSide = side group _caller;

// Fallback just in case something weird happens with the caller's group or they are "Undercover"
if (_playerSide == sideLogic || _playerSide == civilian) then {
    _playerSide = west;
};

// ==========================================
// --- 2. SERVER ECONOMY & COOLDOWN CHECK ---
// ==========================================

// REROUTED: Safely grab the GLOBAL economy preset from Core
private _econPreset = missionNamespace getVariable ["AAS_Econ_Preset_Core", 0];

// Safely grab the base cost depending on the preset
private _baseCost = switch (_econPreset) do {
    case 0: { parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_Custom", "0"]) };
    case 1: { parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_Antistasi", "1000"]) };
    case 3: { parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_Overthrow", "3000"]) };
    case 4: { parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_Warlords", "400"]) };
    case 5: { parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_DUWS", "10"]) };
    case 6: { parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_Antistasi", "1000"]) };
    default { 0 };
};

private _cost = 0;
// Using the new global cooldown editbox you set up in the settings
private _cdTime = parseNumber (missionNamespace getVariable ["AAS_ART_Cooldown_Global", "600"]);
private _lastUseVar = "";
private _mult = 1.0;

// Route the multiplier and last use variables safely based on the requested strike
switch (_strikeType) do {
    // 82mm Mortar
    case "Arty82mm_HEX7": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_82mm_HEX7", "1.0"]); _lastUseVar = "AAS_ART_LastUse_82mm_HEX7"; };
    case "Arty82mm_HEX14": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_82mm_HEX14", "2.0"]); _lastUseVar = "AAS_ART_LastUse_82mm_HEX14"; };
    case "Arty82mm_Smoke": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_82mm_Smoke", "0.5"]); _lastUseVar = "AAS_ART_LastUse_82mm_Smoke"; };
    
    // 155mm Howitzer
    case "Arty155mm_HEX5": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_155mm_HEX5", "3.0"]); _lastUseVar = "AAS_ART_LastUse_155mm_HEX5"; };
    case "Arty155mm_HEX10": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_155mm_HEX10", "6.0"]); _lastUseVar = "AAS_ART_LastUse_155mm_HEX10"; };
    case "Arty155mm_DPICM": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_155mm_DPICM", "3.0"]); _lastUseVar = "AAS_ART_LastUse_155mm_DPICM"; };
    case "Arty155mm_ADAM": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_155mm_ADAM", "4.0"]); _lastUseVar = "AAS_ART_LastUse_155mm_ADAM"; };
    case "Arty155mm_RAAMS": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_155mm_RAAMS", "6.0"]); _lastUseVar = "AAS_ART_LastUse_155mm_RAAMS"; };
    
    // MLRS
    case "ArtyMLRS_HEDPX7": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_MLRS_HEDPX7", "5.0"]); _lastUseVar = "AAS_ART_LastUse_MLRS_HEDPX7"; };
    case "ArtyMLRS_HEDPX14": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_MLRS_HEDPX14", "10.0"]); _lastUseVar = "AAS_ART_LastUse_MLRS_HEDPX14"; };
    case "ArtyMLRS_WP": { _mult = parseNumber (missionNamespace getVariable ["AAS_ART_Mult_MLRS_WP", "4.0"]); _lastUseVar = "AAS_ART_LastUse_MLRS_WP"; };
};

// Calculate final cost
if (_econPreset == 2) then {
    // KP Liberation: Base Thresholds Only (No Multipliers) packed into an array
    _cost = [
        parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_KPLib_S", "100"]),
        parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_KPLib_A", "50"]),
        parseNumber (missionNamespace getVariable ["AAS_ART_Cost_Base_KPLib_F", "250"])
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
    (format ["HQ: Artillery on cooldown. Available in %1 mins.", _timeLeft]) remoteExec ["systemChat", _caller];
};

// --- Economy Deduction ---
private _econCode = missionNamespace getVariable ["AAS_ART_Econ_Code", ""];

// REROUTED: Call the Master Router
private _econPass = [_caller, _cost, _econPreset, _econCode] call aas_core_fnc_setEconomyPreset;

// If the manager returns false (insufficient funds), abort!
if (isNil "_econPass" || {!_econPass}) exitWith {};

// --- Lock the Cooldown Timer ---
// Passed both checks! Register the time this was used across the server.
missionNamespace setVariable [_lastUseVar, serverTime, true];

// ====================================================================================
// --- 3. MASTER STRIKE ROUTER ---
// ====================================================================================

// FIX: The missing switch statement was placed here!
switch (_strikeType) do {

    // ------------------- 82mm Mortar -------------------
    case "Arty82mm_HEX7": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 7;
            private _spread = 38; 
            
            private _delays = [];
            for "_i" from 1 to _shellCount do {
                _delays pushBack (0.7 + random 1.1); 
            };
            
            sleep 7;
            "FDC: Copy that, grid received. Setting up mortars." remoteExec ["systemChat", _caller];
            ["aas_art_settingmortars"] remoteExec ["playSound", _caller];
            sleep 4;

            private _soundPos = _dropPos getPos [1200, random 360];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            for "_i" from 0 to (_shellCount - 1) do {
                private _pitch = 0.5 + random 0.2; 
                [
                    ["A3\Sounds_F\weapons\Mortar\mortar_01.wss", _soundDummy, false, getPosASL _soundDummy, 5, _pitch, 3000]
                ] remoteExec ["playSound3D", 0];
                
                sleep (_delays select _i);
            };

            // Added sleep for radio silence after firing
            sleep 4.5;

            if (random 1 > 0.5) then {
                "FDC: Rounds complete, over." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete1"] remoteExec ["playSound", _caller];
            } else {
                "FDC: Rounds complete." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete2"] remoteExec ["playSound", _caller];
            };
            
            sleep 15;
            
            "FDC: SPLASH" remoteExec ["systemChat", _caller];
            ["aas_art_splash"] remoteExec ["playSound", _caller];
            deleteVehicle _soundDummy;

            for "_i" from 0 to (_shellCount - 1) do {
                private _impactPos = _dropPos getPos [random _spread, random 360];
                private _spawnPos = [_impactPos select 0, _impactPos select 1, (_dropPos select 2) + 350];
                
                private _shell = createVehicle ["Sh_82mm_AMOS", _spawnPos, [], 0, "FLY"];
                _shell setShotParents [_caller, _caller];
                _shell setVelocity [0, 0, -50]; 
                
                sleep (_delays select _i);
            };
        };
    };
    
    case "Arty82mm_HEX14": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 14;
            private _spread = 56; 
            
            private _delays = [];
            for "_i" from 1 to _shellCount do {
                _delays pushBack (0.5 + random 0.8); 
            };
            
            sleep 7;
            "FDC: Copy that, grid received. Setting up mortars." remoteExec ["systemChat", _caller];
            ["aas_art_settingmortars"] remoteExec ["playSound", _caller];
            sleep 4;

            private _soundPos = _dropPos getPos [1200, random 360];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            for "_i" from 0 to (_shellCount - 1) do {
                private _pitch = 0.5 + random 0.2;
                [
                    ["A3\Sounds_F\weapons\Mortar\mortar_01.wss", _soundDummy, false, getPosASL _soundDummy, 5, _pitch, 3000]
                ] remoteExec ["playSound3D", 0];
                sleep (_delays select _i);
            };

            // Added sleep for radio silence after firing
            sleep 5.5;

            if (random 1 > 0.5) then {
                "FDC: Rounds complete, over." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete1"] remoteExec ["playSound", _caller];
            } else {
                "FDC: Rounds complete." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete2"] remoteExec ["playSound", _caller];
            };
            
            sleep 15;
            
            "FDC: SPLASH" remoteExec ["systemChat", _caller];
            ["aas_art_splash"] remoteExec ["playSound", _caller];
            deleteVehicle _soundDummy;

            for "_i" from 0 to (_shellCount - 1) do {
                private _impactPos = _dropPos getPos [random _spread, random 360];
                private _spawnPos = [_impactPos select 0, _impactPos select 1, (_dropPos select 2) + 350];
                
                private _shell = createVehicle ["Sh_82mm_AMOS", _spawnPos, [], 0, "FLY"];
                _shell setShotParents [_caller, _caller];
                _shell setVelocity [0, 0, -50]; 
                sleep (_delays select _i);
            };
        };
    };
    
    case "Arty82mm_Smoke": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 6;
            private _spread = 44; 
            
            private _delays = [];
            for "_i" from 1 to _shellCount do {
                _delays pushBack (0.7 + random 1.1); 
            };
            
            sleep 7;
            "FDC: Copy that, grid received. Setting up mortars." remoteExec ["systemChat", _caller];
            ["aas_art_settingmortars"] remoteExec ["playSound", _caller];
            sleep 4;

            private _soundPos = _dropPos getPos [1200, random 360];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            for "_i" from 0 to (_shellCount - 1) do {
                private _pitch = 0.5 + random 0.2;
                [
                    ["A3\Sounds_F\weapons\Mortar\mortar_01.wss", _soundDummy, false, getPosASL _soundDummy, 5, _pitch, 3000]
                ] remoteExec ["playSound3D", 0];
                sleep (_delays select _i);
            };

            // Added sleep for radio silence after firing
            sleep 3.5;

            if (random 1 > 0.5) then {
                "FDC: Rounds complete, over." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete1"] remoteExec ["playSound", _caller];
            } else {
                "FDC: Rounds complete." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete2"] remoteExec ["playSound", _caller];
            };
            
            sleep 15;
            
            "FDC: SPLASH" remoteExec ["systemChat", _caller];
            ["aas_art_splash"] remoteExec ["playSound", _caller];
            deleteVehicle _soundDummy;

            for "_i" from 0 to (_shellCount - 1) do {
                private _impactPos = _dropPos getPos [random _spread, random 360];
                private _spawnPos = [_impactPos select 0, _impactPos select 1, (_dropPos select 2) + 350];
                
                private _shell = createVehicle ["Smoke_82mm_AMOS_White", _spawnPos, [], 0, "FLY"];
                _shell setShotParents [_caller, _caller];
                _shell setVelocity [0, 0, -50]; 
                sleep (_delays select _i);
            };
        };
    };
    
// ------------------- 155mm Howitzer -------------------
    case "Arty155mm_HEX5": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 5;
            private _spread = 50; 
            
            private _delays = [];
            for "_i" from 1 to _shellCount do {
                _delays pushBack (3.5 + random 2.0); 
            };
            
            sleep 7;
            "FDC: Loading High Explosive shells." remoteExec ["systemChat", _caller];
            ["aas_art_loadinghe"] remoteExec ["playSound", _caller];
            sleep 4;

            private _soundPos = _dropPos getPos [1500, random 360];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            for "_i" from 0 to (_shellCount - 1) do {
                // VERIFIED VANILLA SOUND: Pitched down explosion from 1.5km sounds like a heavy cannon crack
                private _pitch = 0.4 + random 0.2;
                [
                    ["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", _soundDummy, false, getPosASL _soundDummy, 5, _pitch, 5000]
                ] remoteExec ["playSound3D", 0];
                sleep (_delays select _i);
            };

            // Added sleep for radio silence after firing
            sleep 2.5;

            if (random 1 > 0.5) then {
                "FDC: Rounds complete, over." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete1"] remoteExec ["playSound", _caller];
            } else {
                "FDC: Rounds complete." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete2"] remoteExec ["playSound", _caller];
            };
            
            sleep 20; 
            
            "FDC: SPLASH" remoteExec ["systemChat", _caller];
            ["aas_art_splash"] remoteExec ["playSound", _caller];
            deleteVehicle _soundDummy;

            for "_i" from 0 to (_shellCount - 1) do {
                private _impactPos = _dropPos getPos [random _spread, random 360];
                private _spawnPos = [_impactPos select 0, _impactPos select 1, (_dropPos select 2) + 400];
                
                private _shell = createVehicle ["Sh_155mm_AMOS", _spawnPos, [], 0, "FLY"];
                _shell setShotParents [_caller, _caller];
                _shell setVelocity [0, 0, -80]; 
                sleep (_delays select _i);
            };
        };
    };
    
    case "Arty155mm_HEX10": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 10;
            private _spread = 75; 
            
            private _delays = [];
            for "_i" from 1 to _shellCount do {
                _delays pushBack (2.0 + random 1.5); 
            };
            
            sleep 7;
            "FDC: Loading High Explosive shells." remoteExec ["systemChat", _caller];
            ["aas_art_loadinghe"] remoteExec ["playSound", _caller];
            sleep 4;

            private _soundPos = _dropPos getPos [1500, random 360];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            for "_i" from 0 to (_shellCount - 1) do {
                // VERIFIED VANILLA SOUND
                private _pitch = 0.4 + random 0.2;
                [
                    ["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", _soundDummy, false, getPosASL _soundDummy, 5, _pitch, 5000]
                ] remoteExec ["playSound3D", 0];
                sleep (_delays select _i);
            };

            // Added sleep for radio silence after firing
            sleep 4.5;

            if (random 1 > 0.5) then {
                "FDC: Rounds complete, over." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete1"] remoteExec ["playSound", _caller];
            } else {
                "FDC: Rounds complete." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete2"] remoteExec ["playSound", _caller];
            };
            
            sleep 20;
            
            "FDC: SPLASH" remoteExec ["systemChat", _caller];
            ["aas_art_splash"] remoteExec ["playSound", _caller];
            deleteVehicle _soundDummy;

            for "_i" from 0 to (_shellCount - 1) do {
                private _impactPos = _dropPos getPos [random _spread, random 360];
                private _spawnPos = [_impactPos select 0, _impactPos select 1, (_dropPos select 2) + 400];
                
                private _shell = createVehicle ["Sh_155mm_AMOS", _spawnPos, [], 0, "FLY"];
                _shell setShotParents [_caller, _caller];
                _shell setVelocity [0, 0, -80]; 
                
                sleep (_delays select _i);
            };
        };
    };
    case "Arty155mm_DPICM": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 2;
            private _fireDelay = 7; 
            
            sleep 6;
            "FDC: Roger that. Airburst munition loaded!" remoteExec ["systemChat", _caller];
            ["aas_art_dpicmloaded"] remoteExec ["playSound", _caller];
            sleep 4;

            private _soundPos = _dropPos getPos [1500, random 360];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            // 1. Firing Phase (Heavy 155mm Thumps)
            for "_i" from 1 to _shellCount do {
                private _pitch = 0.4 + random 0.2;
                [
                    ["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", _soundDummy, false, getPosASL _soundDummy, 5, _pitch, 5000]
                ] remoteExec ["playSound3D", 0];
                sleep _fireDelay;
            };

            // Added sleep for radio silence after firing
            sleep 2.5;

            if (random 1 > 0.5) then {
                "FDC: Rounds complete, over." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete1"] remoteExec ["playSound", _caller];
            } else {
                "FDC: Rounds complete." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete2"] remoteExec ["playSound", _caller];
            };
            
            sleep 20;
            
            "FDC: SPLASH" remoteExec ["systemChat", _caller];
            ["aas_art_splash"] remoteExec ["playSound", _caller];
            deleteVehicle _soundDummy;
            sleep 5;

            // 2. DPICM AIRBURST PHASE
            for "_i" from 1 to _shellCount do {
                private _impactPos = _dropPos getPos [random 15, random 360];
                private _burstPos = [_impactPos select 0, _impactPos select 1, (_dropPos select 2) + 120];
                
                // Visual & Audio for the carrier shell popping open
                createVehicle ["HelicopterExploSmall", _burstPos, [], 0, "NONE"];
                [
                    [_burstPos], {
                        params ["_pos"];
                        // FIX: Replaced broken sound with a pitched-up airburst crack
                        playSound3D ["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", objNull, false, AGLToASL _pos, 5, 1.5, 3000];
                    }
                ] remoteExec ["spawn", 0];

                // 3. BOMBLET SATURATION (HIGHLY COMPRESSED)
                // 2 batches of 30 for 60 bomblets per shell
                for "_batch" from 1 to 2 do {
                    [_impactPos, _caller] spawn {
                        params ["_center", "_caller"];
                        
                        for "_b" from 1 to 30 do {
                            // 1. The Main Explosive Bomblet (40mm HE)
                            private _bPos = _center getPos [random 45, random 360];
                            
                            // Tighter vertical grouping (70m to 90m) so they impact closer together in time
                            _bPos set [2, 70 + random 20]; 
                            private _bomb = createVehicle ["G_40mm_HE", _bPos, [], 0, "CAN_COLLIDE"];
                            _bomb setShotParents [_caller, _caller];
                            
                            // Faster downward velocity
                            _bomb setVelocity [0, 0, -50 - random 10]; 
                            
                            // 2. The Shrapnel/Dirt Kick-up (Heavy MG Bullet)
                            private _dirtPos = _center getPos [random 45, random 360];
                            _dirtPos set [2, 2];
                            private _bullet = createVehicle ["B_127x99_Ball", _dirtPos, [], 0, "CAN_COLLIDE"];
                            _bullet setShotParents [_caller, _caller];
                            _bullet setVelocity [0, 0, -300]; 
                            
                            // Extremely tight delay (0 to 20ms) for an aggressive, overlapping ripping sound
                            sleep (random 0.02); 
                        };
                    };
                    
                    // Only 0.15s between batches so they practically merge into one massive popcorn effect
                    sleep 0.15; 
                };
                
                sleep _fireDelay;
            };
        };
    };
    
    case "Arty155mm_ADAM": { 
        [_caller, _dropPos, _playerSide] spawn {
            params ["_caller", "_dropPos", "_playerSide"];
            
            sleep 7;
            "FDC: Copy that, setting up ADAM fuze." remoteExec ["systemChat", _caller];
            ["aas_art_adamloaded"] remoteExec ["playSound", _caller];
            sleep 4;

            private _soundPos = _dropPos getPos [1500, random 360];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            private _pitch = 0.4 + random 0.2;
            [["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", _soundDummy, false, getPosASL _soundDummy, 5, _pitch, 5000]] remoteExec ["playSound3D", 0];

            // Added sleep for radio silence after firing
            sleep 6.5;

            if (random 1 > 0.5) then {
                "FDC: Rounds complete, over." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete1"] remoteExec ["playSound", _caller];
            } else {
                "FDC: Rounds complete." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete2"] remoteExec ["playSound", _caller];
            };
            
            sleep 18;
            
            "FDC: SPLASH" remoteExec ["systemChat", _caller];
            ["aas_art_splash"] remoteExec ["playSound", _caller];
            deleteVehicle _soundDummy;
            sleep 5;

            // AIRBURST
            private _burstPos = [_dropPos select 0, _dropPos select 1, (_dropPos select 2) + 120];
            createVehicle ["HelicopterExploSmall", _burstPos, [], 0, "NONE"];
            // FIX: Replaced broken sound with a pitched-up airburst crack
            [[_burstPos], { playSound3D ["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", objNull, false, AGLToASL (_this select 0), 5, 1.5, 3000]; }] remoteExec ["spawn", 0];

            // MINE DEPLOYMENT (28 AP Mines)
            private _mines = [];
            for "_b" from 1 to 28 do {
                private _mPos = _dropPos getPos [random 50, random 360];
                _mPos set [2, 0]; // Force exactly to ground level
                
                // Proper createMine command ensures it is armed and functional
                private _mine = createMine ["APERSMine", _mPos, [], 0];
                
                // Reveal the red triangle to the caller's side
                _playerSide revealMine _mine;
                _mines pushBack _mine;
                
                // Visual drop (Bullet slammed into the dirt 2 meters away so it doesn't accidentally hit the mine)
                private _dirtPos = [_mPos select 0, (_mPos select 1) + 2, 50];
                private _bullet = createVehicle ["B_127x99_Ball", _dirtPos, [], 0, "CAN_COLLIDE"];
                _bullet setShotParents [_caller, _caller];
                _bullet setVelocity [0, 0, -300]; 
                
                sleep (random 0.05); 
            };
            
            sleep 3;
            "FDC: Area Denial Munition deployed, check your step." remoteExec ["systemChat", _caller];
            ["aas_art_adamdployed"] remoteExec ["playSound", _caller];

            // MAP MARKER & TIMER (30 Minutes)
            [_dropPos, _mines, 30, _playerSide] spawn {
                params ["_pos", "_mines", "_minutes", "_side"];
                private _mID = format ["AAS_Minefield_%1", round time];
                
                private _mArea = createMarker [_mID + "_area", _pos];
                _mArea setMarkerShape "ELLIPSE";
                _mArea setMarkerSize [50, 50];
                _mArea setMarkerColor "ColorRed";
                _mArea setMarkerBrush "Border";
                
                private _mIcon = createMarker [_mID + "_icon", _pos];
                _mIcon setMarkerType "mil_warning";
                _mIcon setMarkerColor "ColorRed";
                
                private _jipKey = _mID + "_JIP";
                [[_mArea, _mIcon, _side], {
                    params ["_area", "_icon", "_s"];
                    if (hasInterface && {side group player != _s}) then {
                        _area setMarkerAlphaLocal 0;
                        _icon setMarkerAlphaLocal 0;
                    };
                }] remoteExec ["call", 0, _jipKey];

                for "_m" from _minutes to 1 step -1 do {
                    _mIcon setMarkerText (format ["MINEFIELD - EXPIRES IN %1 MIN", _m]);
                    sleep 60; 
                };
                
                deleteMarker _mArea;
                deleteMarker _mIcon;
                remoteExec ["", _jipKey]; 
                
                { if (!isNull _x) then { deleteVehicle _x; }; } forEach _mines;
            };
        };
    };
    
    // ================================================================================
    // [5] 155mm RAAMS (Anti-Armor Minefield)
    // ================================================================================
    case "Arty155mm_RAAMS": { 
        [_caller, _dropPos, _playerSide] spawn {
            params ["_caller", "_dropPos", "_playerSide"];
            
            sleep 7;
            "FDC: Preparing for minefield deployment. Shells loaded." remoteExec ["systemChat", _caller];
            ["aas_art_raamsloaded"] remoteExec ["playSound", _caller];
            sleep 4;

            private _soundPos = _dropPos getPos [1500, random 360];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            private _pitch = 0.4 + random 0.2;
            [["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", _soundDummy, false, getPosASL _soundDummy, 5, _pitch, 5000]] remoteExec ["playSound3D", 0];

            // Added sleep for radio silence after firing
            sleep 5.5;

            if (random 1 > 0.5) then {
                "FDC: Rounds complete, over." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete1"] remoteExec ["playSound", _caller];
            } else {
                "FDC: Rounds complete." remoteExec ["systemChat", _caller];
                ["aas_art_roundscomplete2"] remoteExec ["playSound", _caller];
            };
            
            sleep 18;
            
            "FDC: SPLASH" remoteExec ["systemChat", _caller];
            ["aas_art_splash"] remoteExec ["playSound", _caller];
            deleteVehicle _soundDummy;
            sleep 5;

            // AIRBURST
            private _burstPos = [_dropPos select 0, _dropPos select 1, (_dropPos select 2) + 120];
            createVehicle ["HelicopterExploSmall", _burstPos, [], 0, "NONE"];
            // FIX: Replaced broken sound with a pitched-up airburst crack
            [[_burstPos], { playSound3D ["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", objNull, false, AGLToASL (_this select 0), 5, 1.5, 3000]; }] remoteExec ["spawn", 0];

            // MINE DEPLOYMENT (15 AT Mines)
            private _mines = [];
            private _roads = _dropPos nearRoads 60; 
            
            for "_b" from 1 to 15 do {
                private _mPos = [];
                
                // 50% chance to snap to a road if one is nearby
                if (count _roads > 0 && {random 1 > 0.5}) then {
                    _mPos = (getPos (selectRandom _roads)) getPos [random 6, random 360];
                } else {
                    // Increased drop radius to 75m
                    _mPos = _dropPos getPos [random 75, random 360];
                };
                
                _mPos set [2, 0]; // Force to ground level
                
                // Proper createMine command
                private _mine = createMine ["ATMine", _mPos, [], 0];
                
                _playerSide revealMine _mine;
                _mines pushBack _mine;
                
                private _dirtPos = [_mPos select 0, (_mPos select 1) + 2, 50];
                private _bullet = createVehicle ["B_127x99_Ball", _dirtPos, [], 0, "CAN_COLLIDE"];
                _bullet setShotParents [_caller, _caller];
                _bullet setVelocity [0, 0, -300]; 
                
                sleep (random 0.05); 
            };
            
            sleep 3;
            "FDC: RAAMS deployed. Be careful!" remoteExec ["systemChat", _caller];
            ["aas_art_raamsdeployed"] remoteExec ["playSound", _caller];

            // MAP MARKER & TIMER (45 Minutes)
            [_dropPos, _mines, 45, _playerSide] spawn {
                params ["_pos", "_mines", "_minutes", "_side"];
                private _mID = format ["AAS_Minefield_%1", round time];
                
                private _mArea = createMarker [_mID + "_area", _pos];
                _mArea setMarkerShape "ELLIPSE";
                _mArea setMarkerSize [75, 75]; // Updated marker size to match 75m drop radius
                _mArea setMarkerColor "ColorRed";
                _mArea setMarkerBrush "Border";
                
                private _mIcon = createMarker [_mID + "_icon", _pos];
                _mIcon setMarkerType "mil_warning";
                _mIcon setMarkerColor "ColorRed";
                
                private _jipKey = _mID + "_JIP";
                [[_mArea, _mIcon, _side], {
                    params ["_area", "_icon", "_s"];
                    if (hasInterface && {side group player != _s}) then {
                        _area setMarkerAlphaLocal 0;
                        _icon setMarkerAlphaLocal 0;
                    };
                }] remoteExec ["call", 0, _jipKey];

                for "_m" from _minutes to 1 step -1 do {
                    _mIcon setMarkerText (format ["AT MINEFIELD - EXPIRES IN %1 MIN", _m]);
                    sleep 60; 
                };
                
                deleteMarker _mArea;
                deleteMarker _mIcon;
                remoteExec ["", _jipKey]; 
                
                { if (!isNull _x) then { deleteVehicle _x; }; } forEach _mines;
            };
        };
    };
    
    // ------------------- MLRS Rocket Strike -------------------
    case "ArtyMLRS_HEDPX7": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 7;
            private _spread = 60; 
            private _fireDelay = 0.8; 
            
            sleep 5;
            "FDC: Launching rockets toward the target." remoteExec ["systemChat", _caller];
            ["aas_art_launchingrockets"] remoteExec ["playSound", _caller];
            sleep 4;

            private _dir = _caller getDir _dropPos;
            // Spawn 45 degrees over the left or right shoulder
            private _launchOffset = selectRandom [-45, 45];
            private _launchDir = _dir - 180 + _launchOffset;
            
            // 1700m out + 1700m up = ~2400m diagonal distance. 
            // At 150 m/s, this guarantees exactly a 16-second flight time.
            private _spawnPos2D = _dropPos getPos [1700, _launchDir];
            private _spawnOrigin = [_spawnPos2D select 0, _spawnPos2D select 1, 1700];

            private _soundPos = _dropPos getPos [1500, _launchDir];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            for "_i" from 1 to _shellCount do {
                private _pitch = 0.8 + random 0.2;
                [["A3\Sounds_F\weapons\Rockets\new_rocket_8.wss", _soundDummy, false, getPosASL _soundDummy, 2.5, _pitch, 5000]] remoteExec ["playSound3D", 0];

                private _impactPos = _dropPos getPos [random _spread, random 360];
                
                [_spawnOrigin, _impactPos, _caller] spawn {
                    params ["_startPos", "_targetPos", "_caller"];
                    
                    private _targetASL = AGLToASL _targetPos;
                    private _startASL = AGLToASL _startPos;
                    
                    // Vanilla MLRS Rocket with standard smoke trail
                    private _rocket = createVehicle ["R_230mm_HE", _startPos, [], 0, "FLY"];
                    _rocket setShotParents [_caller, _caller];
                    _rocket setPosASL _startASL;
                    _rocket allowDamage false; 
                    
                    private _speed = 150; // Cinematic tracking speed
                    private _timeout = time + 25;
                    private _flybyPlayed = false;

                    while {alive _rocket && {(_rocket distance _targetASL) > 15} && {time < _timeout}} do {
                        private _currentPos = getPosASL _rocket;
                        
                        // Aim exactly at the target. No deep-earth offset, no forced "Up" vector.
                        private _newDir = [_currentPos, _targetASL] call BIS_fnc_vectorFromXToY;
                        
                        _rocket setVectorDir _newDir;
                        _rocket setVelocity ([_newDir, _speed] call BIS_fnc_vectorMultiply);
                        
                        if (!_flybyPlayed && {(_rocket distance _caller) < 400}) then {
                            _flybyPlayed = true;
                            [[_caller], {
                                params ["_c"];
                                if (hasInterface && {player distance _c < 800}) then {
                                    playSound3D ["A3\Sounds_F\weapons\Rockets\titan_flyby.wss", player, false, getPosASL player, 2.5, 1, 0];
                                };
                            }] remoteExec ["spawn", 0];
                        };

                        sleep 0.05; 
                    };
                    
                    // FIX: Double Explosion Bug
                    // Only manually detonate if the rocket hasn't already hit the ground naturally!
                    if (alive _rocket) then { 
                        deleteVehicle _rocket; 
                        
                        private _boomPos = _targetPos;
                        _boomPos set [2, 0.5];
                        
                        private _he = createVehicle ["R_230mm_HE", _boomPos, [], 0, "CAN_COLLIDE"];
                        _he setShotParents [_caller, _caller];
                        _he setDamage 1;
                    };
                };
                
                sleep _fireDelay;
            };

            // Calculate flight time to clean up the dummy object properly
            sleep 25;
            deleteVehicle _soundDummy;
        };
    };

    // ================================================================================
    // [7] MLRS ROCKET STRIKE (HEDP x14)
    // ================================================================================
    case "ArtyMLRS_HEDPX14": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 14;
            private _spread = 90; 
            private _fireDelay = 0.4; 
            
            sleep 5;
            "FDC: Launching rockets toward the target." remoteExec ["systemChat", _caller];
            ["aas_art_launchingrockets"] remoteExec ["playSound", _caller];
            sleep 4;

            private _dir = _caller getDir _dropPos;
            private _launchOffset = selectRandom [-45, 45];
            private _launchDir = _dir - 180 + _launchOffset;
            
            private _spawnPos2D = _dropPos getPos [1700, _launchDir];
            private _spawnOrigin = [_spawnPos2D select 0, _spawnPos2D select 1, 1700];

            private _soundPos = _dropPos getPos [1500, _launchDir];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            for "_i" from 1 to _shellCount do {
                private _pitch = 0.8 + random 0.2;
                [["A3\Sounds_F\weapons\Rockets\new_rocket_8.wss", _soundDummy, false, getPosASL _soundDummy, 2.5, _pitch, 5000]] remoteExec ["playSound3D", 0];

                private _impactPos = _dropPos getPos [random _spread, random 360];
                
                [_spawnOrigin, _impactPos, _caller] spawn {
                    params ["_startPos", "_targetPos", "_caller"];
                    
                    private _targetASL = AGLToASL _targetPos;
                    private _startASL = AGLToASL _startPos;
                    
                    private _rocket = createVehicle ["R_230mm_HE", _startPos, [], 0, "FLY"];
                    _rocket setShotParents [_caller, _caller];
                    _rocket setPosASL _startASL;
                    _rocket allowDamage false; 
                    
                    private _speed = 150; 
                    private _timeout = time + 25;
                    private _flybyPlayed = false;

                    while {alive _rocket && {(_rocket distance _targetASL) > 15} && {time < _timeout}} do {
                        private _currentPos = getPosASL _rocket;
                        private _newDir = [_currentPos, _targetASL] call BIS_fnc_vectorFromXToY;
                        
                        _rocket setVectorDir _newDir;
                        _rocket setVelocity ([_newDir, _speed] call BIS_fnc_vectorMultiply);
                        
                        if (!_flybyPlayed && {(_rocket distance _caller) < 400}) then {
                            _flybyPlayed = true;
                            [[_caller], {
                                params ["_c"];
                                if (hasInterface && {player distance _c < 800}) then {
                                    playSound3D ["A3\Sounds_F\weapons\Rockets\titan_flyby.wss", player, false, getPosASL player, 2.5, 1, 0];
                                };
                            }] remoteExec ["spawn", 0];
                        };

                        sleep 0.05; 
                    };
                    
                    // FIX: Double Explosion Bug
                    if (alive _rocket) then { 
                        deleteVehicle _rocket; 
                        
                        private _boomPos = _targetPos;
                        _boomPos set [2, 0.5];

                        private _he = createVehicle ["R_230mm_HE", _boomPos, [], 0, "CAN_COLLIDE"];
                        _he setShotParents [_caller, _caller];
                        _he setDamage 1;
                    };
                };
                
                sleep _fireDelay;
            };

            // Calculate flight time to clean up the dummy object properly
            sleep 25;
            deleteVehicle _soundDummy;
        };
    };
    
    case "ArtyMLRS_WP": { 
        [_caller, _dropPos] spawn {
            params ["_caller", "_dropPos"];
            
            private _shellCount = 3;
            private _fireDelay = 3.5;
            
            sleep 5;
            "FDC: White Phospor rockets incoming." remoteExec ["systemChat", _caller];
            ["aas_art_wprocketsincoming"] remoteExec ["playSound", _caller];
            sleep 4;

            private _dir = _caller getDir _dropPos;
            private _launchOffset = selectRandom [-45, 45];
            private _launchDir = _dir - 180 + _launchOffset;
            
            // 70-degree dive trajectory
            private _spawnPos2D = _dropPos getPos [800, _launchDir];
            private _spawnOrigin = [_spawnPos2D select 0, _spawnPos2D select 1, 2200];

            private _soundPos = _dropPos getPos [1200, _launchDir];
            _soundPos set [2, 0];
            private _soundDummy = createVehicle ["Land_HelipadEmpty_F", _soundPos, [], 0, "CAN_COLLIDE"];

            // --------------------------------------------------------
            // MULTI-ROCKET FIRING LOOP
            // --------------------------------------------------------
            for "_i" from 1 to _shellCount do {
                
                private _pitch = 0.8 + random 0.2;
                [["A3\Sounds_F\weapons\Rockets\new_rocket_8.wss", _soundDummy, false, getPosASL _soundDummy, 2.5, _pitch, 5000]] remoteExec ["playSound3D", 0];

                // Identify if this is the first rocket (The one that spawns the heavy smoke & damage)
                private _isMainRocket = (_i == 1);
                
                // NEW LOGIC: Rocket 1 hits center. Rockets 2 & 3 land 15m to 30m away to spread the cloud.
                private _impactDist = if (_isMainRocket) then { random 5 } else { 15 + random 15 };
                private _impactPos = _dropPos getPos [_impactDist, random 360];
                
                // FIRE INDIVIDUAL ROCKET
                [_spawnOrigin, _impactPos, _caller, _isMainRocket] spawn {
                    params ["_startPos", "_targetPos", "_caller", "_isMainRocket"];

                    private _rocket = createVehicle ["R_230mm_HE", _startPos, [], 0, "FLY"];
                    _rocket setShotParents [_caller, _caller];
                    _rocket setPosASL (AGLToASL _startPos);
                    
                    private _targetASL = AGLToASL _targetPos;
                    private _aimASL = [_targetASL select 0, _targetASL select 1, (_targetASL select 2) - 1000];
                    
                    private _speed = 150; 
                    private _timeout = time + 25;

                    while {alive _rocket && {((getPosATL _rocket) select 2) > 50} && {time < _timeout}} do {
                        private _currentPos = getPosASL _rocket;
                        private _newDir = [_currentPos, _aimASL] call BIS_fnc_vectorFromXToY;
                        
                        _rocket setVectorDir _newDir;
                        _rocket setVelocity ([_newDir, _speed] call BIS_fnc_vectorMultiply);
                        sleep 0.01; 
                    };
                    
                    // ========================================================
                    // 1. AIRBURST (ALL ROCKETS DO THIS)
                    // ========================================================
                    private _burstPos = if (alive _rocket) then { getPosATL _rocket } else { [_targetPos select 0, _targetPos select 1, 50] };
                    if (alive _rocket) then { deleteVehicle _rocket; }; 
                    
                    createVehicle ["SmallSecondary", _burstPos, [], 0, "NONE"];
                    [[_burstPos], { playSound3D ["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", objNull, false, AGLToASL (_this select 0), 5, 1.5, 3000]; }] remoteExec ["spawn", 0];

                    // ========================================================
                    // 2. THE AIR OCTOPUS (ALL ROCKETS DO THIS)
                    // ========================================================
                    for "_f" from 1 to 12 do {
                        private _flare = createVehicle ["CMflareAmmo", _burstPos, [], 0, "CAN_COLLIDE"];
                        private _angle = _f * 30; 
                        _flare setVelocity [sin(_angle) * 20, cos(_angle) * 20, -35 - random 10];
                    };

                    // ========================================================
                    // 3. HEAVY SMOKE & TOXIC LOOP (ONLY MAIN ROCKET)
                    // ========================================================
                    if (_isMainRocket) then {
                        
                        // --- PARTICLES ---
                        [
                            [_burstPos, _targetPos], {
                                params ["_bPos", "_gPos"];
                                if (!hasInterface) exitWith {};
                                
                                private _psAir = "#particlesource" createVehicleLocal _bPos;
                                _psAir setParticleParams [
                                    ["\A3\data_f\ParticleEffects\Universal\Universal", 16, 7, 48, 1], "", "Billboard",
                                    1, 15, [0, 0, 0], [0, 0, -40], 0, 10, 7.9, 0, 
                                    [8, 15, 30], [[1, 1, 1, 0.2], [1, 1, 1, 0.5], [1, 1, 1, 0]],
                                    [0.5], 0.1, 0.1, "", "", _bPos
                                ];
                                _psAir setParticleRandom [2, [5, 5, 5], [5, 5, 0], 0, 0.5, [0, 0, 0, 0], 0, 0];
                                _psAir setDropInterval 0.05; 
                                [_psAir] spawn { sleep 1.5; deleteVehicle (_this select 0); }; 
                                
                                private _psGround = "#particlesource" createVehicleLocal _gPos;
                                _psGround setParticleParams [
                                    ["\A3\data_f\ParticleEffects\Universal\Universal", 16, 7, 48, 1], "", "Billboard",
                                    1, 30, [0, 0, 0], [0, 0, 1], 0, 10, 7.9, 0,
                                    [10, 30, 45], [[1, 1, 1, 0.2], [1, 1, 1, 0.4], [1, 1, 1, 0]],
                                    [0.5], 0.1, 0.1, "", "", _gPos
                                ];
                                _psGround setParticleRandom [2, [15, 15, 2], [3, 3, 2], 0, 0.5, [0, 0, 0, 0], 0, 0];
                                _psGround setDropInterval 0.15;
                                [_psGround] spawn { sleep 45; deleteVehicle (_this select 0); }; 
                            }
                        ] remoteExec ["spawn", 0];

                        // --- GROUND SPLASH & TOXIC LOOP ---
                        [_targetPos] spawn {
                            params ["_gPos"];
                            
                            sleep 1.5; 
                            
                            [[_gPos], { playSound3D ["A3\Sounds_F\weapons\Explosion\expl_shell_2.wss", objNull, false, AGLToASL (_this select 0), 5, 1.5, 3000]; }] remoteExec ["spawn", 0];
                            
                            for "_s" from 1 to 6 do {
                                createVehicle ["SmokeShellArty", _gPos getPos [random 20, random 360], [], 0, "CAN_COLLIDE"];
                            };

                            for "_b" from 1 to 8 do {
                                private _flare = createVehicle ["CMflareAmmo", _gPos, [], 0, "CAN_COLLIDE"];
                                _flare setVelocity [(random 40) - 20, (random 40) - 20, 20 + random 15]; 
                            };

                            // CHECK IF ACE3 IS LOADED (Specifically the fire component)
                            private _hasACE = !isNil "ace_fire_fnc_burn";

                            private _endTime = time + 45;
                            while {time < _endTime} do {
                                
                                // 5x Random Flares
                                for "_f" from 1 to 5 do {
                                    if (random 1 > 0.6) then {
                                        private _randFlare = createVehicle ["CMflareAmmo", _gPos getPos [random 25, random 360], [], 0, "CAN_COLLIDE"];
                                        _randFlare setVelocity [(random 30) - 15, (random 30) - 15, 10 + random 25];
                                    };
                                };

                                // Apply WP damage & effects (80m Radius)
                                private _victims = _gPos nearEntities [["Man", "Car", "Tank"], 80];
                                
                                { 
                                    private _victim = _x;
                                    if (alive _victim) then { 
                                        
                                        private _dist = _victim distance2D _gPos;
                                        
                                        // 1. Calculate base damage multiplier based on distance (40m vs 80m)
                                        private _dmgMult = if (_dist <= 40) then { 1 } else { 0.25 };
                                        
                                        // 2. Halve the damage if they are inside a vehicle
                                        private _inVehicle = (vehicle _victim != _victim);
                                        if (_inVehicle) then { _dmgMult = _dmgMult * 0.5; };
                                        
                                        // 3. Apply the calculated damage
                                        // Base: Infantry die in 10s, Vehicles take 50s to melt
                                        private _dmgAmount = if (_victim isKindOf "Man") then { 0.1 } else { 0.02 };
                                        _victim setDamage ((damage _victim) + (_dmgAmount * _dmgMult)); 

                                        // 4. VISUAL BURNING & PANIC EFFECT
                                        if !(_victim getVariable ["aas_isBurning", false]) then {
                                            
                                            // DELAYED IGNITION: 20% chance per second to catch on fire
                                            if (random 1 > 0.80) then {
                                                _victim setVariable ["aas_isBurning", true];
                                                
                                                if (_hasACE) then {
                                                    // ------------------------------------------------
                                                    // ACE3 INTEGRATION
                                                    // ------------------------------------------------
                                                    [_victim, 15] call ace_fire_fnc_burn; // Capped to 15s

                                                    // Allow them to catch fire again after 15s if they are still in the cloud
                                                    [_victim] spawn {
                                                        params ["_v"];
                                                        sleep 15;
                                                        if (alive _v) then { _v setVariable ["aas_isBurning", false]; };
                                                    };

                                                } else {
                                                    // ------------------------------------------------
                                                    // VANILLA FALLBACK
                                                    // ------------------------------------------------
                                                    if (_victim isKindOf "Man") then {
                                                        // A. Play a vanilla choking/screaming sound
                                                        private _scream = selectRandom [
                                                            "a3\sounds_f\characters\human-sfx\person0\p0_choke_04.wss", 
                                                            "a3\sounds_f\characters\human-sfx\person1\p1_choke_04.wss",
                                                            "a3\sounds_f\characters\human-sfx\person2\p2_choke_05.wss"
                                                        ];
                                                        [[_scream, _victim], { playSound3D [(_this select 0), (_this select 1), false, getPosASL (_this select 1), 3, 1, 150]; }] remoteExec ["spawn", 0];
                                                        
                                                        // B. AI Panic Logic (Only runs if victim is AI and local)
                                                        if (local _victim && {!(isPlayer _victim)}) then {
                                                            _victim setUnitPos "UP";
                                                            _victim setSpeedMode "FULL";
                                                            _victim setBehaviour "CARELESS"; 
                                                            _victim disableAI "AUTOTARGET";
                                                            _victim disableAI "TARGET";
                                                            _victim disableAI "SUPPRESSION";
                                                            
                                                            // Make them run directly away from the center of the WP strike
                                                            private _runDir = _gPos getDir _victim;
                                                            private _escapePos = _victim getPos [50 + random 50, _runDir + (random 60 - 30)];
                                                            _victim doMove _escapePos;
                                                        };
                                                    };

                                                    // C. RemoteExec particle flames so all players see them burning
                                                    [[_victim], {
                                                        params ["_v"];
                                                        if (!hasInterface) exitWith {};
                                                        
                                                        private _fire = "#particlesource" createVehicleLocal getPos _v;
                                                        _fire setParticleClass "ObjectDestructionFire1Smallx";
                                                        _fire attachTo [_v, [0, 0, 0.5]];

                                                        private _smoke = "#particlesource" createVehicleLocal getPos _v;
                                                        _smoke setParticleClass "ObjectDestructionSmokeSmallx";
                                                        _smoke attachTo [_v, [0, 0, 0.5]];

                                                        // STRICT 15 SECOND TIMER (Dead or alive)
                                                        [_v, _fire, _smoke] spawn {
                                                            params ["_v", "_f", "_s"];
                                                            sleep 15; 
                                                            
                                                            // Delete the visual effects
                                                            if (!isNull _f) then { deleteVehicle _f; };
                                                            if (!isNull _s) then { deleteVehicle _s; };

                                                            // Reset the burning tag so they can reignite if they are still in the WP cloud!
                                                            if (alive _v) then { _v setVariable ["aas_isBurning", false]; };
                                                        };
                                                    }] remoteExec ["spawn", 0];
                                                };
                                            };
                                        }; 
                                    }; 
                                } forEach _victims;
                                
                                sleep 1;
                            };
                        };
                    };
                };
                
                // Delay before firing the next rocket
                sleep _fireDelay; 
            };

            // Calculate flight time to clean up the dummy object properly
            sleep 25;
            deleteVehicle _soundDummy;
        };
    };
};