/** "Phalanx Protocol" - Full immunity while blocking. Parries stagger all 3m. */
class ZTRoguelikeHelper_RIOT extends ZTRoguelikeHelper;

function ModifyIncomingDamage(out int InDamage, int DefaultDamage, KFPawn OwnerP, class<DamageType> DamageType)
{
    local KFPawn_Human KFPH;
    KFPH = KFPawn_Human(OwnerP);
    if (KFPH != None && KFPH.IsDoingSpecialMove(SM_Block))
    {
        InDamage = 0;
    }
}

defaultproperties
{
    Name="Default__ZTRoguelikeHelper_RIOT"
}
