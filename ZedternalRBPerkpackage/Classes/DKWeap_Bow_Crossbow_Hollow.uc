class DKWeap_Bow_Crossbow_Hollow extends KFWeap_Bow_Crossbow;

// ===================================================================
// HOLLOW VARIANT — Bow_Crossbow
//
// This is a Hollow weapon variant. It extends the base weapon directly.
// Stat bonuses are applied through DKUpgrade_Perk_Hollow's ModifyXXX
// functions using DKHollowWeaponData for bonus values.
//
// - BuyPrice: 0 (free once unlocked)
// - Not eligible for weapon upgrades
// - Only visible to the player who completed all 5 conditions
// ===================================================================


simulated function string GetHumanReadableName()
{
	return "Marrow Bolt";
}


defaultproperties
{
	Name="Default__DKWeap_Bow_Crossbow_Hollow"
}
