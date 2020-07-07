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
#define VERSION 					"0.01"

#define CVAR_TAG					"mines_extra_turret"

#define LANG_KEY_PLANT_GROUND 		"TURRET_PLANT_GROUND"
#define LANG_KEY_LONGNAME			"TURRET_LONG_NAME"
// ADMIN LEVEL
#define ADMIN_ACCESSLEVEL			ADMIN_LEVEL_H

#define MAX_TURRET					40
#define ENT_CLASS_TURRET			"sentry_turret"

#define TURRET_MAXWAIT				15
#define TURRET_TURNRATE				30	//angles per 0.1 second
#define TURRET_MAXWAIT				15	// seconds turret will stay active w/o a target
#define TURRET_MAXSPIN				5	// seconds turret barrel will spin w/o a target
#define TURRET_MACHINE_VOLUME		0.5

#define TURRET_PEV_POWERUP			pev_fuser2
#define TURRET_PEV_CURRENT_ANGLES	pev_vuser1
#define TURRET_PEV_GOAL_ANGLES		pev_vuser2
#define TURRET_PEV_HACKED_GUNPOS	pev_vuser3
#define TURRET_PEV_TURN_RATES		pev_fuser1
#define TURRET_PEV_ORIENTATION		pev_iuser2	// 

enum _:TURRET_ANIM
{
	TURRET_ANIM_NONE = 0,
	TURRET_ANIM_FIRE,
	TURRET_ANIM_SPIN,
	TURRET_ANIM_DEPLOY,
	TURRET_ANIM_RETIRE,
	TURRET_ANIM_DIE
};

enum _:TURRET_THINK
{
	DEPLOY			= 0,
	SEARCH			,
	DETECTED		,
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
	precache_model(gEntModel);
	// precache_model(gEntSprite);

	return PLUGIN_CONTINUE;
}

//====================================================
// TURRET Settings.
//====================================================
public mines_entity_spawn_settings(iEnt, uID, iMinesId)
{
	if (iMinesId != gMinesId) return;
	// Entity Setting.
	// set class name.
	set_pev(iEnt, pev_classname, gEntName);

	// set models.
	engfunc(EngFunc_SetModel, iEnt, gEntModel);

	// set solid.
	set_pev(iEnt, pev_solid, SOLID_NOT);

	// set movetype.
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY);

	// set model animation.
	set_pev(iEnt, pev_body, 		0);
	UTIL_PlayAnim(iEnt, TURRET_ANIM_NONE, 120.0, 0.1, 0.1);

	set_pev(iEnt, TURRET_PEV_ORIENTATION, FLOOR_MOUNT);

	set_pev(iEnt, pev_rendermode,	kRenderNormal);
	set_pev(iEnt, pev_renderfx,	 	kRenderFxNone);

	// set take damage.
	set_pev(iEnt, pev_takedamage, DAMAGE_YES);
	set_pev(iEnt, pev_dmg, 100.0);

	// set entity health.
	set_pev(iEnt, pev_health, gMinesData[MINE_HEALTH]);

	// set mine position
	set_mine_position(uID, iEnt);

	// Save results to be used later.
	set_pev(iEnt, MINES_OWNER, uID );

	// Reset powoer on delay time.
	new Float:fCurrTime = get_gametime();
	set_pev(iEnt, TURRET_PEV_POWERUP, fCurrTime + 2.5 );
	set_pev(iEnt, MINES_STEP, DEPLOY);

	// think rate. hmmm....
	set_pev(iEnt, pev_nextthink, fCurrTime + 0.2 );

	// Power up sound.
	// cm_play_sound(iEnt, SOUND_POWERUP);
}

//====================================================
// Set TURRET Position.
//====================================================
set_mine_position(uID, iEnt)
{
	// Vector settings.
	new Float:vOrigin[3];
	new	Float:vNewOrigin[3],Float:vNormal[3],
		Float:vTraceEnd[3],Float:vEntAngles[3];

	// get user position.
	pev(uID, pev_origin, vOrigin);
	velocity_by_aim(uID, 128, vTraceEnd);
	vTraceEnd[2] = -128.0;
	xs_vec_add(vTraceEnd, vOrigin, vTraceEnd );

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
		}
	}
    // free the trace handle.
	free_tr2(trace);

	// xs_vec_mul_scalar( vNormal, 1.0, vNormal );
	xs_vec_add( vTraceEnd, vNormal, vNewOrigin );

	set_pev(iEnt, pev_sequence, 0);

	// set size.
	new Float:mins[3], Float:maxs[3];
	if (GetModelBoundingBox(iEnt, mins, maxs, Model_CurrentSequence))
	{
		engfunc(EngFunc_SetSize, iEnt, mins, maxs);
		client_print_color(0, print_chat, "%.2f, %.2f, %.2f %.2f, %.2f, %.2f", mins[0], mins[1], mins[2], maxs[0], maxs[1], maxs[2]);
	}
	else
		// -16.91, -13.28, -0.01 13.30, 13.29, 57.02
		engfunc(EngFunc_SetSize, iEnt, Float:{ -7.8, -26.0, -8.44 }, Float:{ 7.8, 4.8, 7.8 } );
	// set entity position.
	engfunc(EngFunc_SetOrigin, iEnt, vNewOrigin );

	// TURRET user Angles.
	new Float:pAngles[3];
	pev(uID, pev_angles, pAngles);
	pAngles[0]   = -90.0;
	pAngles[1]  += 90.0;

	// Rotate tripmine.
	vector_to_angle(vNormal, vEntAngles);
	xs_vec_add(vEntAngles, pAngles, vEntAngles); 

	// set angle.
	// set_pev(iEnt, pev_angles, vEntAngles);
	Turret_Initialize(iEnt);
	Turret_Deploy(iEnt);
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

	static Float:fCurrTime;
	static step;

	fCurrTime = get_gametime();
	step = pev(iEnt, MINES_STEP);

	// TURRET state.
	// Power up.
	switch(step)
	{
		case DEPLOY:
		{
			Turret_Initialize(iEnt);
			Turret_Deploy(iEnt);
			mines_glow(iEnt, gMinesData);
			// solid complete.
			set_pev(iEnt, pev_solid, SOLID_BBOX);
			set_pev(iEnt, pev_movetype, MOVETYPE_FLY);
			// next state.
			set_pev(iEnt, MINES_STEP, SEARCH);
		}
		case SEARCH:
		{return;}
		case DETECTED:
		{return;}
		case LOST:
		{return;}
		// EXPLODE
		case EXPLODE:
		{
			// Stopping sound.
			// cm_play_sound(iEnt, SOUND_STOP);

			// effect explosion.
			mines_explosion(pev(iEnt, MINES_OWNER), iMinesId, iEnt);
		}
	}

	return;
}

