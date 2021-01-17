// #pragma semicolon 1
//=============================================
//	Plugin Writed by Visual Studio Code.
//=============================================
// Supported BIOHAZARD.
// #define BIOHAZARD_SUPPORT
// #define ZP_SUPPORT

//=====================================
//  INCLUDE AREA
//=====================================
#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <mines_common>
#include <mines_natives>
#include <beams>
#if defined ZP_SUPPORT
	#include <zp50_colorchat>
	#include <zp50_ammopacks>
#endif
//=====================================
//  Resource Setting AREA
//=====================================
#define ENT_MODELS					"models/mines/sentry.mdl"
// #define ENT_SOUND1				"mines/TURRET_deploy.wav"
// #define ENT_SOUND2				"mines/TURRET_wallhit.wav"
// #define ENT_SPRITE1 				"sprites/mines/TURRET_wire.spr"

//=====================================
//  MACRO AREA
//=====================================
//
// String Data.
//
// AUTHOR NAME +ARUKARI- => SandStriker => Aoi.Kagase
#define PLUGIN 						"[M.P] Sentry Turret"
#define AUTHOR 						"Aoi.Kagase"

#define CVAR_TAG					"mines_extra_turret"

#define LANG_KEY_PLANT_GROUND 		"TURRET_PLANT_GROUND"
#define LANG_KEY_LONGNAME			"TURRET_LONG_NAME"
// ADMIN LEVEL
#define ADMIN_ACCESSLEVEL			ADMIN_LEVEL_H

#define MAX_TURRET					40
#define ENT_CLASS_TURRET			"sentry_turret"

#define TURRET_SHOTS				0.16
#define TURRET_RANGE				(100.0 * 12.0)
#define TURRET_SPREAD				Float:{0.0, 0.0, 0.0}
#define TURRET_TURNRATE				30	//angles per 0.1 second
#define TURRET_MAXWAIT				15	// seconds turret will stay active w/o a target
#define TURRET_MAXSPIN				5	// seconds turret barrel will spin w/o a target
#define TURRET_MACHINE_VOLUME		0.5

#define TR_PEV_POWERUP				"CED_TR_F_POWERUP"
#define TR_PEV_SHOTS				"CED_TR_F_SHOTS"
#define TR_PEV_ANGLES_CURRENT		"CED_TR_V_ANGLES_CURRENT"
#define TR_PEV_ANGLES_GOAL			"CED_TR_V_ANGLES_GOAL"
#define TR_PEV_HACKED_GUNPOS		"CED_TR_V_HACKED_GUNPOS"
#define TR_PEV_TURN_RATES			"CED_TR_F_TURN_RATES"
#define TR_PEV_ORIENTATION			"CED_TR_I_ORIENTATION"

enum _:TURRET_ANIM
{
	TURRET_ANIM_NONE = 0,
	TURRET_ANIM_FIRE,
	TURRET_ANIM_SPIN,
	TURRET_ANIM_DEPLOY,
	TURRET_ANIM_RETIRE,
	TURRET_ANIM_DIE
};

// bullet types
enum _:BULLET_TYPE
{
	BULLET_NONE = 0,
	BULLET_PLAYER_9MM, // glock
	BULLET_PLAYER_MP5, // mp5
	BULLET_PLAYER_357, // python
	BULLET_PLAYER_BUCKSHOT, // shotgun
	BULLET_PLAYER_CROWBAR, // crowbar swipe

	BULLET_MONSTER_9MM,
	BULLET_MONSTER_MP5,
	BULLET_MONSTER_12MM,
};

enum _:TURRET_THINK
{
	DEPLOY			= 0,
	SEARCH			,
	DETECTED		,
	FIREING			,
	LOST			,
	EXPLODE			,
};

enum _:TURRET_ORIENTATION
{
	FLOOR_MOUNT,
	CEILING_MOUNT,
};

//
// CVAR SETTINGS
//
enum _:CVAR_SETTING
{
	CVAR_MAX_HAVE			,    	// Max having ammo.
	CVAR_START_HAVE			,    	// Start having ammo.
	CVAR_FRAG_MONEY         ,    	// Get money per kill.
	CVAR_COST               ,    	// Buy cost.
	CVAR_BUY_ZONE           ,    	// Stay in buy zone can buy.
	CVAR_MAX_DEPLOY			,		// user max deploy.
	CVAR_TEAM_MAX           ,    	// Max deployed in team.
	CVAR_EXPLODE_RADIUS     ,   	// Explosion Radius.
	CVAR_EXPLODE_DMG        ,   	// Explosion Damage.
	CVAR_FRIENDLY_FIRE      ,   	// Friendly Fire.
	CVAR_CBT                ,   	// Can buy team. TR/CT/ALL
	CVAR_BUY_MODE           ,   	// Buy mode. 0 = off, 1 = on.
	CVAR_MINE_HEALTH        ,   	// TURRET health. (Can break.)
	CVAR_MINE_GLOW          ,   	// Glowing tripmine.
	CVAR_MINE_GLOW_MODE     ,   	// Glowing color mode.
	CVAR_MINE_GLOW_CT     	,   	// Glowing color for CT.
	CVAR_MINE_GLOW_TR    	,   	// Glowing color for T.
	CVAR_MINE_BROKEN		,		// Can Broken Mines. 0 = Mine, 1 = Team, 2 = Enemy.
	CVAR_DEATH_REMOVE		,		// Dead Player Remove TURRET.
	CVAR_ST_ACTIVATE		,		// Waiting for put TURRET. (0 = no progress bar.)
	CVAR_ALLOW_PICKUP		,		// allow pickup.
	CVAR_MAX_COUNT			,
};

