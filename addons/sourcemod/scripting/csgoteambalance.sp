#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
  name = "CS:GO Teambalance",
  author = "Brian Cosgrove",
  description = "Balance teams based on player performance.",
  version = "0.1",
  url = "https://github.com/cosgroveb/sm_csgoteambalance/"
};

new Handle:statsDatabase = INVALID_HANDLE

ConnectDatabase()
{
  new Handle:connectKv = INVALID_HANDLE
  connectKv = CreateKeyValues("")

  KvSetString(connectKv, "driver", "sqlite")
  KvSetString(connectKv, "database", "csgoteambalance")

  new String:error[255]

  statsDatabase = SQL_ConnectCustom(connectKv, error, sizeof(error), true)

  if (statsDatabase == INVALID_HANDLE)
  {
    PrintToServer("CSGOTEAMBALANCE: could not connect: %s", error)
  }
}

public OnPluginStart()
{
  ConnectDatabase()
  CreateDatabaseIfNotExists()
}

public OnMapStart()
{
  HookEvent("player_death", Event_LogKillStats, EventHookMode_Post)
}

public QueryCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
  new String:message[512]

  if (hndl == INVALID_HANDLE)
  {
    PrintToServer("Got INVALID_HANDLE!")
  }
  else
  {
    Format(message, sizeof(message), "Executed query returned. Errors? %s", error)
    PrintToServer(message)
  }
}

CreateDatabaseIfNotExists()
{
  SQL_TQuery(statsDatabase, QueryCallback, "CREATE TABLE kills (attacker_name TEXT, attacker_team INTEGER, assister_name TEXT, assister_team INTEGER, victim_name TEXT, victim_team, weapon TEXT, headshot INTEGER)")
}

public Action:Event_LogKillStats(Handle:event, const String:name[], bool:dontBroadcast)
{
  new attackerUserId = GetEventInt(event, "attacker")
  new assisterUserId = GetEventInt(event, "assister")
  new victimUserId   = GetEventInt(event, "userid")

  if (attackerUserId == 0 || victimUserId == 0)
  {
    /* victim or attacker is a bot or world */
    return
  }
  new String:attackerName[MAX_NAME_LENGTH]
  GetClientName(GetClientOfUserId(attackerUserId), attackerName, sizeof(attackerName))
  new attackerTeam = GetClientTeam(GetClientOfUserId(attackerUserId))

  new String:assisterName[MAX_NAME_LENGTH]
  new assisterTeam = -1
  if ( assisterUserId > 0 )
  {
    GetClientName(GetClientOfUserId(assisterUserId), assisterName, sizeof(assisterName))
    assisterTeam = GetClientTeam(GetClientOfUserId(assisterUserId))
  }
  else
  {
    /* don't credit a bot with an assist */
    assisterName = ""
  }

  new String:victimName[MAX_NAME_LENGTH]
  GetClientName(GetClientOfUserId(victimUserId), victimName, sizeof(victimName))
  new victimTeam = GetClientTeam(GetClientOfUserId(victimUserId))

  new String:weaponName[MAX_NAME_LENGTH]
  GetEventString(event, "weapon", weaponName, sizeof(weaponName))

  new headshot = GetEventBool(event, "headshot")

  new String:query[512]

  Format(query, sizeof(query), "INSERT INTO kills ('attacker_name', 'attacker_team', 'assister_name', 'assister_team', 'victim_name', 'victim_team', 'weapon', 'headshot') VALUES ( '%s', %i, '%s', %i, '%s', %i, '%s', %i)", attackerName, attackerTeam, assisterName, assisterTeam, victimName, victimTeam, weaponName, headshot)
  SQL_TQuery(statsDatabase, QueryCallback, query)
}


