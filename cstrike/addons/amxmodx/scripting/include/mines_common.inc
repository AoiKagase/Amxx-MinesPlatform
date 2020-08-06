// =====================================
//	Mines Platform Common Functions
//
// 	by Aoi.Kagase
//
// =====================================

#if defined _mines_common_included
	#endinput
#endif
#define _mines_common_included
#include <mines_const>
#include <xs>

// Spark Effect.
stock mines_spark_wall				(Float:vEndOrigin[])
{
 	// Sparks
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vEndOrigin, 0);
	write_byte(TE_SPARKS); // TE id
	engfunc(EngFunc_WriteCoord, vEndOrigin[0]); // x
	engfunc(EngFunc_WriteCoord, vEndOrigin[1]); // y
	engfunc(EngFunc_WriteCoord, vEndOrigin[2]); // z
	message_end();
      
	// Effects when cut
	engfunc(EngFunc_MessageBegin, MSG_BROADCAST, SVC_TEMPENTITY, {0, 0, 0}, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord, vEndOrigin[0]);
	engfunc(EngFunc_WriteCoord, vEndOrigin[1]);
	engfunc(EngFunc_WriteCoord, vEndOrigin[2] - 10.0);
	write_short(TE_SPARKS);	// sprite index
	write_byte(1);	// scale in 0.1's
	write_byte(30);	// framerate
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND);	// flags
	message_end();
}

// Spark Effect.
stock mines_spark(Float:vEndOrigin[])
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_SPARKS);
	engfunc(EngFunc_WriteCoord, vEndOrigin[0]);
	engfunc(EngFunc_WriteCoord, vEndOrigin[1]);
	engfunc(EngFunc_WriteCoord, vEndOrigin[2]);
	message_end();
}

// Bit to Color.
// r = 0, g = 1, b = 2
stock get_color(src, rgb)
{
    src >>= ((rgb * 0x08));
    return (src & 0xFF);
}

// RGB to Bit.
stock set_color(r, g, b)
{
    new color = r;
    color |= (g << 8);
    color |= (b << 16);
    return color;
}

// Cvar to TeamCode.
stock CsTeams:get_team_code(const arg[])
{
    new CsTeams:team;
	// Terrorist
#if defined BIOHAZARD_SUPPORT
	if(equali(arg, "Z")  || equali(arg, "Zombie"))
#else
	if(equali(arg, "TR") || equali(arg, "T"))
#endif
		team = CS_TEAM_T;
	else
	// Counter-Terrorist
#if defined BIOHAZARD_SUPPORT
	if(equali(arg, "H") || equali(arg, "Human"))
#else
	if(equali(arg, "CT"))
#endif
		team = CS_TEAM_CT;
	else
	// All team.
#if defined BIOHAZARD_SUPPORT
	if(equali(arg, "ZH") || equali(arg, "HZ") || equali(arg, "ALL"))
#else
	if(equali(arg, "ALL"))
#endif
		team = CS_TEAM_UNASSIGNED;
	else
		team = CS_TEAM_UNASSIGNED;

    return team;
}

// Cvar to Color Bit.
stock get_cvar_to_color(const args[])
{
	new values[3];
	get_cvar_to_array(args, values, 3);
	return set_color(values[0], values[1], values[2]);
}

stock get_cvar_to_array(const args[], values[], size)
{
	new i = 0, n = 0, iPos = 0;
	new sSplit		[20];
	new sSplitLen = charsmax(sSplit);
	new argsb[255];

	formatex(argsb, charsmax(argsb), "%s%s", args, ",");
	while((i = split_string(argsb[iPos += i], ",", sSplit, sSplitLen)) != -1 && n < size)
	{
		values[n++] = str_to_num(sSplit);
	}
}

// Glowing.
stock mines_glow(iEnt, const minesData[COMMON_MINES_DATA])
{
	// Glow mode.
	if (minesData[GLOW_ENABLE])
	{
		new Float:tcolor[3];
		// Color setting.
		if (!minesData[GLOW_MODE])
		{
			// Team color.
			switch (mines_get_owner_team(iEnt))
			{
				case CS_TEAM_T:
					for(new i = 0; i < 3; i++) tcolor[i] = float(get_color(minesData[GLOW_COLOR_TR], i));
				case CS_TEAM_CT:
					for(new i = 0; i < 3; i++) tcolor[i] = float(get_color(minesData[GLOW_COLOR_CT], i));
				default:
				{
					tcolor[0] = 0.0;
					tcolor[1] = 255.0;
					tcolor[2] = 0.0;
				}
			} 
		}
		else
		{
			tcolor[0] = 0.0;
			tcolor[1] = 255.0;
			tcolor[2] = 0.0;
		}

		set_pev(iEnt, pev_renderfx, 	kRenderFxGlowShell);
		set_pev(iEnt, pev_rendercolor,	tcolor);
		set_pev(iEnt, pev_rendermode, 	kRenderNormal);
		set_pev(iEnt, pev_renderamt, 	float(5));
	}
}

stock get_cvar_to_vector(const args[13], Float:vector[3])
{
	new values[3];
	get_cvar_to_array(args, values, 3);
	xs_vec_set(vector, float(values[0]), float(values[1]), float(values[2]));
}

//====================================================
// Get Owner Team.
//====================================================
stock CsTeams:mines_get_owner_team(iEnt)
{
	return cs_get_user_team(pev(iEnt, MINES_OWNER));
}