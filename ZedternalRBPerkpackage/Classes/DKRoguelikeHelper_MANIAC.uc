/** "Chain Detonation" - Grenade kills 30% chance drop another. +15% nade dmg. */
class DKRoguelikeHelper_MANIAC extends DKRoguelikeHelper;

const GRENADE_BONUS = 0.15;
const CHAIN_CHANCE = 0.30;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Explosive'))
        return GRENADE_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_MANIAC"
}
