/**
 * ZTRoguelikeHelper_TYCOON — "Hostile Takeover"
 * Per 1000 dosh earned, gain +2% permanent all-damage bonus (max +20%).
 * Trader purchases refund 5% of the price.
 */
class ZTRoguelikeHelper_TYCOON extends ZTRoguelikeHelper;

var int TrackedDosh;
var int MilestonesReached;

const DOSH_PER_MILESTONE = 1000;
const DAMAGE_PER_MILESTONE = 0.02;
const MAX_MILESTONES = 10;  // 10 * 2% = 20% cap

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (MilestonesReached > 0)
        return DAMAGE_PER_MILESTONE * float(MilestonesReached);

    return 0.0;
}

/** Called externally when player earns dosh (kills, wave end, etc.) */
function TrackDoshEarned(int Amount)
{
    local int NewMilestones;

    if (Amount <= 0)
        return;

    TrackedDosh += Amount;
    NewMilestones = Min(TrackedDosh / DOSH_PER_MILESTONE, MAX_MILESTONES);

    if (NewMilestones > MilestonesReached)
    {
        MilestonesReached = NewMilestones;
        `log("[DK_RL_TYCOON] Hostile Takeover:" @ MilestonesReached @ "milestones (+" $ int(DAMAGE_PER_MILESTONE * MilestonesReached * 100) $ "% dmg)");
    }
}

defaultproperties
{
    TrackedDosh=0
    MilestonesReached=0
    Name="Default__ZTRoguelikeHelper_TYCOON"
}
