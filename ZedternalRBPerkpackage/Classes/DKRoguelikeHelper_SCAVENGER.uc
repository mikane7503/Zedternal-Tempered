/** "Treasure Hunter" - 5% kill -> ammo pickup. Every 50 kills -> upgrade token. */
class DKRoguelikeHelper_SCAVENGER extends DKRoguelikeHelper;

var int TotalKills;
const AMMO_DROP_CHANCE = 0.05;
const KILLS_PER_TOKEN = 50;

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    TotalKills++;
    if (FRand() <= AMMO_DROP_CHANCE)
        `log("[DK_RL_SCAVENGER] Treasure Hunter: ammo drop!");
    if (TotalKills % KILLS_PER_TOKEN == 0)
        `log("[DK_RL_SCAVENGER] Treasure Hunter: upgrade token!");
}

defaultproperties
{
    TotalKills=0
    Name="Default__DKRoguelikeHelper_SCAVENGER"
}
