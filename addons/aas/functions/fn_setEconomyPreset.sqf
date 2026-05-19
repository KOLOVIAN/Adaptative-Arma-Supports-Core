// functions/fn_setEconomyPreset.sqf
// This function handles all money logic and returns TRUE (pass) or FALSE (fail).
// Master Economy Router for AAS Core and all Sub-Modules.

params [
    "_caller", 
    "_cost", 
    "_presetIndex", 
    ["_customCodeString", ""], 
    ["_supportType", ""] // Optional: kept for legacy compatibility
];

// STRICT SECURITY: Default to false. It only turns true if a specific economy check passes.
private _passed = false;

switch (_presetIndex) do {
    
    // ==========================================
    // PRESET 0: CUSTOM / FREE
    // ==========================================
    case 0: {
        if (_customCodeString isNotEqualTo "") then {
            // Evaluates custom code defined by the user in CBA settings securely
            _passed = [_caller, _cost] call compile _customCodeString;
        } else {
            _passed = true; // Free mode if no code is provided
        };
    };

    // ==========================================
    // PRESET 1: ANTISTASI (Faction Funds)
    // ==========================================
    case 1: {
        // Antistasi safely uses the dynamic _cost variable from the server script
        private _currentMoney = server getVariable ["resourcesFIA", 0];
        if (_currentMoney < _cost) then {
            (format ["HQ: Insufficient Faction funds. Need €%1.", _cost]) remoteExec ["systemChat", _caller];
        } else {
            [0, -_cost] remoteExec ["A3A_fnc_resourcesFIA", 2];
            _passed = true;
        };
    };

    // ==========================================
    // PRESET 2: KP LIBERATION (Threshold Check Only)
    // ==========================================
    case 2: {
        private _suppliesNeeded = 0;
        private _ammoNeeded = 0;
        private _fuelNeeded = 0;
        
        // KP Lib now expects the server script to pass an array [S, A, F] into the _cost parameter
        if (_cost isEqualType []) then {
            _suppliesNeeded = _cost param [0, 0];
            _ammoNeeded     = _cost param [1, 0];
            _fuelNeeded     = _cost param [2, 0];
        } else {
            // Failsafe: If a sub-mod only passes a single number, assign it to supplies to prevent a crash
            _suppliesNeeded = _cost;
        };

        // Fetch current global resources from the FOB network
        private _currentSupplies = missionNamespace getVariable ["KP_liberation_supplies_global", 0];
        private _currentAmmo = missionNamespace getVariable ["KP_liberation_ammo_global", 0];
        private _currentFuel = missionNamespace getVariable ["KP_liberation_fuel_global", 0];

        // Check if the commander meets the logistical threshold
        if (_currentSupplies < _suppliesNeeded || _currentAmmo < _ammoNeeded || _currentFuel < _fuelNeeded) then {
            (format ["HQ: FOB logistical capacity too low. Need %1 S / %2 A / %3 F.", _suppliesNeeded, _ammoNeeded, _fuelNeeded]) remoteExec ["systemChat", _caller];
        } else {
            // No physical deduction. Resources act as a logistical requirement check.
            "HQ: Logistical threshold met. Support authorized." remoteExec ["systemChat", _caller];
            _passed = true;
        };
    };

    // ==========================================
    // PRESET 3: OVERTHROW
    // ==========================================
    case 3: {
        // Overthrow tracks money directly on the player's unit
        private _currentMoney = _caller getVariable ["money", 0];

        if (_currentMoney < _cost) then {
            (format ["HQ: Insufficient funds. Need $%1.", _cost]) remoteExec ["systemChat", _caller];
        } else {
            // Deduct the money directly from the player's personal wallet
            _caller setVariable ["money", _currentMoney - _cost, true];
            _passed = true;
        };
    };

    // ==========================================
    // PRESET 4: VANILLA WARLORDS
    // ==========================================
    case 4: {
        // Warlords uses a specific BIS function to read and modify Command Points
        private _currentFunds = _caller getVariable ["BIS_WL_funds", 0];
        
        if (_currentFunds >= _cost) then {
            // Deduct funds using the official Warlords database function
            [_caller, -_cost] call BIS_fnc_WLfundsDatabase; 
            _passed = true;
        } else {
            (format ["HQ: Insufficient Command Points. Need %1 CP.", _cost]) remoteExec ["systemChat", _caller];
        };
    };

    // ==========================================
    // PRESET 5: DUWS
    // ==========================================
    case 5: {
        // DUWS tracks CP via a global mission namespace variable
        private _currentCP = missionNamespace getVariable ["commandpointsblu1", 0];

        if (_currentCP < _cost) then {
            (format ["HQ: Insufficient Command Points. Need %1 CP.", _cost]) remoteExec ["systemChat", _caller];
        } else {
            // Deduct the CP globally
            missionNamespace setVariable ["commandpointsblu1", _currentCP - _cost, true];
            _passed = true;
        };
    };

    // ==========================================
    // PRESET 6: ANTISTASI (Personal Funds)
    // ==========================================
    case 6: { 
        // Personal money is tracked on the player object as "moneyX"
        private _currentFunds = _caller getVariable ["moneyX", 0];
        
        if (_currentFunds >= _cost) then {
            // PERFECT FIX: We only call the native function once, preventing the double deduction!
            [-_cost] remoteExec ["A3A_fnc_resourcesPlayer", _caller];
            
            // Explicit systemChat so the player knows the money was taken
            (format ["HQ: Support authorized. -%1 € deducted from Personal Account.", _cost]) remoteExec ["systemChat", _caller];
            
            _passed = true;
        } else {
            (format ["HQ: Insufficient Personal funds. Need %1 €.", _cost]) remoteExec ["systemChat", _caller];
        };
    };
};

// Return the final result back to the server script that asked for it
_passed;