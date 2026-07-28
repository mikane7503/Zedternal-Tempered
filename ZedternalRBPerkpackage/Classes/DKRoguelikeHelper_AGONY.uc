/** "Temporal Prison" - ZT kills 20% chance freeze nearby zeds 3s. 15s CD. */
class DKRoguelikeHelper_AGONY extends DKRoguelikeHelper;

var float LastProcTime;
const PROC_CHANCE = 0.20;
const COOLDOWN = 15.0;

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (OwnerPawn == None || OwnerPawn.WorldInfo.TimeDilation >= 1.0)
        return;
    if (OwnerPawn.WorldInfo.TimeSeconds - LastProcTime < COOLDOWN)
        return;
    if (FRand() <= PROC_CHANCE)
    {
        LastProcTime = OwnerPawn.WorldInfo.TimeSeconds;
        `log("[DK_RL_AGONY] Temporal Prison: ACTIVATED!");
    }
}

defaultproperties
{
    LastProcTime=-999.0
    Name="Default__DKRoguelikeHelper_AGONY"
}
