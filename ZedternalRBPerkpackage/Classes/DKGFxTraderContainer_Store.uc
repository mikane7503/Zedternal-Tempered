class DKGFxTraderContainer_Store extends WMGFxTraderContainer_Store;

// ===================================================================
// DK TRADER STORE — Per-Player Hollow Weapon Filtering
//
// Extends IsItemFiltered to hide Hollow weapons from players who
// haven't unlocked them. Uses the Hollow Helper's client-side
// unlock cache to determine visibility.
//
// The DKGFxMenu_Trader must bind this class via SubWidgetBindings:
//   SubWidgetBindings(2)=(WidgetName="ShopContainer",
//       WidgetClass=Class'ZedternalRBPerkpackage.DKGFxTraderContainer_Store')
// ===================================================================

function bool IsItemFiltered(STraderItem Item, optional bool bDebug)
{
	// Check Hollow weapons FIRST — before super.
	// super.IsItemFiltered calls IsItemAllowed which is wave-gated.
	// Hollow weapons are registered at the end of AllowedWeaponsList,
	// so they're always beyond the wave-gate cutoff.
	// We handle Hollow visibility ourselves via the unlock cache.
	if (IsHollowItem(Item))
	{
		// If Hollow weapon system is disabled, hide all Hollow items
		if (!class'DKConfig_HollowWeapons'.static.IsEnabled())
			return True;

		// Still check if player already owns this weapon
		if (KFPC.GetPurchaseHelper().IsInOwnedItemList(Item.ClassName))
			return True;

		// Filter by unlock state
		if (!IsHollowUnlockedForPlayer(Item))
			return True;

		// Hollow weapon is unlocked — show it (bypass wave gate)
		return False;
	}

	// Non-Hollow weapons: use normal filtering (wave-gated)
	return super.IsItemFiltered(Item, bDebug);
}

// Check if a trader item is a Hollow weapon variant
function bool IsHollowItem(STraderItem Item)
{
	local string ClassName;
	local string DefName;

	// Primary check: weapon class name
	ClassName = string(Item.ClassName);
	if (Len(ClassName) > 7 && Right(ClassName, 7) ~= "_Hollow")
		return True;

	// Fallback: WeaponDef class name (more reliable early in loading)
	if (Item.WeaponDef != None)
	{
		DefName = string(Item.WeaponDef.Name);
		if (Len(DefName) > 7 && Right(DefName, 7) ~= "_Hollow")
			return True;
	}

	return False;
}

// Check if the local player has unlocked this Hollow weapon
function bool IsHollowUnlockedForPlayer(STraderItem Item)
{
	local DKUpgrade_Perk_Hollow_Helper HollowHelper;
	local KFPawn_Human KFPH;
	local string NormName;
	local string WeapClassName;

	if (KFPC == None || KFPC.Pawn == None)
		return False;

	KFPH = KFPawn_Human(KFPC.Pawn);
	if (KFPH == None)
		return False;

	// Get the weapon class name from ClassName or WeaponDef path
	WeapClassName = string(Item.ClassName);
	if (WeapClassName == "" || WeapClassName == "None")
	{
		if (Item.WeaponDef != None)
			WeapClassName = Split(Item.WeaponDef.default.WeaponClassPath, ".", true);
	}

	if (WeapClassName == "")
		return False;

	// Normalize: strip prefix + _Hollow suffix
	NormName = class'DKUpgrade_Perk_Hollow'.static.NormalizeWeaponName(WeapClassName);

	// Find the Hollow Helper on this player's pawn
	foreach KFPH.ChildActors(class'DKUpgrade_Perk_Hollow_Helper', HollowHelper)
	{
		return HollowHelper.IsWeaponUnlockedClient(NormName);
	}

	// No Hollow Helper found = player doesn't have the Hollow perk = hide all Hollow weapons
	return False;
}

defaultproperties
{
	Name="Default__DKGFxTraderContainer_Store"
}
