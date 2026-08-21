/** "Stone Gaze" - Bonus damage to incapacitated targets. Placeholder for petrify. */
class ZTRoguelikeHelper_MEDUSA extends ZTRoguelikeHelper;

const PETRIFIED_BONUS = 2.00;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    if (Target != None && Target.IsIncapacitated())
        return PETRIFIED_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_MEDUSA"
}