//====================================================
// Check: On the wall.
//====================================================
public CheckForDeploy(id, iMinesId)
{
	if(iMinesId != gMinesId) return false;

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

public mines_deploy_hologram(id, iEnt, iMinesId)
{
	if (iMinesId != gMinesId)
		return 0;

	// Vector settings.
	static	Float:vOrigin[3];
	static	Float:vNewOrigin[3],Float:vNormal[3],
			Float:vTraceEnd[3],Float:vEntAngles[3];

	// Get wall position.
	velocity_by_aim(id, 128, vTraceEnd);
	vTraceEnd[2] = -128.0;

	// get user position.
	pev(id, pev_origin, vOrigin);
	xs_vec_add(vTraceEnd, vOrigin, vTraceEnd);

	// create the trace handle.
	static trace;
	static result;
	result = 0;
	trace = create_tr2();

	// get wall position to vNewOrigin.
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, IGNORE_MONSTERS, id, trace);
	{
		// -- We hit something!
		// -- Save results to be used later.
		get_tr2(trace, TR_vecEndPos, vTraceEnd);
		get_tr2(trace, TR_vecPlaneNormal, vNormal);

		if (xs_vec_distance(vOrigin, vTraceEnd) < 128.0)
		{
			// xs_vec_mul_scalar(vNormal, 8.0, vNormal);
			xs_vec_add(vTraceEnd, vNormal, vNewOrigin);
			// set entity position.
			engfunc(EngFunc_SetOrigin, iEnt, vNewOrigin);
			// TURRET user Angles.
			new Float:pAngles[3];
			pev(id, pev_angles, pAngles);
			pAngles[0]   = -90.0;
			pAngles[1]  +=  90.0;

			// Rotate tripmine.
			vector_to_angle(vNormal, vEntAngles);
			xs_vec_add(vEntAngles, pAngles, vEntAngles); 
			// set angle.
			// set_pev(iEnt, pev_angles, vEntAngles);
			Turret_Initialize(iEnt);
			result = 1;
		}
		else
		{
			result = 0;
		}
	}
	// free the trace handle.
	free_tr2(trace);

	return result;
}

stock UTIL_PlayAnim(const id, const sequence, Float:frame=0.0, Float:framerate=1.0, Float:animtime=1.0)
{
	set_pev(id, pev_sequence, 		sequence);
	set_pev(id, pev_gaitsequence, 	sequence);
	set_pev(id, pev_frame, 			frame);
	set_pev(id, pev_framerate, 		framerate); 
	set_pev(id, pev_animtime, 		get_gametime() + animtime); //get_gametime()
}

//====================================================
// Include HLSDK
//====================================================
stock Float:StudioFrameAdvance(iEnt, Float:flInterval = 0.0, Float:flFrameRate = 0.0, fSequenceLoops = 0)
{
	new Float:animtime;
	pev(iEnt, pev_animtime, animtime);
	
	new Float:frame;
	new Float:framerate;
	pev(iEnt, pev_frame, frame);
	pev(iEnt, pev_framerate, framerate);

	if (flInterval == 0.0)
	{
		flInterval = get_gametime() - animtime;
		if(flInterval <= 0.001)
		{
			set_pev(iEnt, pev_animtime, get_gametime());
			return 0.0;
		}
	}
	if (!animtime)
		flInterval = 0.0;

	frame += flInterval * flFrameRate * framerate;
	set_pev(iEnt, pev_frame, frame);

	if (frame < 0.0 || frame >= 256.0)
	{
		if(fSequenceLoops)
			frame -= (frame / 256.0) * 256.0;
		else
			frame = (frame < 0.0) ? 0.0 : 255.0;
		// fSequenceFinished = TRUE;	// just in case it wasn't caught in GetEvents
	}
	set_pev(iEnt, pev_frame, frame);

	return flInterval;
}

