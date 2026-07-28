/** "Pandemic Protocol" - Toxic kills -> poison cloud. Poisoned: -30% dmg, +15% taken. */
class DKRoguelikeHelper_VENOMANCER extends DKRoguelikeHelper;

const TOXIC_BONUS = 0.15;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Toxic'))
        return TOXIC_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_VENOMANCER"
}
