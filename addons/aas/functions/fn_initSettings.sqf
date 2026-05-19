// functions/fn_initSettings.sqf

// --- NEW: GLOBAL REGISTRY INITIALIZATION (PRE-INIT) ---
// Moved here to prevent load-order overwrites with Theme mods!
if (isNil "AAS_Menu_Registry") then { AAS_Menu_Registry = []; };
if (isNil "AAS_Loaded_Modules") then { AAS_Loaded_Modules = []; };


// ==========================================
// --- AAS - DYNAMIC THEME REGISTRY ---
// ==========================================
// Initialize the registry if it hasn't been created by another mod already.
// Any third-party theme mod MUST list AAS-Core in its 'requiredAddons' to ensure 
// they can push to this array before this settings file executes.

if (isNil "AAS_Theme_Registry") then {
    // Format: ["ThemeID", "Display Name", "Pager_PAA_Path", "Tablet_PAA_Path"]
    AAS_Theme_Registry = [
        ["aas_modern", "Modern", "\aas\data\tacticalpager_modern.paa", "\aas\data\tablet.paa"],
        ["aas_retro", "Retro", "\aas\data\tacticalpager_retro.paa", "\aas\data\tablet_retro.paa"]
    ];
};

// Dynamically build the arrays required by CBA Settings
private _themeValues = [];
private _themeNames = [];

{
    _themeValues pushBack _forEachIndex;  // Uses the index (0, 1, 2...) as the setting value
    _themeNames pushBack (_x select 1);   // Extracts the "Display Name" for the dropdown UI
} forEach AAS_Theme_Registry;


// ==========================================
// --- AAS - CORE SETTINGS ---
// ==========================================

// --- NEW: Toggle for Startup Notification ---
[ 
    "AAS_Show_Startup_Message", "CHECKBOX", 
    ["Startup Notification", "Show the systemChat message displaying loaded AAS modules on mission start."], 
    ["AAS - CORE SETTINGS", "1. UI & Systems"], 
    false, 
    1 
] call CBA_fnc_addSetting;

[ 
    "AAS_Pager_Theme", "LIST", 
    ["Aesthetic", "Choose the visual theme for the Pager and Support Tablets. (Dynamically populated via mod registry)"], 
    ["AAS - CORE SETTINGS", "1. UI & Systems"], 
    [_themeValues, _themeNames, 0], // Injecting the dynamically generated lists here
    1 
] call CBA_fnc_addSetting;

[ 
    "AAS_Signal_Grenade", "EDITBOX", 
    ["Signal Grenade", "Classname for the smoke grenade that opens the supports menu."], 
    ["AAS - CORE SETTINGS", "1. UI & Systems"], 
    "SmokeShellOrange", 
    1 
] call CBA_fnc_addSetting;

[ 
    "AAS_Econ_Preset_Core", "LIST", 
    ["Global Economy Preset", "Select which economy framework to use across ALL supports."], 
    ["AAS - CORE SETTINGS", "2. Global Economy"], [
        [0, 1, 6, 2, 3, 4, 5], 
        ["Custom / Free", "Antistasi (Faction Funds)", "Antistasi (Personal Funds)", "KP Liberation", "Overthrow", "Vanilla Warlords", "DUWS"], 
        0
    ], 1 
] call CBA_fnc_addSetting;

// ==========================================
// --- SUPPLY DROP MODULE ---
// ==========================================

// --- Classnames & Parameters ---
[ "AAS_Heli_Supply", "EDITBOX", ["Supply Helicopter", "Classname for the unarmed supply drop helicopter."], ["AAS - Supply Drop", "1. Classnames & Parameters"], "O_Heli_Light_02_unarmed_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Supply", "EDITBOX", ["Supply Cooldown (Seconds)", "Enter the cooldown time in seconds."], ["AAS - Supply Drop", "1. Classnames & Parameters"], "600", 1 ] call CBA_fnc_addSetting;

