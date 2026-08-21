// ===================================================================
// ZTGameReplicationInfo_AllWeapons - All Weapons mode variant
// Extends ZTGameReplicationInfo to inherit character selection system
// Overrides IsItemAllowed to unlock ALL normal weapons from wave 1
// Reforged weapons still require bitmask unlock via Artificer perk
// ===================================================================
class ZTGameReplicationInfo_AllWeapons extends ZTGameReplicationInfo;

// Override: Allow all NORMAL items, but Reforged weapons still require bitmask unlock
simulated function bool IsItemAllowed(STraderItem Item)
{
    local string ClassName;
    local int i, BitIndex;

    // Check if this is a Reforged weapon by class name suffix
    ClassName = string(Item.ClassName);
    if (Len(ClassName) > 8 && Right(ClassName, 8) ~= "Reforged")
    {
        // Reforged weapons must pass the bitmask check
        if (ReforgedStartIndex > 0)
        {
            for (i = ReforgedStartIndex; i < AllowedWeaponsList.Length; ++i)
            {
                if (Item.ClassName == AllowedWeaponsList[i].WeaponName
                    || Item.SingleClassName == AllowedWeaponsList[i].WeaponName)
                {
                    BitIndex = i - ReforgedStartIndex;
                    return IsReforgedBitSet(BitIndex);
                }
            }
        }

        return False;
    }

    // DK FIX: Precious filter REMOVED. Precious weapon variants are allowed
    // again (ZR parity) -- hiding them while the server consumed RNG slot
    // positions for them desynced the weapon-upgrade lists. Same fix as
    // ZTGameReplicationInfo.IsItemAllowed.

    // All non-Reforged weapons are always allowed in AllWeapons mode
    return True;
}

defaultproperties
{
    Name="Default__ZTGameReplicationInfo_AllWeapons"
}
