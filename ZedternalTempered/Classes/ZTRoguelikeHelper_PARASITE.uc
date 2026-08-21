/** "Infestation Cascade" - Infested kills spread to 2 nearby: +20% dmg, -20% speed. */
class ZTRoguelikeHelper_PARASITE extends ZTRoguelikeHelper;

const INFESTED_BONUS = 0.20;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    return INFESTED_BONUS;
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_PARASITE"
}