stock Turret_Initialize(iEnt)
{
	// m_iOn = 0;
	// m_fBeserk = 0;
	// m_iSpin = 0;
	new Float:vecOfs[3], Float:vecAngles[3], Float:vecGoalAngles[3];
	pev(iEnt, pev_angles, vecAngles);
	pev(iEnt, pev_angles, vecGoalAngles);

	set_controller(iEnt, 0, 0.0);
	set_controller(iEnt, 1, 0.0);

	if( pev(iEnt, TURRET_PEV_ORIENTATION) == CEILING_MOUNT)
	{
		pev(iEnt, pev_view_ofs, vecOfs);
		vecOfs[2] = -vecOfs[2];

		set_pev(iEnt, pev_idealpitch, 180.0);
		vecAngles[0] = 180.0;
		set_pev(iEnt, pev_angles, vecAngles);
		set_pev(iEnt, pev_view_ofs, vecOfs);
		set_pev(iEnt, pev_effects, pev(iEnt, pev_effects) | EF_INVLIGHT);

		vecAngles[1] += 180.0;
		if( vecAngles[1] > 360 )
			vecAngles[1] -= 360.0;
		set_pev(iEnt, pev_angles, vecAngles);
	}

	vecGoalAngles[0] = 0.0;
	// m_flLastSight = get_gametime() + TURRET_MAXWAIT;
	set_pev(iEnt, TURRET_PEV_GOAL_ANGLES, vecGoalAngles);
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
}

stock Turret_Deploy(iEnt)
{
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);
	new sequence = pev(iEnt, pev_sequence);
	StudioFrameAdvance(iEnt);

	if( sequence != TURRET_ANIM_DEPLOY)
	{
		// m_iOn = 1;
		Turret_SetTurretAnim(iEnt, TURRET_ANIM_DEPLOY);
		emit_sound(iEnt, CHAN_BODY, "turret/tu_deploy.wav", 0.5, ATTN_NORM, 0, PITCH_NORM);
		// SUB_UseTargets( this, USE_ON, 0 );
	}

	// if( true )
	{
		new Float:vecCurAngles[3]; 
		new Float:vecAngles[3];
		new iOrientation = 0;

		pev(iEnt, TURRET_PEV_CURRENT_ANGLES, vecCurAngles);
		pev(iEnt, TURRET_PEV_ORIENTATION,	 iOrientation);
		pev(iEnt, pev_angles, vecAngles);
		// pev->maxs.z = m_iDeployHeight;
		// pev->mins.z = -m_iDeployHeight;
		// UTIL_SetSize( pev, pev->mins, pev->maxs );

		vecCurAngles[0] = 0.0;

		if( iOrientation == 1 )
			vecCurAngles[1] = UTIL_AngleMod( vecAngles[1] + 180.0 );
		else
			vecCurAngles[1] = UTIL_AngleMod( vecAngles[1] );

		Turret_SetTurretAnim(iEnt, TURRET_ANIM_SPIN);
		set_pev(iEnt, pev_framerate, 0.0);
		set_pev(iEnt, TURRET_PEV_CURRENT_ANGLES, vecCurAngles);
		set_pev(iEnt, MINES_STEP, SEARCH);
	}

	// m_flLastSight = gpGlobals->time + m_flMaxWait;
}

stock Turret_SetTurretAnim(iEnt, anim)
{
	new sequence = pev(iEnt, pev_sequence);
	if(sequence != anim)
	{
		switch(anim)
		{
			case TURRET_ANIM_FIRE, TURRET_ANIM_SPIN:
				if( sequence != TURRET_ANIM_FIRE && sequence != TURRET_ANIM_SPIN )
					set_pev(iEnt, pev_frame, 0);
			default:
				set_pev(iEnt, pev_frame, 0);
		}

		set_pev(iEnt, pev_sequence, anim);
		set_pev(iEnt, pev_animtime, get_gametime());
		set_pev(iEnt, pev_framerate, 1.0);

		switch(anim)
		{
			case TURRET_ANIM_RETIRE:
			{
				set_pev(iEnt, pev_frame, 255);
				set_pev(iEnt, pev_framerate, -1.0);
			}
			case TURRET_ANIM_DIE:
				set_pev(iEnt, pev_framerate, 1.0);
		}
	}
}

