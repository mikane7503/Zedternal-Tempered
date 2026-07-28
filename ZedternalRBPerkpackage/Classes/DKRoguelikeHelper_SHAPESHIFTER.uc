/** "Chimera Form" - Form bonuses doubled. Switching forms: 3s invuln. */
class DKRoguelikeHelper_SHAPESHIFTER extends DKRoguelikeHelper;

var float InvulnEndTime;
const FORM_BONUS = 0.20;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    return FORM_BONUS;
}

function ModifyIncomingDamage(out int InDamage, int DefaultDamage, KFPawn OwnerP, class<DamageType> DamageType)
{
    if (OwnerP != None && OwnerP.WorldInfo.TimeSeconds < InvulnEndTime)
        InDamage = 0;
}

defaultproperties
{
    InvulnEndTime=0.0
    Name="Default__DKRoguelikeHelper_SHAPESHIFTER"
}
