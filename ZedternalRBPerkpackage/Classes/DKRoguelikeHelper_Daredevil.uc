/**
 * DKRoguelikeHelper_Daredevil — "Dead Man's Hand"
 * Consecutive headshot kills build a damage multiplier.
 * 1st = baseline, 2nd = +20%, 3rd = +40%, 4th = +60%, 5th+ = +100%.
 * Resets on non-headshot kill.
 */
class DKRoguelikeHelper_Daredevil extends DKRoguelikeHelper;

var int ConsecutiveHeadshotKills;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    // Bonus applies to ALL shots while streak is active, not just headshots
    if (ConsecutiveHeadshotKills <= 0)
        return 0.0;

    if (ConsecutiveHeadshotKills == 1)
        return 0.20;
    else if (ConsecutiveHeadshotKills == 2)
        return 0.40;
    else if (ConsecutiveHeadshotKills == 3)
        return 0.60;
    else
        return 1.00; // 4+ kills = +100%
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (HitZoneIdx == HZI_HEAD)
    {
        ConsecutiveHeadshotKills++;
        if (ConsecutiveHeadshotKills <= 5)
        {
            `log("[DK_RL_DAREDEVIL] Dead Man's Hand: streak" @ ConsecutiveHeadshotKills);
        }
    }
    else
    {
        // Body shot kill breaks the streak
        if (ConsecutiveHeadshotKills > 0)
        {
            `log("[DK_RL_DAREDEVIL] Dead Man's Hand: streak broken at" @ ConsecutiveHeadshotKills);
            ConsecutiveHeadshotKills = 0;
        }
    }
}

defaultproperties
{
    ConsecutiveHeadshotKills=0
    Name="Default__DKRoguelikeHelper_Daredevil"
}
