/** "Jack of All Trades" - +5% damage per distinct perk weapon type. Max 6 = +30%. */
class DKRoguelikeHelper_SURVIVALIST extends DKRoguelikeHelper;

function float GetDamageMultiplier(KFPawn_Monster Target, class<KFDamageType> DamageType, int HitZoneIdx, Actor DamageCauser)
{
    local int TypeCount;

    if (OwnerPawn == None)
        return 0.0;

    TypeCount = CountDistinctPerkWeaponTypes();
    if (TypeCount > 6)
        TypeCount = 6;

    return 0.05 * float(TypeCount);
}

function int CountDistinctPerkWeaponTypes()
{
    local Inventory Inv;
    local KFWeapon KFW;
    local array< class<KFPerk> > PerkList;
    local array< class<KFPerk> > SeenPerks;
    local int i;

    if (OwnerPawn == None || OwnerPawn.InvManager == None)
        return 0;

    for (Inv = OwnerPawn.InvManager.InventoryChain; Inv != None; Inv = Inv.Inventory)
    {
        KFW = KFWeapon(Inv);
        if (KFW == None)
            continue;

        PerkList = KFW.GetAssociatedPerkClasses();
        for (i = 0; i < PerkList.Length; i++)
        {
            if (PerkList[i] != None && SeenPerks.Find(PerkList[i]) == INDEX_NONE)
                SeenPerks.AddItem(PerkList[i]);
        }
    }

    return SeenPerks.Length;
}

defaultproperties
{
    Name="Default__DKRoguelikeHelper_SURVIVALIST"
}
