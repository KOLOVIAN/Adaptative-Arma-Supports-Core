// AAS-Airstrikes/functions/fn_initSettings.sqf

// ==========================================
// --- 1. GAMEPLAY SETTINGS ---
// ==========================================
[ "AAS_AS_DangerClose_Radius", "SLIDER", ["Danger Close Radius", "Minimum safe distance (in meters) required to lock a target."], ["AAS - Airstrikes", "1. Gameplay Settings"], [0, 500, 150, 0], 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Toggle_Brrrt", "CHECKBOX", ["Enable Gun Run BRRRT", "Toggle the custom realistic GAU-8/A 'BRRRT' sound during the Gun Run."], ["AAS - Airstrikes", "1. Gameplay Settings"], true, 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 2. HUD SETTINGS ---
// ==========================================
[ "AAS_AS_HUD_Height", "SLIDER", ["Targeting HUD Height", "0 = Top of screen, 0.5 = Center, 1 = Bottom."], ["AAS - Airstrikes", "2. HUD Settings"], [0.0, 1.0, 0.35, 2], 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_HUD_Size", "SLIDER", ["Targeting HUD Size", "Multiplier for the targeting UI text size."], ["AAS - Airstrikes", "2. HUD Settings"], [0.5, 2.0, 1.0, 2], 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 3. CLASSES - AIRCRAFT ---
// ==========================================
[ "AAS_AS_Plane_MidnightSun", "EDITBOX", ["Midnight Sun Aircraft", "Classname for the Midnight Sun (Flare) plane."], ["AAS - Airstrikes", "3. Classes - Aircraft"], "B_T_VTOL_01_vehicle_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Plane_GunRun", "EDITBOX", ["Gun Run Aircraft", "Classname for the Gun Run plane (A-164 Wipeout)."], ["AAS - Airstrikes", "3. Classes - Aircraft"], "B_Plane_CAS_01_dynamicLoadout_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Plane_UnguidedBomb", "EDITBOX", ["Carpet Bombing Aircraft", "Classname for the Carpet Bombing plane."], ["AAS - Airstrikes", "3. Classes - Aircraft"], "B_Plane_Fighter_01_F", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Plane_JDAM", "EDITBOX", ["JDAM Aircraft", "Classname for the JDAM strike plane (F/A-181 Black Wasp II)."], ["AAS - Airstrikes", "3. Classes - Aircraft"], "B_Plane_Fighter_01_F", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 4. TIMERS & COOLDOWNS ---
// ==========================================
[ "AAS_AS_Cooldown_MidnightSun", "EDITBOX", ["Midnight Sun Cooldown", "Time in seconds."], ["AAS - Airstrikes", "4. Timers & Cooldowns"], "300", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cooldown_GunRun", "EDITBOX", ["Gun Run Cooldown", "Time in seconds."], ["AAS - Airstrikes", "4. Timers & Cooldowns"], "300", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cooldown_UnguidedBomb", "EDITBOX", ["Carpet Bombing Cooldown", "Time in seconds."], ["AAS - Airstrikes", "4. Timers & Cooldowns"], "600", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cooldown_CruiseMissile", "EDITBOX", ["Cruise Missile Cooldown", "Time in seconds."], ["AAS - Airstrikes", "4. Timers & Cooldowns"], "720", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cooldown_JDAM", "EDITBOX", ["JDAM Cooldown", "Time in seconds."], ["AAS - Airstrikes", "4. Timers & Cooldowns"], "720", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 5. ECONOMY (BASE COSTS) ---
// ==========================================
// NOTE: AAS_AS_Econ_Preset removed. It now strictly follows the Main AAS Core Global Setting.
[ "AAS_AS_Cost_Base_Custom", "EDITBOX", ["Base Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cost_Base_Antistasi", "EDITBOX", ["Base Cost: Antistasi", "Default FIA / Personal Resources."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "1000", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cost_Base_Overthrow", "EDITBOX", ["Base Cost: Overthrow", "Default Wallet funds."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "3000", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cost_Base_Warlords", "EDITBOX", ["Base Cost: Warlords", "Default Command Points."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "400", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cost_Base_DUWS", "EDITBOX", ["Base Cost: DUWS", "Default CP."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "10", 1 ] call CBA_fnc_addSetting;
// NEW: KP Liberation Base Thresholds
[ "AAS_AS_Cost_Base_KPLib_S", "EDITBOX", ["Base Cost: KP Lib (Supplies)", "Supplies base threshold."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "50", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cost_Base_KPLib_A", "EDITBOX", ["Base Cost: KP Lib (Ammo)", "Ammo base threshold."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "150", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Cost_Base_KPLib_F", "EDITBOX", ["Base Cost: KP Lib (Fuel)", "Fuel base threshold."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "200", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Econ_Code", "EDITBOX", ["Airstrikes Economy Code", "SQF code executed when called. Leave blank for free mode."], ["AAS - Airstrikes", "5. Economy (Base Costs)"], "", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 6. ECONOMY (MULTIPLIERS) ---
// ==========================================
[ "AAS_AS_Mult_MidnightSun", "EDITBOX", ["Multiplier: Midnight Sun", "Multiplies the Base Cost."], ["AAS - Airstrikes", "6. Economy (Multipliers)"], "0.5", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Mult_GunRun", "EDITBOX", ["Multiplier: Gun Run", "Multiplies the Base Cost."], ["AAS - Airstrikes", "6. Economy (Multipliers)"], "1.5", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Mult_UnguidedBomb", "EDITBOX", ["Multiplier: Carpet Bombing", "Multiplies the Base Cost."], ["AAS - Airstrikes", "6. Economy (Multipliers)"], "4.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Mult_CruiseMissile", "EDITBOX", ["Multiplier: Cruise Missile", "Multiplies the Base Cost."], ["AAS - Airstrikes", "6. Economy (Multipliers)"], "8.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_AS_Mult_JDAM", "EDITBOX", ["Multiplier: JDAM", "Multiplies the Base Cost."], ["AAS - Airstrikes", "6. Economy (Multipliers)"], "10.0", 1 ] call CBA_fnc_addSetting;