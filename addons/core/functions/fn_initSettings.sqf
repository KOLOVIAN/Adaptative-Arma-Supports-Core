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
        ["aas_modern", "Modern", "\z\aas\addons\core\data\tacticalpager_modern.paa", "\z\aas\addons\core\data\tablet.paa"],
        ["aas_retro", "Retro", "\z\aas\addons\core\data\tacticalpager_retro.paa", "\z\aas\addons\core\data\tablet_retro.paa"]
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

// --- 1. UI & Systems ---
[ "AAS_Show_Startup_Message", "CHECKBOX", ["Startup Notification", "Show the systemChat message displaying loaded AAS modules on mission start."], ["AAS - CORE SETTINGS", "1. UI & Systems"], false, 1 ] call CBA_fnc_addSetting;
[ "AAS_Pager_Theme", "LIST", ["Aesthetic", "Choose the visual theme for the Pager and Support Tablets. (Dynamically populated via mod registry)"], ["AAS - CORE SETTINGS", "1. UI & Systems"], [_themeValues, _themeNames, 0], 1 ] call CBA_fnc_addSetting;
[ "AAS_Signal_Grenade", "EDITBOX", ["Signal Grenade", "Classname for the smoke grenade that opens the supports menu."], ["AAS - CORE SETTINGS", "1. UI & Systems"], "SmokeShellOrange", 1 ] call CBA_fnc_addSetting;

// --- 2. Global Economy ---
[ "AAS_Econ_Preset_Core", "LIST", ["Global Economy Preset", "Select which economy framework to use across ALL supports."], ["AAS - CORE SETTINGS", "2. Global Economy"], [[0, 1, 6, 2, 3, 4, 5], ["Custom / Free", "Antistasi (Faction Funds)", "Antistasi (Personal Funds)", "KP Liberation", "Overthrow", "Vanilla Warlords", "DUWS"], 0], 1 ] call CBA_fnc_addSetting;


// ==========================================
// --- Supply Drop MODULE ---
// ==========================================

// --- 1. Classnames & Parameters ---
[ "AAS_Heli_Supply", "EDITBOX", ["Supply Helicopter", "Classname for the unarmed supply drop helicopter."], ["AAS - Supply Drop", "1. Classnames & Parameters"], "B_Heli_Light_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Supply", "EDITBOX", ["Supply Cooldown (Seconds)", "Enter the cooldown time in seconds."], ["AAS - Supply Drop", "1. Classnames & Parameters"], "600", 1 ] call CBA_fnc_addSetting;

// --- 2. Economy Costs ---
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
// --- Close Air Support (CAS) MODULE ---
// ==========================================