enum _:CVAR_VALUE
{
	VALUE_MAX_HAVE				,    	// Max having ammo.
	VALUE_START_HAVE			,    	// Start having ammo.
	VALUE_FRAG_MONEY         	,    	// Get money per kill.
	VALUE_COST               	,    	// Buy cost.
	VALUE_BUY_ZONE           	,    	// Stay in buy zone can buy.
	VALUE_MAX_DEPLOY			,		// user max deploy.
	VALUE_TEAM_MAX           	,    	// Max deployed in team.
	VALUE_BUY_MODE           	,   	// Buy mode. 0 = off, 1 = on.
	// Laser design.
	VALUE_MINE_GLOW         	,   	// Glowing tripmine.
	VALUE_MINE_GLOW_MODE    	,   	// Glowing color mode.
	VALUE_MINE_BROKEN			,		// Can Broken Mines. 0 = Mine, 1 = Team, 2 = Enemy.
	VALUE_DEATH_REMOVE			,		// Dead Player Remove TURRET.
	VALUE_ALLOW_PICKUP			,		// allow pickup.
	Float:VALUE_EXPLODE_RADIUS  ,   	// Explosion Radius.
	Float:VALUE_EXPLODE_DMG     ,   	// Explosion Damage.
	Float:VALUE_MINE_HEALTH    	,   	// TURRET health. (Can break.)
	Float:VALUE_ST_ACTIVATE		,		// Waiting for put TURRET. (0 = no progress bar.)
	VALUE_CBT               [4]	,   	// Can buy team. TR/CT/ALL
	VALUE_MINE_GLOW_CT     	[13],   	// Glowing color for CT.
	VALUE_MINE_GLOW_TR    	[13],   	// Glowing color for T.
};

//====================================================
//  GLOBAL VARIABLES
//====================================================
new gCvar		[CVAR_SETTING];
new gCvarValue	[CVAR_VALUE];

new gMinesId;
new gMinesData[COMMON_MINES_DATA];


new const gEntName	[]	= ENT_CLASS_TURRET;
new const gEntModel	[]	= ENT_MODELS;
// new const gEntSprite[]	= ENT_SPRITE1;
// new const gEntSound	[][]={ENT_SOUND1, ENT_SOUND2};

//====================================================
//  PLUGIN INITIALIZE
//====================================================
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	// CVar settings.
	// Ammo.
	gCvar[CVAR_START_HAVE]	    = create_cvar(fmt("%s%s", CVAR_TAG, "_amount"),					"1"				);	// Round start have ammo count.
	gCvar[CVAR_MAX_HAVE]       	= create_cvar(fmt("%s%s", CVAR_TAG, "_max_amount"),   			"2"				);	// Max having ammo.
	gCvar[CVAR_TEAM_MAX]		= create_cvar(fmt("%s%s", CVAR_TAG, "_team_max"),				"10"			);	// Max deployed in team.
	gCvar[CVAR_MAX_DEPLOY]		= create_cvar(fmt("%s%s", CVAR_TAG, "_max_deploy"),				"10"			);	// Max deployed in user.

	// Buy system.
	gCvar[CVAR_BUY_MODE]	    = create_cvar(fmt("%s%s", CVAR_TAG, "_buy_mode"),				"1"				);	// 0 = off, 1 = on.
	gCvar[CVAR_CBT]    			= create_cvar(fmt("%s%s", CVAR_TAG, "_buy_team"),				"ALL"			);	// Can buy team. TR / CT / ALL. (BIOHAZARD: Z = Zombie)
	gCvar[CVAR_COST]           	= create_cvar(fmt("%s%s", CVAR_TAG, "_buy_price"),				"2500"			);	// Buy cost.
	gCvar[CVAR_BUY_ZONE]        = create_cvar(fmt("%s%s", CVAR_TAG, "_buy_zone"),				"1"				);	// Stay in buy zone can buy.
	gCvar[CVAR_FRAG_MONEY]     	= create_cvar(fmt("%s%s", CVAR_TAG, "_frag_money"),   			"300"			);	// Get money.

	// Mine design.
	gCvar[CVAR_MINE_HEALTH]    	= create_cvar(fmt("%s%s", CVAR_TAG, "_mine_health"),			"50"			);	// Tripmine Health. (Can break.)
	gCvar[CVAR_MINE_GLOW]      	= create_cvar(fmt("%s%s", CVAR_TAG, "_mine_glow"),				"0"				);	// Tripmine glowing. 0 = off, 1 = on.
	gCvar[CVAR_MINE_GLOW_MODE]  = create_cvar(fmt("%s%s", CVAR_TAG, "_mine_glow_color_mode"),	"0"				);	// Mine glow coloer 0 = team color, 1 = green.
	gCvar[CVAR_MINE_GLOW_TR]  	= create_cvar(fmt("%s%s", CVAR_TAG, "_mine_glow_color_t"),		"255,0,0"		);	// Team-Color for Terrorist. default:red (R,G,B)
	gCvar[CVAR_MINE_GLOW_CT]  	= create_cvar(fmt("%s%s", CVAR_TAG, "_mine_glow_color_ct"),		"0,0,255"		);	// Team-Color for Counter-Terrorist. default:blue (R,G,B)
	gCvar[CVAR_MINE_BROKEN]		= create_cvar(fmt("%s%s", CVAR_TAG, "_mine_broken"),			"2"				);	// Can broken Mines.(0 = mines, 1 = Team, 2 = Enemy)
	gCvar[CVAR_EXPLODE_RADIUS] 	= create_cvar(fmt("%s%s", CVAR_TAG, "_explode_radius"),			"320.0"			);	// Explosion radius.
	gCvar[CVAR_EXPLODE_DMG]		= create_cvar(fmt("%s%s", CVAR_TAG, "_explode_damage"),			"100"			);	// Explosion radius damage.

	// Misc Settings.
	gCvar[CVAR_DEATH_REMOVE]	= create_cvar(fmt("%s%s", CVAR_TAG, "_death_remove"),			"0"				);	// Dead Player remove TURRET. 0 = off, 1 = on.
	gCvar[CVAR_ST_ACTIVATE]		= create_cvar(fmt("%s%s", CVAR_TAG, "_activate_time"),			"1.0"			);	// Waiting for put TURRET. (int:seconds. 0 = no progress bar.)
	gCvar[CVAR_ALLOW_PICKUP]	= create_cvar(fmt("%s%s", CVAR_TAG, "_allow_pickup"),			"1"				);	// allow pickup mine. (0 = disable, 1 = it's mine, 2 = allow friendly mine, 3 = allow enemy mine!)

	create_cvar("mines_extra_turret", VERSION, FCVAR_SERVER|FCVAR_SPONLY);

	gMinesId 					= register_mines(ENT_CLASS_TURRET, LANG_KEY_LONGNAME);

	// Multi Language Dictionary.
	mines_register_dictionary("mines/mines_extra_turret.txt");

