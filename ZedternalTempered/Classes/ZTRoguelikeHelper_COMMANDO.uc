/** "Endless Zed Time" - +50% ZT extension, full speed, +25% dmg during ZT. */
class ZTRoguelikeHelper_COMMANDO extends ZTRoguelikeHelper;

const ZT_DAMAGE_BONUS = 0.25;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (OwnerPawn != None && OwnerPawn.WorldInfo.TimeDilation < 1.0)
        return ZT_DAMAGE_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_COMMANDO"
}
