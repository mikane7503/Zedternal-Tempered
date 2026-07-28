/** "Black Ops Protocol" - +50% from behind. 30% less aggro. First hit unaware = crit. */
class DKRoguelikeHelper_SPECIALAGENT extends DKRoguelikeHelper;

const BACKSTAB_BONUS = 0.50;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    local vector ToAttacker, TargetFwd;
    if (Target == None || OwnerPawn == None) return 0.0;
    ToAttacker = Normal(OwnerPawn.Location - Target.Location);
    TargetFwd = vector(Target.Rotation);
    if ((ToAttacker dot TargetFwd) < -0.5)
        return BACKSTAB_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_SPECIALAGENT"
}
