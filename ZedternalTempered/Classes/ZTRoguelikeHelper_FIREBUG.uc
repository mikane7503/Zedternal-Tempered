/** "Infernal Aura" - Zeds in 5m on fire. Ground fire 50% larger/longer. */
class ZTRoguelikeHelper_FIREBUG extends ZTRoguelikeHelper;

const FIRE_DAMAGE_BONUS = 0.15;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Fire'))
        return FIRE_DAMAGE_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_FIREBUG"
}
