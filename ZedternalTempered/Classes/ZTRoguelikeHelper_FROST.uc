/** "Absolute Zero Aura" - Every 30 kills: frost pulse. Frozen +50% dmg taken. */
class ZTRoguelikeHelper_FROST extends ZTRoguelikeHelper;

var int KillCount;
const KILLS_PER_PULSE = 30;
const FROZEN_BONUS = 0.50;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (Target != None && Target.IsDoingSpecialMove(SM_Frozen))
        return FROZEN_BONUS;
    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    KillCount++;
    if (KillCount >= KILLS_PER_PULSE)
    {
        KillCount = 0;
        `log("[DK_RL_FROST] Absolute Zero Aura: frost pulse!");
    }
}

defaultproperties
{
    KillCount=0
    Name="Default__ZTRoguelikeHelper_FROST"
}
