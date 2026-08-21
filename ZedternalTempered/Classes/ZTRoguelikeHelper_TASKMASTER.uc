/** "Drill Sergeant" - All allies +5% dmg/reload permanent. Kills heal ally 5HP (10s CD). */
class ZTRoguelikeHelper_TASKMASTER extends ZTRoguelikeHelper;

var float LastAllyHealTime;
const ALLY_HEAL = 5;
const HEAL_COOLDOWN = 10.0;
const SELF_BONUS = 0.05;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    return SELF_BONUS;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    local KFPawn_Human KFPH;
    if (OwnerPawn == None) return;
    if (OwnerPawn.WorldInfo.TimeSeconds - LastAllyHealTime < HEAL_COOLDOWN) return;

    foreach OwnerPawn.WorldInfo.AllPawns(class'KFPawn_Human', KFPH)
    {
        if (KFPH != OwnerPawn && KFPH.IsAliveAndWell())
        {
            KFPH.Health = Min(KFPH.Health + ALLY_HEAL, KFPH.HealthMax);
            LastAllyHealTime = OwnerPawn.WorldInfo.TimeSeconds;
            break;
        }
    }
}

defaultproperties
{
    LastAllyHealTime=-999.0
    Name="Default__ZTRoguelikeHelper_TASKMASTER"
}
