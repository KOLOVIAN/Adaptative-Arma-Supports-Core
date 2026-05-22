// AAS-QRF/functions/fn_moduleQRF.sqf

params ["_logic", "_units", "_activated"];

if (!_activated) exitWith {};

// The caller is the player who placed the module (the Zeus)
private _caller = player;
private _dropPos = getPosATL _logic;
private _isZeusOverride = true; // Override flag to skip costs/cooldowns

// Forward the parameters to the new QRF server-side function
[_caller, _dropPos, _isZeusOverride] remoteExec ["aqr_fnc_serverQRF", 2];

// Clean up the module so it doesn't clutter the Zeus screen
deleteVehicle _logic;