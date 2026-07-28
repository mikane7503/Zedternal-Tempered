/** "Void Resonance" - Hollow weapons +25% dmg. 10% kill -> Void Rift. */
class DKRoguelikeHelper_HOLLOW extends DKRoguelikeHelper;

const HOLLOW_BONUS = 0.25;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    local KFWeapon KFW;
    KFW = KFWeapon(DamageCauser);
    if (KFW == None && DamageCauser != None && DamageCauser.Instigator != None)
        KFW = KFWeapon(DamageCauser.Instigator.Weapon);
    if (KFW != None && InStr(string(KFW.Class.Name), "_Hollow") != INDEX_NONE)
        return HOLLOW_BONUS;
    return 0.0;
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_HOLLOW"
}