#if AMXX_VERSION_NUM > 182
	bind_cvars();
	AutoExecConfig(true, "mines_cvars_extra_turret", "mines");

	for (new i = 0; i < CVAR_MAX_COUNT; i++)
		if(gCvar[i])
			hook_cvar_change(gCvar[i], "hook_cvars");
#endif
	return PLUGIN_CONTINUE;
}

#if AMXX_VERSION_NUM < 190
//====================================================
//  PLUGIN CONFIG
//====================================================
public plugin_cfg()
{
	new file[128];
	new len = charsmax(file);
	get_localinfo("amxx_configsdir", file, len);
	formatex(file, len, "%s/plugins/mines/mines_cvars_extra_turret.cfg", file);

	if(file_exists(file)) 
	{
		server_cmd("exec %s", file);
		server_exec();
	}
	bind_cvars();
}
#else
public hook_cvars(pcvar, const old_value[], const new_value[])
{
	for(new i = 0; i < CVAR_MAX_COUNT; i++)
	{
		if (pcvar == gCvar[i])
		{
			switch(i)
			{
				case CVAR_START_HAVE		: gCvarValue[VALUE_START_HAVE]		= str_to_num(new_value);
				case CVAR_MAX_HAVE			: gCvarValue[VALUE_MAX_HAVE]		= str_to_num(new_value);
#if defined BIOHAZARD_SUPPORT
				case CVAR_NOROUND			: gCvarValue[VALUE_NOROUND]			= str_to_num(new_value);
#endif
				case CVAR_MAX_DEPLOY		: gCvarValue[VALUE_MAX_DEPLOY]		= str_to_num(new_value);
				case CVAR_TEAM_MAX			: gCvarValue[VALUE_TEAM_MAX]		= str_to_num(new_value);
				case CVAR_BUY_MODE			: gCvarValue[VALUE_BUY_MODE]		= str_to_num(new_value);
				case CVAR_BUY_ZONE			: gCvarValue[VALUE_BUY_ZONE]		= str_to_num(new_value);
				case CVAR_COST				: gCvarValue[VALUE_COST]			= str_to_num(new_value);
				case CVAR_FRAG_MONEY		: gCvarValue[VALUE_FRAG_MONEY]		= str_to_num(new_value);
				case CVAR_MINE_BROKEN		: gCvarValue[VALUE_MINE_BROKEN]		= str_to_num(new_value);
				case CVAR_ALLOW_PICKUP		: gCvarValue[VALUE_ALLOW_PICKUP]	= str_to_num(new_value);
				case CVAR_DEATH_REMOVE		: gCvarValue[VALUE_DEATH_REMOVE]	= str_to_num(new_value);
				case CVAR_MINE_GLOW			: gCvarValue[VALUE_MINE_GLOW]		= str_to_num(new_value);
				case CVAR_MINE_GLOW_MODE	: gCvarValue[VALUE_MINE_GLOW_MODE]	= str_to_num(new_value);
				case CVAR_MINE_HEALTH		: gCvarValue[VALUE_MINE_HEALTH]		= str_to_float(new_value);
				case CVAR_ST_ACTIVATE		: gCvarValue[VALUE_ST_ACTIVATE]		= str_to_float(new_value);
				case CVAR_EXPLODE_RADIUS	: gCvarValue[VALUE_EXPLODE_RADIUS]	= str_to_float(new_value);
				case CVAR_EXPLODE_DMG		: gCvarValue[VALUE_EXPLODE_DMG]		= str_to_float(new_value);

				case CVAR_CBT				: copy(gCvarValue[VALUE_CBT], 				charsmax(gCvarValue[VALUE_CBT])				   , new_value);
				case CVAR_MINE_GLOW_TR		: copy(gCvarValue[VALUE_MINE_GLOW_TR],		charsmax(gCvarValue[VALUE_MINE_GLOW_TR]) 	- 1, new_value);// last comma - 1
				case CVAR_MINE_GLOW_CT		: copy(gCvarValue[VALUE_MINE_GLOW_CT],		charsmax(gCvarValue[VALUE_MINE_GLOW_CT]) 	- 1, new_value);// last comma - 1
			}
			break;
		}
	}
	update_mines_parameter();
}
#endif

