/** "Perfect Symbiosis" - +2 HP/s above 50%. Below 50%: +30% dmg. */
class DKRoguelikeHelper_SYMBIOTE extends DKRoguelikeHelper;

const LOW_HP_BONUS = 0.30;
const REGEN_RATE = 2;

function Initialize(KFPawn_Human InPawn)
{
    super.Initialize(InPawn);
    SetTimer(1.0, true, 'RegenTick');
}

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (OwnerPawn != None && OwnerPawn.Health < (OwnerPawn.HealthMax / 2))
        return LOW_HP_BONUS;
    return 0.0;
}

function RegenTick()
{
    if (OwnerPawn != None && OwnerPawn.IsAliveAndWell() && OwnerPawn.Health >= (OwnerPawn.HealthMax / 2))
        OwnerPawn.Health = Min(OwnerPawn.Health + REGEN_RATE, OwnerPawn.HealthMax);
}

function Cleanup()
{
    ClearTimer('RegenTick');
    super.Cleanup();
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_SYMBIOTE"
}
