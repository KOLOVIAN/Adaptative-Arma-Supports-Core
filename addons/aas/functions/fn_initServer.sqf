// functions/fn_initServer.sqf

if (!isServer) exitWith {};

// Supply Drop cooldown tracking (Set to -99999 so it can be used immediately regardless of CBA settings)
missionNamespace setVariable ["AAS_SupplyDrop_LastUseTime", -99999, true];

// CAS cooldown tracking (Set to -99999 so it can be used immediately regardless of CBA settings)
missionNamespace setVariable ["AAS_CAS_LastUseTime", -99999, true];

// Reinforcements cooldown tracking (Set to -99999 so it can be used immediately regardless of CBA settings)
missionNamespace setVariable ["AAS_Reinf_LastUseTime", -99999, true];

diag_log "[AAS - Server] Initialization complete. Cooldown trackers active.";