bind_cvars()
{
	bind_pcvar_num		(gCvar[CVAR_START_HAVE],		gCvarValue[VALUE_START_HAVE]);
	bind_pcvar_num		(gCvar[CVAR_MAX_HAVE],			gCvarValue[VALUE_MAX_HAVE]);
#if defined BIOHAZARD_SUPPORT
	bind_pcvar_num		(gCvar[CVAR_NOROUND],			gCvarValue[VALUE_NOROUND]);
#endif
	bind_pcvar_num		(gCvar[CVAR_MAX_DEPLOY],		gCvarValue[VALUE_MAX_DEPLOY]);
	bind_pcvar_num		(gCvar[CVAR_TEAM_MAX],			gCvarValue[VALUE_TEAM_MAX]);
	bind_pcvar_num		(gCvar[CVAR_BUY_MODE],			gCvarValue[VALUE_BUY_MODE]);
	bind_pcvar_num		(gCvar[CVAR_BUY_ZONE],			gCvarValue[VALUE_BUY_ZONE]);
	bind_pcvar_num		(gCvar[CVAR_COST],				gCvarValue[VALUE_COST]);
	bind_pcvar_num		(gCvar[CVAR_FRAG_MONEY],		gCvarValue[VALUE_FRAG_MONEY]);
	bind_pcvar_num		(gCvar[CVAR_MINE_BROKEN],		gCvarValue[VALUE_MINE_BROKEN]);
	bind_pcvar_num		(gCvar[CVAR_ALLOW_PICKUP],		gCvarValue[VALUE_ALLOW_PICKUP]);
	bind_pcvar_num		(gCvar[CVAR_DEATH_REMOVE],		gCvarValue[VALUE_DEATH_REMOVE]);
	bind_pcvar_num		(gCvar[CVAR_MINE_GLOW],			gCvarValue[VALUE_MINE_GLOW]);
	bind_pcvar_num		(gCvar[CVAR_MINE_GLOW_MODE],	gCvarValue[VALUE_MINE_GLOW_MODE]);
	bind_pcvar_float	(gCvar[CVAR_MINE_HEALTH],		gCvarValue[VALUE_MINE_HEALTH]);
	bind_pcvar_float	(gCvar[CVAR_ST_ACTIVATE],		gCvarValue[VALUE_ST_ACTIVATE]);
	bind_pcvar_float	(gCvar[CVAR_EXPLODE_RADIUS],	gCvarValue[VALUE_EXPLODE_RADIUS]);
	bind_pcvar_float	(gCvar[CVAR_EXPLODE_DMG],		gCvarValue[VALUE_EXPLODE_DMG]);

	bind_pcvar_string	(gCvar[CVAR_CBT], 				gCvarValue[VALUE_CBT], 				charsmax(gCvarValue[VALUE_CBT]));
	bind_pcvar_string	(gCvar[CVAR_MINE_GLOW_TR],		gCvarValue[VALUE_MINE_GLOW_TR],		charsmax(gCvarValue[VALUE_MINE_GLOW_TR]) 	- 1);// last comma - 1
	bind_pcvar_string	(gCvar[CVAR_MINE_GLOW_CT],		gCvarValue[VALUE_MINE_GLOW_CT],		charsmax(gCvarValue[VALUE_MINE_GLOW_CT]) 	- 1);// last comma - 1

	update_mines_parameter();
}

