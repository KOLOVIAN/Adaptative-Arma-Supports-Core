params ["_logic", "_units", "_activated"];

if (!_activated) exitWith {};

private _caller = player; 
private _dropPos = getPosATL _logic;
private _isZeusOverride = true; 

// Forward to your server-side supply drop script
[_caller, _dropPos, _isZeusOverride] remoteExec ["aas_fnc_serverSupplyDrop", 2]; 

deleteVehicle _logic;