stock Turret_MoveTurret(iEnt, Float:vecTarget[3])
{
	new state = 0;
	// any x movement?

	new Float:vecCurAngles[3]; 
	new Float:vecAngles[3];
	new Float:fTurnRate;
	new iOrientation = 0;

	pev(iEnt, TURRET_PEV_CURRENT_ANGLES, vecCurAngles);
	pev(iEnt, TURRET_TURN_RATES,	 fTurnRate);
	pev(iEnt, TURRET_ORIENTATION,	 iOrientation);

	if( vecCurAngles[0] != vecTarget[0] )
	{
		new Float:flDir = vecTarget[0] > vecCurAngles[0] ? 1 : -1 ;

		vecCurAngles[0] += 0.1 * fTurnRate * flDir;

		// if we started below the goal, and now we're past, peg to goal
		if( flDir == 1 )
		{
			if( vecCurAngles[0] > vecTarget[0] )
				vecCurAngles[0] = vecTarget[0];
		} 
		else
		{
			if( vecCurAngles[0] < vecTarget[0] )
				vecCurAngles[0] = vecTarget[0];
		}

		if( iOrientation == 0 )
			set_controller(iEnt, 1, vecCurAngles[0]);
		else
			set_controller(iEnt, 1, vecCurAngles[0]);

		state = 1;
	}

	if( vecCurAngles[1] != vecTarget[1] )
	{
		new Float:flDir		= vecTarget[1] > vecCurAngles[1] ? 1 : -1 ;
		new Float:flDist	= fabs(vecTarget[1] - vecCurAngles[1]);

		if( flDist > 180.0 )
		{
			flDist	= 360.0 - flDist;
			flDir	= -flDir;
		}

		if( flDist > 30.0 )
		{
			if( fTurnRate < TURRET_TURNRATE * 10.0 )
			{
				fTurnRate += TURRET_TURNRATE;
			}
		}
		else if( fTurnRate > 45.0 )
			fTurnRate -= TURRET_TURNRATE;
		else
			fTurnRate += TURRET_TURNRATE;

		vecCurAngles[1] += 0.1 * fTurnRate * flDir;

		if( vecCurAngles[1] < 0 )
			vecCurAngles[1] += 360.0;
		else if( vecCurAngles[1] >= 360.0 )
			vecCurAngles[1] -= 360.0;

		if( flDist < ( 0.05 * TURRET_TURNRATE ) )
			vecCurAngles[1] = vecTarget[1];

		//ALERT( at_console, "%.2f -> %.2f\n", m_vecCurAngles.y, y );
		pev(iEnt, pev_angles, vecAngles);
		if( iOrientation == 0 )
			set_controller(iEnt, 0, vecCurAngles[1] - vecAngles[1])
		else 
			set_controller(iEnt, 0, vecAngles[1] - 180.0 - vecCurAngles[1]);

		state = 1;
	}

	if( !state )
		fTurnRate = TURRET_TURNRATE;

	set_pev(iEnt, TURRET_PEV_CURRENT_ANGLES, vecCurAngles);
	set_pev(iEnt, TURRET_TURN_RATES, fTurnRate);

	return state;
}

stock Float:UTIL_AngleMod( Float:a )
{
	a = floatmod( a, 360.0 );
	if( a < 0 )
		a += 360;
	return a;
}

stock Float:floatmod( Float:a, Float:n, mode = 0 )
{
    new Float:result = a - n * floatround( a / n )
    if ( mode )
        if ( a < 0 ) result = -floatabs( result )
        else result = floatabs( result )
    else
        if ( n < 0 ) result = -floatabs( result )
        else result = floatabs( result ) 

    return result
} 

//
// This search function will sit with the turret deployed and look for a new target. 
// After a set amount of time, the barrel will spin down. After m_flMaxWait, the turret will
// retact.
//
stock Turret_SearchThink(iEnt)
{
	// ensure rethink
	SetTurretAnim(TURRET_ANIM_SPIN);
	StudioFrameAdvance();
	set_pev(iEnt, pev_nextthink, get_gametime() + 0.1);

	if( m_flSpinUpTime == 0 && m_flMaxSpin )
		m_flSpinUpTime = gpGlobals->time + m_flMaxSpin;

	Ping();

	// If we have a target and we're still healthy
	if( m_hEnemy != 0 )
	{
		if( !m_hEnemy->IsAlive() )
			m_hEnemy = NULL;// Dead enemy forces a search for new one
	}

	// Acquire Target
	if( m_hEnemy == 0 )
	{
		Look( TURRET_RANGE );
		m_hEnemy = BestVisibleEnemy();
	}

	// If we've found a target, spin up the barrel and start to attack
	if( m_hEnemy != 0 )
	{
		m_flLastSight = 0;
		m_flSpinUpTime = 0;
		SetThink( &CBaseTurret::ActiveThink );
	}
	else
	{
		// Are we out of time, do we need to retract?
 		if( gpGlobals->time > m_flLastSight )
		{
			//Before we retrace, make sure that we are spun down.
			m_flLastSight = 0;
			m_flSpinUpTime = 0;
			SetThink( &CBaseTurret::Retire );
		}
		// should we stop the spin?
		else if( ( m_flSpinUpTime ) && ( gpGlobals->time > m_flSpinUpTime ) )
		{
			SpinDownCall();
		}
		
		// generic hunt for new victims
		m_vecGoalAngles.y = ( m_vecGoalAngles.y + 0.1f * m_fTurnRate );
		if( m_vecGoalAngles.y >= 360 )
			m_vecGoalAngles.y -= 360;
		MoveTurret();
	}
}

stock Turret_Ping(iEnt)
{
	// make the pinging noise every second while searching
	if (m_flPingTime == 0)
		m_flPingTime = gpGlobals->time + 1;
	else if (m_flPingTime <= gpGlobals->time)
	{
		m_flPingTime = gpGlobals->time + 1;
		EMIT_SOUND(ENT(pev), CHAN_ITEM, "turret/tu_ping.wav", 1, ATTN_NORM);
		EyeOn( );
	}
	else if (m_eyeBrightness > 0)
	{
		EyeOff( );
	}
}