update_mines_parameter()
{
	gMinesData[AMMO_HAVE_START] =	gCvarValue[VALUE_START_HAVE];
	gMinesData[AMMO_HAVE_MAX]	=	gCvarValue[VALUE_MAX_HAVE];
#if defined BIOHAZARD_SUPPORT
	gMinesData[NO_ROUND]		=	gCvarValue[VALUE_NOROUND];
#endif
	gMinesData[DEPLOY_MAX]		=	gCvarValue[VALUE_MAX_DEPLOY];
	gMinesData[DEPLOY_TEAM_MAX]	=	gCvarValue[VALUE_TEAM_MAX];
	gMinesData[BUY_MODE]		=	gCvarValue[VALUE_BUY_MODE];
	gMinesData[BUY_ZONE]		=	gCvarValue[VALUE_BUY_ZONE];
	gMinesData[BUY_PRICE]		=	gCvarValue[VALUE_COST];
	gMinesData[FRAG_MONEY]		=	gCvarValue[VALUE_FRAG_MONEY];
	gMinesData[MINES_BROKEN]	=	gCvarValue[VALUE_MINE_BROKEN];
	gMinesData[ALLOW_PICKUP]	=	gCvarValue[VALUE_ALLOW_PICKUP];
	gMinesData[DEATH_REMOVE]	=	gCvarValue[VALUE_DEATH_REMOVE];
	gMinesData[GLOW_ENABLE]		=	gCvarValue[VALUE_MINE_GLOW];
	gMinesData[GLOW_MODE]		=	gCvarValue[VALUE_MINE_GLOW_MODE];
	gMinesData[MINE_HEALTH]		=	_:gCvarValue[VALUE_MINE_HEALTH];
	gMinesData[ACTIVATE_TIME]	=	_:gCvarValue[VALUE_ST_ACTIVATE];
	gMinesData[EXPLODE_RADIUS]	=	_:gCvarValue[VALUE_EXPLODE_RADIUS];
	gMinesData[EXPLODE_DAMAGE]	=	_:gCvarValue[VALUE_EXPLODE_DMG];
	gMinesData[BUY_TEAM] 		=	_:get_team_code(gCvarValue[VALUE_CBT]);
	gMinesData[GLOW_COLOR_TR]	=	get_cvar_to_color(gCvarValue[VALUE_MINE_GLOW_TR]);
	gMinesData[GLOW_COLOR_CT]	=	get_cvar_to_color(gCvarValue[VALUE_MINE_GLOW_CT]);

	register_mines_data(gMinesId, gMinesData, gEntModel);
}

//====================================================
//  PLUGIN PRECACHE
//====================================================
public plugin_precache() 
{
	// for (new i = 0; i < sizeof(gEntSound); i++)
	// 	precache_sound(gEntSound[i]);
	precache_sound("turret/tu_deploy.wav");
	precache_sound("weapons/hks1.wav");
	precache_sound("weapons/hks2.wav");
	precache_sound("weapons/hks3.wav");

	precache_model(gEntModel);
	// precache_model(gEntSprite);

	return PLUGIN_CONTINUE;
}

//====================================================
// TURRET Settings.
//====================================================
public mines_entity_spawn_settings(iEnt, uID, iMinesId)
{
	if (iMinesId != gMinesId) return 0;
	// Entity Setting.
	// set class name.
	set_pev(iEnt, pev_classname, 	gEntName);
	// set models.
	engfunc(EngFunc_SetModel, 		iEnt, gEntModel);
	// set solid.
	set_pev(iEnt, pev_solid, 		SOLID_NOT);
	// set movetype.
	set_pev(iEnt, pev_movetype, 	MOVETYPE_FLY);
	// set model animation.
	set_pev(iEnt, pev_body, 		0);

	new Float:vOfs[3] = {0.0, 0.0,  12.75};
	set_pev(iEnt, pev_view_ofs, 	vOfs);

	set_pev(iEnt, pev_rendermode,	kRenderNormal);
	set_pev(iEnt, pev_renderfx,	 	kRenderFxNone);

	// set take damage.
	set_pev(iEnt, pev_takedamage, 	DAMAGE_YES);
	set_pev(iEnt, pev_dmg, 			100.0);
	
	// set size.
	// new Float:mins[3], Float:maxs[3];
	// if (GetModelBoundingBox(iEnt, mins, maxs, Model_CurrentSequence))
	// 	engfunc(EngFunc_SetSize, iEnt, 	mins, maxs);
	// else
	engfunc(EngFunc_SetSize, iEnt, 	Float:{ -16.0, -16.0, -32.0}, Float:{ 16.0, 16.0, 32.0});

	set_pev(iEnt, pev_effects, 		pev(iEnt, pev_effects) | EF_INVLIGHT)
	set_pev(iEnt, pev_animtime, 	get_gametime());
	set_pev(iEnt, pev_framerate, 	1.0);
	// set entity health.
	mines_set_health(iEnt, gMinesData[MINE_HEALTH]);

	// Save results to be used later.
	CED_SetCell(iEnt, MINES_OWNER, uID);

	// Reset powoer on delay time.
	new Float:fCurrTime = get_gametime();
	CED_SetCell(iEnt, TR_PEV_POWERUP, 	fCurrTime + 2.5);
	CED_SetCell(iEnt, MINES_STEP, 		DEPLOY);

	// think rate. hmmm....
	set_pev(iEnt, pev_nextthink, fCurrTime + 0.2 );

	// Power up sound.
	// cm_play_sound(iEnt, SOUND_POWERUP);
	return 1;
}

