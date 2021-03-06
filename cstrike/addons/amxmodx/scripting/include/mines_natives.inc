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

native mines_get_csx_weapon_id		(iMinesId);
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

// Create Effects
native mines_create_explosion		(const Float:vOrigin[3], const Float:fDamage, const Float:fRadius, sprExplosion1, sprExplosion2, sprBlast);
native mines_create_smoke			(const Float:vOrigin[3], const Float:fDamage, const Float:fRadius, const sprSmoke);
native mines_create_explosion_decals(const Float:vOrigin[3]);
native mines_create_bubbles			(const Float:vOrigin[3], const Float:flDamageMax, const Float:flDamageRadius, const sprBubbles);
native mines_create_hblood			(const Float:vOrigin[3], const iDamageMax, const sprBloodSpray = 0, const sprBlood = 0);

// Deployed Mines, Set Any Settings.
forward mines_entity_spawn_settings	(iEnt, uID, iMinesId);
// Deployed Mines, Set Position Settings.
forward mines_entity_set_position	(iEnt, uID, iMinesId);

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

