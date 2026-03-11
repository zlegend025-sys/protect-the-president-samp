new PresidentMarker;

#include <a_samp>

#define TEAM_NONE 0
#define TEAM_PRESIDENT 1
#define TEAM_SECRET 2
#define TEAM_ASSASSIN 3

#define ROUND_TIME 600000 // 10 minutes

new PlayerTeam[MAX_PLAYERS];
new PresidentID = INVALID_PLAYER_ID;
new RoundActive = false;
new RoundTimer;

forward StartRound();
forward EndRound(team);

public OnGameModeInit()
{
    SetGameModeText("Protect The President");

    AddPlayerClass(0, 1481.0,-1771.0,18.8,0.0,0,0,0,0,0,0);

    print("Protect the President gamemode loaded.");
    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerTeam[playerid] = TEAM_NONE;

    SendClientMessage(playerid,-1,"Welcome to Protect the President.");

    if(GetPlayerPoolSize() >= 2 && !RoundActive)
    {
        StartRound();
    }

    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(playerid == PresidentID && RoundActive)
    {
        SendClientMessageToAll(-1,"President left the game. Assassins win.");
        EndRound(TEAM_ASSASSIN);
    }
    return 1;
}

public OnPlayerSpawn(playerid)
{
    ResetPlayerWeapons(playerid);

    switch(PlayerTeam[playerid])
    {
        case TEAM_PRESIDENT:
        {
            SetPlayerColor(playerid,0xFFFF00FF);
            SetPlayerPos(playerid,1481.0,-1771.0,18.8);

            GivePlayerWeapon(playerid,24,100);
        }

        case TEAM_SECRET:
        {
            SetPlayerColor(playerid,0x00FFFFFF);
            SetPlayerPos(playerid,1485.0,-1770.0,18.8);

            GivePlayerWeapon(playerid,31,200);
        }

        case TEAM_ASSASSIN:
        {
            SetPlayerColor(playerid,0xFF0000FF);
            SetPlayerPos(playerid,1500.0,-1800.0,18.8);

            GivePlayerWeapon(playerid,34,50);
        }
    }

    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    if(playerid == PresidentID && RoundActive)
    {
        SendClientMessageToAll(-1,"The President has been assassinated!");
        EndRound(TEAM_ASSASSIN);
    }

    return 1;
}

StartRound()
{
    new players[MAX_PLAYERS], count;

    for(new i=0;i<MAX_PLAYERS;i++)
    {
        if(IsPlayerConnected(i))
        {
            players[count++] = i;
        }
    }

    if(count < 2) return 1;

    PresidentID = players[random(count)];

    for(new i=0;i<count;i++)
    {
        new id = players[i];

        if(id == PresidentID)
        {
            PlayerTeam[id] = TEAM_PRESIDENT;
        }
        else
        {
            if(random(2))
                PlayerTeam[id] = TEAM_SECRET;
            else
                PlayerTeam[id] = TEAM_ASSASSIN;
        }

        SpawnPlayer(id);
    }

    RoundActive = true;

    SendClientMessageToAll(-1,"Round started! Protect the President!");

    RoundTimer = SetTimer("RoundTimeUp",ROUND_TIME,false);

    return 1;
}

forward RoundTimeUp();

public RoundTimeUp()
{
    if(RoundActive)
    {
        SendClientMessageToAll(-1,"President survived. Secret Service wins!");
        EndRound(TEAM_SECRET);
    }

    return 1;
}

EndRound(team)
{
    RoundActive = false;

    KillTimer(RoundTimer);

    for(new i=0;i<MAX_PLAYERS;i++)
    {
        if(IsPlayerConnected(i))
        {
            GameTextForPlayer(i,"~w~Next round starting...",3000,3);
        }
    }

    SetTimer("StartRound",5000,false);

    return 1;
}
