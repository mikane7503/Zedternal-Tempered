/** "Apex Predator" - Marked kills: +15% dmg 10s. Large zed marks: +30%. */
class ZTRoguelikeHelper_PREDATOR extends ZTRoguelikeHelper;

var float BonusExpireTime;
var float CurrentBonus;
const NORMAL_BONUS = 0.15;
const LARGE_BONUS = 0.30;
const BONUS_DURATION = 10.0;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds < BonusExpireTime)
        return CurrentBonus;
    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (OwnerPawn == None) return;
    if (Killed != None && Killed.IsLargeZed())
        CurrentBonus = LARGE_BONUS;
    else
        CurrentBonus = NORMAL_BONUS;
    BonusExpireTime = OwnerPawn.WorldInfo.TimeSeconds + BONUS_DURATION;
}

defaultproperties
{
    BonusExpireTime=0.0
    CurrentBonus=0.0
    Name="Default__ZTRoguelikeHelper_PREDATOR"
}
