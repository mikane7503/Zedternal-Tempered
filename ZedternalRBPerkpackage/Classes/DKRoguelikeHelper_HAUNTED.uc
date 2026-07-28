/** "The Watcher's Gift" - 3% hit chance terrify. Placeholder stub. */
class DKRoguelikeHelper_HAUNTED extends DKRoguelikeHelper;

const TERRIFY_BONUS = 0.30;
const TERRIFY_CHANCE = 0.03;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    // TODO: Implement terrify/flee mechanic via custom affliction
    return 0.0;
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_HAUNTED"
}
