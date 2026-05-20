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
        ["aas_modern", "Modern", "\z\aas\addons\aas\data\tacticalpager_modern.paa", "\z\aas\addons\aas\data\tablet.paa"],
        ["aas_retro", "Retro", "\z\aas\addons\aas\data\tacticalpager_retro.paa", "\z\aas\addons\aas\data\tablet_retro.paa"]
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
// --- CLOSE AIR SUPPORT (CAS) MODULE ---
// ==========================================

// --- 1. Global CAS Parameters ---
[ "AAS_Cooldown_CAS", "EDITBOX", ["Global CAS Cooldown (Seconds)", "Global cooldown time for all CAS supports."], ["AAS - Close Air Support", "1. Global Parameters"], "900", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_CAS", "EDITBOX", ["Global CAS RTB Time (Seconds)", "Global time before the CAS leaves the AO."], ["AAS - Close Air Support", "1. Global Parameters"], "120", 1 ] call CBA_fnc_addSetting;

// --- 2. Plane Settings ---
[ "AAS_CAS_Plane_Class", "EDITBOX", ["Plane Classname", "Classname for the CAS Plane."], ["AAS - Close Air Support", "2. Plane"], "B_Plane_CAS_01_dynamicLoadout_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Plane_Behavior", "LIST", ["Plane Behavior", "Select the AI behavior pattern."], ["AAS - Close Air Support", "2. Plane"], [[0, 1], ["Loiter (Circles LZ)", "Search and Destroy (Hunts Targets)"], 1], 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Plane_CostMult", "EDITBOX", ["Plane Cost Multiplier", "Multiplies the base CAS cost."], ["AAS - Close Air Support", "2. Plane"], "1.5", 1 ] call CBA_fnc_addSetting;

// --- 3. Helicopter Settings ---
[ "AAS_CAS_Heli_Class", "EDITBOX", ["Helicopter Classname", "Classname for the CAS Helicopter."], ["AAS - Close Air Support", "3. Helicopter"], "B_Heli_Attack_01_dynamicLoadout_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Heli_Behavior", "LIST", ["Helicopter Behavior", "Select the AI behavior pattern."], ["AAS - Close Air Support", "3. Helicopter"], [[0, 1], ["Loiter (Circles LZ)", "Search and Destroy (Hunts Targets)"], 0], 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Heli_Height", "EDITBOX", ["Helicopter Loiter Height", "Altitude in meters."], ["AAS - Close Air Support", "3. Helicopter"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Heli_Radius", "EDITBOX", ["Helicopter Loiter Radius", "Radius in meters."], ["AAS - Close Air Support", "3. Helicopter"], "600", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Heli_CostMult", "EDITBOX", ["Helicopter Cost Multiplier", "Multiplies the base CAS cost."], ["AAS - Close Air Support", "3. Helicopter"], "1.0", 1 ] call CBA_fnc_addSetting;

// --- 4. Gunship Settings ---
[ "AAS_CAS_Gunship_Class", "EDITBOX", ["Gunship Classname", "Classname for the Gunship."], ["AAS - Close Air Support", "4. Gunship"], "B_T_VTOL_01_armed_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Gunship_Orbit", "CHECKBOX", ["Force Counter-Clockwise Orbit", "Forces a counter-clockwise loiter direction."], ["AAS - Close Air Support", "4. Gunship"], true, 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Gunship_Height", "EDITBOX", ["Gunship Loiter Height", "Altitude in meters."], ["AAS - Close Air Support", "4. Gunship"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Gunship_Radius", "EDITBOX", ["Gunship Loiter Radius", "Radius in meters."], ["AAS - Close Air Support", "4. Gunship"], "1000", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Gunship_CostMult", "EDITBOX", ["Gunship Cost Multiplier", "Multiplies the base CAS cost."], ["AAS - Close Air Support", "4. Gunship"], "2.5", 1 ] call CBA_fnc_addSetting;

// --- 5. Economy Base Costs ---
[ "AAS_Cost_CAS_Custom", "EDITBOX", ["Base Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - Close Air Support", "5. Economy Base Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Antistasi", "EDITBOX", ["Base Cost: Antistasi", "Used for both Faction and Personal presets."], ["AAS - Close Air Support", "5. Economy Base Costs"], "1000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Overthrow", "EDITBOX", ["Base Cost: Overthrow", "Default Wallet funds."], ["AAS - Close Air Support", "5. Economy Base Costs"], "6000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Warlords", "EDITBOX", ["Base Cost: Warlords", "Default Command Points."], ["AAS - Close Air Support", "5. Economy Base Costs"], "250", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_DUWS", "EDITBOX", ["Base Cost: DUWS", "Default CP."], ["AAS - Close Air Support", "5. Economy Base Costs"], "8", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_S", "EDITBOX", ["Base Cost: KP Lib (Supplies)", "Supplies threshold."], ["AAS - Close Air Support", "5. Economy Base Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_A", "EDITBOX", ["Base Cost: KP Lib (Ammo)", "Ammo threshold."], ["AAS - Close Air Support", "5. Economy Base Costs"], "200", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_F", "EDITBOX", ["Base Cost: KP Lib (Fuel)", "Fuel threshold."], ["AAS - Close Air Support", "5. Economy Base Costs"], "150", 1 ] call CBA_fnc_addSetting;
[ "AAS_Econ_Code_CAS", "EDITBOX", ["CAS Economy Code", "SQF code for Custom mode. Use '_cost' in your code."], ["AAS - Close Air Support", "5. Economy Base Costs"], "", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- REINFORCEMENTS MODULE ---
// ==========================================

// --- 0. Global Economy Base Costs & Squad Logic ---
[ "AAS_Behavior_Infantry", "LIST", ["Infantry Behavior", "Global orders for all 6 Air/Ground Infantry supports."], ["AAS - Reinforcements", "0. Global Economy & Settings"], [[0, 1, 2], ["Follow Player", "Join Player", "Engage Nearest"], 0], 1 ] call CBA_fnc_addSetting;
[ "AAS_Behavior_Armor", "LIST", ["Armor Behavior", "Global orders for all 3 Armor supports."], ["AAS - Reinforcements", "0. Global Economy & Settings"], [[0, 1, 2], ["Follow Player", "Join Player", "Engage Nearest"], 0], 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Custom", "EDITBOX", ["Base Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Antistasi", "EDITBOX", ["Base Cost: Antistasi", "Used for both Faction and Personal presets."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "1500", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Overthrow", "EDITBOX", ["Base Cost: Overthrow", "Default Wallet funds."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "9000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Warlords", "EDITBOX", ["Base Cost: Warlords", "Default Command Points."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_DUWS", "EDITBOX", ["Base Cost: DUWS", "Default CP."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "12", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_S", "EDITBOX", ["Base Cost: KP Lib (Supplies)", "Supplies threshold."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "200", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_A", "EDITBOX", ["Base Cost: KP Lib (Ammo)", "Ammo threshold."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "150", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_F", "EDITBOX", ["Base Cost: KP Lib (Fuel)", "Fuel threshold."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "50", 1 ] call CBA_fnc_addSetting;
[ "AAS_Econ_Code_Reinf", "EDITBOX", ["Reinf Economy Code", "SQF code for Custom mode. Use '_cost' in your code."], ["AAS - Reinforcements", "0. Global Economy & Settings"], "", 1 ] call CBA_fnc_addSetting;

// --- 1. Air Transported Infantry ---
[ "AAS_Reinf_Air_LightHeli", "EDITBOX", ["Light Helicopter (4-Man)", "Classname for light transport helicopter."], ["AAS - Reinf: Air Transport", "1. Classnames"], "B_Heli_Light_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_StdHeli", "EDITBOX", ["Standard Helicopter (8-Man)", "Classname for standard transport helicopter."], ["AAS - Reinf: Air Transport", "1. Classnames"], "B_Heli_Transport_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_Plane", "EDITBOX", ["Paradrop Plane (12-Man)", "Classname for paradrop aircraft."], ["AAS - Reinf: Air Transport", "1. Classnames"], "B_T_VTOL_01_infantry_F", 1 ] call CBA_fnc_addSetting;

[ "AAS_Reinf_Air_SL", "EDITBOX", ["1. Squad Leader", "Base classname."], ["AAS - Reinf: Air Transport", "2. Infantry Classes"], "B_Soldier_SL_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_Sniper", "EDITBOX", ["2. Sniper / Marksman", "Base classname."], ["AAS - Reinf: Air Transport", "2. Infantry Classes"], "B_soldier_M_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_AT", "EDITBOX", ["3. Anti-Tank", "Base classname."], ["AAS - Reinf: Air Transport", "2. Infantry Classes"], "B_soldier_LAT_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_AR", "EDITBOX", ["4. Autorifleman", "Base classname."], ["AAS - Reinf: Air Transport", "2. Infantry Classes"], "B_soldier_AR_F", 1 ] call CBA_fnc_addSetting;

[ "AAS_Reinf_Air_CostMult_4", "EDITBOX", ["Cost Multiplier: 4-Man", "Multiplies base cost."], ["AAS - Reinf: Air Transport", "3. Economy & Timers"], "1.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_CostMult_8", "EDITBOX", ["Cost Multiplier: 8-Man", "Multiplies base cost."], ["AAS - Reinf: Air Transport", "3. Economy & Timers"], "2.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_CostMult_12", "EDITBOX", ["Cost Multiplier: 12-Man", "Multiplies base cost."], ["AAS - Reinf: Air Transport", "3. Economy & Timers"], "3.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Reinf_Air", "EDITBOX", ["Global Air Cooldown (Sec)", "Cooldown for Air Transported supports."], ["AAS - Reinf: Air Transport", "3. Economy & Timers"], "600", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_Reinf_Air", "EDITBOX", ["Global Air RTB (Sec)", "Extraction time for Air Transported supports."], ["AAS - Reinf: Air Transport", "3. Economy & Timers"], "300", 1 ] call CBA_fnc_addSetting;

// --- 2. Ground Transported Infantry ---
[ "AAS_Reinf_Ground_MRAP", "EDITBOX", ["MRAP (4-Man)", "Classname for MRAP."], ["AAS - Reinf: Ground Transport", "1. Classnames"], "B_MRAP_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_APC", "EDITBOX", ["APC (8-Man)", "Classname for ground APC."], ["AAS - Reinf: Ground Transport", "1. Classnames"], "B_APC_Wheeled_01_cannon_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_Truck", "EDITBOX", ["Truck (12-Man)", "Classname for transport truck."], ["AAS - Reinf: Ground Transport", "1. Classnames"], "B_Truck_01_transport_F", 1 ] call CBA_fnc_addSetting;

[ "AAS_Reinf_Ground_SL", "EDITBOX", ["1. Squad Leader", "Base classname."], ["AAS - Reinf: Ground Transport", "2. Infantry Classes"], "B_Soldier_SL_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_Sniper", "EDITBOX", ["2. Sniper / Marksman", "Base classname."], ["AAS - Reinf: Ground Transport", "2. Infantry Classes"], "B_soldier_M_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_AT", "EDITBOX", ["3. Anti-Tank", "Base classname."], ["AAS - Reinf: Ground Transport", "2. Infantry Classes"], "B_soldier_LAT_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_AR", "EDITBOX", ["4. Autorifleman", "Base classname."], ["AAS - Reinf: Ground Transport", "2. Infantry Classes"], "B_soldier_AR_F", 1 ] call CBA_fnc_addSetting;

[ "AAS_Reinf_Ground_CostMult_4", "EDITBOX", ["Cost Multiplier: 4-Man (MRAP)", "Multiplies base cost."], ["AAS - Reinf: Ground Transport", "3. Economy & Timers"], "0.8", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_CostMult_8", "EDITBOX", ["Cost Multiplier: 8-Man (APC)", "Multiplies base cost."], ["AAS - Reinf: Ground Transport", "3. Economy & Timers"], "1.6", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_CostMult_12", "EDITBOX", ["Cost Multiplier: 12-Man (Truck)", "Multiplies base cost."], ["AAS - Reinf: Ground Transport", "3. Economy & Timers"], "2.4", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Reinf_Ground", "EDITBOX", ["Global Ground Cooldown (Sec)", "Cooldown for Ground Transported supports."], ["AAS - Reinf: Ground Transport", "3. Economy & Timers"], "600", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_Reinf_Ground", "EDITBOX", ["Global Ground RTB (Sec)", "Extraction time for Ground Transported supports."], ["AAS - Reinf: Ground Transport", "3. Economy & Timers"], "300", 1 ] call CBA_fnc_addSetting;

// --- 3. Armor ---
[ "AAS_Reinf_Armor_Turret", "EDITBOX", ["Turreted Vehicle", "Classname for armed MRAP/Car."], ["AAS - Reinf: Armor", "1. Classnames"], "B_MRAP_01_hmg_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_APC", "EDITBOX", ["IFV / APC", "Classname for IFV/APC."], ["AAS - Reinf: Armor", "1. Classnames"], "B_APC_Tracked_01_rcws_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_Tank", "EDITBOX", ["Tank", "Classname for Main Battle Tank."], ["AAS - Reinf: Armor", "1. Classnames"], "B_MBT_01_cannon_F", 1 ] call CBA_fnc_addSetting;

[ "AAS_Reinf_Armor_CostMult_Turret", "EDITBOX", ["Cost Multiplier: Turreted", "Multiplies base cost."], ["AAS - Reinf: Armor", "2. Economy & Timers"], "2.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_CostMult_APC", "EDITBOX", ["Cost Multiplier: IFV / APC", "Multiplies base cost."], ["AAS - Reinf: Armor", "2. Economy & Timers"], "4.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_CostMult_Tank", "EDITBOX", ["Cost Multiplier: Tank", "Multiplies base cost."], ["AAS - Reinf: Armor", "2. Economy & Timers"], "8.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Reinf_Armor", "EDITBOX", ["Global Armor Cooldown (Sec)", "Cooldown for Armor supports."], ["AAS - Reinf: Armor", "2. Economy & Timers"], "1200", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_Reinf_Armor", "EDITBOX", ["Global Armor RTB (Sec)", "Extraction time for Armor supports."], ["AAS - Reinf: Armor", "2. Economy & Timers"], "600", 1 ] call CBA_fnc_addSetting;