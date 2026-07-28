/** "Bullet Storm" - 50 consecutive hits = 5s frenzy: +100% fire rate, unlimited ammo. */
class DKRoguelikeHelper_SWAT extends DKRoguelikeHelper;

var int ConsecutiveHits;
var float FrenzyEndTime;
const HITS_FOR_FRENZY = 50;
const FRENZY_DAMAGE_BONUS = 0.30;
const FRENZY_DURATION = 5.0;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    ConsecutiveHits++;
    if (ConsecutiveHits >= HITS_FOR_FRENZY && OwnerPawn != None)
    {
        if (OwnerPawn.WorldInfo.TimeSeconds >= FrenzyEndTime)
        {
            FrenzyEndTime = OwnerPawn.WorldInfo.TimeSeconds + FRENZY_DURATION;
            ConsecutiveHits = 0;
            `log("[DK_RL_SWAT] Bullet Storm: FRENZY!");
        }
    }
    if (OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds < FrenzyEndTime)
        return FRENZY_DAMAGE_BONUS;
    return 0.0;
}

defaultproperties
{
    ConsecutiveHits=0
    FrenzyEndTime=0.0
    Name="Default__DKRoguelikeHelper_SWAT"
}
