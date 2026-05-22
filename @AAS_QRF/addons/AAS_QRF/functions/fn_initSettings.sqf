// AAS-QRF/functions/fn_initSettings.sqf

// ==========================================
// --- 1. TOGGLES ---
// ==========================================

[ "AQR_Enable_Menu", "CHECKBOX", ["Show in Interface Menu", "If disabled, players cannot call the QRF via the tactical pager."], ["AAS - QRF", "1. Toggles"], true, 1 ] call CBA_fnc_addSetting;
[ "AQR_Toggle_PreDep", "CHECKBOX", ["Enable Pre-Deployment", "Toggle pre-deployment logic on or off."], ["AAS - QRF", "1. Toggles"], true, 1 ] call CBA_fnc_addSetting;
[ "AQR_Toggle_Flares", "CHECKBOX", ["Enable Midnight Sun", "Toggle night LUU-2B flares for QRF."], ["AAS - QRF", "1. Toggles"], true, 1 ] call CBA_fnc_addSetting;
[ "AQR_Toggle_Air", "CHECKBOX", ["Enable Air Support", "Toggle the air component of the QRF."], ["AAS - QRF", "1. Toggles"], true, 1 ] call CBA_fnc_addSetting;
[ "AQR_Toggle_Ground", "CHECKBOX", ["Enable Ground Support", "Toggle the ground component of the QRF."], ["AAS - QRF", "1. Toggles"], true, 1 ] call CBA_fnc_addSetting;
[ "AQR_Toggle_Sea", "CHECKBOX", ["Enable Maritime Support", "Toggle the naval component of the QRF."], ["AAS - QRF", "1. Toggles"], true, 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 2. TIMERS & COOLDOWNS ---
// ==========================================

[ "AQR_Cooldown_QRF", "EDITBOX", ["QRF Cooldown (Seconds)", "Enter the master cooldown time in seconds."], ["AAS - QRF", "2. Timers & Cooldowns"], "1800", 1 ] call CBA_fnc_addSetting;
[ "AQR_RTB_Escort", "EDITBOX", ["Escort RTB Time (Seconds)", "Time in seconds before the escort heli leaves the AO."], ["AAS - QRF", "2. Timers & Cooldowns"], "120", 1 ] call CBA_fnc_addSetting;
[ "AQR_RTB_CAS", "EDITBOX", ["CAS RTB Time (Seconds)", "Time in seconds before CAS heli leaves the AO."], ["AAS - QRF", "2. Timers & Cooldowns"], "300", 1 ] call CBA_fnc_addSetting;
[ "AQR_RTB_Armor", "EDITBOX", ["Armor RTB Time (Seconds)", "Time in seconds before armor leaves the AO."], ["AAS - QRF", "2. Timers & Cooldowns"], "600", 1 ] call CBA_fnc_addSetting;
[ "AQR_RTB_Troops", "EDITBOX", ["Troops RTB Time (Seconds)", "Time in seconds before troops extract/despawn."], ["AAS - QRF", "2. Timers & Cooldowns"], "600", 1 ] call CBA_fnc_addSetting;
[ "AQR_RTB_Sea", "EDITBOX", ["Sea RTB Time (Seconds)", "Time in seconds before sea units leave the AO."], ["AAS - QRF", "2. Timers & Cooldowns"], "600", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 3. AIR & GROUND CLASSES ---
// ==========================================

[ "AQR_Plane_Class", "EDITBOX", ["Transport Plane", "Classname for the VTOL/Transport plane."], ["AAS - QRF", "3. Air & Ground Classes"], "B_T_VTOL_01_vehicle_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Heli_Heavy", "EDITBOX", ["Heavy Helicopter", "Classname for the heavy transport helicopter."], ["AAS - QRF", "3. Air & Ground Classes"], "B_Heli_Transport_03_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Heli_Escort", "EDITBOX", ["Escort Helicopter", "Classname for the escort turreted helicopter."], ["AAS - QRF", "3. Air & Ground Classes"], "B_Heli_Attack_01_dynamicLoadout_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Heli_CAS", "EDITBOX", ["CAS Helicopter", "Classname for the CAS support helicopter."], ["AAS - QRF", "3. Air & Ground Classes"], "B_Heli_Light_01_dynamicLoadout_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Ground_APC", "EDITBOX", ["Ground APC", "Classname for the APC."], ["AAS - QRF", "3. Air & Ground Classes"], "B_APC_Wheeled_01_cannon_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Ground_Turret", "EDITBOX", ["Turreted Vehicle", "Classname for the turreted vehicle."], ["AAS - QRF", "3. Air & Ground Classes"], "B_MRAP_01_hmg_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Sea_Boat", "EDITBOX", ["Armed Boat", "Classname for the naval armed boat."], ["AAS - QRF", "3. Air & Ground Classes"], "B_Boat_Armed_01_minigun_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Sea_Amphib", "EDITBOX", ["Amphibious APC", "Classname for the amphibious landing vehicle."], ["AAS - QRF", "3. Air & Ground Classes"], "B_APC_Wheeled_01_cannon_F", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 4. SQUAD CLASSES ---
// ==========================================

[ "AQR_Squad_SL", "EDITBOX", ["1. Squad Leader", "Base classname for the Infantry Squad Leader."], ["AAS - QRF", "4. Squad Classes"], "B_Soldier_SL_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Squad_MG", "EDITBOX", ["2. Machine Gunner", "Base classname for the Infantry Machine Gunner."], ["AAS - QRF", "4. Squad Classes"], "B_autorifleman_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Squad_AT", "EDITBOX", ["3. Anti-Tank/AA", "Base classname for the Infantry AT/AA specialist."], ["AAS - QRF", "4. Squad Classes"], "B_soldier_LAT_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Squad_Sniper", "EDITBOX", ["4. Sniper/Medic", "Base classname for the Infantry Sniper/Medic."], ["AAS - QRF", "4. Squad Classes"], "B_sniper_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Amphib_SL", "EDITBOX", ["1. Amphib Squad Leader", "Base classname for the maritime Team Leader."], ["AAS - QRF", "4. Squad Classes"], "B_diver_TL_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Amphib_MG", "EDITBOX", ["2. Amphib Machine Gunner", "Base classname for the maritime Auto-Rifleman."], ["AAS - QRF", "4. Squad Classes"], "B_diver_AR_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Amphib_AT", "EDITBOX", ["3. Amphib Anti-Tank/AA", "Base classname for the maritime AT/AA Specialist."], ["AAS - QRF", "4. Squad Classes"], "B_diver_exp_F", 1 ] call CBA_fnc_addSetting;
[ "AQR_Amphib_Sniper", "EDITBOX", ["4. Amphib Sniper/Medic", "Base classname for the maritime Sniper/Medic."], ["AAS - QRF", "4. Squad Classes"], "B_diver_F", 1 ] call CBA_fnc_addSetting;

// ==========================================
// --- 5. ECONOMY COSTS ---
// ==========================================

// NOTE: AQR_Econ_Preset removed. It now follows the Main AAS Core Global Setting.

[ "AQR_Cost_QRF_Custom", "EDITBOX", ["Cost: Custom / Free", "Used when 'Custom / Free' is selected."], ["AAS - QRF", "5. Economy Costs"], "0", 1 ] call CBA_fnc_addSetting;
[ "AQR_Cost_QRF_Antistasi", "EDITBOX", ["Cost: Antistasi", "Used for both Faction and Personal presets."], ["AAS - QRF", "5. Economy Costs"], "12000", 1 ] call CBA_fnc_addSetting;
[ "AQR_Cost_QRF_Overthrow", "EDITBOX", ["Cost: Overthrow", "Default Wallet funds."], ["AAS - QRF", "5. Economy Costs"], "25000", 1 ] call CBA_fnc_addSetting;
[ "AQR_Cost_QRF_Warlords", "EDITBOX", ["Cost: Warlords", "Default Command Points."], ["AAS - QRF", "5. Economy Costs"], "2000", 1 ] call CBA_fnc_addSetting;
[ "AQR_Cost_QRF_DUWS", "EDITBOX", ["Cost: DUWS", "Default CP."], ["AAS - QRF", "5. Economy Costs"], "50", 1 ] call CBA_fnc_addSetting;

// NEW: KP Liberation Individual Thresholds
[ "AQR_Cost_QRF_KPLib_S", "EDITBOX", ["Cost: KP Lib (Supplies)", "Supplies threshold for QRF."], ["AAS - QRF", "5. Economy Costs"], "350", 1 ] call CBA_fnc_addSetting;
[ "AQR_Cost_QRF_KPLib_A", "EDITBOX", ["Cost: KP Lib (Ammo)", "Ammo threshold for QRF."], ["AAS - QRF", "5. Economy Costs"], "350", 1 ] call CBA_fnc_addSetting;
[ "AQR_Cost_QRF_KPLib_F", "EDITBOX", ["Cost: KP Lib (Fuel)", "Fuel threshold for QRF."], ["AAS - QRF", "5. Economy Costs"], "350", 1 ] call CBA_fnc_addSetting;

[ "AQR_Econ_Code", "EDITBOX", ["QRF Economy Code", "SQF code for Custom mode. Use '_cost' in your code."], ["AAS - QRF", "5. Economy Costs"], "", 1 ] call CBA_fnc_addSetting;