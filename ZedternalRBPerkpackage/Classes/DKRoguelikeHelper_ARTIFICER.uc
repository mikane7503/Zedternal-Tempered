/** "Masterwork Synthesis" - Each mastery milestone gives +3% dmg to all other weapons. */
class DKRoguelikeHelper_ARTIFICER extends DKRoguelikeHelper;

var int TrackedMilestones;
const BONUS_PER_MILESTONE = 0.03;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (TrackedMilestones > 0)
        return BONUS_PER_MILESTONE * float(TrackedMilestones);
    return 0.0;
}

/** Called externally from Artificer helper when milestone is reached */
function OnMasteryMilestone()
{
    TrackedMilestones++;
    `log("[DK_RL_ARTIFICER] Masterwork Synthesis: +" $ int(BONUS_PER_MILESTONE * TrackedMilestones * 100) $ "% dmg");
}

defaultproperties
{
    TrackedMilestones=0
    Name="Default__DKRoguelikeHelper_ARTIFICER"
}