void CBaseTurret::Retire(void)
{
	// make the turret level
	m_vecGoalAngles.x = 0;
	m_vecGoalAngles.y = m_flStartYaw;

	pev->nextthink = gpGlobals->time + 0.1;

	StudioFrameAdvance( );

	EyeOff( );

	if (!MoveTurret())
	{
		if (m_iSpin)
		{
			SpinDownCall();
		}
		else if (pev->sequence != TURRET_ANIM_RETIRE)
		{
			SetTurretAnim(TURRET_ANIM_RETIRE);
			EMIT_SOUND_DYN(ENT(pev), CHAN_BODY, "turret/tu_deploy.wav", TURRET_MACHINE_VOLUME, ATTN_NORM, 0, 120);
			SUB_UseTargets( this, USE_OFF, 0 );
		}
		else if (m_fSequenceFinished) 
		{	
			m_iOn = 0;
			m_flLastSight = 0;
			SetTurretAnim(TURRET_ANIM_NONE);
			pev->maxs.z = m_iRetractHeight;
			pev->mins.z = -m_iRetractHeight;
			UTIL_SetSize(pev, pev->mins, pev->maxs);
			if (m_iAutoStart)
			{
				SetThink(&CBaseTurret::AutoSearchThink);		
				pev->nextthink = gpGlobals->time + .1;
			}
			else
				SetThink(&CBaseTurret::SUB_DoNothing);
		}
	}
	else
	{
		SetTurretAnim(TURRET_ANIM_SPIN);
	}
}


void CTurret::SpinUpCall(void)
{
	StudioFrameAdvance( );
	pev->nextthink = gpGlobals->time + 0.1;

	// Are we already spun up? If not start the two stage process.
	if (!m_iSpin)
	{
		SetTurretAnim( TURRET_ANIM_SPIN );
		// for the first pass, spin up the the barrel
		if (!m_iStartSpin)
		{
			pev->nextthink = gpGlobals->time + 1.0; // spinup delay
			EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_spinup.wav", TURRET_MACHINE_VOLUME, ATTN_NORM);
			m_iStartSpin = 1;
			pev->framerate = 0.1;
		}
		// after the barrel is spun up, turn on the hum
		else if (pev->framerate >= 1.0)
		{
			pev->nextthink = gpGlobals->time + 0.1; // retarget delay
			EMIT_SOUND(ENT(pev), CHAN_STATIC, "turret/tu_active2.wav", TURRET_MACHINE_VOLUME, ATTN_NORM);
			SetThink(&CTurret::ActiveThink);
			m_iStartSpin = 0;
			m_iSpin = 1;
		} 
		else
		{
			pev->framerate += 0.075;
		}
	}

	if (m_iSpin)
	{
		SetThink(&CTurret::ActiveThink);
	}
}


void CTurret::SpinDownCall(void)
{
	if (m_iSpin)
	{
		SetTurretAnim( TURRET_ANIM_SPIN );
		if (pev->framerate == 1.0)
		{
			EMIT_SOUND_DYN(ENT(pev), CHAN_STATIC, "turret/tu_active2.wav", 0, 0, SND_STOP, 100);
			EMIT_SOUND(ENT(pev), CHAN_ITEM, "turret/tu_spindown.wav", TURRET_MACHINE_VOLUME, ATTN_NORM);
		}
		pev->framerate -= 0.02;
		if (pev->framerate <= 0)
		{
			pev->framerate = 0;
			m_iSpin = 0;
		}
	}
}


void CBaseTurret::SetTurretAnim(TURRET_ANIM anim)
{
	if (pev->sequence != anim)
	{
		switch(anim)
		{
		case TURRET_ANIM_FIRE:
		case TURRET_ANIM_SPIN:
			if (pev->sequence != TURRET_ANIM_FIRE && pev->sequence != TURRET_ANIM_SPIN)
			{
				pev->frame = 0;
			}
			break;
		default:
			pev->frame = 0;
			break;
		}

		pev->sequence = anim;
		ResetSequenceInfo( );

		switch(anim)
		{
		case TURRET_ANIM_RETIRE:
			pev->frame			= 255;
			pev->framerate		= -1.0;
			break;
		case TURRET_ANIM_DIE:
			pev->framerate		= 1.0;
			break;
		default:
			break;
		}
		//ALERT(at_console, "Turret anim #%d\n", anim);
	}
}


