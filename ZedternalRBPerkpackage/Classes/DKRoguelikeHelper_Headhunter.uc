/**
 * DKRoguelikeHelper_Headhunter — "Trophy Collection"
 * Every 25 headshot kills accumulated grants permanent +2% headshot damage.
 * No cap. Progress persists for the entire run.
 */
class DKRoguelikeHelper_Headhunter extends DKRoguelikeHelper;

var int HeadshotKills;
var int MilestonesReached;

const KILLS_PER_MILESTONE = 25;
const BONUS_PER_MILESTONE = 0.02;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    // Only apply bonus on headshots
    if (HitZoneIdx == HZI_HEAD && MilestonesReached > 0)
        return BONUS_PER_MILESTONE * float(MilestonesReached);

    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    local int NewMilestones;

    if (HitZoneIdx != HZI_HEAD)
        return;

    HeadshotKills++;
    NewMilestones = HeadshotKills / KILLS_PER_MILESTONE;

    if (NewMilestones > MilestonesReached)
    {
        MilestonesReached = NewMilestones;
        `log("[DK_RL_HEADHUNTER] Trophy Collection:" @ MilestonesReached @ "milestones (+" $ int(BONUS_PER_MILESTONE * MilestonesReached * 100) $ "% HS dmg)");
    }
}

defaultproperties
{
    HeadshotKills=0
    MilestonesReached=0
    Name="Default__DKRoguelikeHelper_Headhunter"
}