//====================================================
// Set TURRET Position.
//====================================================
public mines_entity_set_position(iEnt, uID, iMinesId)
{
	if (iMinesId != gMinesId) return 0;

	// Vector settings.
	new Float:vOrigin	[3],Float:vViewOfs	[3];
	new	Float:vNewOrigin[3],Float:vNormal	[3],
		Float:vTraceEnd	[3],Float:vEntAngles[3];
	new Float:vDecals	[3];
	new iReturn = 0;

	// get user position.
	pev(uID, pev_origin, 	vOrigin);
	pev(uID, pev_view_ofs, 	vViewOfs);

	velocity_by_aim(uID, 128, vTraceEnd);
	vTraceEnd[2] = -128.0;

	xs_vec_add(vOrigin, 	vViewOfs, 	vOrigin);
	xs_vec_add(vTraceEnd, 	vOrigin, 	vTraceEnd);

    // create the trace handle.
	new trace = create_tr2();
	// get wall position to vNewOrigin.
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, uID, trace);
	{
		new Float:fFraction;
		get_tr2( trace, TR_flFraction, fFraction );
			
		// -- We hit something!
		if ( fFraction < 1.0 )
		{
			// -- Save results to be used later.
			get_tr2( trace, TR_vecEndPos, vTraceEnd );
			get_tr2( trace, TR_vecPlaneNormal, vNormal );

			if (xs_vec_distance(vOrigin, vTraceEnd) < 128.0)
			{
				// calc Decal position.
				xs_vec_add(vTraceEnd, vNormal, vDecals);
				// TURRET user Angles.
				new Float:pAngles[3];
				pev(uID, pev_angles, pAngles);

				// Rotate tripmine.
				vector_to_angle(vNormal, vEntAngles);
				vEntAngles[0] = 0.0;
				vEntAngles[1] = pAngles[1];
				vEntAngles[2] = 0.0;

				// xs_vec_mul_scalar( vNormal, 1.0, vNormal);
				xs_vec_add(vTraceEnd, vNormal, vNewOrigin);

				// set entity position.
				engfunc(EngFunc_SetOrigin, iEnt, vNewOrigin);

				// set angle.
				set_pev(iEnt, pev_angles, 	vEntAngles);
				CED_SetArray(iEnt, MINES_DECALS, vDecals, sizeof(vDecals));
				iReturn = 1;
			}
		}
	}
    // free the trace handle.
	free_tr2(trace);
	return iReturn;
}

//====================================================
// TURRET Think Event.
//====================================================
public MinesThink(iEnt, iMinesId)
{
	if (!pev_valid(iEnt))
		return;

	// is this TURRET? no.
	if (iMinesId != gMinesId)
		return;

	// static Float:fCurrTime;
	static step;
	new Float:vOrigin[3];
	new Float:vEnemy[3];
	new Float:fCurTime;
	new iOwner;
	new Float:vOfs[3];
	pev(iEnt, pev_origin, vOrigin);
	pev(iEnt, pev_view_ofs, vOfs);
	xs_vec_add(vOrigin, vOfs, vOrigin);
	CED_GetCell(iEnt, MINES_OWNER, iOwner);
	pev(iOwner, pev_origin, vEnemy);
	// fCurrTime = get_gametime();
	CED_GetCell(iEnt, MINES_STEP, step);

	// TURRET state.
	// Power up.
	switch(step)
	{
		case DEPLOY:
		{
			// Turret_Initialize(iEnt);
			emit_sound(iEnt, CHAN_BODY, "turret/tu_deploy.wav", 0.5, ATTN_NORM, 0, PITCH_NORM);
			if (pev(iEnt, pev_sequence) != TURRET_ANIM_DEPLOY)
			{
				SetTurretAnim(iEnt, TURRET_ANIM:TURRET_ANIM_DEPLOY);
				set_pev(iEnt, pev_controller_1,	0.0);
			}
			// Turret_Deploy(iEnt);
			mines_glow(iEnt, gMinesData);
			// solid complete.
			set_pev(iEnt, pev_solid, 	SOLID_BBOX);
			set_pev(iEnt, pev_movetype, MOVETYPE_TOSS);
			// next state.
			CED_SetCell(iEnt, MINES_STEP, SEARCH);
		}
		case SEARCH:
		{
			CED_GetCell(iEnt, TR_PEV_SHOTS, fCurTime);
			SetTurretAnim(iEnt, TURRET_ANIM:TURRET_ANIM_SPIN);
				set_pev(iEnt, pev_controller_1,	0.0);
			// Turret_SearchThink(iEnt);
			Shoot(iEnt, iOwner, vOrigin, vEnemy);
			if (fCurTime < get_gametime())
			{
				new Float:angle = xs_vec_angle(vOrigin, vEnemy);
				set_pev(iEnt, pev_controller_0, angle);
				CED_SetCell(iEnt, TR_PEV_SHOTS, fCurTime + TURRET_SHOTS);
				set_pev(iEnt, pev_nextthink, get_gametime() + TURRET_SHOTS);
			}
		}
		case DETECTED:
		{return;}
		case FIREING:
		{return;}
		case LOST:
		{return;}
		// EXPLODE
		case EXPLODE:
		{
			// Stopping sound.
			// cm_play_sound(iEnt, SOUND_STOP);

			// effect explosion.
			static owner;
			CED_GetCell(iEnt, MINES_OWNER, owner);
			mines_explosion(owner, iMinesId, iEnt);
		}
	}

	return;
}

