/** "One Shot One Kill" - Large zed HS kills refund 50% ammo. +25% dmg after HS kill 2s. */
class DKRoguelikeHelper_SHARPSHOOTER extends DKRoguelikeHelper;

var float BonusExpireTime;
const POST_HS_BONUS = 0.25;
const BONUS_WINDOW = 2.0;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds < BonusExpireTime)
        return POST_HS_BONUS;
    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (HitZoneIdx == HZI_HEAD)
    {
        if (OwnerPawn != None)
            BonusExpireTime = OwnerPawn.WorldInfo.TimeSeconds + BONUS_WINDOW;
    }
}

defaultproperties
{
    BonusExpireTime=0.0
    Name="Default__DKRoguelikeHelper_SHARPSHOOTER"
}