// --- Economy Costs ---
[ "AAS_Cost_Supply_Custom", "EDITBOX", ["Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - Supply Drop", "2. Economy Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Supply_Antistasi", "EDITBOX", ["Cost: Antistasi", "Used for both Faction and Personal presets."], ["AAS - Supply Drop", "2. Economy Costs"], "500", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Supply_Overthrow", "EDITBOX", ["Cost: Overthrow", "Default Wallet funds."], ["AAS - Supply Drop", "2. Economy Costs"], "2000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Supply_Warlords", "EDITBOX", ["Cost: Warlords", "Default Command Points."], ["AAS - Supply Drop", "2. Economy Costs"], "100", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Supply_DUWS", "EDITBOX", ["Cost: DUWS", "Default CP."], ["AAS - Supply Drop", "2. Economy Costs"], "3", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Supply_KPLib_S", "EDITBOX", ["Cost: KP Lib (Supplies)", "Supplies threshold."], ["AAS - Supply Drop", "2. Economy Costs"], "50", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Supply_KPLib_A", "EDITBOX", ["Cost: KP Lib (Ammo)", "Ammo threshold."], ["AAS - Supply Drop", "2. Economy Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Supply_KPLib_F", "EDITBOX", ["Cost: KP Lib (Fuel)", "Fuel threshold."], ["AAS - Supply Drop", "2. Economy Costs"], "50", 1 ] call CBA_fnc_addSetting;
[ "AAS_Econ_Code_Supply", "EDITBOX", ["Supply Economy Code", "SQF code for Custom mode. Use '_cost' in your code."], ["AAS - Supply Drop", "2. Economy Costs"], "", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- CAS STRIKE MODULE ---
// ==========================================

// --- Classnames & Parameters ---
[ "AAS_Heli_CAS", "EDITBOX", ["CAS Aircraft", "Classname for the attack helicopter/plane."], ["AAS - CAS Strike", "1. Classnames & Parameters"], "B_Heli_Attack_01_dynamicLoadout_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_CAS", "EDITBOX", ["CAS Cooldown (Seconds)", "Enter the cooldown time in seconds."], ["AAS - CAS Strike", "1. Classnames & Parameters"], "900", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_CAS", "EDITBOX", ["CAS RTB Time (Seconds)", "Time in seconds before the CAS leaves the AO."], ["AAS - CAS Strike", "1. Classnames & Parameters"], "120", 1 ] call CBA_fnc_addSetting;
[ "AAS_Height_CAS", "EDITBOX", ["CAS Flight Height (Meters)", "Altitude maintained during loiter. Set higher for drones (e.g., 500)."], ["AAS - CAS Strike", "1. Classnames & Parameters"], "150", 1 ] call CBA_fnc_addSetting;
[ "AAS_Loiter_CAS", "EDITBOX", ["CAS Loiter Radius (Meters)", "Radius of the loiter circle. Larger is better for fixed-wing/drones."], ["AAS - CAS Strike", "1. Classnames & Parameters"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_Behavior_CAS", "LIST", ["CAS Behavior", "Select the AI behavior pattern."], ["AAS - CAS Strike", "1. Classnames & Parameters"], [[0, 1], ["Loiter (Circles LZ)", "Search and Destroy (Hunts Targets)"], 0], 1 ] call CBA_fnc_addSetting;

// --- NEW: Gunship Orbit Toggle ---
[ "AAS_CAS_CounterClockwise", "CHECKBOX", ["Force Gunship Orbit", "Forces a counter-clockwise loiter and disables pilot attack dives. For aircraft with side-firing weapons."], ["AAS - CAS Strike", "1. Classnames & Parameters"], false, 1 ] call CBA_fnc_addSetting;

// --- Economy Costs ---
[ "AAS_Cost_CAS_Custom", "EDITBOX", ["Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - CAS Strike", "2. Economy Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Antistasi", "EDITBOX", ["Cost: Antistasi", "Used for both Faction and Personal presets."], ["AAS - CAS Strike", "2. Economy Costs"], "1000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Overthrow", "EDITBOX", ["Cost: Overthrow", "Default Wallet funds."], ["AAS - CAS Strike", "2. Economy Costs"], "6000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Warlords", "EDITBOX", ["Cost: Warlords", "Default Command Points."], ["AAS - CAS Strike", "2. Economy Costs"], "250", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_DUWS", "EDITBOX", ["Cost: DUWS", "Default CP."], ["AAS - CAS Strike", "2. Economy Costs"], "8", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_S", "EDITBOX", ["Cost: KP Lib (Supplies)", "Supplies threshold."], ["AAS - CAS Strike", "2. Economy Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_A", "EDITBOX", ["Cost: KP Lib (Ammo)", "Ammo threshold."], ["AAS - CAS Strike", "2. Economy Costs"], "200", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_F", "EDITBOX", ["Cost: KP Lib (Fuel)", "Fuel threshold."], ["AAS - CAS Strike", "2. Economy Costs"], "150", 1 ] call CBA_fnc_addSetting;
[ "AAS_Econ_Code_CAS", "EDITBOX", ["CAS Economy Code", "SQF code for Custom mode. Use '_cost' in your code."], ["AAS - CAS Strike", "2. Economy Costs"], "", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- REINFORCEMENTS MODULE ---
// ==========================================

// --- Classnames & Parameters ---
[ "AAS_Heli_Reinf", "EDITBOX", ["Transport Helicopter", "Classname for the troop transport helicopter."], ["AAS - Reinforcements", "1. Classnames & Parameters"], "B_Heli_Light_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_SL", "EDITBOX", ["1. Squad Leader", "Base classname for the Squad Leader model."], ["AAS - Reinforcements", "1. Classnames & Parameters"], "B_G_Soldier_SL_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_MG", "EDITBOX", ["2. Machine Gunner", "Base classname for the Machine Gunner model."], ["AAS - Reinforcements", "1. Classnames & Parameters"], "B_G_Soldier_AR_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_AT", "EDITBOX", ["3. Anti-Tank Specialist", "Base classname for the AT model."], ["AAS - Reinforcements", "1. Classnames & Parameters"], "B_G_Soldier_GL_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Sniper", "EDITBOX", ["4. Sniper / Medic", "Base classname for the Sniper model."], ["AAS - Reinforcements", "1. Classnames & Parameters"], "B_G_Soldier_M_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Reinf", "EDITBOX", ["Reinforcements Cooldown (Seconds)", "Enter the cooldown time in seconds."], ["AAS - Reinforcements", "1. Classnames & Parameters"], "600", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_Reinf", "EDITBOX", ["Transport RTB Time (Seconds)", "Time in seconds before the troops extract/despawn."], ["AAS - Reinforcements", "1. Classnames & Parameters"], "300", 1 ] call CBA_fnc_addSetting;
[ "AAS_Behavior_Reinf", "LIST", ["Squad Behavior", "Select the squad's orders upon landing."], ["AAS - Reinforcements", "1. Classnames & Parameters"], [[0, 1, 2], ["Guard LZ", "Follow Player", "Rush Enemies"], 0], 1 ] call CBA_fnc_addSetting;

// --- Economy Costs ---
[ "AAS_Cost_Reinf_Custom", "EDITBOX", ["Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - Reinforcements", "2. Economy Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Antistasi", "EDITBOX", ["Cost: Antistasi", "Used for both Faction and Personal presets."], ["AAS - Reinforcements", "2. Economy Costs"], "1500", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Overthrow", "EDITBOX", ["Cost: Overthrow", "Default Wallet funds."], ["AAS - Reinforcements", "2. Economy Costs"], "9000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Warlords", "EDITBOX", ["Cost: Warlords", "Default Command Points."], ["AAS - Reinforcements", "2. Economy Costs"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_DUWS", "EDITBOX", ["Cost: DUWS", "Default CP."], ["AAS - Reinforcements", "2. Economy Costs"], "12", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_S", "EDITBOX", ["Cost: KP Lib (Supplies)", "Supplies threshold."], ["AAS - Reinforcements", "2. Economy Costs"], "200", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_A", "EDITBOX", ["Cost: KP Lib (Ammo)", "Ammo threshold."], ["AAS - Reinforcements", "2. Economy Costs"], "150", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_F", "EDITBOX", ["Cost: KP Lib (Fuel)", "Fuel threshold."], ["AAS - Reinforcements", "2. Economy Costs"], "50", 1 ] call CBA_fnc_addSetting;
[ "AAS_Econ_Code_Reinf", "EDITBOX", ["Reinf Economy Code", "SQF code for Custom mode. Use '_cost' in your code."], ["AAS - Reinforcements", "2. Economy Costs"], "", 1 ] call CBA_fnc_addSetting;