//
// This search function will sit with the turret deployed and look for a new target. 
// After a set amount of time, the barrel will spin down. After m_flMaxWait, the turret will
// retact.
//
void CBaseTurret::SearchThink(void)
{
	// ensure rethink
	SetTurretAnim(TURRET_ANIM_SPIN);
	StudioFrameAdvance( );
	pev->nextthink = gpGlobals->time + 0.1;

	if (m_flSpinUpTime == 0 && m_flMaxSpin)
		m_flSpinUpTime = gpGlobals->time + m_flMaxSpin;

	Ping( );

	// If we have a target and we're still healthy
	if (m_hEnemy != 0)
	{
		if (!m_hEnemy->IsAlive() )
			m_hEnemy = NULL;// Dead enemy forces a search for new one
	}


	// Acquire Target
	if (m_hEnemy == 0)
	{
		Look(TURRET_RANGE);
		m_hEnemy = BestVisibleEnemy();
	}

	// If we've found a target, spin up the barrel and start to attack
	if (m_hEnemy != 0)
	{
		m_flLastSight = 0;
		m_flSpinUpTime = 0;
		SetThink(&CBaseTurret::ActiveThink);
	}
	else
	{
		// Are we out of time, do we need to retract?
 		if (gpGlobals->time > m_flLastSight)
		{
			//Before we retrace, make sure that we are spun down.
			m_flLastSight = 0;
			m_flSpinUpTime = 0;
			SetThink(&CBaseTurret::Retire);
		}
		// should we stop the spin?
		else if ((m_flSpinUpTime) && (gpGlobals->time > m_flSpinUpTime))
		{
			SpinDownCall();
		}
		
		// generic hunt for new victims
		m_vecGoalAngles.y = (m_vecGoalAngles.y + 0.1 * m_fTurnRate);
		if (m_vecGoalAngles.y >= 360)
			m_vecGoalAngles.y -= 360;
		MoveTurret();
	}
}


// 
// This think function will deploy the turret when something comes into range. This is for
// automatically activated turrets.
//
void CBaseTurret::AutoSearchThink(void)
{
	// ensure rethink
	StudioFrameAdvance( );
	pev->nextthink = gpGlobals->time + 0.3;

	// If we have a target and we're still healthy

	if (m_hEnemy != 0)
	{
		if (!m_hEnemy->IsAlive() )
			m_hEnemy = NULL;// Dead enemy forces a search for new one
	}

	// Acquire Target

	if (m_hEnemy == 0)
	{
		Look( TURRET_RANGE );
		m_hEnemy = BestVisibleEnemy();
	}

	if (m_hEnemy != 0)
	{
		SetThink(&CBaseTurret::Deploy);
		EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_alert.wav", TURRET_MACHINE_VOLUME, ATTN_NORM);
	}
}


void CBaseTurret ::	TurretDeath( void )
{
	StudioFrameAdvance( );
	pev->nextthink = gpGlobals->time + 0.1;

	if (pev->deadflag != DEAD_DEAD)
	{
		pev->deadflag = DEAD_DEAD;

		float flRndSound = RANDOM_FLOAT ( 0 , 1 );

		if ( flRndSound <= 0.33 )
			EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_die.wav", 1.0, ATTN_NORM);
		else if ( flRndSound <= 0.66 )
			EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_die2.wav", 1.0, ATTN_NORM);
		else 
			EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_die3.wav", 1.0, ATTN_NORM);

		EMIT_SOUND_DYN(ENT(pev), CHAN_STATIC, "turret/tu_active2.wav", 0, 0, SND_STOP, 100);

		if (m_iOrientation == 0)
			m_vecGoalAngles.x = -15;
		else
			m_vecGoalAngles.x = -90;

		SetTurretAnim(TURRET_ANIM_DIE); 

		EyeOn( );	
	}

	EyeOff( );

	if (pev->dmgtime + RANDOM_FLOAT( 0, 2 ) > gpGlobals->time)
	{
		// lots of smoke
		MESSAGE_BEGIN( MSG_BROADCAST, SVC_TEMPENTITY );
			WRITE_BYTE( TE_SMOKE );
			WRITE_COORD( RANDOM_FLOAT( pev->absmin.x, pev->absmax.x ) );
			WRITE_COORD( RANDOM_FLOAT( pev->absmin.y, pev->absmax.y ) );
			WRITE_COORD( pev->origin.z - m_iOrientation * 64 );
			WRITE_SHORT( g_sModelIndexSmoke );
			WRITE_BYTE( 25 ); // scale * 10
			WRITE_BYTE( 10 - m_iOrientation * 5); // framerate
		MESSAGE_END();
	}
	
	if (pev->dmgtime + RANDOM_FLOAT( 0, 5 ) > gpGlobals->time)
	{
		Vector vecSrc = Vector( RANDOM_FLOAT( pev->absmin.x, pev->absmax.x ), RANDOM_FLOAT( pev->absmin.y, pev->absmax.y ), 0 );
		if (m_iOrientation == 0)
			vecSrc = vecSrc + Vector( 0, 0, RANDOM_FLOAT( pev->origin.z, pev->absmax.z ) );
		else
			vecSrc = vecSrc + Vector( 0, 0, RANDOM_FLOAT( pev->absmin.z, pev->origin.z ) );

		UTIL_Sparks( vecSrc );
	}

	if (m_fSequenceFinished && !MoveTurret( ) && pev->dmgtime + 5 < gpGlobals->time)
	{
		pev->framerate = 0;
		SetThink( NULL );
	}
}



void CBaseTurret :: TraceAttack( entvars_t *pevAttacker, float flDamage, Vector vecDir, TraceResult *ptr, int bitsDamageType)
{
	if ( ptr->iHitgroup == 10 )
	{
		// hit armor
		if ( pev->dmgtime != gpGlobals->time || (RANDOM_LONG(0,10) < 1) )
		{
			UTIL_Ricochet( ptr->vecEndPos, RANDOM_FLOAT( 1, 2) );
			pev->dmgtime = gpGlobals->time;
		}

		flDamage = 0.1;// don't hurt the monster much, but allow bits_COND_LIGHT_DAMAGE to be generated
	}

	if ( !pev->takedamage )
		return;

	AddMultiDamage( pevAttacker, this, flDamage, bitsDamageType );
}

