/** "Undying Rage" - Cheat death: 5s invuln + 100% melee. 60s CD. */
class DKRoguelikeHelper_BERSERKER extends DKRoguelikeHelper;

var float LastTriggerTime;
var float InvulnEndTime;
const INVULN_DURATION = 5.0;
const COOLDOWN = 60.0;
const MELEE_BONUS = 1.00;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (OwnerPawn != None && OwnerPawn.WorldInfo.TimeSeconds < InvulnEndTime)
    {
        if (DamageType != None && ClassIsChildOf(DamageType, class'KFDT_Bludgeon'))
            return MELEE_BONUS;
    }
    return 0.0;
}

function ModifyIncomingDamage(out int InDamage, int DefaultDamage, KFPawn OwnerP, class<DamageType> DamageType)
{
    // During invuln: immune
    if (OwnerP != None && OwnerP.WorldInfo.TimeSeconds < InvulnEndTime)
    {
        InDamage = 0;
        return;
    }
    // Death prevention
    if (OwnerP != None && (OwnerP.Health - InDamage) <= 0)
    {
        if (OwnerP.WorldInfo.TimeSeconds - LastTriggerTime >= COOLDOWN)
        {
            LastTriggerTime = OwnerP.WorldInfo.TimeSeconds;
            InvulnEndTime = OwnerP.WorldInfo.TimeSeconds + INVULN_DURATION;
            InDamage = OwnerP.Health - 1;
            `log("[DK_RL_BERSERKER] Undying Rage ACTIVATED!");
        }
    }
}

defaultproperties
{
    LastTriggerTime=-999.0
    InvulnEndTime=0.0
    Name="Default__DKRoguelikeHelper_BERSERKER"
}
