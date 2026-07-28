/** "Shatter Storm" - Frozen enemy kills explode into ice shards. */
class DKRoguelikeHelper_CRYOPHILITE extends DKRoguelikeHelper;

const FREEZE_KILL_BONUS = 0.30;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Freeze'))
        return FREEZE_KILL_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_CRYOPHILITE"
}
