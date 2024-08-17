using{/Fortnite.com/Devices}
using { /Verse.org/Simulation }
using { /Verse.org/Random }
using {cc}

tycoon_stomper <public> := class(creative_device):
    var PlayerStatsMap <public> : [player]?playerstats = map{}

    

    @editable var Bases <public> : []base = array{}

    @editable var SL <public> : log = log{}
    

    #When the game starts, tell the bases to start / initialize
    OnBegin<override>()<suspends>:void=
        for(I -> Base:Bases):
            Base.OnBegin(I)
            set Base.Owner = Self



    AsyncManageTempStats()<suspends>:void=
        Playspace := GetPlayspace()
            race:
                block:
                    Player := Playspace.PlayerAddedEvent().Await()
                    if. GiveTemporaryPlayerStats[Player]
                block:
                    Player := Playspace.PlayerRemovedEvent().Await()
                    if. RemoveTemporaryPlayerStats[Player]
        
    GiveTemporaryPlayerStats(P:player)<transacts><decides>:void=
        not PlayerStatsMap[P]?
        set PlayerStatsMap[P] = option{playerstats{}}
        GlobalSuperlog("Granted player stats to a player")

    RemoveTemporaryPlayerStats(P:player)<transacts><decides>:void=
        PlayerStatsMap[P]?
        set PlayerStatsMap[P] = false
        GlobalSuperlog("Removed player stats from a player")

    


        


    