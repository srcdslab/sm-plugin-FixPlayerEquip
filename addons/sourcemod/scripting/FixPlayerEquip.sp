#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

// void CCSPlayer::StockPlayerAmmo( CBaseCombatWeapon *pNewWeapon )
Handle g_hCCSPlayer_StockPlayerAmmo;

public Plugin myinfo =
{
	name = "FixPlayerEquip",
	author = "BotoX",
	description = "Fix lag caused by game_player_equip entity.",
	version = "1.0"
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("FixPlayerEquip.games");
	if(hGameConf == INVALID_HANDLE)
	{
		SetFailState("Couldn't load FixPlayerEquip.games game config!");
		return;
	}

	// void CCSPlayer::StockPlayerAmmo( CBaseCombatWeapon *pNewWeapon )
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CCSPlayer_StockPlayerAmmo"))
	{
		CloseHandle(hGameConf);
		SetFailState("PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, \"CCSPlayer_StockPlayerAmmo\" failed!");
		return;
	}
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hCCSPlayer_StockPlayerAmmo = EndPrepSDKCall();

	CloseHandle(hGameConf);

	/* Late Load */
	int entity = INVALID_ENT_REFERENCE;
	while((entity = FindEntityByClassname(entity, "game_player_equip")) != INVALID_ENT_REFERENCE)
	{
		OnEntityCreated(entity, "game_player_equip");
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "game_player_equip"))
	{
		SDKHook(entity, SDKHook_Use, OnUse);
	}
}

public Action OnUse(int entity, int client)
{
	static int s_MaxEquip = -1;
	if(s_MaxEquip == -1)
		s_MaxEquip = GetEntPropArraySize(entity, Prop_Data, "m_weaponNames");

	if(client > MaxClients || client <= 0)
		return Plugin_Continue;

	bool bGaveAmmo = false;

	for(int i = 0; i < s_MaxEquip; i++)
	{
		char sWeapon[32];
		GetEntPropString(entity, Prop_Data, "m_weaponNames", sWeapon, sizeof(sWeapon), i);

		if(!sWeapon[0])
			break;

		if(strncmp(sWeapon, "ammo_", 5, false) == 0)
		{
			if(!bGaveAmmo)
			{
				int iWeapon = INVALID_ENT_REFERENCE;
				if((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY)) != INVALID_ENT_REFERENCE)
					StockPlayerAmmo(client, iWeapon);

				if((iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY)) != INVALID_ENT_REFERENCE)
					StockPlayerAmmo(client, iWeapon);

				bGaveAmmo = true;
			}
		}
		else if(StrEqual(sWeapon, "item_kevlar", false))
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
		}
		else if(StrEqual(sWeapon, "item_assaultsuit", false))
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1, 1);
		}
		else
		{
			GivePlayerItem(client, sWeapon);
		}
	}

	return Plugin_Handled;
}

int StockPlayerAmmo(int client, int iWeapon)
{
	return SDKCall(g_hCCSPlayer_StockPlayerAmmo, client, iWeapon);
}