//====================================================
// Check: On the wall.
//====================================================
public CheckForDeploy(id, iMinesId)
{
	if(iMinesId != gMinesId) 
		return false;

	new Float:vTraceEnd[3];
	new Float:vOrigin[3];

	// Get potision.
	pev(id, pev_origin, vOrigin);
	
	// Get wall position.
	velocity_by_aim(id, 128, vTraceEnd);
	vTraceEnd[2] = -128.0;

	xs_vec_add(vTraceEnd, vOrigin, vTraceEnd);

    // create the trace handle.
	new trace = create_tr2();
	new Float:fFraction = 0.0;
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, id, trace);
	{
    	get_tr2( trace, TR_flFraction, fFraction );
    }
    // free the trace handle.
	free_tr2(trace);

	// We hit something!
	if ( fFraction < 1.0 )
		return true;

	new sLongName[MAX_NAME_LENGTH];
	formatex(sLongName, charsmax(sLongName), "%L", id, LANG_KEY_LONGNAME);
	client_print_color(id, id, "%L", id, LANG_KEY_PLANT_GROUND, CHAT_TAG, sLongName);

	return false;
}

public MinesBreaked(iMinesId, iEnt, iAttacker)
{
	if (iMinesId != gMinesId) return HAM_IGNORED;
#if defined ZP_SUPPORT
	zp_ammopacks_set(iAttacker, zp_ammopacks_get(iAttacker) + gCvarValue[VALUE_FRAG_MONEY]);
	zp_colored_print(0, "^4%n ^1earned^4 %i points ^1for destorying a turret !", iAttacker, addpoint);
#endif
    return HAM_IGNORED;
}

//====================================================
// Play sound.
//====================================================
// cm_play_sound(iEnt, iSoundType)
// {
// 	switch (iSoundType)
// 	{
// 		case SOUND_POWERUP:
// 		{
// 			emit_sound(iEnt, CHAN_VOICE, gEntSound[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
// 		}
// 		case SOUND_ACTIVATE:
// 		{
// 			emit_sound(iEnt, CHAN_VOICE, gEntSound[1], 0.5, ATTN_NORM, 1, 75);
// 		}
// 	}
// }



//====================================================
// Include HLSDK
//====================================================
stock UTIL_PlayAnim(const id, const sequence, Float:frame=0.0, Float:framerate=1.0, Float:animtime=1.0)
{
	set_pev(id, pev_sequence, 		sequence);
	set_pev(id, pev_gaitsequence, 	sequence);
	set_pev(id, pev_frame, 			frame);
	set_pev(id, pev_framerate, 		framerate); 
	set_pev(id, pev_animtime, 		get_gametime() + animtime); //get_gametime()
}

stock Shoot(iEnt, iAttacker, Float:vecSrc[3], Float:vecDirToEnemy[3])
{
	FireBullets(iEnt, vecSrc, vecDirToEnemy, 0, iAttacker);

	// switch(random_num(0,2))
	// {
	// 	case 0: emit_sound(iEnt, CHAN_WEAPON, "weapons/hks1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	// 	case 1: emit_sound(iEnt, CHAN_WEAPON, "weapons/hks2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	// 	case 2: emit_sound(iEnt, CHAN_WEAPON, "weapons/hks3.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
	// }
	set_pev(iEnt, pev_effects, pev(iEnt, pev_effects) | EF_MUZZLEFLASH);
}

/*
================
FireBullets
Go to the trouble of combining multiple pellets into a single damage call.
This version is used by Monsters.
================
param: iEnt
param: cShot = 1
*/
// FireBullets(iEnt, 1, vecSrc, vecDirToEnemy, TURRET_SPREAD, TURRET_RANGE, 1);

stock FireBullets
(	
	iEnt,				// iEnt,
	Float:vecSrc[3], 	// vecSrc
	Float:vecDir[3], 	// VecDirToEnemy
	iDamage 	= 0,
	iAttacker
)
{

	new Float:vecTmp[3];
	new Float:fFraction;
	new iTarget;

	new trace = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecDir, DONT_IGNORE_MONSTERS, iEnt, trace);
	{
		get_tr2(trace, TR_flFraction, fFraction);
		get_tr2(trace, TR_vecEndPos, vecTmp);

		message_begin	(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte		(TE_TRACER);
		write_coord_f	(vecSrc[0]);
		write_coord_f	(vecSrc[1]);
		write_coord_f	(vecSrc[2]);
		write_coord_f	(vecTmp[0]);
		write_coord_f	(vecTmp[1]);
		write_coord_f	(vecTmp[2]);
		message_end		();

		// do damage, paint decals
		if (fFraction != 1.0)
		{
			iTarget = get_tr2(trace, TR_pHit);

			// message_begin	(MSG_BROADCAST, SVC_TEMPENTITY);
			// write_byte		(TE_GUNSHOTDECAL);
			// write_coord_f	(vecTmp[0]);
			// write_coord_f	(vecTmp[1]);
			// write_coord_f	(vecTmp[2]);
			// write_short		(iTarget);
			// write_byte		(BULLET_MONSTER_MP5);
			// message_end		();

			if (iDamage)
			{
				ExecuteHamB(Ham_TakeDamage, iTarget, iEnt, iAttacker, Float:iDamage, DMG_BULLET);
			}
				/*
				if( iDamage )
				{
					pEntity->TraceAttack( pevAttacker, iDamage, vecDir, &tr, DMG_BULLET | ( ( iDamage > 16 ) ? DMG_ALWAYSGIB : DMG_NEVERGIB ) );

					TEXTURETYPE_PlaySound( &tr, vecSrc, vecEnd, iBulletType );
					DecalGunshot( &tr, iBulletType );
				} 
				*/
		}
		free_tr2(trace);
	// make bullet trails
//		UTIL_BubbleTrail( vecSrc, tr.vecEndPos, (int)( ( flDistance * tr.flFraction ) / 64.0f ) );
	}
}

