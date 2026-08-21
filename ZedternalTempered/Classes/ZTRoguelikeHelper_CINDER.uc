/** "Living Pyre" - 5+ burning enemies: +50% speed, fire trail. */
class ZTRoguelikeHelper_CINDER extends ZTRoguelikeHelper;

const FIRE_BONUS = 0.20;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Fire'))
        return FIRE_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_CINDER"
}
