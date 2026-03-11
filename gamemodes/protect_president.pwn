#include <a_samp>

#define TEAM_NONE 0
#define TEAM_PRESIDENT 1
#define TEAM_SECRET 2
#define TEAM_ASSASSIN 3

#define ROUND_TIME 300
#define LOBBY_TIME 15
#define MIN_PLAYERS 3

new PlayerTeam[MAX_PLAYERS];
new PlayerScore[MAX_PLAYERS];
new bool:SpawnProtected[MAX_PLAYERS];

new PresidentID = INVALID_PLAYER_ID;
new bool:RoundActive = false;

new RoundTimer;
new LobbyTimer;

new PresidentVehicle = INVALID_VEHICLE_ID;

new Text:HUDTimer;

new Float:SecretSpawns[][3] =
{
    {1485.0,-1770.0,18.8},
    {1487.0,-1768.0,18.8},
    {1490.0,-1766.0,18.8}
};

new Float:AssassinSpawns[][3] =
{
    {1600.0,-2000.0,13.0},
    {1610.0,-1990.0,13.0},
    {1590.0,-1980.0,13.0}
};

forward StartRound();
forward RoundTimeUp();
forward EndRound(team);
forward LobbyCount();
forward RemoveSpawnProtection(playerid);

public OnGameModeInit()
{
    SetGameModeText("Protect The President");

    AddPlayerClass(0,1958.0,1343.0,15.3,270.0,0,0,0,0,0,0);

    HUDTimer = TextDrawCreate(320.0,20.0," ");
    TextDrawAlignment(HUDTimer,2);
    TextDrawLetterSize(HUDTimer,0.4,1.5);

    print("Protect The President Loaded");

    LobbyTimer = SetTimer("LobbyCount",1000,true);

    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerTeam[playerid] = TEAM_NONE;
    PlayerScore[playerid] = 0;

    SendClientMessage(playerid,-1,"Protect the President");
    SendClientMessage(playerid,-1,"/joinsecret /joinassassin");

    return 1;
}

public OnPlayerSpawn(playerid)
{
    ResetPlayerWeapons(playerid);

    SpawnProtected[playerid] = true;
    SetTimerEx("RemoveSpawnProtection",3000,false,"d",playerid);

    switch(PlayerTeam[playerid])
    {
        case TEAM_PRESIDENT:
        {
            SetPlayerColor(playerid,0xFFFF00FF);
            SetPlayerPos(playerid,1481.0,-1771.0,18.8);

            GivePlayerWeapon(playerid,24,200);
        }

        case TEAM_SECRET:
        {
            new r = random(sizeof SecretSpawns);

            SetPlayerColor(playerid,0x00FFFFFF);
            SetPlayerPos(playerid,
                SecretSpawns[r][0],
                SecretSpawns[r][1],
                SecretSpawns[r][2]);

            GivePlayerWeapon(playerid,31,300);
            GivePlayerWeapon(playerid,25,50);
        }

        case TEAM_ASSASSIN:
        {
            new r = random(sizeof AssassinSpawns);

            SetPlayerColor(playerid,0xFF0000FF);
            SetPlayerPos(playerid,
                AssassinSpawns[r][0],
                AssassinSpawns[r][1],
                AssassinSpawns[r][2]);

            GivePlayerWeapon(playerid,34,30);
            GivePlayerWeapon(playerid,23,120);
        }
    }

    return 1;
}

public RemoveSpawnProtection(playerid)
{
    SpawnProtected[playerid] = false;
    return 1;
}

public OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid)
{
    if(SpawnProtected[playerid]) return 0;
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    if(RoundActive)
    {
        if(playerid == PresidentID)
        {
            SendClientMessageToAll(-1,"President assassinated!");
            EndRound(TEAM_ASSASSIN);
        }

        if(killerid != INVALID_PLAYER_ID)
        {
            PlayerScore[killerid]++;
            GivePlayerMoney(killerid,1000);
        }
    }

    return 1;
}

public LobbyCount()
{
    if(RoundActive) return 1;

    new players = 0;

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerTeam[i] != TEAM_NONE)
        {
            players++;
        }
    }

    if(players >= MIN_PLAYERS)
    {
        SendClientMessageToAll(-1,"Round starting...");
        KillTimer(LobbyTimer);
        SetTimer("StartRound",3000,false);
    }

    return 1;
}

public StartRound()
{
    if(RoundActive) return 1;

    new players[MAX_PLAYERS];
    new count = 0;

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerTeam[i] != TEAM_NONE)
        {
            players[count++] = i;
        }
    }

    if(count < MIN_PLAYERS)
    {
        LobbyTimer = SetTimer("LobbyCount",1000,true);
        return 1;
    }

    PresidentID = players[random(count)];
    PlayerTeam[PresidentID] = TEAM_PRESIDENT;

    new name[MAX_PLAYER_NAME];
    GetPlayerName(PresidentID,name,sizeof(name));

    new msg[128];
    format(msg,sizeof msg,"%s is the President!",name);
    SendClientMessageToAll(-1,msg);

    for(new i = 0; i < count; i++)
    {
        SpawnPlayer(players[i]);
    }

    PresidentVehicle = CreateVehicle(409,1481.0,-1765.0,18.8,0.0,1,1,-1);

    if(PresidentVehicle != INVALID_VEHICLE_ID)
    {
        PutPlayerInVehicle(PresidentID,PresidentVehicle,0);
    }

    RoundActive = true;

    RoundTimer = SetTimer("RoundTimeUp",ROUND_TIME*1000,false);

    return 1;
}

public RoundTimeUp()
{
    if(RoundActive)
    {
        SendClientMessageToAll(-1,"President survived!");
        EndRound(TEAM_SECRET);
    }
    return 1;
}

public EndRound(team)
{
    RoundActive = false;

    KillTimer(RoundTimer);

    if(PresidentVehicle != INVALID_VEHICLE_ID)
    {
        DestroyVehicle(PresidentVehicle);
        PresidentVehicle = INVALID_VEHICLE_ID;
    }

    PresidentID = INVALID_PLAYER_ID;

    SendClientMessageToAll(-1,"Next round soon...");

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i))
        {
            PlayerTeam[i] = TEAM_NONE;
            SpawnPlayer(i);
        }
    }

    LobbyTimer = SetTimer("LobbyCount",1000,true);

    return 1;
}

public OnPlayerCommandText(playerid,cmdtext[])
{
    if(strcmp(cmdtext,"/joinsecret",true)==0)
    {
        if(RoundActive) return SendClientMessage(playerid,-1,"Wait next round.");

        PlayerTeam[playerid] = TEAM_SECRET;
        SendClientMessage(playerid,-1,"You joined Secret Service.");
        return 1;
    }

    if(strcmp(cmdtext,"/joinassassin",true)==0)
    {
        if(RoundActive) return SendClientMessage(playerid,-1,"Wait next round.");

        PlayerTeam[playerid] = TEAM_ASSASSIN;
        SendClientMessage(playerid,-1,"You joined Assassins.");
        return 1;
    }

    if(strcmp(cmdtext,"/score",true)==0)
    {
        new msg[64];
        format(msg,sizeof msg,"Score: %d",PlayerScore[playerid]);
        SendClientMessage(playerid,-1,msg);
        return 1;
    }

    if(strcmp(cmdtext,"/spec",true)==0)
    {
        TogglePlayerSpectating(playerid,true);
        SendClientMessage(playerid,-1,"Spectator mode enabled.");
        return 1;
    }

    return 0;
}
