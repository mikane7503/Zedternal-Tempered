/**
 * ZTRoguelikeHelper_VOODOO — "Blood Pact"
 * At 1 HP: additional +50% damage on top of existing Voodoo scaling.
 * Kills at 1 HP heal 3 HP.
 */
class ZTRoguelikeHelper_VOODOO extends ZTRoguelikeHelper;

const LOW_HP_THRESHOLD = 1;
const DAMAGE_BONUS = 0.50;
const HEAL_AMOUNT = 3;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (OwnerPawn != None && OwnerPawn.Health <= LOW_HP_THRESHOLD)
        return DAMAGE_BONUS;

    return 0.0;
}

function OnZedKilled(KFPawn_Monster Killed, int HitZoneIdx, KFPlayerController KillerPC)
{
    if (OwnerPawn != None && OwnerPawn.Health <= LOW_HP_THRESHOLD)
    {
        OwnerPawn.Health = Min(OwnerPawn.Health + HEAL_AMOUNT, OwnerPawn.HealthMax);
        `log("[DK_RL_VOODOO] Blood Pact: healed" @ HEAL_AMOUNT @ "HP on kill at 1 HP");
    }
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_VOODOO"
}