// take damage. bitsDamageType indicates type of damage sustained, ie: DMG_BULLET

int CBaseTurret::TakeDamage(entvars_t *pevInflictor, entvars_t *pevAttacker, float flDamage, int bitsDamageType)
{
	if ( !pev->takedamage )
		return 0;

	if (!m_iOn)
		flDamage /= 10.0;

	pev->health -= flDamage;
	if (pev->health <= 0)
	{
		pev->health = 0;
		pev->takedamage = DAMAGE_NO;
		pev->dmgtime = gpGlobals->time;

		ClearBits (pev->flags, FL_MONSTER); // why are they set in the first place???

		SetUse(NULL);
		SetThink(&CBaseTurret::TurretDeath);
		SUB_UseTargets( this, USE_ON, 0 ); // wake up others
		pev->nextthink = gpGlobals->time + 0.1;

		return 0;
	}

	if (pev->health <= 10)
	{
		if (m_iOn && (1 || RANDOM_LONG(0, 0x7FFF) > 800))
		{
			m_fBeserk = 1;
			SetThink(&CBaseTurret::SearchThink);
		}
	}

	return 1;
}

void CSentry::Shoot(Vector &vecSrc, Vector &vecDirToEnemy)
{
	FireBullets( 1, vecSrc, vecDirToEnemy, TURRET_SPREAD, TURRET_RANGE, BULLET_MONSTER_MP5, 1 );
	
	switch(RANDOM_LONG(0,2))
	{
	case 0: EMIT_SOUND(ENT(pev), CHAN_WEAPON, "weapons/hks1.wav", 1, ATTN_NORM); break;
	case 1: EMIT_SOUND(ENT(pev), CHAN_WEAPON, "weapons/hks2.wav", 1, ATTN_NORM); break;
	case 2: EMIT_SOUND(ENT(pev), CHAN_WEAPON, "weapons/hks3.wav", 1, ATTN_NORM); break;
	}
	pev->effects = pev->effects | EF_MUZZLEFLASH;
}

int CSentry::TakeDamage(entvars_t *pevInflictor, entvars_t *pevAttacker, float flDamage, int bitsDamageType)
{
	if ( !pev->takedamage )
		return 0;

	if (!m_iOn)
	{
		SetThink( &CSentry::Deploy );
		SetUse( NULL );
		pev->nextthink = gpGlobals->time + 0.1;
	}

	pev->health -= flDamage;
	if (pev->health <= 0)
	{
		pev->health = 0;
		pev->takedamage = DAMAGE_NO;
		pev->dmgtime = gpGlobals->time;

		ClearBits (pev->flags, FL_MONSTER); // why are they set in the first place???

		SetUse(NULL);
		SetThink( &CSentry::SentryDeath);
		SUB_UseTargets( this, USE_ON, 0 ); // wake up others
		pev->nextthink = gpGlobals->time + 0.1;

		return 0;
	}

	return 1;
}


void CSentry::SentryTouch( CBaseEntity *pOther )
{
	if ( pOther && (pOther->IsPlayer() || (pOther->pev->flags & FL_MONSTER)) )
	{
		TakeDamage(pOther->pev, pOther->pev, 0, 0 );
	}
}


