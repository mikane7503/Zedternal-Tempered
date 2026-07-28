/** "Phalanx Protocol" - Full immunity while blocking. Parries stagger all 3m. */
class DKRoguelikeHelper_RIOT extends DKRoguelikeHelper;

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
    Name="Default__DKRoguelikeHelper_RIOT"
}
