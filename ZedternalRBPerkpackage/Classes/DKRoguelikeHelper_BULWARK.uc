/**
 * DKRoguelikeHelper_BULWARK — "Immovable Object"
 * Cannot be knocked down or stumbled.
 * Hits over 50 damage are capped at 50 (10s cooldown).
 */
class DKRoguelikeHelper_BULWARK extends DKRoguelikeHelper;

var float LastDamageCapTime;

const DAMAGE_CAP = 50;
const CAP_COOLDOWN = 10.0;

function ModifyIncomingDamage(out int InDamage, int DefaultDamage, KFPawn OwnerP, class<DamageType> DamageType)
{
    if (InDamage > DAMAGE_CAP)
    {
        if (OwnerP.WorldInfo.TimeSeconds - LastDamageCapTime >= CAP_COOLDOWN)
        {
            LastDamageCapTime = OwnerP.WorldInfo.TimeSeconds;
            `log("[DK_RL_BULWARK] Immovable Object: capped" @ InDamage @ "to" @ DAMAGE_CAP);
            InDamage = DAMAGE_CAP;
        }
    }
}

defaultproperties
{
    LastDamageCapTime=-999.0
    Name="Default__DKRoguelikeHelper_BULWARK"
}