// --- 0. Global Settings & Base Costs ---
[ "AAS_Cooldown_CAS", "EDITBOX", ["Global CAS Cooldown (Seconds)", "Global cooldown time for all CAS supports."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "900", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_CAS", "EDITBOX", ["Global CAS RTB Time (Seconds)", "Global time before the CAS leaves the AO."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "270", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Custom", "EDITBOX", ["Base Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Antistasi", "EDITBOX", ["Base Cost: Antistasi", "Used for both Faction and Personal presets."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "1000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Overthrow", "EDITBOX", ["Base Cost: Overthrow", "Default Wallet funds."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "6000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_Warlords", "EDITBOX", ["Base Cost: Warlords", "Default Command Points."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "250", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_DUWS", "EDITBOX", ["Base Cost: DUWS", "Default CP."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "8", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_S", "EDITBOX", ["Base Cost: KP Lib (Supplies)", "Supplies threshold."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_A", "EDITBOX", ["Base Cost: KP Lib (Ammo)", "Ammo threshold."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "200", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_CAS_KPLib_F", "EDITBOX", ["Base Cost: KP Lib (Fuel)", "Fuel threshold."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "150", 1 ] call CBA_fnc_addSetting;
[ "AAS_Econ_Code_CAS", "EDITBOX", ["CAS Economy Code", "SQF code for Custom mode. Use '_cost' in your code."], ["AAS - Close Air Support", "0. Global Settings & Base Costs"], "", 1 ] call CBA_fnc_addSetting;

// --- 1. Plane ---
[ "AAS_CAS_Plane_Class", "EDITBOX", ["Plane Classname", "Classname for the CAS Plane."], ["AAS - Close Air Support", "1. Plane"], "B_Plane_CAS_01_dynamicLoadout_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Plane_Behavior", "LIST", ["Plane Behavior", "Select the AI behavior pattern."], ["AAS - Close Air Support", "1. Plane"], [[0, 1], ["Loiter (Circles LZ)", "Search and Destroy (Hunts Targets)"], 1], 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Plane_CostMult", "EDITBOX", ["Plane Cost Multiplier", "Multiplies the base CAS cost."], ["AAS - Close Air Support", "1. Plane"], "1.5", 1 ] call CBA_fnc_addSetting;

// --- 2. Helicopter ---
[ "AAS_CAS_Heli_Class", "EDITBOX", ["Helicopter Classname", "Classname for the CAS Helicopter."], ["AAS - Close Air Support", "2. Helicopter"], "B_Heli_Attack_01_dynamicLoadout_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Heli_Behavior", "LIST", ["Helicopter Behavior", "Select the AI behavior pattern."], ["AAS - Close Air Support", "2. Helicopter"], [[0, 1], ["Loiter (Circles LZ)", "Search and Destroy (Hunts Targets)"], 0], 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Heli_Height", "EDITBOX", ["Helicopter Loiter Height", "Altitude in meters."], ["AAS - Close Air Support", "2. Helicopter"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Heli_Radius", "EDITBOX", ["Helicopter Loiter Radius", "Radius in meters."], ["AAS - Close Air Support", "2. Helicopter"], "600", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Heli_CostMult", "EDITBOX", ["Helicopter Cost Multiplier", "Multiplies the base CAS cost."], ["AAS - Close Air Support", "2. Helicopter"], "1.0", 1 ] call CBA_fnc_addSetting;

// --- 3. Gunship ---
[ "AAS_CAS_Gunship_Class", "EDITBOX", ["Gunship Classname", "Classname for the Gunship."], ["AAS - Close Air Support", "3. Gunship"], "B_T_VTOL_01_armed_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Gunship_Orbit", "CHECKBOX", ["Force Counter-Clockwise Orbit", "Forces a counter-clockwise loiter direction."], ["AAS - Close Air Support", "3. Gunship"], true, 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Gunship_Height", "EDITBOX", ["Gunship Loiter Height", "Altitude in meters."], ["AAS - Close Air Support", "3. Gunship"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Gunship_Radius", "EDITBOX", ["Gunship Loiter Radius", "Radius in meters."], ["AAS - Close Air Support", "3. Gunship"], "1000", 1 ] call CBA_fnc_addSetting;
[ "AAS_CAS_Gunship_CostMult", "EDITBOX", ["Gunship Cost Multiplier", "Multiplies the base CAS cost."], ["AAS - Close Air Support", "3. Gunship"], "2.5", 1 ] call CBA_fnc_addSetting;


// ==========================================
// --- Reinforcements MODULE ---
// ==========================================

// --- 0. Global Settings & Base Costs ---
[ "AAS_Behavior_Infantry", "LIST", ["Infantry Behavior", "Global orders for all 6 Air/Ground Infantry supports."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], [[0, 1, 2], ["Follow Player", "Join Player", "Engage Nearest"], 0], 1 ] call CBA_fnc_addSetting;
[ "AAS_Behavior_Armor", "LIST", ["Armor Behavior", "Global orders for all 3 Armor supports."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], [[0, 1, 2], ["Follow Player", "Join Player", "Engage Nearest"], 0], 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Custom", "EDITBOX", ["Base Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Antistasi", "EDITBOX", ["Base Cost: Antistasi", "Used for both Faction and Personal presets."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "1500", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Overthrow", "EDITBOX", ["Base Cost: Overthrow", "Default Wallet funds."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "9000", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_Warlords", "EDITBOX", ["Base Cost: Warlords", "Default Command Points."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_DUWS", "EDITBOX", ["Base Cost: DUWS", "Default CP."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "12", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_S", "EDITBOX", ["Base Cost: KP Lib (Supplies)", "Supplies threshold."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "200", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_A", "EDITBOX", ["Base Cost: KP Lib (Ammo)", "Ammo threshold."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "150", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cost_Reinf_KPLib_F", "EDITBOX", ["Base Cost: KP Lib (Fuel)", "Fuel threshold."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "50", 1 ] call CBA_fnc_addSetting;
[ "AAS_Econ_Code_Reinf", "EDITBOX", ["Reinf Economy Code", "SQF code for Custom mode. Use '_cost' in your code."], ["AAS - Reinforcements", "0. Global Settings & Base Costs"], "", 1 ] call CBA_fnc_addSetting;

// --- 1. Airborne Infantry ---
[ "AAS_Reinf_Air_LightHeli", "EDITBOX", ["Light Helicopter (4-Man)", "Classname for light transport helicopter."], ["AAS - Reinforcements", "1. Airborne Infantry"], "B_Heli_Light_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_StdHeli", "EDITBOX", ["Standard Helicopter (8-Man)", "Classname for standard transport helicopter."], ["AAS - Reinforcements", "1. Airborne Infantry"], "B_Heli_Transport_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_Plane", "EDITBOX", ["Paradrop Plane (12-Man)", "Classname for paradrop aircraft."], ["AAS - Reinforcements", "1. Airborne Infantry"], "B_T_VTOL_01_infantry_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_SL", "EDITBOX", ["1. Squad Leader", "Base classname."], ["AAS - Reinforcements", "1. Airborne Infantry"], "B_Soldier_SL_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_Sniper", "EDITBOX", ["2. Sniper / Marksman", "Base classname."], ["AAS - Reinforcements", "1. Airborne Infantry"], "B_soldier_M_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_AT", "EDITBOX", ["3. Anti-Tank", "Base classname."], ["AAS - Reinforcements", "1. Airborne Infantry"], "B_soldier_LAT_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_AR", "EDITBOX", ["4. Autorifleman", "Base classname."], ["AAS - Reinforcements", "1. Airborne Infantry"], "B_soldier_AR_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_CostMult_4", "EDITBOX", ["Cost Multiplier: 4-Man", "Multiplies base cost."], ["AAS - Reinforcements", "1. Airborne Infantry"], "1.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_CostMult_8", "EDITBOX", ["Cost Multiplier: 8-Man", "Multiplies base cost."], ["AAS - Reinforcements", "1. Airborne Infantry"], "2.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Air_CostMult_12", "EDITBOX", ["Cost Multiplier: 12-Man", "Multiplies base cost."], ["AAS - Reinforcements", "1. Airborne Infantry"], "3.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Reinf_Air", "EDITBOX", ["Air Cooldown (Sec)", "Cooldown for Air Transported supports."], ["AAS - Reinforcements", "1. Airborne Infantry"], "600", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_Reinf_Air", "EDITBOX", ["Air RTB (Sec)", "Extraction time for Air Transported supports."], ["AAS - Reinforcements", "1. Airborne Infantry"], "300", 1 ] call CBA_fnc_addSetting;

// --- 2. Mechanized Infantry ---
[ "AAS_Reinf_Ground_MRAP", "EDITBOX", ["MRAP (4-Man)", "Classname for MRAP."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "B_MRAP_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_APC", "EDITBOX", ["APC (8-Man)", "Classname for ground APC."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "B_APC_Wheeled_01_cannon_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_Truck", "EDITBOX", ["Truck (12-Man)", "Classname for transport truck."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "B_Truck_01_transport_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_SL", "EDITBOX", ["1. Squad Leader", "Base classname."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "B_Soldier_SL_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_Sniper", "EDITBOX", ["2. Sniper / Marksman", "Base classname."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "B_soldier_M_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_AT", "EDITBOX", ["3. Anti-Tank", "Base classname."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "B_soldier_LAT_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_AR", "EDITBOX", ["4. Autorifleman", "Base classname."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "B_soldier_AR_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_CostMult_4", "EDITBOX", ["Cost Multiplier: 4-Man (MRAP)", "Multiplies base cost."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "0.8", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_CostMult_8", "EDITBOX", ["Cost Multiplier: 8-Man (APC)", "Multiplies base cost."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "1.6", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Ground_CostMult_12", "EDITBOX", ["Cost Multiplier: 12-Man (Truck)", "Multiplies base cost."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "2.4", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Reinf_Ground", "EDITBOX", ["Ground Cooldown (Sec)", "Cooldown for Ground Transported supports."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "600", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_Reinf_Ground", "EDITBOX", ["Ground RTB (Sec)", "Extraction time for Ground Transported supports."], ["AAS - Reinforcements", "2. Mechanized Infantry"], "300", 1 ] call CBA_fnc_addSetting;

// --- 3. Armor ---
[ "AAS_Reinf_Armor_Turret", "EDITBOX", ["Turreted Vehicle", "Classname for armed MRAP/Car."], ["AAS - Reinforcements", "3. Armor"], "B_MRAP_01_hmg_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_APC", "EDITBOX", ["IFV / APC", "Classname for IFV/APC."], ["AAS - Reinforcements", "3. Armor"], "B_APC_Tracked_01_rcws_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_Tank", "EDITBOX", ["Tank", "Classname for Main Battle Tank."], ["AAS - Reinforcements", "3. Armor"], "B_MBT_01_cannon_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_CostMult_Turret", "EDITBOX", ["Cost Multiplier: Turreted", "Multiplies base cost."], ["AAS - Reinforcements", "3. Armor"], "2.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_CostMult_APC", "EDITBOX", ["Cost Multiplier: IFV / APC", "Multiplies base cost."], ["AAS - Reinforcements", "3. Armor"], "4.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Reinf_Armor_CostMult_Tank", "EDITBOX", ["Cost Multiplier: Tank", "Multiplies base cost."], ["AAS - Reinforcements", "3. Armor"], "8.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_Cooldown_Reinf_Armor", "EDITBOX", ["Armor Cooldown (Sec)", "Cooldown for Armor supports."], ["AAS - Reinforcements", "3. Armor"], "1200", 1 ] call CBA_fnc_addSetting;
[ "AAS_RTB_Reinf_Armor", "EDITBOX", ["Armor RTB (Sec)", "Extraction time for Armor supports."], ["AAS - Reinforcements", "3. Armor"], "600", 1 ] call CBA_fnc_addSetting;

private _registry = profileNamespace getVariable ["AAS_Template_Registry", []];
private _names    = ["— Default —"] + (_registry apply { _x select 0 });
private _indices  = [-1]            + (_registry apply { _forEachIndex });


// ==========================================
// --- FACTION TEMPLATES ---
// ==========================================

// Hardcoded Vanilla NATO defaults — used by the reset option
AAS_VanillaDefaults = [
    /* Supply */
    ["AAS_Heli_Supply",                  "B_Heli_Light_01_F"                 ],
    /* Close Air Support */
    ["AAS_CAS_Gunship_Class",            "B_T_VTOL_01_armed_F"               ],
    ["AAS_CAS_Gunship_Height",           "400"                               ],
    ["AAS_CAS_Gunship_Orbit",            true                                ],
    ["AAS_CAS_Gunship_Radius",           "1000"                              ],
    ["AAS_CAS_Heli_Class",               "B_Heli_Attack_01_dynamicLoadout_F" ],
    ["AAS_CAS_Plane_Class",              "B_Plane_CAS_01_dynamicLoadout_F"   ],
    /* Reinforcements - Airborne */
    ["AAS_Reinf_Air_SL",                 "B_Soldier_SL_F"                    ],
    ["AAS_Reinf_Air_Sniper",             "B_soldier_M_F"                     ],
    ["AAS_Reinf_Air_AT",                 "B_soldier_LAT_F"                   ],
    ["AAS_Reinf_Air_AR",                 "B_soldier_AR_F"                    ],
    ["AAS_Reinf_Air_LightHeli",          "B_Heli_Light_01_F"                 ],
    ["AAS_Reinf_Air_StdHeli",            "B_Heli_Transport_01_F"             ],
    ["AAS_Reinf_Air_Plane",              "B_T_VTOL_01_infantry_F"            ],
    /* Reinforcements - Ground */
    ["AAS_Reinf_Ground_SL",              "B_Soldier_SL_F"                    ],
    ["AAS_Reinf_Ground_Sniper",          "B_soldier_M_F"                     ],
    ["AAS_Reinf_Ground_AT",              "B_soldier_LAT_F"                   ],
    ["AAS_Reinf_Ground_AR",              "B_soldier_AR_F"                    ],
    ["AAS_Reinf_Ground_MRAP",            "B_MRAP_01_F"                       ],
    ["AAS_Reinf_Ground_APC",             "B_APC_Wheeled_01_cannon_F"         ],
    ["AAS_Reinf_Ground_Truck",           "B_Truck_01_transport_F"            ],
    /* Reinforcements - Armor */
    ["AAS_Reinf_Armor_Turret",           "B_MRAP_01_hmg_F"                   ],
    ["AAS_Reinf_Armor_APC",              "B_APC_Tracked_01_rcws_F"           ],
    ["AAS_Reinf_Armor_Tank",             "B_MBT_01_cannon_F"                 ],
    /* QRF - Squad */
    ["AQR_Squad_SL",                     "B_Soldier_SL_F"                    ],
    ["AQR_Squad_MG",                     "B_autorifleman_F"                  ],
    ["AQR_Squad_AT",                     "B_soldier_LAT_F"                   ],
    ["AQR_Squad_Sniper",                 "B_sniper_F"                        ],
    /* QRF - Amphibious */
    ["AQR_Amphib_SL",                    "B_diver_TL_F"                      ],
    ["AQR_Amphib_MG",                    "B_diver_AR_F"                      ],
    ["AQR_Amphib_AT",                    "B_diver_exp_F"                     ],
    ["AQR_Amphib_Sniper",                "B_diver_F"                         ],
    /* QRF - Ground */
    ["AQR_Ground_Turret",                "B_MRAP_01_hmg_F"                   ],
    ["AQR_Ground_APC",                   "B_APC_Wheeled_01_cannon_F"         ],
    /* QRF - Sea */
    ["AQR_Sea_Boat",                     "B_Boat_Armed_01_minigun_F"         ],
    ["AQR_Sea_Amphib",                   "B_APC_Wheeled_01_cannon_F"         ],
    /* QRF - Air */
    ["AQR_Heli_CAS",                     "B_Heli_Light_01_dynamicLoadout_F"  ],
    ["AQR_Heli_Escort",                  "B_Heli_Attack_01_dynamicLoadout_F" ],
    ["AQR_Heli_Heavy",                   "B_Heli_Transport_03_F"             ],
    ["AQR_Plane_Class",                  "B_T_VTOL_01_vehicle_F"             ],
    /* Airstrikes */
    ["AAS_AS_Plane_GunRun",              "B_Plane_CAS_01_dynamicLoadout_F"   ],
    ["AAS_AS_Plane_JDAM",                "B_Plane_Fighter_01_F"              ],
    ["AAS_AS_Plane_MidnightSun",         "B_T_VTOL_01_vehicle_F"             ],
    ["AAS_AS_Plane_UnguidedBomb",        "B_Plane_Fighter_01_F"              ],
    ["AAS_AS_Toggle_Brrrt",              true                                ],
    /* Logistics - Transport */
    ["AAS_LOG_Comp_Heli",                "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Transport_HeliClass",      "B_Heli_Transport_01_F"             ],
    ["AAS_LOG_TransportHeavy_HeliClass", "B_Heli_Transport_03_F"             ],
    /* Logistics - Equipment */
    ["AAS_LOG_Equip1_Name",              "NATO Supplies"                     ],
    ["AAS_LOG_Equip1_Class",             "B_CargoNet_01_ammo_F"              ],
    ["AAS_LOG_Equip1_Heli",              "B_Heli_Light_01_F"                 ],
    ["AAS_LOG_Equip1_Container",         false                               ],
    ["AAS_LOG_Equip1_ForceRope",         false                               ],
    ["AAS_LOG_Equip1_Mult",              "4.0"                               ],
    ["AAS_LOG_Equip2_Name",              "OPFOR Supplies"                    ],
    ["AAS_LOG_Equip2_Class",             "O_CargoNet_01_ammo_F"              ],
    ["AAS_LOG_Equip2_Heli",              "B_Heli_Light_01_F"                 ],
    ["AAS_LOG_Equip2_Container",         false                               ],
    ["AAS_LOG_Equip2_ForceRope",         false                               ],
    ["AAS_LOG_Equip2_Mult",              "4.0"                               ],
    ["AAS_LOG_Equip3_Name",              "AN/MPQ-105"                        ],
    ["AAS_LOG_Equip3_Class",             "B_Radar_System_01_F"               ],
    ["AAS_LOG_Equip3_Heli",              "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Equip3_Container",         true                                ],
    ["AAS_LOG_Equip3_ForceRope",         false                               ],
    ["AAS_LOG_Equip3_Mult",              "6.0"                               ],
    ["AAS_LOG_Equip4_Name",              "Praetorian 1C"                     ],
    ["AAS_LOG_Equip4_Class",             "B_AAA_System_01_F"                 ],
    ["AAS_LOG_Equip4_Heli",              "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Equip4_Container",         true                                ],
    ["AAS_LOG_Equip4_ForceRope",         false                               ],
    ["AAS_LOG_Equip4_Mult",              "10.0"                              ],
    ["AAS_LOG_Equip5_Name",              "Mk49 Spartan"                      ],
    ["AAS_LOG_Equip5_Class",             "B_SAM_System_01_F"                 ],
    ["AAS_LOG_Equip5_Heli",              "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Equip5_Container",         true                                ],
    ["AAS_LOG_Equip5_ForceRope",         false                               ],
    ["AAS_LOG_Equip5_Mult",              "12.0"                              ],
    ["AAS_LOG_Equip6_Name",              "MIM-145 Defender"                  ],
    ["AAS_LOG_Equip6_Class",             "B_SAM_System_03_F"                 ],
    ["AAS_LOG_Equip6_Heli",              "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Equip6_Container",         true                                ],
    ["AAS_LOG_Equip6_ForceRope",         false                               ],
    ["AAS_LOG_Equip6_Mult",              "18.0"                              ],
    /* Logistics - Vehicles */
    ["AAS_LOG_Veh1_Name",                "Quadbike"                          ],
    ["AAS_LOG_Veh1_Class",               "B_Quadbike_01_F"                   ],
    ["AAS_LOG_Veh1_Heli",                "B_Heli_Light_01_F"                 ],
    ["AAS_LOG_Veh1_Container",           false                               ],
    ["AAS_LOG_Veh1_ForceRope",           false                               ],
    ["AAS_LOG_Veh1_Mult",                "0.2"                               ],
    ["AAS_LOG_Veh2_Name",                "Jeep"                              ],
    ["AAS_LOG_Veh2_Class",               "C_Offroad_02_unarmed_F"            ],
    ["AAS_LOG_Veh2_Heli",                "B_Heli_Transport_01_F"             ],
    ["AAS_LOG_Veh2_Container",           false                               ],
    ["AAS_LOG_Veh2_ForceRope",           false                               ],
    ["AAS_LOG_Veh2_Mult",                "0.5"                               ],
    ["AAS_LOG_Veh3_Name",                "Prowler HMG"                       ],
    ["AAS_LOG_Veh3_Class",               "B_LSV_01_armed_F"                  ],
    ["AAS_LOG_Veh3_Heli",                "B_Heli_Transport_01_F"             ],
    ["AAS_LOG_Veh3_Container",           false                               ],
    ["AAS_LOG_Veh3_ForceRope",           false                               ],
    ["AAS_LOG_Veh3_Mult",                "2.0"                               ],
    ["AAS_LOG_Veh4_Name",                "HEMTT Cargo"                       ],
    ["AAS_LOG_Veh4_Class",               "B_Truck_01_transport_F"            ],
    ["AAS_LOG_Veh4_Heli",                "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Veh4_Container",           false                               ],
    ["AAS_LOG_Veh4_ForceRope",           false                               ],
    ["AAS_LOG_Veh4_Mult",                "2.0"                               ],
    ["AAS_LOG_Veh5_Name",                "Hunter GMG"                        ],
    ["AAS_LOG_Veh5_Class",               "B_MRAP_01_gmg_F"                   ],
    ["AAS_LOG_Veh5_Heli",                "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Veh5_Container",           false                               ],
    ["AAS_LOG_Veh5_ForceRope",           false                               ],
    ["AAS_LOG_Veh5_Mult",                "6.0"                               ],
    ["AAS_LOG_Veh6_Name",                "AMV-7 Marshall"                    ],
    ["AAS_LOG_Veh6_Class",               "B_APC_Wheeled_01_cannon_F"         ],
    ["AAS_LOG_Veh6_Heli",                "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Veh6_Container",           true                                ],
    ["AAS_LOG_Veh6_ForceRope",           false                               ],
    ["AAS_LOG_Veh6_Mult",                "10.0"                              ],
    ["AAS_LOG_Veh7_Name",                "SDV Submersible"                   ],
    ["AAS_LOG_Veh7_Class",               "B_SDV_01_F"                        ],
    ["AAS_LOG_Veh7_Heli",                "B_Heli_Transport_01_F"             ],
    ["AAS_LOG_Veh7_Container",           false                               ],
    ["AAS_LOG_Veh7_ForceRope",           false                               ],
    ["AAS_LOG_Veh7_Mult",                "2.0"                               ],
    ["AAS_LOG_Veh8_Name",                "Armed Boat"                        ],
    ["AAS_LOG_Veh8_Class",               "B_Boat_Armed_01_minigun_F"         ],
    ["AAS_LOG_Veh8_Heli",                "B_Heli_Transport_03_F"             ],
    ["AAS_LOG_Veh8_Container",           false                               ],
    ["AAS_LOG_Veh8_ForceRope",           false                               ],
    ["AAS_LOG_Veh8_Mult",                "4.0"                               ]
];

// Build dropdown from installed templates in profile
AAS_Template_Registry_Cache = profileNamespace getVariable ["AAS_Template_Registry", []];

private _registry = AAS_Template_Registry_Cache;
private _names    = ["— Default (Vanilla NATO) —"] + (_registry apply { _x select 0 });
private _values   = ["__default__"]               + (_registry apply { _x select 0 });

AAS_Template_UI_Ready = false;

["AAS_Selected_Template", "LIST",
    ["Faction Template", "Select an installed faction template. Place an [AAS FACTION] composition via Zeus to install one permanently."],
    ["AAS - CORE SETTINGS", "3. Faction Templates"],
    [_values, _names, 0],
    false,
    {
        params ["_val"];
        if (!AAS_Template_UI_Ready) exitWith {};

        if (_val == "__default__") then {
            { [_x select 0, _x select 1, 2, "server"] call CBA_settings_fnc_set; } forEach AAS_VanillaDefaults;
            profileNamespace setVariable ["AAS_ActiveTemplate", []];
            saveProfileNamespace;
            "[AAS] Reset to Vanilla NATO defaults." remoteExec ["systemChat", 0];
        } else {
            private _idx = AAS_Template_Registry_Cache findIf { (_x select 0) == _val };

            if (_idx < 0) exitWith {
                "[AAS] Template not found — reinstall the composition." remoteExec ["systemChat", 0];
            };

            private _t = (AAS_Template_Registry_Cache select _idx) select 1;
            { [_x select 0, _x select 1, 2, "server"] call CBA_settings_fnc_set; } forEach _t;
            profileNamespace setVariable ["AAS_ActiveTemplate", _t];
            saveProfileNamespace;
            (format ["[AAS] '%1' faction template applied.", _val]) remoteExec ["systemChat", 0];
        };
    }
] call CBA_fnc_addSetting;

[] spawn {
    waitUntil { time > 0 };
    AAS_Template_UI_Ready = true;
    private _active = profileNamespace getVariable ["AAS_ActiveTemplate", []];
    if (count _active > 0) then {
        { [_x select 0, _x select 1, 2, "server"] call CBA_settings_fnc_set; } forEach _active;
    };
};