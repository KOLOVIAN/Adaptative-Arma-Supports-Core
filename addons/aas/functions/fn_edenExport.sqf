// AAS_Core/functions/fn_edenExport.sqf

// Get the entity the mouse is currently hovering over in Eden
private _hoveredEntity = get3DENMouseOver;

// Failsafe: Ensure they actually clicked/hovered on a valid object
if (count _hoveredEntity == 0 || {(_hoveredEntity select 0) != "Object"}) exitWith {
    ["AAS ERROR: No object selected.", 1] call BIS_fnc_3DENNotification; // 1 = Red Error Notification
};

// Grab the hovered object
private _obj = _hoveredEntity select 1;
private _class = typeOf _obj;
private _exportData = "";
private _clipboardFormat = [];

// ==========================================
// 1. SOLDIER EXPORT (Virtual Arsenal)
// ==========================================
if (_obj isKindOf "Man") then {
    private _loadout = getUnitLoadout _obj;
    _clipboardFormat = [_class, _loadout];
    
    // Copy to clipboard formatted exactly as an array
    copyToClipboard (str _clipboardFormat);
    
    // Shows a Green Success Notification in the Eden Editor UI
    ["AAS SUCCESS: Infantry Loadout copied to clipboard!", 0] call BIS_fnc_3DENNotification; 
} 
// ==========================================
// 2. VEHICLE EXPORT (Pylons & Skins)
// ==========================================
else {
    private _codeString = "";

    // A. Extract Eden Skins and Animations (Doors removed, camo nets, etc.)
    private _customization = [_obj] call BIS_fnc_getVehicleCustomization;
    private _textures = _customization select 0;
    private _anims = _customization select 1;
    
    if (count _textures > 0 || count _anims > 0) then {
        // Build the code string to re-apply the skin/animations
        _codeString = _codeString + format ["[_this, %1, %2] call BIS_fnc_initVehicle; ", _textures, _anims];
    };

    // B. Extract Dynamic Pylons (Bombs, Missiles, Guns)
    private _pylons = getPylonMagazines _obj;
    if (count _pylons > 0) then {
        {
            if (_x != "") then {
                // _forEachIndex + 1 gets the correct Pylon number
                // We intentionally use single quotes around %2 so it doesn't break the outer string!
                _codeString = _codeString + format ["_this setPylonLoadout [%1, '%2']; ", _forEachIndex + 1, _x];
            };
        } forEach _pylons;
    };

    // If no custom code was generated, just export the classname
    if (_codeString == "") then {
        _clipboardFormat = [_class, ""];
    } else {
        _clipboardFormat = [_class, _codeString];
    };

    copyToClipboard (str _clipboardFormat);
    
    // Shows a Green Success Notification in the Eden Editor UI
    ["AAS SUCCESS: Vehicle Configuration copied to clipboard!", 0] call BIS_fnc_3DENNotification;
};