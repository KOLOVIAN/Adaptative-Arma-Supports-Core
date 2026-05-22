// AAS-Artillery/functions/fn_initSettings.sqf

// ==========================================
// --- 1. GAMEPLAY SETTINGS ---
// ==========================================

[ "AAS_ART_DangerClose_Radius", "SLIDER", ["Danger Close Radius", "Minimum safe distance (in meters) required to lock a target."], ["AAS - Artillery", "1. Gameplay Settings"], [0, 500, 150, 0], 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 2. HUD SETTINGS ---
// ==========================================

[ "AAS_ART_HUD_Height", "SLIDER", ["Targeting HUD Height", "0 = Top of screen, 0.5 = Center, 1 = Bottom."], ["AAS - Artillery", "2. HUD Settings"], [0.0, 1.0, 0.35, 2], 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_HUD_Size", "SLIDER", ["Targeting HUD Size", "Multiplier for the targeting UI text size."], ["AAS - Artillery", "2. HUD Settings"], [0.5, 2.0, 1.0, 2], 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 3. TIMERS & COOLDOWNS ---
// ==========================================

[ "AAS_ART_Cooldown_Global", "EDITBOX", ["Global Artillery Cooldown", "Time in seconds applied to all artillery strikes."], ["AAS - Artillery", "3. Timers & Cooldowns"], "600", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 4. ECONOMY (BASE COSTS) ---
// ==========================================

// NOTE: AAS_ART_Econ_Preset removed. It now strictly follows the Main AAS Core Global Setting.

[ "AAS_ART_Cost_Base_Custom", "EDITBOX", ["Base Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - Artillery", "4. Economy (Base Costs)"], "0", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Cost_Base_Antistasi", "EDITBOX", ["Base Cost: Antistasi", "Default FIA / Personal Resources."], ["AAS - Artillery", "4. Economy (Base Costs)"], "2000", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Cost_Base_Overthrow", "EDITBOX", ["Base Cost: Overthrow", "Default Wallet funds."], ["AAS - Artillery", "4. Economy (Base Costs)"], "5000", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Cost_Base_Warlords", "EDITBOX", ["Base Cost: Warlords", "Default Command Points."], ["AAS - Artillery", "4. Economy (Base Costs)"], "500", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Cost_Base_DUWS", "EDITBOX", ["Base Cost: DUWS", "Default CP."], ["AAS - Artillery", "4. Economy (Base Costs)"], "20", 1 ] call CBA_fnc_addSetting;

// NEW: KP Liberation Base Thresholds
[ "AAS_ART_Cost_Base_KPLib_S", "EDITBOX", ["Base Cost: KP Lib (Supplies)", "Supplies base threshold."], ["AAS - Artillery", "4. Economy (Base Costs)"], "200", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Cost_Base_KPLib_A", "EDITBOX", ["Base Cost: KP Lib (Ammo)", "Ammo base threshold."], ["AAS - Artillery", "4. Economy (Base Costs)"], "250", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Cost_Base_KPLib_F", "EDITBOX", ["Base Cost: KP Lib (Fuel)", "Fuel base threshold."], ["AAS - Artillery", "4. Economy (Base Costs)"], "50", 1 ] call CBA_fnc_addSetting;

[ "AAS_ART_Econ_Code", "EDITBOX", ["Artillery Economy Code", "SQF code executed when called. Leave blank for free mode."], ["AAS - Artillery", "4. Economy (Base Costs)"], "", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 5. ECONOMY (MULTIPLIERS) ---
// ==========================================

// 82mm Mortar
[ "AAS_ART_Mult_82mm_HEX7", "EDITBOX", ["Multiplier: 82mm HE x7", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "1.5", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Mult_82mm_HEX14", "EDITBOX", ["Multiplier: 82mm HE x14", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "3.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Mult_82mm_Smoke", "EDITBOX", ["Multiplier: 82mm Smoke", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "0.5", 1 ] call CBA_fnc_addSetting;

// 155mm Howitzer
[ "AAS_ART_Mult_155mm_HEX5", "EDITBOX", ["Multiplier: 155mm HE x5", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "3.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Mult_155mm_HEX10", "EDITBOX", ["Multiplier: 155mm HE x10", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "6.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Mult_155mm_DPICM", "EDITBOX", ["Multiplier: 155mm DPICM", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "3.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Mult_155mm_ADAM", "EDITBOX", ["Multiplier: 155mm ADAM", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "2.5", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Mult_155mm_RAAMS", "EDITBOX", ["Multiplier: 155mm RAAMS", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "5.0", 1 ] call CBA_fnc_addSetting;

// MLRS Rocket Strike
[ "AAS_ART_Mult_MLRS_HEDPX7", "EDITBOX", ["Multiplier: MLRS HEDP x7", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "5.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Mult_MLRS_HEDPX14", "EDITBOX", ["Multiplier: MLRS HEDP x14", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "10.0", 1 ] call CBA_fnc_addSetting;
[ "AAS_ART_Mult_MLRS_WP", "EDITBOX", ["Multiplier: MLRS White Phosphor", "Multiplies the Base Cost."], ["AAS - Artillery", "5. Economy (Multipliers)"], "7.0", 1 ] call CBA_fnc_addSetting;