void CSentry ::	SentryDeath( void )
{
	StudioFrameAdvance( );
	pev->nextthink = gpGlobals->time + 0.1;

	if (pev->deadflag != DEAD_DEAD)
	{
		pev->deadflag = DEAD_DEAD;

		float flRndSound = RANDOM_FLOAT ( 0 , 1 );

		if ( flRndSound <= 0.33 )
			EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_die.wav", 1.0, ATTN_NORM);
		else if ( flRndSound <= 0.66 )
			EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_die2.wav", 1.0, ATTN_NORM);
		else 
			EMIT_SOUND(ENT(pev), CHAN_BODY, "turret/tu_die3.wav", 1.0, ATTN_NORM);

		EMIT_SOUND_DYN(ENT(pev), CHAN_STATIC, "turret/tu_active2.wav", 0, 0, SND_STOP, 100);

		SetBoneController( 0, 0 );
		SetBoneController( 1, 0 );

		SetTurretAnim(TURRET_ANIM_DIE); 

		pev->solid = SOLID_NOT;
		pev->angles.y = UTIL_AngleMod( pev->angles.y + RANDOM_LONG( 0, 2 ) * 120 );

		EyeOn( );
	}

	EyeOff( );

	Vector vecSrc, vecAng;
	GetAttachment( 1, vecSrc, vecAng );

	if (pev->dmgtime + RANDOM_FLOAT( 0, 2 ) > gpGlobals->time)
	{
		// lots of smoke
		MESSAGE_BEGIN( MSG_BROADCAST, SVC_TEMPENTITY );
			WRITE_BYTE( TE_SMOKE );
			WRITE_COORD( vecSrc.x + RANDOM_FLOAT( -16, 16 ) );
			WRITE_COORD( vecSrc.y + RANDOM_FLOAT( -16, 16 ) );
			WRITE_COORD( vecSrc.z - 32 );
			WRITE_SHORT( g_sModelIndexSmoke );
			WRITE_BYTE( 15 ); // scale * 10
			WRITE_BYTE( 8 ); // framerate
		MESSAGE_END();
	}
	
	if (pev->dmgtime + RANDOM_FLOAT( 0, 8 ) > gpGlobals->time)
	{
		UTIL_Sparks( vecSrc );
	}

	if (m_fSequenceFinished && pev->dmgtime + 5 < gpGlobals->time)
	{
		pev->framerate = 0;
		SetThink( NULL );
	}
}
stock Turret_ActiveThink(iEnt)
{
	int fAttack = 0;
	Vector vecDirToEnemy;

	pev->nextthink = gpGlobals->time + 0.1f;
	StudioFrameAdvance();

	if( ( !m_iOn ) || ( m_hEnemy == 0 ) )
	{
		m_hEnemy = NULL;
		m_flLastSight = gpGlobals->time + m_flMaxWait;
		SetThink( &CBaseTurret::SearchThink );
		return;
	}

	// if it's dead, look for something new
	if( !m_hEnemy->IsAlive() )
	{
		if( !m_flLastSight )
		{
			m_flLastSight = gpGlobals->time + 0.5f; // continue-shooting timeout
		}
		else
		{
			if( gpGlobals->time > m_flLastSight )
			{
				m_hEnemy = NULL;
				m_flLastSight = gpGlobals->time + m_flMaxWait;
				SetThink( &CBaseTurret::SearchThink );
				return;
			}
		}
	}

	Vector vecMid = pev->origin + pev->view_ofs;
	Vector vecMidEnemy = m_hEnemy->BodyTarget( vecMid );

	// Look for our current enemy
	int fEnemyVisible = FBoxVisible( pev, m_hEnemy->pev, vecMidEnemy );	

	vecDirToEnemy = vecMidEnemy - vecMid;	// calculate dir and dist to enemy
	float flDistToEnemy = vecDirToEnemy.Length();

	Vector vec = UTIL_VecToAngles( vecMidEnemy - vecMid );

	// Current enmey is not visible.
	if( !fEnemyVisible || ( flDistToEnemy > TURRET_RANGE ) )
	{
		if( !m_flLastSight )
			m_flLastSight = gpGlobals->time + 0.5f;
		else
		{
			// Should we look for a new target?
			if( gpGlobals->time > m_flLastSight )
			{
				m_hEnemy = NULL;
				m_flLastSight = gpGlobals->time + m_flMaxWait;
				SetThink( &CBaseTurret::SearchThink );
				return;
			}
		}
		fEnemyVisible = 0;
	}
	else
	{
		m_vecLastSight = vecMidEnemy;
	}

	UTIL_MakeAimVectors( m_vecCurAngles );

	/*
	ALERT( at_console, "%.0f %.0f : %.2f %.2f %.2f\n", 
		m_vecCurAngles.x, m_vecCurAngles.y,
		gpGlobals->v_forward.x, gpGlobals->v_forward.y, gpGlobals->v_forward.z );
	*/
	
	Vector vecLOS = vecDirToEnemy; //vecMid - m_vecLastSight;
	vecLOS = vecLOS.Normalize();

	// Is the Gun looking at the target
	if( DotProduct( vecLOS, gpGlobals->v_forward ) <= 0.866f ) // 30 degree slop
		fAttack = FALSE;
	else
		fAttack = TRUE;

	// fire the gun
	if( m_iSpin && ( ( fAttack ) || ( m_fBeserk ) ) )
	{
		Vector vecSrc, vecAng;
		GetAttachment( 0, vecSrc, vecAng );
		SetTurretAnim( TURRET_ANIM_FIRE );
		Shoot( vecSrc, gpGlobals->v_forward );
	} 
	else
	{
		SetTurretAnim( TURRET_ANIM_SPIN );
	}

	//move the gun
	if( m_fBeserk )
	{
		if( RANDOM_LONG( 0, 9 ) == 0 )
		{
			m_vecGoalAngles.y = RANDOM_FLOAT( 0, 360 );
			m_vecGoalAngles.x = RANDOM_FLOAT( 0, 90 ) - 90 * m_iOrientation;
			TakeDamage( pev, pev, 1, DMG_GENERIC ); // don't beserk forever
			return;
		}
	} 
	else if( fEnemyVisible )
	{
		if( vec.y > 360 )
			vec.y -= 360;

		if( vec.y < 0 )
			vec.y += 360;

		//ALERT( at_console, "[%.2f]", vec.x );

		if( vec.x < -180 )
			vec.x += 360;

		if( vec.x > 180 )
			vec.x -= 360;

		// now all numbers should be in [1...360]
		// pin to turret limitations to [-90...15]

		if( m_iOrientation == 0 )
		{
			if( vec.x > 90 )
				vec.x = 90;
			else if( vec.x < m_iMinPitch )
				vec.x = m_iMinPitch;
		}
		else
		{
			if( vec.x < -90 )
				vec.x = -90;
			else if( vec.x > -m_iMinPitch )
				vec.x = -m_iMinPitch;
		}

		// ALERT( at_console, "->[%.2f]\n", vec.x );

		m_vecGoalAngles.y = vec.y;
		m_vecGoalAngles.x = vec.x;
	}

	SpinUpCall();
	MoveTurret();
}