/** "Spontaneous Combustion" - Every 15 kills: next hit ignites 5x. Large +500 fire. */
class DKRoguelikeHelper_PYROKINETIC extends DKRoguelikeHelper;

var int KillCount;
var bool bCharged;
const KILLS_PER_CHARGE = 15;
const CHARGED_BONUS = 1.00;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (bCharged)
    {
        bCharged = false;
        `log("[DK_RL_PYROKINETIC] Spontaneous Combustion!");
        return CHARGED_BONUS;
    }
    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    KillCount++;
    if (KillCount >= KILLS_PER_CHARGE)
    {
        KillCount = 0;
        bCharged = true;
        `log("[DK_RL_PYROKINETIC] Spontaneous Combustion CHARGED");
    }
}

defaultproperties
{
    KillCount=0
    bCharged=false
    Name="Default__DKRoguelikeHelper_PYROKINETIC"
}
