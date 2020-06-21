#if defined _mines_natives_included
    #endinput
#endif
#define _mines_natives_included
#if AMXX_VERSION_NUM >= 175
	#pragma reqlib mines_natives
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib mines_natives
	#endif
#else
	#pragma library mines_natives
#endif

// These two are used to register land mines.
native register_mines				(classname[MAX_CLASS_LENGTH], langKey[MAX_NAME_LENGTH]);
native register_mines_data			(iMinesId, minesData[COMMON_MINES_DATA], const minesModel[]);

// If you want to deploy or pick up in each mines logic, call these.
// Normally it is not used because it is processed by core.
native mines_progress_deploy		(id, iMinesId);
native mines_progress_pickup		(id, iMinesId);
native mines_progress_stop			(id);

// Call these if you want to make a purchase for each mine logic.
// Normally it is not used because it is processed by core.
native mines_buy					(id, iMinesId);

// Explosion.
native mines_explosion				(id, iMinesId, iEnt);

// is valid take damage?
native mines_valid_takedamage		(iAttacker, iTarget);

// Set Multi Language file.
native mines_register_dictionary	(path[]);
// Set Custom Resources.
native mines_resources				(iMinesId, key[], value[], size, def[]);

// Deployed Mines, Set Any Settings.
forward mines_entity_spawn_settings	(iEnt, uID, iMinesId);
// Deploying Cursor Set Position.
forward mines_deploy_hologram		(id, iEnt, iMinesId);
// client_putinserver
forward mines_client_putinserver	(id);
// client_disconnected
forward mines_client_disconnected	(id);
// plugins_end
forward mines_plugin_end			();
// Remove Mines.
forward mines_remove_entity			(iEnt);

// Check Logic.
// check for deploy.
forward CheckForDeploy				(id, iMinesId);
// check for pickup.
forward CheckForPickup				(id, iMinesId);
// check for buy.
forward CheckForBuy					(id, iMinesId);

forward MinesPickup					(id, iMinesId, target);
// Think Event Logic.
forward MinesThink					(iEnt, iMinesId);
// Mines Breaked Logic.
// If take some action if the mine breaks?
forward MinesBreaked				(iMinesId, iEnt, iAttacker);