stock SetTurretAnim(iEnt, TURRET_ANIM:anim)
{
	new TURRET_ANIM:sequence;
	pev(iEnt, pev_sequence, sequence);

	if (sequence != anim)
	{
		switch(anim)
		{
			case TURRET_ANIM_FIRE, TURRET_ANIM_SPIN:
			{
				if (sequence != TURRET_ANIM:TURRET_ANIM_FIRE && sequence != TURRET_ANIM:TURRET_ANIM_SPIN)
					set_pev(iEnt, pev_frame, 0);
			}
			default:
				set_pev(iEnt, pev_frame, 0);
		}

		set_pev(iEnt, pev_sequence, anim);

		// ResetSequenceInfo( );

		switch(anim)
		{
			case TURRET_ANIM_RETIRE:
			{
				set_pev(iEnt, pev_frame, 		255);
				set_pev(iEnt, pev_framerate, 	-1.0);
			}
			case TURRET_ANIM_DIE:
			{
				set_pev(iEnt, pev_framerate, 	1.0);
			}
		}
		//ALERT(at_console, "Turret anim #%d\n", anim);
	}
}

// //=========================================================
// // StudioFrameAdvance - advance the animation frame up to the current time
// // if an flInterval is passed in, only advance animation that number of seconds
// //=========================================================
// stock Flaot:StudioFrameAdvance (iEnt, Float:flInterval = 0.0 )
// {
// 	new Float:animtime;
// 	pev(iEnt, pev_animtime, animtime);
// 	if (flInterval == 0.0)
// 	{
// 		flInterval = (gpGlobals->time - animtime);
// 		if (flInterval <= 0.001)
// 		{
// 			set_pev(iEnt, pev_animtime, get_gametime());
// 			return 0.0;
// 		}
// 	}

// 	if (animtime > 0.0)
// 		flInterval = 0.0;
	
// 	new frame, Float:framerate;
// 	pev(iEnt, pev_framerate, framerate);
// 	set_pev(iEnt, pev_frame, pev(iEnt, pev_frame) + (flInterval * framerate));
// 	set_pev(iEnt, pev_animtime, get_gametime());

// 	frame = pev(iEnt, pev_frame);
// 	if (frame < 0.0 || frame >= 256.0) 
// 	{
// 		if (m_fSequenceLoops)
// 			pev->frame -= (int)(frame / 256.0) * 256.0;
// 		else
// 			pev->frame = (frame < 0.0) ? 0 : 255;
// 		m_fSequenceFinished = TRUE;	// just in case it wasn't caught in GetEvents
// 	}

// 	return flInterval;
// }

// stock SpinUpCall(void)
// {
// 	StudioFrameAdvance( );
// 	pev->nextthink = gpGlobals->time + 0.1;

// 	// Are we already spun up? If not start the two stage process.
// 	if (!m_iSpin)
// 	{
// 		SetTurretAnim( TURRET_ANIM_SPIN );
// 		// for the first pass, spin up the the barrel
// 		if (!m_iStartSpin)
// 		{
// 			pev->nextthink = gpGlobals->time + 1.0; // spinup delay
// 			EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_spinup.wav", TURRET_MACHINE_VOLUME, ATTN_NORM);
// 			m_iStartSpin = 1;
// 			pev->framerate = 0.1;
// 		}
// 		// after the barrel is spun up, turn on the hum
// 		else if (pev->framerate >= 1.0)
// 		{
// 			pev->nextthink = gpGlobals->time + 0.1; // retarget delay
// 			EMIT_SOUND(ENT(pev), CHAN_STATIC, "turret/tu_active2.wav", TURRET_MACHINE_VOLUME, ATTN_NORM);
// 			SetThink(&CTurret::ActiveThink);
// 			m_iStartSpin = 0;
// 			m_iSpin = 1;
// 		} 
// 		else
// 		{
// 			pev->framerate += 0.075;
// 		}
// 	}

// 	if (m_iSpin)
// 	{
// 		SetThink(&CTurret::ActiveThink);
// 	}
// }


// void CTurret::SpinDownCall(void)
// {
// 	if (m_iSpin)
// 	{
// 		SetTurretAnim( TURRET_ANIM_SPIN );
// 		if (pev->framerate == 1.0)
// 		{
// 			EMIT_SOUND_DYN(ENT(pev), CHAN_STATIC, "turret/tu_active2.wav", 0, 0, SND_STOP, 100);
// 			EMIT_SOUND(ENT(pev), CHAN_ITEM, "turret/tu_spindown.wav", TURRET_MACHINE_VOLUME, ATTN_NORM);
// 		}
// 		pev->framerate -= 0.02;
// 		if (pev->framerate <= 0)
// 		{
// 			pev->framerate = 0;
// 			m_iSpin = 0;
// 		}
// 	}
// }